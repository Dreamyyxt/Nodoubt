import { Injectable, NotFoundException } from "@nestjs/common";
import { PrismaService } from "../prisma/prisma.service";
import { successResponse } from "../../common/utils/api-response";
import { UpdateMeDto } from "./dto/update-me.dto";

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: true,
        userTags: {
          include: {
            tag: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException("User not found");
    }

    return successResponse({
      id: user.id,
      phone: user.phone,
      nickname: user.nickname,
      avatarUrl: user.avatarUrl,
      cityCode: user.cityCode,
      bio: user.bio,
      creditScore: user.creditScore,
      level: user.level,
      ratingAvg: user.ratingAvg,
      ratingCount: user.ratingCount,
      completedTaskCount: user.completedTaskCount,
      completedExchangeCount: user.completedExchangeCount,
      profile: user.profile,
      tags: user.userTags.map((relation) => ({
        id: relation.tag.id,
        name: relation.tag.name,
        relationType: relation.relationType,
      })),
    });
  }

  async updateMe(userId: string, dto: UpdateMeDto) {
    const existingUser = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!existingUser) {
      throw new NotFoundException("User not found");
    }

    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        nickname: dto.nickname,
        avatarUrl: dto.avatarUrl,
        cityCode: dto.cityCode,
        bio: dto.bio,
      },
      select: {
        id: true,
        nickname: true,
        avatarUrl: true,
        cityCode: true,
        bio: true,
      },
    });

    return successResponse(user, "profile updated");
  }

  async getUserProfile(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        nickname: true,
        avatarUrl: true,
        cityCode: true,
        bio: true,
        creditScore: true,
        level: true,
        ratingAvg: true,
        ratingCount: true,
        completedTaskCount: true,
        completedExchangeCount: true,
      },
    });

    if (!user) {
      throw new NotFoundException("User not found");
    }

    return successResponse(user);
  }
}
