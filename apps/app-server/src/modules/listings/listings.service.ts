import { ForbiddenException, Injectable, NotFoundException } from "@nestjs/common";
import { AuditStatus, ListingStatus, Prisma } from "@prisma/client";
import { successResponse } from "../../common/utils/api-response";
import { PrismaService } from "../prisma/prisma.service";
import { mapListingResponse } from "./listing-response.mapper";
import { CreateListingDto } from "./dto/create-listing.dto";
import { QueryListingsDto } from "./dto/query-listings.dto";
import { UpdateListingDto } from "./dto/update-listing.dto";

@Injectable()
export class ListingsService {
  constructor(private readonly prisma: PrismaService) {}

  private async expireFeaturedListingsIfNeeded() {
    await this.prisma.listing.updateMany({
      where: {
        isFeatured: true,
        featuredUntil: {
          not: null,
          lte: new Date(),
        },
      },
      data: {
        isFeatured: false,
        featuredPriority: 0,
        featuredAt: null,
        featuredUntil: null,
        opsNote: null,
      },
    });
  }

  async create(userId: string, dto: CreateListingDto) {
    const created = await this.prisma.listing.create({
      data: {
        listingType: dto.listingType,
        publisherId: userId,
        title: dto.title,
        description: dto.description,
        categoryCode: dto.categoryCode,
        tagsJson: dto.tagIds ?? [],
        cityCode: dto.cityCode,
        locationText: dto.locationText,
        longitude: dto.longitude != null ? new Prisma.Decimal(dto.longitude) : undefined,
        latitude: dto.latitude != null ? new Prisma.Decimal(dto.latitude) : undefined,
        serviceMode: dto.serviceMode,
        budgetType: dto.budgetType,
        budgetAmount: dto.budgetAmount,
        exchangeOfferText: dto.exchangeOfferText,
        exchangeWantText: dto.exchangeWantText,
        startTime: dto.startTime ? new Date(dto.startTime) : undefined,
        endTime: dto.endTime ? new Date(dto.endTime) : undefined,
        isUrgent: dto.isUrgent ?? false,
        visibility: dto.visibility,
        status: ListingStatus.PENDING_REVIEW,
        auditStatus: AuditStatus.PENDING,
        images: dto.images?.length
          ? {
              create: dto.images.map((imageUrl, index) => ({
                imageUrl,
                sortOrder: index,
              })),
            }
          : undefined,
      },
      include: {
        images: true,
      },
    });

    return successResponse(mapListingResponse(created), "listing created");
  }

  async findAll(query: QueryListingsDto, userId?: string) {
    await this.expireFeaturedListingsIfNeeded();
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? 100;
    const skip = (page - 1) * pageSize;
    const andConditions: Prisma.ListingWhereInput[] = [];
    const publicWhere: Prisma.ListingWhereInput = {
      status: {
        in: [ListingStatus.PUBLISHED, ListingStatus.MATCHED, ListingStatus.IN_PROGRESS],
      },
      auditStatus: AuditStatus.APPROVED,
    };
    const includeMine = query.includeMine === true && !!userId;

    andConditions.push(
      includeMine
        ? {
            OR: [
              publicWhere,
              {
                publisherId: userId,
              },
            ],
          }
        : publicWhere,
    );

    if (query.keyword) {
      andConditions.push({
        OR: [
          { title: { contains: query.keyword, mode: "insensitive" } },
          { description: { contains: query.keyword, mode: "insensitive" } },
        ],
      });
    }

    if (query.tagId) {
      andConditions.push({
        tagsJson: {
          array_contains: [query.tagId],
        },
      });
    }

    const where: Prisma.ListingWhereInput = {
      listingType: query.listingType,
      cityCode: query.cityCode,
      categoryCode: query.categoryCode,
      serviceMode: query.serviceMode,
      AND: andConditions,
    };

    const [items, total] = await this.prisma.$transaction([
      this.prisma.listing.findMany({
        where,
        skip,
        take: pageSize,
        orderBy: [
          { isFeatured: "desc" },
          { featuredPriority: "desc" },
          { featuredAt: "desc" },
          { publishedAt: "desc" },
          { createdAt: "desc" },
        ],
        include: {
          images: {
            orderBy: { sortOrder: "asc" },
            take: 1,
          },
          _count: {
            select: {
              applications: true,
              orders: true,
            },
          },
          publisher: {
            select: {
              id: true,
              nickname: true,
              avatarUrl: true,
              creditScore: true,
              ratingAvg: true,
              ratingCount: true,
              completedTaskCount: true,
              completedExchangeCount: true,
            },
          },
        },
      }),
      this.prisma.listing.count({ where }),
    ]);

    return successResponse({
      items: mapListingResponse(items),
      page,
      pageSize,
      total,
      hasMore: skip + items.length < total,
    });
  }

  async findMine(userId: string) {
    await this.expireFeaturedListingsIfNeeded();
    const items = await this.prisma.listing.findMany({
      where: {
        publisherId: userId,
      },
      orderBy: [
        { isFeatured: "desc" },
        { featuredPriority: "desc" },
        { featuredAt: "desc" },
        { createdAt: "desc" },
      ],
      include: {
        images: {
          orderBy: { sortOrder: "asc" },
          take: 1,
        },
        _count: {
          select: {
            applications: true,
            orders: true,
          },
        },
        publisher: {
          select: {
            id: true,
            nickname: true,
            avatarUrl: true,
            creditScore: true,
            ratingAvg: true,
            ratingCount: true,
            completedTaskCount: true,
            completedExchangeCount: true,
          },
        },
      },
    });

    return successResponse(mapListingResponse(items));
  }

  async findOne(id: string) {
    await this.expireFeaturedListingsIfNeeded();
    const listing = await this.prisma.listing.findUnique({
      where: { id },
      include: {
        images: {
          orderBy: { sortOrder: "asc" },
        },
        _count: {
          select: {
            applications: true,
            orders: true,
          },
        },
        publisher: {
          select: {
            id: true,
            nickname: true,
            avatarUrl: true,
            cityCode: true,
            bio: true,
            creditScore: true,
            level: true,
            ratingAvg: true,
            ratingCount: true,
            completedTaskCount: true,
            completedExchangeCount: true,
          },
        },
      },
    });

    if (!listing) {
      throw new NotFoundException("Listing not found");
    }

    return successResponse(mapListingResponse(listing));
  }

  async update(userId: string, id: string, dto: UpdateListingDto) {
    const listing = await this.prisma.listing.findUnique({
      where: { id },
      select: {
        id: true,
        publisherId: true,
        status: true,
      },
    });

    if (!listing) {
      throw new NotFoundException("Listing not found");
    }

    if (listing.publisherId !== userId) {
      throw new ForbiddenException("You cannot update this listing");
    }

    const isEditableStatus =
      listing.status === ListingStatus.DRAFT ||
      listing.status === ListingStatus.REJECTED ||
      listing.status === ListingStatus.PENDING_REVIEW;

    if (!isEditableStatus) {
      throw new ForbiddenException("Only editable listings can be updated");
    }

    const updated = await this.prisma.listing.update({
      where: { id },
      data: {
        title: dto.title,
        description: dto.description,
        categoryCode: dto.categoryCode,
        tagsJson: dto.tagIds ?? undefined,
        cityCode: dto.cityCode,
        locationText: dto.locationText,
        longitude: dto.longitude != null ? new Prisma.Decimal(dto.longitude) : undefined,
        latitude: dto.latitude != null ? new Prisma.Decimal(dto.latitude) : undefined,
        serviceMode: dto.serviceMode,
        budgetType: dto.budgetType,
        budgetAmount: dto.budgetAmount,
        exchangeOfferText: dto.exchangeOfferText,
        exchangeWantText: dto.exchangeWantText,
        startTime: dto.startTime ? new Date(dto.startTime) : undefined,
        endTime: dto.endTime ? new Date(dto.endTime) : undefined,
        isUrgent: dto.isUrgent,
        visibility: dto.visibility,
        ...(dto.images
          ? {
              images: {
                deleteMany: {},
                create: dto.images.map((imageUrl, index) => ({
                  imageUrl,
                  sortOrder: index,
                })),
              },
            }
          : {}),
      },
      include: {
        images: {
          orderBy: { sortOrder: "asc" },
        },
      },
    });

    return successResponse(mapListingResponse(updated), "listing updated");
  }

  async close(userId: string, id: string) {
    const listing = await this.prisma.listing.findUnique({
      where: { id },
      select: {
        id: true,
        publisherId: true,
        status: true,
        acceptedApplicationId: true,
        _count: {
          select: {
            orders: true,
          },
        },
      },
    });

    if (!listing) {
      throw new NotFoundException("Listing not found");
    }

    if (listing.publisherId !== userId) {
      throw new ForbiddenException("You cannot close this listing");
    }

    const canCloseStatus =
      listing.status === ListingStatus.DRAFT ||
      listing.status === ListingStatus.REJECTED ||
      listing.status === ListingStatus.PENDING_REVIEW ||
      listing.status === ListingStatus.PUBLISHED;

    const hasMatchedApplication = !!listing.acceptedApplicationId;
    const hasOrders = listing._count.orders > 0;

    if (!canCloseStatus || hasMatchedApplication || hasOrders) {
      throw new ForbiddenException("Matched or in-progress listings cannot be closed");
    }

    const updated = await this.prisma.listing.update({
      where: { id },
      data: {
        status: ListingStatus.CLOSED,
        closedAt: new Date(),
      },
    });

    return successResponse(mapListingResponse(updated), "listing closed");
  }
}
