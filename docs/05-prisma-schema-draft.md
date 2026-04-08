# 确任 MVP Prisma Schema 初稿

## 1. 文档目标

这份文档用于把 [03-data-schema-and-api.md](/Users/dreamyyxt/Projects/Nodoubt/docs/03-data-schema-and-api.md) 中的数据模型，进一步落成接近可执行的 Prisma Schema 草稿。

目标不是一次性把所有细节写死，而是先得到一份足够稳定的首版数据骨架，便于后续：

- 初始化 `app-server`
- 编写 `schema.prisma`
- 生成 migration
- 开始 NestJS 模块开发

## 2. 首版取舍说明

为了让 MVP 先跑起来，这份 Prisma 草稿做了几个克制取舍：

- 保留任务和交换的统一 `Listing` 模型
- 先用字符串枚举，不提前引入复杂字典表
- `tags_json`、`images_json`、`portfolio_urls` 这类可变结构先用 `Json`
- 聊天和订单事件保留核心结构，不先做过度拆分
- 先以 PostgreSQL 为目标数据库

## 3. Prisma 建议目录

如果后面开始初始化服务端，建议把 Prisma 目录放在：

`apps/app-server/prisma/schema.prisma`

种子和迁移建议放在：

- `apps/app-server/prisma/seed.ts`
- `apps/app-server/prisma/migrations/`

## 4. Schema 设计要点

### 4.1 ID 策略

首版建议所有核心表统一使用：

- `String @id @default(cuid())`

原因：

- 对客户端和 API 更友好
- 避免暴露连续自增 ID
- Monorepo 和多端协作时更稳

如果你更偏好数据库性能和简单性，后面也可以切回 `BigInt`，但对 MVP 来说 `cuid()` 已经够用。

### 4.2 时间字段

统一保留：

- `createdAt`
- `updatedAt`

必要时再加：

- `deletedAt`
- 业务动作时间字段，例如 `publishedAt`、`completedAt`

### 4.3 状态字段

Prisma 建议直接定义枚举，保证前后端状态一致。

## 5. Prisma Schema 草稿

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum UserStatus {
  ACTIVE
  RESTRICTED
  SUSPENDED
  BANNED
}

enum VerificationType {
  BASIC
  REAL_NAME
  SKILL
  OFFICIAL
}

enum VerificationStatus {
  PENDING
  APPROVED
  REJECTED
}

enum TagType {
  SKILL
  INTEREST
  LISTING
  SCENARIO
}

enum TagStatus {
  ACTIVE
  INACTIVE
}

enum UserTagRelationType {
  SKILL
  INTEREST
}

enum ListingType {
  TASK
  EXCHANGE
}

enum ServiceMode {
  ONLINE
  OFFLINE
  BOTH
}

enum BudgetType {
  FIXED
  RANGE
  NEGOTIABLE
  FREE_EXCHANGE
}

enum VisibilityType {
  PUBLIC
  CITY_ONLY
  PRIVATE
}

enum ListingStatus {
  DRAFT
  PENDING_REVIEW
  PUBLISHED
  MATCHED
  IN_PROGRESS
  COMPLETED
  CLOSED
  REJECTED
}

enum AuditStatus {
  PENDING
  APPROVED
  REJECTED
}

enum ApplicationStatus {
  PENDING
  ACCEPTED
  REJECTED
  WITHDRAWN
  EXPIRED
}

enum ChatType {
  LISTING_CONSULT
  ORDER_CHAT
  SYSTEM
}

enum ChatStatus {
  ACTIVE
  CLOSED
}

enum ChatMemberRole {
  PUBLISHER
  APPLICANT
  BUYER
  SELLER
  SYSTEM
}

enum MessageType {
  TEXT
  IMAGE
  SYSTEM_CARD
  ACTION_CARD
}

enum MessageStatus {
  SENT
  RECALLED
  DELETED
}

enum OrderType {
  TASK_ORDER
  EXCHANGE_CONFIRMATION
}

enum EscrowStatus {
  NOT_REQUIRED
  PENDING_PAYMENT
  PAID
  FROZEN
  RELEASED
  REFUNDING
  REFUNDED
}

enum OrderStatus {
  PENDING_PAYMENT
  PENDING_ACCEPT
  IN_PROGRESS
  PENDING_CONFIRMATION
  COMPLETED
  REFUND_REQUESTED
  REFUNDED
  ARBITRATING
  CANCELLED
}

enum OrderEventType {
  CREATED
  PAID
  ACCEPTED
  STARTED
  DELIVERED
  CONFIRMED
  REFUND_REQUESTED
  REFUNDED
  CANCELLED
  ARBITRATION_STARTED
  ARBITRATION_CLOSED
}

enum PaymentChannel {
  WECHAT_PAY
  ALIPAY
}

enum PaymentStatus {
  PENDING
  PAID
  FAILED
  CLOSED
  REFUNDED
}

enum RefundStatus {
  PENDING
  APPROVED
  REJECTED
  COMPLETED
}

enum ReviewStatus {
  VISIBLE
  HIDDEN
}

enum ReportTargetType {
  USER
  LISTING
  MESSAGE
  ORDER
}

enum ReportStatus {
  PENDING
  PROCESSING
  RESOLVED
  REJECTED
}

enum FavoriteTargetType {
  LISTING
}

enum AdminRole {
  SUPER_ADMIN
  OPERATOR
}

enum AdminStatus {
  ACTIVE
  DISABLED
}

model User {
  id                     String                @id @default(cuid())
  phone                  String                @unique
  phoneCountryCode       String                @default("+86")
  passwordHash           String?
  status                 UserStatus            @default(ACTIVE)
  nickname               String
  avatarUrl              String?
  gender                 String?
  birthday               DateTime?
  cityCode               String?
  bio                    String?
  creditScore            Int                   @default(100)
  level                  Int                   @default(1)
  ratingAvg              Decimal?              @db.Decimal(3, 2)
  ratingCount            Int                   @default(0)
  completedTaskCount     Int                   @default(0)
  completedExchangeCount Int                   @default(0)
  lastLoginAt            DateTime?
  createdAt              DateTime              @default(now())
  updatedAt              DateTime              @updatedAt
  deletedAt              DateTime?

  profile                UserProfile?
  verifications          UserVerification[]
  userTags               UserTagRelation[]
  publishedListings      Listing[]             @relation("ListingPublisher")
  applications           Application[]
  sentMessages           Message[]
  boughtOrders           Order[]               @relation("OrderBuyer")
  soldOrders             Order[]               @relation("OrderSeller")
  writtenReviews         Review[]              @relation("ReviewFromUser")
  receivedReviews        Review[]              @relation("ReviewToUser")
  reports                Report[]              @relation("ReportReporter")
  favorites              Favorite[]
  chatMembers            ChatMember[]
}

model UserProfile {
  id                    String    @id @default(cuid())
  userId                String    @unique
  realName              String?
  signature             String?
  serviceCityCode       String?
  skillSummary          String?
  interestSummary       String?
  showGender            Boolean   @default(false)
  showBirthday          Boolean   @default(false)
  profileCompletionRate Int       @default(0)
  createdAt             DateTime  @default(now())
  updatedAt             DateTime  @updatedAt

  user                  User      @relation(fields: [userId], references: [id])
}

model UserVerification {
  id                 String              @id @default(cuid())
  userId             String
  verificationType   VerificationType
  verificationStatus VerificationStatus  @default(PENDING)
  submittedAt        DateTime?
  reviewedAt         DateTime?
  reviewedBy         String?
  remark             String?
  createdAt          DateTime            @default(now())
  updatedAt          DateTime            @updatedAt

  user               User                @relation(fields: [userId], references: [id])

  @@index([userId, verificationType])
}

model Tag {
  id            String             @id @default(cuid())
  tagType       TagType
  name          String
  slug          String             @unique
  sortOrder     Int                @default(0)
  status        TagStatus          @default(ACTIVE)
  createdAt     DateTime           @default(now())
  updatedAt     DateTime           @updatedAt

  userRelations UserTagRelation[]
}

model UserTagRelation {
  id            String              @id @default(cuid())
  userId        String
  tagId         String
  relationType  UserTagRelationType
  createdAt     DateTime            @default(now())

  user          User                @relation(fields: [userId], references: [id])
  tag           Tag                 @relation(fields: [tagId], references: [id])

  @@unique([userId, tagId, relationType])
  @@index([userId])
}

model Listing {
  id                    String             @id @default(cuid())
  listingType           ListingType
  publisherId           String
  title                 String
  description           String
  categoryCode          String?
  tagsJson              Json?
  cityCode              String?
  locationText          String?
  longitude             Decimal?           @db.Decimal(10, 7)
  latitude              Decimal?           @db.Decimal(10, 7)
  serviceMode           ServiceMode
  budgetType            BudgetType?
  budgetAmount          Decimal?           @db.Decimal(10, 2)
  exchangeOfferText     String?
  exchangeWantText      String?
  headcount             Int?
  startTime             DateTime?
  endTime               DateTime?
  isUrgent              Boolean            @default(false)
  visibility            VisibilityType     @default(PUBLIC)
  status                ListingStatus      @default(DRAFT)
  auditStatus           AuditStatus        @default(PENDING)
  auditReason           String?
  acceptedApplicationId String?
  publishedAt           DateTime?
  closedAt              DateTime?
  createdAt             DateTime           @default(now())
  updatedAt             DateTime           @updatedAt
  deletedAt             DateTime?

  publisher             User               @relation("ListingPublisher", fields: [publisherId], references: [id])
  images                ListingImage[]
  applications          Application[]
  chats                 Chat[]
  orders                Order[]
  favorites             Favorite[]
  reports               Report[]           @relation("ReportListing")

  @@index([publisherId, status])
  @@index([listingType, status, cityCode, publishedAt])
  @@index([auditStatus, status])
}

model ListingImage {
  id         String    @id @default(cuid())
  listingId  String
  imageUrl   String
  sortOrder  Int       @default(0)
  createdAt  DateTime  @default(now())

  listing    Listing   @relation(fields: [listingId], references: [id])

  @@index([listingId, sortOrder])
}

model Application {
  id                  String             @id @default(cuid())
  listingId           String
  applicantId         String
  message             String
  quotedPrice         Decimal?           @db.Decimal(10, 2)
  availableStartTime  DateTime?
  portfolioUrls       Json?
  status              ApplicationStatus  @default(PENDING)
  handledAt           DateTime?
  handledBy           String?
  createdAt           DateTime           @default(now())
  updatedAt           DateTime           @updatedAt

  listing             Listing            @relation(fields: [listingId], references: [id])
  applicant           User               @relation(fields: [applicantId], references: [id])
  orders              Order[]

  @@unique([listingId, applicantId])
  @@index([listingId, status])
  @@index([applicantId, status])
}

model Chat {
  id             String      @id @default(cuid())
  chatType       ChatType
  listingId      String?
  orderId        String?
  lastMessageId  String?
  lastMessageAt  DateTime?
  status         ChatStatus  @default(ACTIVE)
  createdAt      DateTime    @default(now())
  updatedAt      DateTime    @updatedAt

  listing        Listing?    @relation(fields: [listingId], references: [id])
  order          Order?      @relation(fields: [orderId], references: [id])
  members        ChatMember[]
  messages       Message[]

  @@index([listingId])
  @@index([orderId])
}

model ChatMember {
  id         String          @id @default(cuid())
  chatId     String
  userId     String
  roleType   ChatMemberRole
  joinedAt   DateTime        @default(now())

  chat       Chat            @relation(fields: [chatId], references: [id])
  user       User            @relation(fields: [userId], references: [id])

  @@unique([chatId, userId])
  @@index([userId])
}

model Message {
  id           String         @id @default(cuid())
  chatId        String
  senderId      String
  messageType   MessageType
  textContent   String?
  imageUrl      String?
  payloadJson   Json?
  status        MessageStatus @default(SENT)
  sentAt        DateTime      @default(now())
  createdAt     DateTime      @default(now())

  chat          Chat          @relation(fields: [chatId], references: [id])
  sender        User          @relation(fields: [senderId], references: [id])
  reports       Report[]      @relation("ReportMessage")

  @@index([chatId, createdAt])
}

model Order {
  id            String         @id @default(cuid())
  listingId     String
  applicationId String?
  buyerId       String
  sellerId      String
  orderType     OrderType
  amountTotal   Decimal        @db.Decimal(10, 2)
  platformFee   Decimal        @default(0) @db.Decimal(10, 2)
  sellerIncome  Decimal        @default(0) @db.Decimal(10, 2)
  escrowStatus  EscrowStatus   @default(NOT_REQUIRED)
  orderStatus   OrderStatus    @default(PENDING_PAYMENT)
  scheduledAt   DateTime?
  deliveredAt   DateTime?
  completedAt   DateTime?
  cancelledAt   DateTime?
  closedReason  String?
  createdAt     DateTime       @default(now())
  updatedAt     DateTime       @updatedAt

  listing       Listing        @relation(fields: [listingId], references: [id])
  application   Application?   @relation(fields: [applicationId], references: [id])
  buyer         User           @relation("OrderBuyer", fields: [buyerId], references: [id])
  seller        User           @relation("OrderSeller", fields: [sellerId], references: [id])
  chats         Chat[]
  events        OrderEvent[]
  payments      Payment[]
  refunds       Refund[]
  reviews       Review[]
  reports       Report[]       @relation("ReportOrder")

  @@index([buyerId, orderStatus])
  @@index([sellerId, orderStatus])
  @@index([listingId])
}

model OrderEvent {
  id             String          @id @default(cuid())
  orderId        String
  eventType      OrderEventType
  operatorUserId String?
  operatorRole   String?
  eventPayload   Json?
  createdAt      DateTime        @default(now())

  order          Order           @relation(fields: [orderId], references: [id])

  @@index([orderId, createdAt])
}

model Payment {
  id                String         @id @default(cuid())
  orderId           String
  payerId           String
  paymentChannel    PaymentChannel
  amount            Decimal        @db.Decimal(10, 2)
  paymentStatus     PaymentStatus  @default(PENDING)
  thirdPartyTradeNo String?
  paidAt            DateTime?
  createdAt         DateTime       @default(now())
  updatedAt         DateTime       @updatedAt

  order             Order          @relation(fields: [orderId], references: [id])

  @@index([orderId, paymentStatus])
}

model Refund {
  id            String        @id @default(cuid())
  orderId       String
  requesterId   String
  reasonCode    String
  description   String?
  refundAmount  Decimal       @db.Decimal(10, 2)
  refundStatus  RefundStatus  @default(PENDING)
  reviewedBy    String?
  reviewedAt    DateTime?
  createdAt     DateTime      @default(now())
  updatedAt     DateTime      @updatedAt

  order         Order         @relation(fields: [orderId], references: [id])

  @@index([orderId, refundStatus])
}

model Review {
  id           String        @id @default(cuid())
  orderId       String
  fromUserId    String
  toUserId      String
  score         Int
  tagsJson      Json?
  content       String?
  imagesJson    Json?
  isAnonymous   Boolean       @default(false)
  status        ReviewStatus  @default(VISIBLE)
  createdAt     DateTime      @default(now())
  updatedAt     DateTime      @updatedAt

  order         Order         @relation(fields: [orderId], references: [id])
  fromUser      User          @relation("ReviewFromUser", fields: [fromUserId], references: [id])
  toUser        User          @relation("ReviewToUser", fields: [toUserId], references: [id])

  @@unique([orderId, fromUserId])
  @@index([toUserId, status])
}

model Report {
  id            String           @id @default(cuid())
  reporterId    String
  targetType    ReportTargetType
  targetId      String
  reasonCode    String
  description   String?
  evidenceUrls  Json?
  status        ReportStatus     @default(PENDING)
  reviewResult  String?
  reviewedBy    String?
  reviewedAt    DateTime?
  createdAt     DateTime         @default(now())
  updatedAt     DateTime         @updatedAt

  reporter      User             @relation("ReportReporter", fields: [reporterId], references: [id])
  listing       Listing?         @relation("ReportListing", fields: [targetId], references: [id], map: "report_listing_fk", onDelete: NoAction, onUpdate: NoAction)
  message       Message?         @relation("ReportMessage", fields: [targetId], references: [id], map: "report_message_fk", onDelete: NoAction, onUpdate: NoAction)
  order         Order?           @relation("ReportOrder", fields: [targetId], references: [id], map: "report_order_fk", onDelete: NoAction, onUpdate: NoAction)

  @@index([reporterId])
  @@index([targetType, targetId])
}

model Favorite {
  id          String             @id @default(cuid())
  userId      String
  targetType  FavoriteTargetType
  targetId    String
  createdAt   DateTime           @default(now())

  user        User               @relation(fields: [userId], references: [id])
  listing     Listing?           @relation(fields: [targetId], references: [id])

  @@unique([userId, targetType, targetId])
  @@index([userId, createdAt])
}

model AdminUser {
  id           String       @id @default(cuid())
  username     String       @unique
  passwordHash String
  role         AdminRole
  status       AdminStatus  @default(ACTIVE)
  lastLoginAt  DateTime?
  createdAt    DateTime     @default(now())
  updatedAt    DateTime     @updatedAt

  auditLogs    AuditLog[]
}

model AuditLog {
  id          String      @id @default(cuid())
  operatorId  String
  targetType  String
  targetId    String
  action      String
  detailJson  Json?
  createdAt   DateTime    @default(now())

  operator    AdminUser   @relation(fields: [operatorId], references: [id])

  @@index([operatorId, createdAt])
  @@index([targetType, targetId])
}
```

## 6. 需要注意的 Prisma 实现细节

### 6.1 `Report` 和 `Favorite` 的多态关联

严格来说，Prisma 不擅长直接表达“一个 `targetId` 指向多个不同表”的典型多态关联。

上面的 Schema 草稿是为了帮助我们表达业务意图，但真正落地到可执行 `schema.prisma` 时，建议改成下面两种方案之一：

方案 A：

- `Report` 保留 `targetType + targetId`
- 不建立 Prisma relation
- 在业务层按 `targetType` 手动查询目标对象

方案 B：

- 把 `listing`、`message`、`order` 分成不同举报表
- 用更强的数据库约束换更高的表数量

对 MVP 来说，我更建议方案 A，简单很多。

`Favorite` 也同理。首版只有收藏 `Listing`，所以也可以直接把 `targetType` 去掉，改成明确的 `listingId`。

### 6.2 `acceptedApplicationId`

`Listing.acceptedApplicationId` 是一个有用的业务快捷字段，但 Prisma 中如果同时保留：

- `Listing.applications`
- `Listing.acceptedApplicationId`

就会出现双重关联表达的问题。

落地时建议：

- 第一版先保留 `acceptedApplicationId` 为普通字符串字段
- 业务层自己校验它是否属于该 `listing`

这样最省心。

### 6.3 `tagsJson`

首版为了快速推进，我建议在 `Listing` 上直接用 `tagsJson`。

如果后续需要：

- 更强搜索
- 更复杂推荐
- 精准统计

再拆成 `listing_tag_relations` 表也不晚。

## 7. 我更推荐的可执行落地版

如果下一步真的要开始写 `schema.prisma`，我建议做这 3 个小调整：

1. 把 `Favorite` 改成只收藏 `Listing`
2. 把 `Report` 的多态 relation 去掉，改成纯字段表达
3. 暂时不在 Prisma 里给 `acceptedApplicationId` 建 relation

这样可以显著减少 Prisma 层面的复杂度。

## 8. 建表优先顺序

如果接下来开始正式建 Prisma Schema，推荐建表顺序：

1. `User`
2. `UserProfile`
3. `UserVerification`
4. `Tag`
5. `UserTagRelation`
6. `Listing`
7. `ListingImage`
8. `Application`
9. `Chat`
10. `ChatMember`
11. `Message`
12. `Order`
13. `OrderEvent`
14. `Payment`
15. `Refund`
16. `Review`
17. `Report`
18. `Favorite`
19. `AdminUser`
20. `AuditLog`

## 9. 当前结论

到这一步，我们已经把“产品文档 -> 页面原型 -> 数据 Schema -> 研发启动 -> Prisma 草稿”这条链路串起来了。

下一步我建议不要再只写文档了，直接进入真正的项目落地二选一：

1. 我把这份草稿转成一版可执行的 `schema.prisma`
2. 我开始初始化 Monorepo 项目骨架

我会优先建议先做第 2 个里的服务端部分，也就是：

先创建 `app-server`，把 Prisma 真正落到代码里。
