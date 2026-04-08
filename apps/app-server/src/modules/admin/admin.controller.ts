import { Body, Controller, Get, Param, Post, Query } from "@nestjs/common";
import { AdminService } from "./admin.service";
import { FeatureListingDto } from "./dto/feature-listing.dto";
import { ReviewListingDto } from "./dto/review-listing.dto";
import { ReviewReportDto } from "./dto/review-report.dto";

@Controller("admin")
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get("overview")
  getOverview() {
    return this.adminService.getOverview();
  }

  @Get("opportunities")
  getOpportunities(@Query("filter") filter?: string) {
    return this.adminService.getOpportunities(filter);
  }

  @Get("listings")
  getListings(@Query("status") status?: string) {
    return this.adminService.getListings(status);
  }

  @Post("listings/:id/approve")
  approveListing(@Param("id") id: string) {
    return this.adminService.approveListing(id);
  }

  @Post("listings/:id/feature")
  featureListing(@Param("id") id: string, @Body() dto: FeatureListingDto) {
    return this.adminService.featureListing(id, dto.note, dto.priority, dto.validDays);
  }

  @Post("listings/:id/unfeature")
  unfeatureListing(@Param("id") id: string) {
    return this.adminService.unfeatureListing(id);
  }

  @Post("listings/:id/reject")
  rejectListing(@Param("id") id: string, @Body() dto: ReviewListingDto) {
    return this.adminService.rejectListing(id, dto.reason);
  }

  @Get("orders")
  getOrders() {
    return this.adminService.getOrders();
  }

  @Get("reports")
  getReports() {
    return this.adminService.getReports();
  }

  @Post("reports/:id/resolve")
  resolveReport(@Param("id") id: string, @Body() dto: ReviewReportDto) {
    return this.adminService.resolveReport(id, dto.result);
  }

  @Post("reports/:id/reject")
  rejectReport(@Param("id") id: string, @Body() dto: ReviewReportDto) {
    return this.adminService.rejectReport(id, dto.result);
  }

  @Get("users")
  getUsers() {
    return this.adminService.getUsers();
  }
}
