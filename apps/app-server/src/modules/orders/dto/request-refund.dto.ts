import { IsNotEmpty, IsOptional, IsString, MaxLength } from "class-validator";

export class RequestRefundDto {
  @IsString()
  @IsNotEmpty()
  reasonCode!: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  description?: string;
}

