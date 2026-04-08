import { Injectable, NotFoundException } from "@nestjs/common";
import { AuditStatus, ListingStatus, Prisma, ReportStatus } from "@prisma/client";
import { successResponse } from "../../common/utils/api-response";
import { PrismaService } from "../prisma/prisma.service";

@Injectable()
export class AdminService {
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

  async getOverview() {
    const [
      pendingListings,
      activeOrders,
      pendingReports,
      totalUsers,
      totalOrderAmount,
      latestListings,
      latestOrders,
      latestReports,
    ] = await this.prisma.$transaction([
      this.prisma.listing.count({
        where: {
          auditStatus: AuditStatus.PENDING,
          status: ListingStatus.PENDING_REVIEW,
        },
      }),
      this.prisma.order.count({
        where: {
          orderStatus: {
            in: ["PENDING_PAYMENT", "PENDING_ACCEPT", "IN_PROGRESS", "PENDING_CONFIRMATION"],
          },
        },
      }),
      this.prisma.report.count({
        where: {
          status: ReportStatus.PENDING,
        },
      }),
      this.prisma.user.count(),
      this.prisma.order.aggregate({
        _sum: {
          amountTotal: true,
        },
      }),
      this.prisma.listing.findMany({
        take: 5,
        orderBy: { createdAt: "desc" },
        select: {
          id: true,
          title: true,
          listingType: true,
          status: true,
          auditStatus: true,
          cityCode: true,
          createdAt: true,
          publisher: {
            select: {
              nickname: true,
            },
          },
        },
      }),
      this.prisma.order.findMany({
        take: 5,
        orderBy: { createdAt: "desc" },
        select: {
          id: true,
          orderStatus: true,
          amountTotal: true,
          createdAt: true,
          listing: {
            select: {
              title: true,
              cityCode: true,
            },
          },
        },
      }),
      this.prisma.report.findMany({
        take: 5,
        orderBy: { createdAt: "desc" },
        select: {
          id: true,
          targetType: true,
          reasonCode: true,
          createdAt: true,
        },
      }),
    ]);

    const cityBuckets = new Map<string, { cityCode: string; listingCount: number; orderCount: number }>();

    for (const item of latestListings) {
      const cityCode = item.cityCode ?? "unknown";
      const bucket = cityBuckets.get(cityCode) ?? {
        cityCode,
        listingCount: 0,
        orderCount: 0,
      };
      bucket.listingCount += 1;
      cityBuckets.set(cityCode, bucket);
    }

    for (const item of latestOrders) {
      const cityCode = item.listing.cityCode ?? "unknown";
      const bucket = cityBuckets.get(cityCode) ?? {
        cityCode,
        listingCount: 0,
        orderCount: 0,
      };
      bucket.orderCount += 1;
      cityBuckets.set(cityCode, bucket);
    }

    const activityTimeline = [
      ...latestListings.map((item) => ({
        id: `listing-${item.id}`,
        eventType: "listing_created",
        cityCode: item.cityCode ?? "unknown",
        title: item.title,
        detail: `${item.publisher.nickname} 发布了 ${item.listingType === "EXCHANGE" ? "交换" : "任务"}`,
        createdAt: item.createdAt,
      })),
      ...latestOrders.map((item) => ({
        id: `order-${item.id}`,
        eventType: "order_updated",
        cityCode: item.listing.cityCode ?? "unknown",
        title: item.listing.title,
        detail: `订单推进到 ${item.orderStatus}`,
        createdAt: item.createdAt,
      })),
      ...latestReports.map((item) => ({
        id: `report-${item.id}`,
        eventType: "report_created",
        cityCode: "unknown",
        title: item.targetType,
        detail: `新增举报：${item.reasonCode}`,
        createdAt: item.createdAt,
      })),
    ]
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .slice(0, 8);

    return successResponse({
      metrics: {
        pendingListings,
        activeOrders,
        pendingReports,
        totalUsers,
        grossMerchandiseValue: Number(totalOrderAmount._sum.amountTotal ?? 0),
        estimatedRevenue: Number(totalOrderAmount._sum.amountTotal ?? 0) * 0.05,
      },
      latestListings: latestListings.map((item) => ({
        id: item.id,
        title: item.title,
        listingType: item.listingType,
        status: item.status,
        auditStatus: item.auditStatus,
        cityCode: item.cityCode,
        publisherName: item.publisher.nickname,
        createdAt: item.createdAt,
      })),
      latestOrders: latestOrders.map((item) => ({
        id: item.id,
        title: item.listing.title,
        cityCode: item.listing.cityCode,
        orderStatus: item.orderStatus,
        amountTotal: Number(item.amountTotal),
        createdAt: item.createdAt,
      })),
      cityActivity: Array.from(cityBuckets.values())
        .sort((a, b) => b.listingCount + b.orderCount - (a.listingCount + a.orderCount))
        .slice(0, 5),
      activityTimeline,
    });
  }

  async getOpportunities(filter?: string) {
    await this.expireFeaturedListingsIfNeeded();
    const now = new Date();
    const normalizedFilter = (filter ?? "ALL").toUpperCase();
    const where: Prisma.ListingWhereInput = {
      deletedAt: null,
      listingType: "TASK",
      auditStatus: AuditStatus.APPROVED,
      status: {
        in: [ListingStatus.PUBLISHED, ListingStatus.MATCHED, ListingStatus.IN_PROGRESS],
      },
      ...(normalizedFilter === "FEATURED"
        ? {
            isFeatured: true,
          }
        : normalizedFilter === "CANDIDATE"
          ? {
              isFeatured: false,
            }
          : normalizedFilter === "CONVERTING"
            ? {
                OR: [
                  {
                    status: {
                      in: [ListingStatus.MATCHED, ListingStatus.IN_PROGRESS],
                    },
                  },
                  {
                    applications: {
                      some: {
                        status: {
                          in: ["PENDING", "ACCEPTED"],
                        },
                      },
                    },
                  },
                ],
              }
            : normalizedFilter === "EXPIRING"
              ? {
                isFeatured: true,
                featuredUntil: {
                  not: null,
                  lte: new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000),
                },
              }
            : {}),
    };
    const items = await this.prisma.listing.findMany({
      where,
      take: 16,
      orderBy: [
        { isFeatured: "desc" },
        { featuredPriority: "desc" },
        { featuredAt: "desc" },
        { isUrgent: "desc" },
        { budgetAmount: "desc" },
        { createdAt: "desc" },
      ],
      include: {
        publisher: {
          select: {
            nickname: true,
            cityCode: true,
          },
        },
        _count: {
          select: {
            applications: true,
            orders: true,
          },
        },
      },
    });

    return successResponse(
      items.map((item) => {
        const budgetAmount = Number(item.budgetAmount ?? 0);
        const estimatedServiceFee = budgetAmount * 0.05;
        const reasons: string[] = [];
        const featuredUntil = item.featuredUntil;
        const isFeaturedActive =
          item.isFeatured && (!featuredUntil || featuredUntil.getTime() > now.getTime());

        if (isFeaturedActive) reasons.push("已人工精选");
        if (item.isUrgent) reasons.push("加急推荐");
        if (budgetAmount >= 500) reasons.push("高客单价");
        else if (budgetAmount >= 300) reasons.push("中高预算");
        if ((item.locationText ?? "").trim().length > 0) reasons.push("地点明确");
        if (item._count.applications <= 1) reasons.push("待人工推动");
        if (item._count.applications >= 3) reasons.push("申请热度高");
        if (item._count.orders > 0 || item.status === ListingStatus.IN_PROGRESS) {
          reasons.push("已进入成交推进");
        }

        const daysRemaining =
          featuredUntil == null
            ? null
            : Math.max(0, Math.ceil((featuredUntil.getTime() - now.getTime()) / (24 * 60 * 60 * 1000)));
        const conversionStage =
          item._count.orders > 0 || item.status === ListingStatus.IN_PROGRESS
            ? "订单推进中"
            : item._count.applications >= 3
              ? "申请热度高"
              : item._count.applications >= 1
                ? "已有申请待跟进"
                : "待人工推动";

        return {
          id: item.id,
          title: item.title,
          cityCode: item.cityCode,
          locationText: item.locationText,
          publisherName: item.publisher.nickname,
          publisherCityCode: item.publisher.cityCode,
          budgetAmount,
          estimatedServiceFee,
          isFeatured: isFeaturedActive,
          featuredPriority: item.featuredPriority,
          featuredUntil,
          featuredDaysRemaining: daysRemaining,
          opsNote: item.opsNote,
          isUrgent: item.isUrgent,
          applicationCount: item._count.applications,
          orderCount: item._count.orders,
          conversionStage,
          reasons,
          createdAt: item.createdAt,
        };
      }),
    );
  }

  async featureListing(id: string, note?: string, priority?: number, validDays?: number) {
    const listing = await this.prisma.listing.findUnique({
      where: { id },
      select: { id: true },
    });

    if (!listing) {
      throw new NotFoundException("Listing not found");
    }

    const now = new Date();
    const days = validDays ?? 7;
    const featuredUntil = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);

    const updated = await this.prisma.listing.update({
      where: { id },
      data: {
        isFeatured: true,
        featuredPriority: priority ?? 3,
        featuredAt: now,
        featuredUntil,
        opsNote: note?.trim() || "运营判断：预算高、地点明确、适合优先推动成交。",
      },
    });

    return successResponse(
      {
        id: updated.id,
        isFeatured: updated.isFeatured,
        featuredPriority: updated.featuredPriority,
        featuredAt: updated.featuredAt,
        featuredUntil: updated.featuredUntil,
        opsNote: updated.opsNote,
      },
      "listing featured",
    );
  }

  async unfeatureListing(id: string) {
    const listing = await this.prisma.listing.findUnique({
      where: { id },
      select: { id: true },
    });

    if (!listing) {
      throw new NotFoundException("Listing not found");
    }

    const updated = await this.prisma.listing.update({
      where: { id },
      data: {
        isFeatured: false,
        featuredPriority: 0,
        featuredAt: null,
        featuredUntil: null,
        opsNote: null,
      },
    });

    return successResponse(
      {
        id: updated.id,
        isFeatured: updated.isFeatured,
        featuredPriority: updated.featuredPriority,
        featuredAt: updated.featuredAt,
        featuredUntil: updated.featuredUntil,
        opsNote: updated.opsNote,
      },
      "listing unfeatured",
    );
  }

  async getListings(status?: string) {
    const where =
      status === "pending"
        ? {
            auditStatus: AuditStatus.PENDING,
            status: ListingStatus.PENDING_REVIEW,
          }
        : undefined;

    const items = await this.prisma.listing.findMany({
      where,
      take: 20,
      orderBy: [{ createdAt: "desc" }],
      include: {
        publisher: {
          select: {
            id: true,
            nickname: true,
            cityCode: true,
          },
        },
        _count: {
          select: {
            applications: true,
            orders: true,
          },
        },
      },
    });

    return successResponse(
      items.map((item) => ({
        id: item.id,
        title: item.title,
        listingType: item.listingType,
        status: item.status,
        auditStatus: item.auditStatus,
        cityCode: item.cityCode,
        isUrgent: item.isUrgent,
        applicationCount: item._count.applications,
        orderCount: item._count.orders,
        publisherName: item.publisher.nickname,
        publisherCityCode: item.publisher.cityCode,
        createdAt: item.createdAt,
      })),
    );
  }

  async approveListing(id: string) {
    const listing = await this.prisma.listing.findUnique({
      where: { id },
      select: {
        id: true,
        status: true,
        auditStatus: true,
      },
    });

    if (!listing) {
      throw new NotFoundException("Listing not found");
    }

    const updated = await this.prisma.listing.update({
      where: { id },
      data: {
        auditStatus: AuditStatus.APPROVED,
        status: ListingStatus.PUBLISHED,
        auditReason: null,
        publishedAt: listing.status === ListingStatus.PUBLISHED ? undefined : new Date(),
      },
    });

    return successResponse(
      {
        id: updated.id,
        auditStatus: updated.auditStatus,
        status: updated.status,
      },
      "listing approved",
    );
  }

  async rejectListing(id: string, reason?: string) {
    const listing = await this.prisma.listing.findUnique({
      where: { id },
      select: {
        id: true,
      },
    });

    if (!listing) {
      throw new NotFoundException("Listing not found");
    }

    const updated = await this.prisma.listing.update({
      where: { id },
      data: {
        auditStatus: AuditStatus.REJECTED,
        status: ListingStatus.REJECTED,
        auditReason: reason?.trim() || "管理员驳回",
      },
    });

    return successResponse(
      {
        id: updated.id,
        auditStatus: updated.auditStatus,
        status: updated.status,
        auditReason: updated.auditReason,
      },
      "listing rejected",
    );
  }

  async getOrders() {
    const items = await this.prisma.order.findMany({
      take: 20,
      orderBy: [{ createdAt: "desc" }],
      include: {
        listing: {
          select: {
            title: true,
            listingType: true,
          },
        },
        buyer: {
          select: {
            nickname: true,
          },
        },
        seller: {
          select: {
            nickname: true,
          },
        },
      },
    });

    return successResponse(
      items.map((item) => ({
        id: item.id,
        title: item.listing.title,
        listingType: item.listing.listingType,
        buyerName: item.buyer.nickname,
        sellerName: item.seller.nickname,
        orderStatus: item.orderStatus,
        amountTotal: Number(item.amountTotal),
        createdAt: item.createdAt,
      })),
    );
  }

  async getReports() {
    const items = await this.prisma.report.findMany({
      take: 20,
      orderBy: [{ createdAt: "desc" }],
      include: {
        reporter: {
          select: {
            nickname: true,
          },
        },
      },
    });

    return successResponse(
      items.map((item) => ({
        id: item.id,
        targetType: item.targetType,
        targetId: item.targetId,
        reasonCode: item.reasonCode,
        description: item.description,
        status: item.status,
        reviewResult: item.reviewResult,
        reporterName: item.reporter.nickname,
        createdAt: item.createdAt,
        reviewedAt: item.reviewedAt,
      })),
    );
  }

  async resolveReport(id: string, result?: string) {
    const report = await this.prisma.report.findUnique({
      where: { id },
      select: { id: true },
    });

    if (!report) {
      throw new NotFoundException("Report not found");
    }

    const updated = await this.prisma.report.update({
      where: { id },
      data: {
        status: ReportStatus.RESOLVED,
        reviewResult: result?.trim() || "已核实并完成处理",
        reviewedAt: new Date(),
        reviewedBy: "dev-admin",
      },
    });

    return successResponse(
      {
        id: updated.id,
        status: updated.status,
        reviewResult: updated.reviewResult,
      },
      "report resolved",
    );
  }

  async rejectReport(id: string, result?: string) {
    const report = await this.prisma.report.findUnique({
      where: { id },
      select: { id: true },
    });

    if (!report) {
      throw new NotFoundException("Report not found");
    }

    const updated = await this.prisma.report.update({
      where: { id },
      data: {
        status: ReportStatus.REJECTED,
        reviewResult: result?.trim() || "举报不成立",
        reviewedAt: new Date(),
        reviewedBy: "dev-admin",
      },
    });

    return successResponse(
      {
        id: updated.id,
        status: updated.status,
        reviewResult: updated.reviewResult,
      },
      "report rejected",
    );
  }

  async getUsers() {
    const items = await this.prisma.user.findMany({
      take: 20,
      orderBy: [{ createdAt: "desc" }],
      include: {
        _count: {
          select: {
            publishedListings: true,
            applications: true,
            boughtOrders: true,
            soldOrders: true,
          },
        },
      },
    });

    return successResponse(
      items.map((item) => ({
        id: item.id,
        nickname: item.nickname,
        phone: item.phone,
        cityCode: item.cityCode,
        creditScore: item.creditScore,
        publishedListings: item._count.publishedListings,
        applications: item._count.applications,
        boughtOrders: item._count.boughtOrders,
        soldOrders: item._count.soldOrders,
        createdAt: item.createdAt,
      })),
    );
  }
}
