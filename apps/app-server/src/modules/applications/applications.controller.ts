import { Body, Controller, Get, Param, Post } from "@nestjs/common";
import { CurrentUserId } from "../../common/decorators/current-user-id.decorator";
import { CreateApplicationDto } from "./dto/create-application.dto";
import { ApplicationsService } from "./applications.service";

@Controller()
export class ApplicationsController {
  constructor(private readonly applicationsService: ApplicationsService) {}

  @Post("listings/:id/applications")
  create(
    @CurrentUserId() userId: string,
    @Param("id") listingId: string,
    @Body() dto: CreateApplicationDto,
  ) {
    return this.applicationsService.create(userId, listingId, dto);
  }

  @Get("me/applications")
  findMyApplications(@CurrentUserId() userId: string) {
    return this.applicationsService.findMyApplications(userId);
  }

  @Get("listings/:id/applications")
  findListingApplications(@CurrentUserId() userId: string, @Param("id") listingId: string) {
    return this.applicationsService.findListingApplications(userId, listingId);
  }

  @Post("applications/:id/accept")
  accept(@CurrentUserId() userId: string, @Param("id") applicationId: string) {
    return this.applicationsService.accept(userId, applicationId);
  }

  @Post("applications/:id/reject")
  reject(@CurrentUserId() userId: string, @Param("id") applicationId: string) {
    return this.applicationsService.reject(userId, applicationId);
  }

  @Post("applications/:id/withdraw")
  withdraw(@CurrentUserId() userId: string, @Param("id") applicationId: string) {
    return this.applicationsService.withdraw(userId, applicationId);
  }
}

