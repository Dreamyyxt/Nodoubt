import { ForbiddenException, Injectable } from "@nestjs/common";
import { successResponse } from "../../common/utils/api-response";
import { PrismaService } from "../prisma/prisma.service";
import { LoginDto } from "./dto/login.dto";
import { SendSmsDto } from "./dto/send-sms.dto";

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService) {}

  sendSms(dto: SendSmsDto) {
    return successResponse(
      {
        phone: dto.phone,
        scene: dto.scene,
        devCode: "123456",
      },
      "development sms sent",
    );
  }

  async login(dto: LoginDto) {
    if (dto.code !== "123456") {
      throw new ForbiddenException("Invalid development verification code");
    }

    const user = await this.prisma.user.upsert({
      where: {
        phone: dto.phone,
      },
      update: {
        lastLoginAt: new Date(),
      },
      create: {
        phone: dto.phone,
        nickname: `用户${dto.phone.slice(-4)}`,
        lastLoginAt: new Date(),
      },
      select: {
        id: true,
        phone: true,
        nickname: true,
        cityCode: true,
      },
    });

    return successResponse(
      {
        accessToken: `dev-token-${user.id}`,
        refreshToken: `dev-refresh-${user.id}`,
        user,
        isProfileCompleted: Boolean(user.nickname && user.cityCode),
        debugHeaders: {
          "x-user-id": user.id,
        },
      },
      "development login success",
    );
  }
}
