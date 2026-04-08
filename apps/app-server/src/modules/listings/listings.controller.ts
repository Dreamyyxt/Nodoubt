import { Body, Controller, Get, Headers, Param, Patch, Post, Query } from "@nestjs/common";
import { CurrentUserId } from "../../common/decorators/current-user-id.decorator";
import { CreateListingDto } from "./dto/create-listing.dto";
import { QueryListingsDto } from "./dto/query-listings.dto";
import { UpdateListingDto } from "./dto/update-listing.dto";
import { ListingsService } from "./listings.service";

@Controller()
export class ListingsController {
  constructor(private readonly listingsService: ListingsService) {}

  @Post("listings")
  create(@CurrentUserId() userId: string, @Body() dto: CreateListingDto) {
    return this.listingsService.create(userId, dto);
  }

  @Get("listings")
  findAll(@Query() query: QueryListingsDto, @Headers("x-user-id") userId?: string) {
    return this.listingsService.findAll(query, userId);
  }

  @Get("me/listings")
  findMine(@CurrentUserId() userId: string) {
    return this.listingsService.findMine(userId);
  }

  @Get("listings/:id")
  findOne(@Param("id") id: string) {
    return this.listingsService.findOne(id);
  }

  @Patch("listings/:id")
  update(@CurrentUserId() userId: string, @Param("id") id: string, @Body() dto: UpdateListingDto) {
    return this.listingsService.update(userId, id, dto);
  }

  @Post("listings/:id/close")
  close(@CurrentUserId() userId: string, @Param("id") id: string) {
    return this.listingsService.close(userId, id);
  }
}
