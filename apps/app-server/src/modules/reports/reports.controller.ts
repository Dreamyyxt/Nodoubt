import { Body, Controller, Get, Post } from "@nestjs/common";
import { CurrentUserId } from "../../common/decorators/current-user-id.decorator";
import { CreateReportDto } from "./dto/create-report.dto";
import { ReportsService } from "./reports.service";

@Controller()
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Post("reports")
  create(@CurrentUserId() userId: string, @Body() dto: CreateReportDto) {
    return this.reportsService.create(userId, dto);
  }

  @Get("me/reports")
  findMyReports(@CurrentUserId() userId: string) {
    return this.reportsService.findMyReports(userId);
  }
}

