import { IsInt, IsOptional, IsString, Max, MaxLength, Min } from "class-validator";

export class FeatureListingDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  note?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  priority?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(30)
  validDays?: number;
}
