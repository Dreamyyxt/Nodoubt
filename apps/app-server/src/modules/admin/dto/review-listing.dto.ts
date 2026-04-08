import { IsOptional, IsString, MaxLength } from "class-validator";

export class ReviewListingDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  reason?: string;
}
