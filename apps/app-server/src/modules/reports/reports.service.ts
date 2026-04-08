import { ReportStatus, ReportTargetType } from "@prisma/client";
import { Injectable } from "@nestjs/common";
import { successResponse } from "../../common/utils/api-response";
import { PrismaService } from "../prisma/prisma.service";
import { CreateReportDto } from "./dto/create-report.dto";

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, dto: CreateReportDto) {
    const report = await this.prisma.report.create({
      data: {
        reporterId: userId,
        targetType: dto.targetType as ReportTargetType,
        targetId: dto.targetId,
        reasonCode: dto.reasonCode,
        description: dto.description,
        evidenceUrls: dto.evidenceUrls ?? [],
        status: ReportStatus.PENDING,
      },
    });

    return successResponse(report, "report created");
  }

  async findMyReports(userId: string) {
    const reports = await this.prisma.report.findMany({
      where: {
        reporterId: userId,
      },
      orderBy: {
        createdAt: "desc",
      },
    });

    return successResponse(reports);
  }
}

