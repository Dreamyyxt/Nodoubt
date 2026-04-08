import { ApplicationStatus, AuditStatus, ListingStatus, Prisma } from "@prisma/client";
import { ConflictException, ForbiddenException, Injectable, NotFoundException } from "@nestjs/common";
import { successResponse } from "../../common/utils/api-response";
import { PrismaService } from "../prisma/prisma.service";
import { mapApplicationResponse } from "./application-response.mapper";
import { CreateApplicationDto } from "./dto/create-application.dto";

@Injectable()
export class ApplicationsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, listingId: string, dto: CreateApplicationDto) {
    const listing = await this.prisma.listing.findUnique({
      where: { id: listingId },
      select: {
        id: true,
        publisherId: true,
        status: true,
        auditStatus: true,
      },
    });

    if (!listing) {
      throw new NotFoundException("Listing not found");
    }

    if (listing.publisherId === userId) {
      throw new ForbiddenException("You cannot apply to your own listing");
    }

    const isOpenForApplication =
      listing.status === ListingStatus.PUBLISHED || listing.status === ListingStatus.MATCHED;

    if (listing.auditStatus !== AuditStatus.APPROVED || !isOpenForApplication) {
      throw new ForbiddenException("This listing is not open for application");
    }

    const existing = await this.prisma.application.findUnique({
      where: {
        listingId_applicantId: {
          listingId,
          applicantId: userId,
        },
      },
    });

    if (existing) {
      const canReapply =
        existing.status === ApplicationStatus.WITHDRAWN ||
        existing.status === ApplicationStatus.REJECTED ||
        existing.status === ApplicationStatus.EXPIRED;

      if (!canReapply) {
        throw new ConflictException("You have already applied to this listing");
      }

      const reapplied = await this.prisma.application.update({
        where: { id: existing.id },
        data: {
          message: dto.message,
          quotedPrice: dto.quotedPrice,
          availableStartTime: dto.availableStartTime ? new Date(dto.availableStartTime) : null,
          portfolioUrls: dto.portfolioUrls ?? [],
          status: ApplicationStatus.PENDING,
          handledAt: null,
          handledBy: null,
        },
      });

      return successResponse(mapApplicationResponse(reapplied), "application created");
    }

    try {
      const application = await this.prisma.application.create({
        data: {
          listingId,
          applicantId: userId,
          message: dto.message,
          quotedPrice: dto.quotedPrice,
          availableStartTime: dto.availableStartTime ? new Date(dto.availableStartTime) : undefined,
          portfolioUrls: dto.portfolioUrls ?? [],
        },
      });

      return successResponse(mapApplicationResponse(application), "application created");
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === "P2002"
      ) {
        throw new ConflictException("You have already applied to this listing");
      }

      throw error;
    }
  }

  async findMyApplications(userId: string) {
    const items = await this.prisma.application.findMany({
      where: { applicantId: userId },
      orderBy: { createdAt: "desc" },
      include: {
        listing: {
          select: {
            id: true,
            title: true,
            listingType: true,
            status: true,
            cityCode: true,
            publisher: {
              select: {
                id: true,
                nickname: true,
              },
            },
          },
        },
      },
    });

    return successResponse(mapApplicationResponse(items));
  }

  async findListingApplications(userId: string, listingId: string) {
    const listing = await this.prisma.listing.findUnique({
      where: { id: listingId },
      select: {
        publisherId: true,
      },
    });

    if (!listing) {
      throw new NotFoundException("Listing not found");
    }

    if (listing.publisherId !== userId) {
      throw new ForbiddenException("You cannot view applications for this listing");
    }

    const items = await this.prisma.application.findMany({
      where: { listingId },
      orderBy: { createdAt: "desc" },
      include: {
        applicant: {
          select: {
            id: true,
            nickname: true,
            avatarUrl: true,
            creditScore: true,
            ratingAvg: true,
          },
        },
        orders: {
          select: {
            id: true,
            orderStatus: true,
          },
          orderBy: {
            createdAt: "desc",
          },
          take: 1,
        },
      },
    });

    return successResponse(mapApplicationResponse(items));
  }

  async accept(userId: string, applicationId: string) {
    const application = await this.prisma.application.findUnique({
      where: { id: applicationId },
      include: {
        listing: {
          select: {
            id: true,
            publisherId: true,
            status: true,
          },
        },
      },
    });

    if (!application) {
      throw new NotFoundException("Application not found");
    }

    if (application.listing.publisherId !== userId) {
      throw new ForbiddenException("You cannot accept this application");
    }

    const result = await this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      const accepted = await tx.application.update({
        where: { id: applicationId },
        data: {
          status: ApplicationStatus.ACCEPTED,
          handledAt: new Date(),
          handledBy: userId,
        },
      });

      await tx.application.updateMany({
        where: {
          listingId: application.listingId,
          id: { not: applicationId },
          status: ApplicationStatus.PENDING,
        },
        data: {
          status: ApplicationStatus.EXPIRED,
          handledAt: new Date(),
          handledBy: userId,
        },
      });

      await tx.listing.update({
        where: { id: application.listingId },
        data: {
          acceptedApplicationId: applicationId,
          status: ListingStatus.MATCHED,
        },
      });

      return accepted;
    });

    return successResponse(mapApplicationResponse(result), "application accepted");
  }

  async reject(userId: string, applicationId: string) {
    const application = await this.prisma.application.findUnique({
      where: { id: applicationId },
      include: {
        listing: {
          select: {
            publisherId: true,
          },
        },
      },
    });

    if (!application) {
      throw new NotFoundException("Application not found");
    }

    if (application.listing.publisherId !== userId) {
      throw new ForbiddenException("You cannot reject this application");
    }

    const result = await this.prisma.application.update({
      where: { id: applicationId },
      data: {
        status: ApplicationStatus.REJECTED,
        handledAt: new Date(),
        handledBy: userId,
      },
    });

    return successResponse(mapApplicationResponse(result), "application rejected");
  }

  async withdraw(userId: string, applicationId: string) {
    const application = await this.prisma.application.findUnique({
      where: { id: applicationId },
      select: {
        applicantId: true,
        status: true,
      },
    });

    if (!application) {
      throw new NotFoundException("Application not found");
    }

    if (application.applicantId !== userId) {
      throw new ForbiddenException("You cannot withdraw this application");
    }

    if (application.status !== ApplicationStatus.PENDING) {
      throw new ForbiddenException("Only pending applications can be withdrawn");
    }

    const result = await this.prisma.application.update({
      where: { id: applicationId },
      data: {
        status: ApplicationStatus.WITHDRAWN,
        handledAt: new Date(),
        handledBy: userId,
      },
    });

    return successResponse(mapApplicationResponse(result), "application withdrawn");
  }
}
