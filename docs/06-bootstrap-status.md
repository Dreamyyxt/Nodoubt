# 确任项目初始化状态

## 已完成

- 已安装本地开发工具链：
  - `node v22.22.2`
  - `npm v10.9.7`
  - `pnpm v10.33.0`
  - `yarn v4.13.0`
  - `Flutter 3.41.6`
  - `Dart 3.11.4`
- 已确认本机可用：
  - `Homebrew 5.1.1`
  - `PostgreSQL 18.3`
- 建立 Monorepo 基础目录：
  - `apps/app-server`
  - `apps/app-mobile`
  - `apps/app-admin`
  - `packages/shared-types`
  - `packages/shared-constants`
- 新增根目录 `package.json`
- 新增 `.gitignore`、`.editorconfig`、`.env.example`
- 新增服务端 `Prisma` 初版文件：
  - `apps/app-server/prisma/schema.prisma`
- 已生成 Prisma Client
- 已创建本地数据库：
  - `nodoubt`
- 已执行首个 Prisma migration：
  - `20260327102232_init`
- 已写入开发环境变量：
  - 根目录 `.env`
  - `apps/app-server/.env`
- 已把服务端从占位文件推进为可编译的 NestJS 骨架：
  - `health` 接口
  - `prisma` 模块
  - `auth` 模块
  - `users` 模块
  - `listings` 模块
  - `applications` 模块
  - `orders` 模块
  - `reviews` 模块
  - `reports` 模块
- `users` 和 `listings` 已从 mock 返回推进为 Prisma 驱动的服务结构
- `applications` 和 `orders` 已补上 Prisma 驱动的主链路服务结构
- `reviews` 和 `reports` 已补上 Prisma 驱动的服务结构
- 已加入开发期用户 Header 方案：
  - 使用 `x-user-id` 或 `x-dev-user-id`
- `auth` 已升级为开发期可联调状态：
  - 验证码固定为 `123456`
  - 登录后返回开发态 `x-user-id`
- 已通过服务端构建校验：
  - `pnpm build:server`
- 已插入开发测试用户：
  - `id = dev_user_001`
  - `phone = 13800000000`
- 已验证真实接口可用：
  - `GET /api/v1/health`
  - `GET /api/v1/me` with `x-user-id: dev_user_001`
  - `POST /api/v1/auth/sms/send`
  - `POST /api/v1/auth/login`
- 已创建 Flutter 移动端工程：
  - `apps/app-mobile`
- 已将 Flutter 默认计数器页替换为确任的初始壳层：
  - 首页
  - 发布
  - 消息
  - 订单
  - 我的
- 已为 Flutter 接入开发期联调基础层：
  - API base URL 配置
  - HTTP 客户端
  - 开发登录
  - `me` 接口请求
  - 列表接口请求
- 已通过移动端校验：
  - `flutter analyze`
  - `flutter test`

## 当前状态

当前已经没有 Node 环境层面的阻塞。

仍然未完成的部分：

- `auth` 仍未接真实短信、JWT 和正式登录态
- 后台工程仍未初始化为 React 项目

## 你装好环境后建议的下一步

1. 启动 Redis
2. 继续把 Flutter 的发布列表、登录态和发布流程做实
3. 初始化后台工程
4. 后续再把 `auth` 切成真实短信/JWT

## 说明

仓库现在已经从“只有文档”进入了“有可编译服务端工程和 Prisma 数据模型”的阶段，可以开始真正按模块往下开发。
