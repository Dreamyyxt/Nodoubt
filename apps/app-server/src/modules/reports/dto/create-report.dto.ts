import { IsArray, IsEnum, IsNotEmpty, IsOptional, IsString, MaxLength } from "class-validator";

export enum ReportTargetTypeDto {
  USER = "USER",
  LISTING = "LISTING",
  MESSAGE = "MESSAGE",
  ORDER = "ORDER",
}

export class CreateReportDto {
  @IsEnum(ReportTargetTypeDto)
  targetType!: ReportTargetTypeDto;

  @IsString()
  @IsNotEmpty()
  targetId!: string;

  @IsString()
  @IsNotEmpty()
  reasonCode!: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  description?: string;

  @IsOptional()
  @IsArray()
  evidenceUrls?: string[];
}

