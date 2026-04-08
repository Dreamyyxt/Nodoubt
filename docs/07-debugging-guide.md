# 确任当前阶段调试指南

## 1. 先说结论

你现在要调试的，不是完整 App，而是两层：

1. 当前已经能调试的：`app-server` 后端接口
2. 未来 Flutter 客户端建起来后再调试的：移动端页面、路由、状态、接口联调

因为目前仓库里还没有 Flutter 工程代码，所以现在最实用的调试方式，是先把后端服务跑起来，用接口调试工具验证业务链路。

## 2. 你现在怎么调试

### 2.1 先准备环境变量

根目录新建 `.env`，至少填：

```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/nodoubt"
REDIS_URL="redis://localhost:6379"
JWT_ACCESS_SECRET="replace-me"
JWT_REFRESH_SECRET="replace-me"
APP_PORT=3000
```

说明：
现在还没把 PostgreSQL 跑起来的话，部分依赖数据库的接口会失败，但基础启动方式先是这样。

### 2.2 启动后端开发服务

在项目根目录运行：

```bash
pnpm dev:server
```

如果你想带调试端口启动 NestJS：

```bash
pnpm --filter @nodoubt/app-server start:debug
```

### 2.3 验证服务是否起来

服务启动后访问：

```bash
curl http://localhost:3000/api/v1/health
```

正常返回应类似：

```json
{
  "status": "ok",
  "service": "app-server",
  "timestamp": "2026-03-27T00:00:00.000Z"
}
```

## 3. 当前后端怎么调接口

现在已经有这些可调试入口：

- `GET /api/v1/health`
- `POST /api/v1/auth/sms/send`
- `POST /api/v1/auth/login`
- `GET /api/v1/me`
- `PATCH /api/v1/me`
- `GET /api/v1/users/:id`
- `POST /api/v1/listings`
- `GET /api/v1/listings`
- `GET /api/v1/listings/:id`
- `PATCH /api/v1/listings/:id`
- `POST /api/v1/listings/:id/close`

说明：
其中 `users` 和 `listings` 已经接入 Prisma 结构，但仍然需要数据库才能真正读写。

## 4. 当前开发期“登录态”怎么模拟

在真实 JWT 还没接好前，我给你留了一个开发期方案：

请求头带上：

- `x-user-id`
或
- `x-dev-user-id`

例如：

```bash
curl http://localhost:3000/api/v1/me \
  -H "x-user-id: your-user-id"
```

这意味着：

- 当前阶段你不需要先完成完整登录系统，仍然可以继续联调 `users` 和 `listings`
- 只要数据库里有这条用户记录，就可以用这个 ID 模拟当前用户

当前仓库里已经插入了一个开发测试用户：

- `x-user-id: dev_user_001`

## 4.1 当前开发验证码

现在的开发期登录逻辑中，验证码固定为：

```text
123456
```

你可以先调：

```bash
curl -X POST http://localhost:3000/api/v1/auth/sms/send \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800000000","scene":"login"}'
```

再调：

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800000000","code":"123456"}'
```

登录返回里会带开发态 `x-user-id`，后面继续调 `me`、`listings`、`applications`、`orders` 时就直接复用这个值。

## 5. 你现在最推荐的调试工具

### 方式 A：curl

适合快速验证接口是否通。

示例：

```bash
curl http://localhost:3000/api/v1/listings
```

### 方式 B：Postman / Apifox

适合：

- 保存接口集合
- 反复切换请求体
- 带 Header 调试
- 团队共享接口测试

这是我更推荐你的方式。

### 方式 C：IDE 断点调试 NestJS

如果你用的是支持 Node 调试的 IDE，可以直接给 controller/service 打断点。

启动方式：

```bash
pnpm --filter @nodoubt/app-server start:debug
```

然后附加到 Node 调试端口。

## 6. 当前最实用的调试顺序

我建议你现在这样调：

1. 先启动后端服务
2. 先用 `health` 验证服务正常
3. 跑通一个测试用户
4. 用 Header 模拟当前用户
5. 调试 `create listing`
6. 调试 `get listings`
7. 调试 `get me`

这条链路最短，也最容易尽快看到真实结果。

## 7. 未来 Flutter App 建起来后怎么调试

等我们开始写 `app-mobile` 后，调试会分成 4 层：

### 7.1 UI 调试

看页面布局、组件状态、文案、交互。

工具：

- Flutter hot reload
- Flutter DevTools

### 7.2 路由调试

看页面跳转和参数传递是否正确。

### 7.3 状态调试

看页面状态、接口状态、错误态是否一致。

### 7.4 联调调试

让 Flutter 真正请求本地 `app-server`。

这里要注意：

- iOS 模拟器一般可直接访问 `localhost`
- Android 模拟器通常要改成本机映射地址，例如 `10.0.2.2`

## 8. 未来移动端调试时你最需要记住的一点

不要一上来就在真机上排所有问题。

正确顺序通常是：

1. 先调后端接口
2. 再调模拟器 UI
3. 再调接口联动
4. 最后再上真机排设备问题

这样效率最高。

## 9. 当前阶段的现实情况

现在仓库的真实状态是：

- 后端已经可以编译
- Prisma 已接进去
- 但数据库还没启动
- Flutter 客户端还没初始化

所以你现在能调试的是：

- 后端启动
- 后端路由
- 后端断点
- Prisma 查询逻辑

你现在还不能调试的是：

- 移动端页面
- 真机 App
- 双端联调完整链路

## 10. 我建议你接下来的调试节奏

最合理的顺序是：

1. 我继续把 PostgreSQL 跑起来
2. 跑首个 migration
3. 插入测试用户数据
4. 你就可以开始用 Postman/Apifox 调接口
5. 然后我再初始化 Flutter 工程

这条路线最稳。
