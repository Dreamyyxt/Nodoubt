import { Body, Controller, Get, Param, Post, Query } from "@nestjs/common";
import { CurrentUserId } from "../../common/decorators/current-user-id.decorator";
import { CreateOrderDto } from "./dto/create-order.dto";
import { QueryOrdersDto } from "./dto/query-orders.dto";
import { RequestRefundDto } from "./dto/request-refund.dto";
import { OrdersService } from "./orders.service";

@Controller("orders")
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  create(@CurrentUserId() userId: string, @Body() dto: CreateOrderDto) {
    return this.ordersService.create(userId, dto);
  }

  @Get("/me")
  findMyOrders(@CurrentUserId() userId: string, @Query() query: QueryOrdersDto) {
    return this.ordersService.findMyOrders(userId, query);
  }

  @Get(":id")
  findOne(@CurrentUserId() userId: string, @Param("id") id: string) {
    return this.ordersService.findOne(userId, id);
  }

  @Post(":id/accept")
  accept(@CurrentUserId() userId: string, @Param("id") id: string) {
    return this.ordersService.accept(userId, id);
  }

  @Post(":id/pay")
  pay(@CurrentUserId() userId: string, @Param("id") id: string) {
    return this.ordersService.pay(userId, id);
  }

  @Post(":id/deliver")
  deliver(@CurrentUserId() userId: string, @Param("id") id: string) {
    return this.ordersService.deliver(userId, id);
  }

  @Post(":id/confirm")
  confirm(@CurrentUserId() userId: string, @Param("id") id: string) {
    return this.ordersService.confirm(userId, id);
  }

  @Post(":id/refund")
  requestRefund(
    @CurrentUserId() userId: string,
    @Param("id") id: string,
    @Body() dto: RequestRefundDto,
  ) {
    return this.ordersService.requestRefund(userId, id, dto);
  }
}
