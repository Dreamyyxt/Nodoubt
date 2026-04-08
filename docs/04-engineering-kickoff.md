# 确任 MVP 研发启动文档

## 1. 文档目标

这份文档承接前面的产品与数据方案：

- [01-mvp-launch-plan.md](/Users/dreamyyxt/Projects/Nodoubt/docs/01-mvp-launch-plan.md)
- [02-page-prototype-checklist.md](/Users/dreamyyxt/Projects/Nodoubt/docs/02-page-prototype-checklist.md)
- [03-data-schema-and-api.md](/Users/dreamyyxt/Projects/Nodoubt/docs/03-data-schema-and-api.md)

目标是回答 4 个研发启动问题：

- 项目应该怎么拆
- 服务端模块应该怎么分
- 代码目录建议怎么搭
- 第一阶段应该按什么顺序开发

这份文档默认技术方案为：

- 客户端：Flutter
- 服务端：NestJS
- 数据库：PostgreSQL
- 缓存：Redis
- 管理后台：React + Ant Design

## 2. 首版工程拆分建议

首版建议至少拆成 3 个工程：

- `app-mobile`
- `app-server`
- `app-admin`

如果团队很小，也可以先只建两个工程：

- `app-mobile`
- `app-server`

后台先在服务端内提供简单管理页面或只开放管理接口。

但如果你希望从一开始就把审核能力做稳，我更建议直接保留独立后台工程。

## 3. Monorepo 还是多仓库

### 建议结论

MVP 推荐使用 Monorepo。

### 原因

- 前后端接口类型和枚举更容易共享
- 文档、脚本、环境配置更集中
- 早期团队协作成本更低
- 版本管理更清晰

### 建议目录顶层

- `apps/`
- `packages/`
- `docs/`
- `scripts/`

## 4. 推荐仓库结构

```text
Nodoubt/
  apps/
    app-mobile/
    app-server/
    app-admin/
  packages/
    shared-types/
    shared-constants/
    eslint-config/
    tsconfig/
  docs/
  scripts/
```

### 4.1 apps/app-mobile

建议职责：

- Flutter 用户端 App
- iOS/Android 双端
- 页面、状态管理、接口调用、即时消息接入

### 4.2 apps/app-server

建议职责：

- NestJS 后端服务
- API
- 鉴权
- 业务逻辑
- 管理接口
- WebSocket
- 定时任务

### 4.3 apps/app-admin

建议职责：

- 审核后台
- 举报处理
- 订单争议处理
- 运营配置

### 4.4 packages/shared-types

建议内容：

- 公共枚举
- DTO 类型声明
- 状态值常量

### 4.5 packages/shared-constants

建议内容：

- 城市枚举
- 分类配置
- 标签常量
- 风控限制常量

## 5. app-server 推荐目录结构

```text
apps/app-server/
  src/
    main.ts
    app.module.ts
    common/
      decorators/
      dto/
      exceptions/
      filters/
      guards/
      interceptors/
      pipes/
      utils/
      constants/
    config/
      app.config.ts
      db.config.ts
      redis.config.ts
      jwt.config.ts
    database/
      migrations/
      seeds/
      prisma/
    modules/
      auth/
      users/
      tags/
      listings/
      applications/
      chats/
      orders/
      payments/
      reviews/
      reports/
      admin/
      notifications/
    jobs/
    gateway/
    tests/
```

说明：

- `common/` 放全局通用能力
- `modules/` 放业务模块
- `gateway/` 可放 WebSocket 网关
- `jobs/` 放定时任务，如超时关闭订单、超时释放申请等

## 6. NestJS 模块拆分建议

## 6.1 auth 模块

职责：

- 短信验证码发送
- 登录登出
- JWT 鉴权
- Refresh Token
- 登录风控限流

建议包含：

- controller
- service
- jwt strategy
- auth guard

核心接口：

- 发送验证码
- 登录
- 刷新 token
- 登出

## 6.2 users 模块

职责：

- 当前用户资料
- 用户主页
- 标签绑定
- 认证申请入口
- 信用分展示

核心接口：

- 获取我的资料
- 更新我的资料
- 获取用户公开主页

## 6.3 tags 模块

职责：

- 标签列表
- 分类配置
- 城市配置

这个模块首版偏配置型，逻辑不会很重。

## 6.4 listings 模块

职责：

- 任务/交换创建、编辑、关闭
- 列表查询
- 详情查询
- 审核状态联动
- 收藏

这是首版最核心的内容模块。

建议内部拆分：

- `listing-query.service`
- `listing-command.service`
- `listing-audit.service`

## 6.5 applications 模块

职责：

- 提交申请
- 查看我的申请
- 查看收到的申请
- 接受/拒绝/撤回申请

关键要求：

- 保证同一条发布不能重复申请
- 保证同一条发布只有一个被接受申请

## 6.6 chats 模块

职责：

- 会话列表
- 消息列表
- 发消息
- 会话创建
- 与发布内容和订单关联

建议设计原则：

- 不做自由聊天
- 所有会话都能追溯到业务对象

## 6.7 orders 模块

职责：

- 创建订单
- 状态流转
- 完成确认
- 退款申请
- 订单事件日志

这是首版交易信任核心。

建议内部拆分：

- `orders.service`
- `order-state-machine.service`
- `order-events.service`

## 6.8 payments 模块

职责：

- 支付单创建
- 第三方支付回调
- 托管状态更新

说明：
MVP 可以先做支付抽象层，即使最早期不接真实支付，也建议把接口预留好。

## 6.9 reviews 模块

职责：

- 创建评价
- 查询评价
- 评价可见性控制

## 6.10 reports 模块

职责：

- 用户提交举报
- 举报状态查询
- 后台处理结果落库

## 6.11 admin 模块

职责：

- 后台登录
- 内容审核
- 举报处理
- 订单仲裁
- 用户封禁

说明：
后台权限首版可以只做两档：

- `super_admin`
- `operator`

## 6.12 notifications 模块

职责：

- 站内通知
- 系统消息
- 重要业务动作通知

首版可先只做站内通知，不急着接完整推送。

## 7. 首版最值得先定义的公共能力

在写具体业务前，建议先把这些公共能力搭好：

- 统一响应结构
- 全局异常处理
- 参数校验
- 登录鉴权
- 权限守卫
- 分页查询基类
- 审计日志工具
- 文件上传能力
- 时间与时区处理规范

如果这些公共层一开始不统一，后面接口很快会散。

## 8. 数据访问层建议

### 推荐方案

NestJS + Prisma

### 原因

- 对 MVP 很友好
- 建模清晰
- 迁移管理方便
- 类型体验好

### 替代方案

- TypeORM
- Drizzle

如果团队没有强偏好，我更建议 Prisma，速度更快，心智更统一。

## 9. 配置与环境建议

至少区分这些环境：

- `local`
- `dev`
- `staging`
- `prod`

建议环境变量分组：

- App 基础配置
- PostgreSQL
- Redis
- JWT
- 短信服务
- 对象存储
- 支付渠道

推荐关键变量示例：

- `APP_PORT`
- `DATABASE_URL`
- `REDIS_URL`
- `JWT_ACCESS_SECRET`
- `JWT_REFRESH_SECRET`
- `SMS_PROVIDER`
- `OSS_BUCKET`
- `WECHAT_PAY_APP_ID`
- `ALIPAY_APP_ID`

## 10. 客户端 app-mobile 建议结构

如果你后面要用 Flutter 开发，建议一开始就按领域拆分，而不是按页面零散堆。

建议结构：

```text
apps/app-mobile/
  lib/
    app/
    core/
      constants/
      network/
      router/
      theme/
      storage/
      utils/
    features/
      auth/
      home/
      listing/
      application/
      chat/
      order/
      profile/
      report/
    shared/
      widgets/
      models/
```

说明：

- `core/` 放全局能力
- `features/` 按业务模块拆分
- `shared/widgets` 放复用 UI 组件

## 11. 管理后台 app-admin 建议结构

建议结构：

```text
apps/app-admin/
  src/
    app/
    modules/
      auth/
      listings/
      reports/
      orders/
      users/
      operations/
    components/
    services/
    constants/
    router/
```

后台首版只做够用，不需要一开始就过度组件化。

## 12. 开发顺序建议

## 阶段 1：基础脚手架

目标：
把工程跑起来。

建议任务：

- 初始化 Monorepo
- 初始化 NestJS 服务
- 初始化 Flutter App
- 初始化后台工程
- 配置 lint、format、commit 规范
- 接入 PostgreSQL 与 Prisma
- 建立基础 CI

## 阶段 2：账号与内容发布

目标：
跑通最小内容创建链路。

建议任务：

- 手机号登录
- 我的资料
- 标签和分类配置
- 创建任务/交换
- 列表查询
- 详情查询
- 内容审核状态流

交付结果：
用户已经可以登录、发内容、看内容。

## 阶段 3：申请与聊天

目标：
跑通用户之间的连接链路。

建议任务：

- 提交申请
- 查看我的申请
- 查看收到的申请
- 创建业务会话
- 文本消息
- 图片消息
- 申请接受/拒绝

交付结果：
用户已经可以围绕任务和交换发生真实沟通。

## 阶段 4：订单与评价

目标：
跑通履约闭环。

建议任务：

- 创建订单
- 订单状态流转
- 支付抽象
- 提交完成
- 确认完成
- 双向评价
- 举报

交付结果：
平台已经具备完整履约链路。

## 阶段 5：后台与风控

目标：
保证平台可运营。

建议任务：

- 后台登录
- 内容审核
- 举报处理
- 订单仲裁
- 用户封禁
- 审计日志

## 13. 建议的里程碑划分

### Milestone 1

完成：

- 登录
- 资料
- 发布
- 首页
- 详情

### Milestone 2

完成：

- 申请
- 我的申请
- 收到的申请
- 基础聊天

### Milestone 3

完成：

- 订单
- 支付占位
- 完成确认
- 评价
- 举报

### Milestone 4

完成：

- 审核后台
- 基础风控
- 上线准备

## 14. 团队协作建议

如果是小团队，建议按“业务主线”分工，而不是按技术层切太细。

一个比较实用的分工方式：

- 产品/UI：先完成首页、详情、发布、申请、会话、订单 6 个核心页面
- 后端：优先做 auth、listings、applications、orders
- 客户端：优先做 auth、home、listing、application
- 后台：跟着内容审核和举报处理走

这样可以最大化保证 MVP 主链路先成型。

## 15. 首版容易踩坑的点

### 15.1 过早做复杂推荐

首版首页用规则排序就够，不要先投入算法。

### 15.2 聊天做成独立社交系统

聊天必须绑定任务、交换或订单，不然边界会迅速失控。

### 15.3 订单状态定义不一致

产品、客户端、服务端、后台必须使用同一套状态枚举。

### 15.4 支付接得太早

可以先把状态和接口抽象好，再接真实支付，避免把前期开发卡死。

### 15.5 风控后置

举报、审核、封禁不是上线后再补的功能，首版就必须有。

## 16. 我对下一步的建议

到这一步，已经可以正式进入代码启动前的最后准备。

最合适的下一步有两个：

1. 我继续为你输出 Prisma Schema 初稿
2. 我直接开始初始化 Monorepo 项目骨架

如果你想先把设计定稳，我建议先做 `Prisma Schema 初稿`。
如果你想直接开干，我可以下一步就开始建项目结构。
