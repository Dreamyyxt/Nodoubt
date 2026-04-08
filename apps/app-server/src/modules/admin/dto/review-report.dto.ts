import { IsOptional, IsString, MaxLength } from "class-validator";

export class ReviewReportDto {
  @IsOptional()
  @IsString()
  @MaxLength(300)
  result?: string;
}
