import { OrderStatus, Prisma, ReviewStatus } from "@prisma/client";
import { ForbiddenException, Injectable, NotFoundException } from "@nestjs/common";
import { successResponse } from "../../common/utils/api-response";
import { PrismaService } from "../prisma/prisma.service";
import { CreateReviewDto } from "./dto/create-review.dto";

@Injectable()
export class ReviewsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, orderId: string, dto: CreateReviewDto) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: {
        id: true,
        buyerId: true,
        sellerId: true,
        orderStatus: true,
      },
    });

    if (!order) {
      throw new NotFoundException("Order not found");
    }

    if (order.buyerId !== userId && order.sellerId !== userId) {
      throw new ForbiddenException("You cannot review this order");
    }

    if (order.orderStatus !== OrderStatus.COMPLETED) {
      throw new ForbiddenException("Only completed orders can be reviewed");
    }

    const toUserId = order.buyerId === userId ? order.sellerId : order.buyerId;

    const review = await this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      const created = await tx.review.create({
        data: {
          orderId,
          fromUserId: userId,
          toUserId,
          score: dto.score,
          tagsJson: dto.tags ?? [],
          content: dto.content,
          imagesJson: dto.images ?? [],
          isAnonymous: dto.isAnonymous ?? false,
          status: ReviewStatus.VISIBLE,
        },
      });

      const aggregate = await tx.review.aggregate({
        where: {
          toUserId,
          status: ReviewStatus.VISIBLE,
        },
        _avg: {
          score: true,
        },
        _count: {
          score: true,
        },
      });

      await tx.user.update({
        where: { id: toUserId },
        data: {
          ratingAvg: aggregate._avg.score ?? undefined,
          ratingCount: aggregate._count.score,
        },
      });

      return created;
    });

    return successResponse(review, "review created");
  }

  async findByOrder(userId: string, orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: {
        buyerId: true,
        sellerId: true,
      },
    });

    if (!order) {
      throw new NotFoundException("Order not found");
    }

    if (order.buyerId !== userId && order.sellerId !== userId) {
      throw new ForbiddenException("You cannot view reviews for this order");
    }

    const reviews = await this.prisma.review.findMany({
      where: { orderId },
      orderBy: { createdAt: "asc" },
    });

    return successResponse(reviews);
  }
}

