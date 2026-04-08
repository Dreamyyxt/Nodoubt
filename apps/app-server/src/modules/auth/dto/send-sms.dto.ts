import { IsNotEmpty, IsString } from "class-validator";

export class SendSmsDto {
  @IsString()
  @IsNotEmpty()
  phone!: string;

  @IsString()
  @IsNotEmpty()
  scene!: string;
}

