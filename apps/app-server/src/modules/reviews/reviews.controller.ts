import { Body, Controller, Get, Param, Post } from "@nestjs/common";
import { CurrentUserId } from "../../common/decorators/current-user-id.decorator";
import { CreateReviewDto } from "./dto/create-review.dto";
import { ReviewsService } from "./reviews.service";

@Controller("orders")
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Post(":id/reviews")
  create(
    @CurrentUserId() userId: string,
    @Param("id") orderId: string,
    @Body() dto: CreateReviewDto,
  ) {
    return this.reviewsService.create(userId, orderId, dto);
  }

  @Get(":id/reviews")
  findByOrder(@CurrentUserId() userId: string, @Param("id") orderId: string) {
    return this.reviewsService.findByOrder(userId, orderId);
  }
}

