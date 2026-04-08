import { Body, Controller, Get, Param, Patch } from "@nestjs/common";
import { CurrentUserId } from "../../common/decorators/current-user-id.decorator";
import { UpdateMeDto } from "./dto/update-me.dto";
import { UsersService } from "./users.service";

@Controller()
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get("me")
  getMe(@CurrentUserId() userId: string) {
    return this.usersService.getMe(userId);
  }

  @Patch("me")
  updateMe(@CurrentUserId() userId: string, @Body() dto: UpdateMeDto) {
    return this.usersService.updateMe(userId, dto);
  }

  @Get("users/:id")
  getUserProfile(@Param("id") id: string) {
    return this.usersService.getUserProfile(id);
  }
}
