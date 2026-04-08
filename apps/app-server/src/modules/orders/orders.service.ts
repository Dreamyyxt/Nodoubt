import {
  ApplicationStatus,
  AuditStatus,
  EscrowStatus,
  ListingStatus,
  OrderEventType,
  OrderStatus,
  OrderType,
  Prisma,
  RefundStatus,
} from "@prisma/client";
import { ConflictException, ForbiddenException, Injectable, NotFoundException } from "@nestjs/common";
import { successResponse } from "../../common/utils/api-response";
import { PrismaService } from "../prisma/prisma.service";
import { mapOrderResponse } from "./order-response.mapper";
import { CreateOrderDto } from "./dto/create-order.dto";
import { QueryOrdersDto } from "./dto/query-orders.dto";
import { RequestRefundDto } from "./dto/request-refund.dto";

@Injectable()
export class OrdersService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, dto: CreateOrderDto) {
    const application = await this.prisma.application.findUnique({
      where: { id: dto.applicationId },
      include: {
        listing: true,
        orders: {
          select: {
            id: true,
          },
          take: 1,
        },
      },
    });

    if (!application) {
      throw new NotFoundException("Application not found");
    }

    if (application.listing.publisherId !== userId) {
      throw new ForbiddenException("You cannot create an order for this application");
    }

    if (application.status !== ApplicationStatus.ACCEPTED) {
      throw new ForbiddenException("Only accepted applications can create orders");
    }

    if (
      application.listing.auditStatus !== AuditStatus.APPROVED ||
      (application.listing.status !== ListingStatus.MATCHED &&
        application.listing.status !== ListingStatus.IN_PROGRESS)
    ) {
      throw new ForbiddenException("This listing is not ready to create an order");
    }

    if (application.orders.length > 0) {
      throw new ConflictException("An order has already been created for this application");
    }

    const amountTotal = new Prisma.Decimal(dto.amountTotal);
    const platformFee = new Prisma.Decimal(dto.platformFee ?? 0);
    const sellerIncome = amountTotal.minus(platformFee);
    const orderType =
      application.listing.listingType === "TASK" ? OrderType.TASK_ORDER : OrderType.EXCHANGE_CONFIRMATION;

    const result = await this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      const order = await tx.order.create({
        data: {
          listingId: application.listingId,
          applicationId: application.id,
          buyerId: application.listing.publisherId,
          sellerId: application.applicantId,
          orderType,
          amountTotal,
          platformFee,
          sellerIncome,
          escrowStatus: amountTotal.gt(0) ? EscrowStatus.PENDING_PAYMENT : EscrowStatus.NOT_REQUIRED,
          orderStatus: amountTotal.gt(0) ? OrderStatus.PENDING_PAYMENT : OrderStatus.PENDING_ACCEPT,
          scheduledAt: dto.scheduledAt ? new Date(dto.scheduledAt) : undefined,
        },
      });

      await tx.orderEvent.create({
        data: {
          orderId: order.id,
          eventType: OrderEventType.CREATED,
          operatorUserId: userId,
          operatorRole: "buyer",
          eventPayload: {
            remark: dto.remark ?? null,
          },
        },
      });

      await tx.listing.update({
        where: { id: application.listingId },
        data: {
          status: ListingStatus.IN_PROGRESS,
        },
      });

      return order;
    });

    return successResponse(mapOrderResponse(result), "order created");
  }

  async findMyOrders(userId: string, query: QueryOrdersDto) {
    const where: Prisma.OrderWhereInput =
      query.role === "seller"
        ? { sellerId: userId, orderStatus: query.status }
        : query.role === "buyer"
          ? { buyerId: userId, orderStatus: query.status }
          : {
              OR: [{ buyerId: userId }, { sellerId: userId }],
              ...(query.status ? { orderStatus: query.status } : {}),
            };

    const items = await this.prisma.order.findMany({
      where,
      orderBy: { createdAt: "desc" },
      include: {
        listing: {
          select: {
            id: true,
            title: true,
            listingType: true,
            cityCode: true,
            locationText: true,
            longitude: true,
            latitude: true,
          },
        },
        buyer: {
          select: {
            id: true,
            nickname: true,
          },
        },
        seller: {
          select: {
            id: true,
            nickname: true,
          },
        },
      },
    });

    return successResponse(mapOrderResponse(items));
  }

  async findOne(userId: string, id: string) {
    const order = await this.prisma.order.findUnique({
      where: { id },
      include: {
        listing: true,
        buyer: {
          select: {
            id: true,
            nickname: true,
          },
        },
        seller: {
          select: {
            id: true,
            nickname: true,
          },
        },
        events: {
          orderBy: { createdAt: "asc" },
        },
      },
    });

    if (!order) {
      throw new NotFoundException("Order not found");
    }

    if (order.buyerId !== userId && order.sellerId !== userId) {
      throw new ForbiddenException("You cannot view this order");
    }

    return successResponse(mapOrderResponse(order));
  }

  async accept(userId: string, id: string) {
    const order = await this.mustGetOrder(id);

    if (order.sellerId !== userId) {
      throw new ForbiddenException("Only the seller can accept this order");
    }

    if (order.orderStatus !== OrderStatus.PENDING_ACCEPT) {
      throw new ForbiddenException("This order cannot be accepted");
    }

    const result = await this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      const updated = await tx.order.update({
        where: { id },
        data: {
          orderStatus: OrderStatus.IN_PROGRESS,
        },
      });

      await tx.orderEvent.create({
        data: {
          orderId: id,
          eventType: OrderEventType.ACCEPTED,
          operatorUserId: userId,
          operatorRole: "seller",
        },
      });

      return updated;
    });

    return successResponse(mapOrderResponse(result), "order accepted");
  }

  async pay(userId: string, id: string) {
    const order = await this.mustGetOrder(id);

    if (order.buyerId !== userId) {
      throw new ForbiddenException("Only the buyer can pay this order");
    }

    if (order.orderStatus !== OrderStatus.PENDING_PAYMENT) {
      throw new ForbiddenException("This order is not awaiting payment");
    }

    const result = await this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      const updated = await tx.order.update({
        where: { id },
        data: {
          orderStatus: OrderStatus.PENDING_ACCEPT,
          escrowStatus: EscrowStatus.PAID,
        },
      });

      await tx.payment.create({
        data: {
          orderId: id,
          payerId: userId,
          paymentChannel: "ALIPAY",
          amount: order.amountTotal,
          paymentStatus: "PAID",
          paidAt: new Date(),
        },
      });

      await tx.orderEvent.create({
        data: {
          orderId: id,
          eventType: OrderEventType.PAID,
          operatorUserId: userId,
          operatorRole: "buyer",
        },
      });

      return updated;
    });

    return successResponse(mapOrderResponse(result), "order paid");
  }

  async deliver(userId: string, id: string) {
    const order = await this.mustGetOrder(id);

    if (order.sellerId !== userId) {
      throw new ForbiddenException("Only the seller can deliver this order");
    }

    if (order.orderStatus !== OrderStatus.IN_PROGRESS) {
      throw new ForbiddenException("This order is not in progress");
    }

    const result = await this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      const updated = await tx.order.update({
        where: { id },
        data: {
          orderStatus: OrderStatus.PENDING_CONFIRMATION,
          deliveredAt: new Date(),
        },
      });

      await tx.orderEvent.create({
        data: {
          orderId: id,
          eventType: OrderEventType.DELIVERED,
          operatorUserId: userId,
          operatorRole: "seller",
        },
      });

      return updated;
    });

    return successResponse(mapOrderResponse(result), "order delivered");
  }

  async confirm(userId: string, id: string) {
    const order = await this.mustGetOrder(id);

    if (order.buyerId !== userId) {
      throw new ForbiddenException("Only the buyer can confirm this order");
    }

    if (order.orderStatus !== OrderStatus.PENDING_CONFIRMATION) {
      throw new ForbiddenException("This order is not awaiting confirmation");
    }

    const result = await this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      const updated = await tx.order.update({
        where: { id },
        data: {
          orderStatus: OrderStatus.COMPLETED,
          completedAt: new Date(),
          escrowStatus:
            order.escrowStatus === EscrowStatus.PAID || order.escrowStatus === EscrowStatus.FROZEN
              ? EscrowStatus.RELEASED
              : order.escrowStatus,
        },
      });

      await tx.orderEvent.create({
        data: {
          orderId: id,
          eventType: OrderEventType.CONFIRMED,
          operatorUserId: userId,
          operatorRole: "buyer",
        },
      });

      await tx.listing.update({
        where: { id: order.listingId },
        data: {
          status: ListingStatus.COMPLETED,
        },
      });

      return updated;
    });

    return successResponse(mapOrderResponse(result), "order confirmed");
  }

  async requestRefund(userId: string, id: string, dto: RequestRefundDto) {
    const order = await this.mustGetOrder(id);

    if (order.buyerId !== userId && order.sellerId !== userId) {
      throw new ForbiddenException("You cannot request refund for this order");
    }

    const result = await this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      const refund = await tx.refund.create({
        data: {
          orderId: id,
          requesterId: userId,
          reasonCode: dto.reasonCode,
          description: dto.description,
          refundAmount: order.amountTotal,
          refundStatus: RefundStatus.PENDING,
        },
      });

      await tx.order.update({
        where: { id },
        data: {
          orderStatus: OrderStatus.REFUND_REQUESTED,
          escrowStatus: EscrowStatus.REFUNDING,
        },
      });

      await tx.orderEvent.create({
        data: {
          orderId: id,
          eventType: OrderEventType.REFUND_REQUESTED,
          operatorUserId: userId,
          operatorRole: userId === order.buyerId ? "buyer" : "seller",
          eventPayload: {
            reasonCode: dto.reasonCode,
          },
        },
      });

      return refund;
    });

    return successResponse(mapOrderResponse(result), "refund requested");
  }

  private async mustGetOrder(id: string) {
    const order = await this.prisma.order.findUnique({
      where: { id },
    });

    if (!order) {
      throw new NotFoundException("Order not found");
    }

    return order;
  }
}
