import { BadRequestException, createParamDecorator, ExecutionContext } from "@nestjs/common";

export const CurrentUserId = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): string => {
    const request = ctx.switchToHttp().getRequest<Request & { headers: Record<string, string | string[] | undefined> }>();
    const userIdHeader = request.headers["x-user-id"] ?? request.headers["x-dev-user-id"];
    const userId = Array.isArray(userIdHeader) ? userIdHeader[0] : userIdHeader;

    if (!userId) {
      throw new BadRequestException("Missing current user id header. Use x-user-id during development.");
    }

    return userId;
  },
);

