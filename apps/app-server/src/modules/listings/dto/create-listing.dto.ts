import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
} from "class-validator";

export enum ListingType {
  TASK = "TASK",
  EXCHANGE = "EXCHANGE",
}

export enum ServiceMode {
  ONLINE = "ONLINE",
  OFFLINE = "OFFLINE",
  BOTH = "BOTH",
}

export enum BudgetType {
  FIXED = "FIXED",
  RANGE = "RANGE",
  NEGOTIABLE = "NEGOTIABLE",
  FREE_EXCHANGE = "FREE_EXCHANGE",
}

export enum VisibilityType {
  PUBLIC = "PUBLIC",
  CITY_ONLY = "CITY_ONLY",
  PRIVATE = "PRIVATE",
}

export class CreateListingDto {
  @IsEnum(ListingType)
  listingType!: ListingType;

  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  title!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(2000)
  description!: string;

  @IsOptional()
  @IsString()
  categoryCode?: string;

  @IsOptional()
  @IsArray()
  tagIds?: string[];

  @IsOptional()
  @IsString()
  cityCode?: string;

  @IsOptional()
  @IsNumber()
  longitude?: number;

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsEnum(ServiceMode)
  serviceMode!: ServiceMode;

  @IsOptional()
  @IsEnum(BudgetType)
  budgetType?: BudgetType;

  @IsOptional()
  @IsNumber()
  budgetAmount?: number;

  @IsOptional()
  @IsString()
  exchangeOfferText?: string;

  @IsOptional()
  @IsString()
  exchangeWantText?: string;

  @IsOptional()
  @IsString()
  locationText?: string;

  @IsOptional()
  @IsString()
  startTime?: string;

  @IsOptional()
  @IsString()
  endTime?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(9)
  images?: string[];

  @IsOptional()
  @IsBoolean()
  isUrgent?: boolean;

  @IsOptional()
  @IsEnum(VisibilityType)
  visibility?: VisibilityType;
}
