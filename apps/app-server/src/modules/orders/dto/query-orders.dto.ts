import { OrderStatus } from "@prisma/client";
import { IsEnum, IsOptional } from "class-validator";

export enum OrderRole {
  BUYER = "buyer",
  SELLER = "seller",
}

export class QueryOrdersDto {
  @IsOptional()
  @IsEnum(OrderRole)
  role?: OrderRole;

  @IsOptional()
  @IsEnum(OrderStatus)
  status?: OrderStatus;
}

