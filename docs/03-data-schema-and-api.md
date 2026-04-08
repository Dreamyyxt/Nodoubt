# 确任 MVP 数据库 Schema 与 API 草案

## 1. 文档目标

这份文档承接：

- [readme.md](/Users/dreamyyxt/Projects/Nodoubt/readme.md)
- [01-mvp-launch-plan.md](/Users/dreamyyxt/Projects/Nodoubt/docs/01-mvp-launch-plan.md)
- [02-page-prototype-checklist.md](/Users/dreamyyxt/Projects/Nodoubt/docs/02-page-prototype-checklist.md)

目标是把产品层的页面和流程，落成研发可以直接继续细化的：

- 核心数据实体
- 表结构建议
- 关键枚举
- 核心实体关系
- API 路由草案
- 状态流转约束

说明：
这里以 MVP 为边界，不提前设计搭子、逛逛内容流、主理人、线下门店等二期能力，但会预留少量扩展空间。

## 2. 设计原则

### 2.1 统一承载任务与交换

MVP 采用统一 `listings` 表承载：

- 任务 `task`
- 交换 `exchange`

原因：

- 列表、搜索、审核、收藏、举报都可以共用一套主逻辑
- 客户端卡片和详情结构更容易统一
- 后续扩展搭子或内容时，数据模型更容易保持一致性

### 2.2 首版避免过度拆表

首版不为了“理论完美”过早拆成大量子表。

优先保证：

- 主链路数据完整
- 查询容易实现
- 审核和风控可落地
- 后续迁移成本可控

### 2.3 所有关键对象都要有状态

MVP 是交易型产品，状态是第一优先级。

这些对象必须有明确状态：

- 用户
- 发布内容
- 申请
- 订单
- 支付
- 举报
- 评价

## 3. 核心实体关系

核心关系可以概括为：

- 一个 `user` 可以发布多个 `listing`
- 一个 `listing` 可以收到多个 `application`
- 一个 `listing` 在 MVP 中最多只产生一个有效主订单 `order`
- 一个 `order` 对应双方用户
- 一个 `order` 可以产生最多两条 `review`
- 用户、发布内容、消息、订单都可能被 `report`

建议关系如下：

- `users 1 -> n listings`
- `users 1 -> n applications`
- `listings 1 -> n applications`
- `listings 1 -> 0..1 orders`
- `orders 1 -> n order_events`
- `orders 1 -> 0..2 reviews`
- `users 1 -> n reports`
- `chats 1 -> n messages`

## 4. 建议的表清单

MVP 最少建议包含以下表：

- `users`
- `user_profiles`
- `user_verifications`
- `user_tag_relations`
- `tags`
- `listings`
- `listing_images`
- `applications`
- `chats`
- `chat_members`
- `messages`
- `orders`
- `order_events`
- `payments`
- `refunds`
- `reviews`
- `reports`
- `favorites`
- `admin_users`
- `audit_logs`

如果想更轻一点，首版也可以把 `user_profiles` 合并进 `users`，但我更建议保留拆分，方便后续演进。

## 5. 数据库建议

推荐数据库：PostgreSQL

建议统一字段约定：

- 主键：`bigserial` 或 `uuid`
- 时间字段：`created_at`, `updated_at`
- 软删除字段：`deleted_at`
- 状态字段：统一使用枚举字符串或受控文本

如果团队偏好简单实现，MVP 可以先用 `bigserial` 主键，对外 API 返回字符串化 ID。

## 6. 主要表结构草案

## 6.1 users

用户账号基础信息。

建议字段：

- `id`
- `phone`
- `phone_country_code`
- `password_hash`
- `status`
- `nickname`
- `avatar_url`
- `gender`
- `birthday`
- `city_code`
- `bio`
- `credit_score`
- `level`
- `rating_avg`
- `rating_count`
- `completed_task_count`
- `completed_exchange_count`
- `last_login_at`
- `created_at`
- `updated_at`
- `deleted_at`

约束建议：

- `phone` 唯一
- `status` 必填
- `credit_score` 默认初始值

推荐 `status` 枚举：

- `active`
- `restricted`
- `suspended`
- `banned`

## 6.2 user_profiles

承载更适合扩展的用户资料字段。

建议字段：

- `user_id`
- `real_name`
- `signature`
- `service_city_code`
- `skill_summary`
- `interest_summary`
- `show_gender`
- `show_birthday`
- `profile_completion_rate`
- `created_at`
- `updated_at`

说明：
如果首版想简化，也可先不建这张表，把必要字段放回 `users`。

## 6.3 user_verifications

承载认证信息。

建议字段：

- `id`
- `user_id`
- `verification_type`
- `verification_status`
- `submitted_at`
- `reviewed_at`
- `reviewed_by`
- `remark`
- `created_at`
- `updated_at`

推荐 `verification_type`：

- `basic`
- `real_name`
- `skill`
- `official`

推荐 `verification_status`：

- `pending`
- `approved`
- `rejected`

## 6.4 tags

统一标签表。

建议字段：

- `id`
- `tag_type`
- `name`
- `slug`
- `sort_order`
- `status`
- `created_at`
- `updated_at`

推荐 `tag_type`：

- `skill`
- `interest`
- `listing`
- `scenario`

## 6.5 user_tag_relations

用户与标签的关系表。

建议字段：

- `id`
- `user_id`
- `tag_id`
- `relation_type`
- `created_at`

推荐 `relation_type`：

- `skill`
- `interest`

## 6.6 listings

MVP 最核心的统一发布表。

建议字段：

- `id`
- `listing_type`
- `publisher_id`
- `title`
- `description`
- `category_code`
- `city_code`
- `location_text`
- `longitude`
- `latitude`
- `service_mode`
- `budget_type`
- `budget_amount`
- `exchange_offer_text`
- `exchange_want_text`
- `headcount`
- `start_time`
- `end_time`
- `is_urgent`
- `visibility`
- `status`
- `audit_status`
- `audit_reason`
- `accepted_application_id`
- `published_at`
- `closed_at`
- `created_at`
- `updated_at`
- `deleted_at`

推荐 `listing_type`：

- `task`
- `exchange`

推荐 `service_mode`：

- `online`
- `offline`
- `both`

推荐 `budget_type`：

- `fixed`
- `range`
- `negotiable`
- `free_exchange`

推荐 `visibility`：

- `public`
- `city_only`
- `private`

推荐 `status`：

- `draft`
- `pending_review`
- `published`
- `matched`
- `in_progress`
- `completed`
- `closed`
- `rejected`

推荐 `audit_status`：

- `pending`
- `approved`
- `rejected`

说明：

- 任务主要使用 `budget_amount`
- 交换主要使用 `exchange_offer_text` 和 `exchange_want_text`
- `accepted_application_id` 用于标记当前被选中的申请

## 6.7 listing_images

发布内容图片表。

建议字段：

- `id`
- `listing_id`
- `image_url`
- `sort_order`
- `created_at`

## 6.8 applications

申请表，任务和交换都共用。

建议字段：

- `id`
- `listing_id`
- `applicant_id`
- `message`
- `quoted_price`
- `available_start_time`
- `portfolio_urls`
- `status`
- `handled_at`
- `handled_by`
- `created_at`
- `updated_at`

推荐 `status`：

- `pending`
- `accepted`
- `rejected`
- `withdrawn`
- `expired`

约束建议：

- 同一 `listing_id + applicant_id` 唯一

## 6.9 chats

会话主表。

建议字段：

- `id`
- `chat_type`
- `listing_id`
- `order_id`
- `last_message_id`
- `last_message_at`
- `status`
- `created_at`
- `updated_at`

推荐 `chat_type`：

- `listing_consult`
- `order_chat`
- `system`

推荐 `status`：

- `active`
- `closed`

说明：
围绕任务、交换和订单建立会话，不做纯陌生人自由聊天。

## 6.10 chat_members

会话成员关系。

建议字段：

- `id`
- `chat_id`
- `user_id`
- `role_type`
- `joined_at`

推荐 `role_type`：

- `publisher`
- `applicant`
- `buyer`
- `seller`
- `system`

## 6.11 messages

聊天消息表。

建议字段：

- `id`
- `chat_id`
- `sender_id`
- `message_type`
- `text_content`
- `image_url`
- `payload_json`
- `status`
- `sent_at`
- `created_at`

推荐 `message_type`：

- `text`
- `image`
- `system_card`
- `action_card`

推荐 `status`：

- `sent`
- `recalled`
- `deleted`

说明：
`payload_json` 用于承载快捷操作卡片的数据，例如“创建订单”“接受申请”等。

## 6.12 orders

任务订单与交换确认单统一表。

建议字段：

- `id`
- `listing_id`
- `application_id`
- `buyer_id`
- `seller_id`
- `order_type`
- `amount_total`
- `platform_fee`
- `seller_income`
- `escrow_status`
- `order_status`
- `scheduled_at`
- `delivered_at`
- `completed_at`
- `cancelled_at`
- `closed_reason`
- `created_at`
- `updated_at`

推荐 `order_type`：

- `task_order`
- `exchange_confirmation`

推荐 `escrow_status`：

- `not_required`
- `pending_payment`
- `paid`
- `frozen`
- `released`
- `refunding`
- `refunded`

推荐 `order_status`：

- `pending_payment`
- `pending_accept`
- `in_progress`
- `pending_confirmation`
- `completed`
- `refund_requested`
- `refunded`
- `arbitrating`
- `cancelled`

说明：

- 现金任务使用真实支付
- 交换确认单可设置 `amount_total = 0`
- 即便金额为 0，也应该保留订单/确认单，方便沉淀履约记录和评价

## 6.13 order_events

订单状态流转日志。

建议字段：

- `id`
- `order_id`
- `event_type`
- `operator_user_id`
- `operator_role`
- `event_payload`
- `created_at`

推荐 `event_type`：

- `created`
- `paid`
- `accepted`
- `started`
- `delivered`
- `confirmed`
- `refund_requested`
- `refunded`
- `cancelled`
- `arbitration_started`
- `arbitration_closed`

这张表很重要，它能解决后续客服、仲裁和排查问题。

## 6.14 payments

支付记录表。

建议字段：

- `id`
- `order_id`
- `payer_id`
- `payment_channel`
- `amount`
- `payment_status`
- `third_party_trade_no`
- `paid_at`
- `created_at`
- `updated_at`

推荐 `payment_channel`：

- `wechat_pay`
- `alipay`

推荐 `payment_status`：

- `pending`
- `paid`
- `failed`
- `closed`
- `refunded`

## 6.15 refunds

退款记录表。

建议字段：

- `id`
- `order_id`
- `requester_id`
- `reason_code`
- `description`
- `refund_amount`
- `refund_status`
- `reviewed_by`
- `reviewed_at`
- `created_at`
- `updated_at`

推荐 `refund_status`：

- `pending`
- `approved`
- `rejected`
- `completed`

## 6.16 reviews

订单评价表。

建议字段：

- `id`
- `order_id`
- `from_user_id`
- `to_user_id`
- `score`
- `tags_json`
- `content`
- `images_json`
- `is_anonymous`
- `status`
- `created_at`
- `updated_at`

推荐 `status`：

- `visible`
- `hidden`

约束建议：

- 同一 `order_id + from_user_id` 唯一

## 6.17 reports

举报表。

建议字段：

- `id`
- `reporter_id`
- `target_type`
- `target_id`
- `reason_code`
- `description`
- `evidence_urls`
- `status`
- `review_result`
- `reviewed_by`
- `reviewed_at`
- `created_at`
- `updated_at`

推荐 `target_type`：

- `user`
- `listing`
- `message`
- `order`

推荐 `status`：

- `pending`
- `processing`
- `resolved`
- `rejected`

## 6.18 favorites

收藏表。

建议字段：

- `id`
- `user_id`
- `target_type`
- `target_id`
- `created_at`

推荐 `target_type`：

- `listing`

## 6.19 admin_users

后台管理员表。

建议字段：

- `id`
- `username`
- `password_hash`
- `role`
- `status`
- `last_login_at`
- `created_at`
- `updated_at`

## 6.20 audit_logs

后台审核和运营操作日志。

建议字段：

- `id`
- `operator_id`
- `target_type`
- `target_id`
- `action`
- `detail_json`
- `created_at`

## 7. 关键索引建议

为了支撑 MVP 常见查询，建议优先建立这些索引：

- `users(phone)`
- `listings(publisher_id, status)`
- `listings(listing_type, status, city_code, published_at desc)`
- `listings(audit_status, status)`
- `applications(listing_id, status)`
- `applications(applicant_id, status)`
- `orders(buyer_id, order_status)`
- `orders(seller_id, order_status)`
- `messages(chat_id, created_at)`
- `reports(target_type, target_id)`

如果后续搜索增强，再考虑全文检索或搜索服务。

## 8. 关键状态流转

## 8.1 listing 状态流转

任务/交换发布状态建议：

- `draft`
- `pending_review`
- `published`
- `matched`
- `in_progress`
- `completed`
- `closed`
- `rejected`

推荐流转：

- 草稿 -> 待审核
- 待审核 -> 已发布
- 待审核 -> 已驳回
- 已发布 -> 已匹配
- 已匹配 -> 进行中
- 进行中 -> 已完成
- 已发布 -> 已关闭
- 已匹配 -> 已关闭

约束建议：

- `rejected` 只能由审核动作触发
- `matched` 只在接受申请后触发
- `completed` 只能在关联订单完成后触发

## 8.2 application 状态流转

- `pending`
- `accepted`
- `rejected`
- `withdrawn`
- `expired`

约束建议：

- 一个发布内容只能有一个 `accepted`
- 当某申请被接受，其他 `pending` 申请应批量转 `expired` 或 `rejected`

## 8.3 order 状态流转

- `pending_payment`
- `pending_accept`
- `in_progress`
- `pending_confirmation`
- `completed`
- `refund_requested`
- `refunded`
- `arbitrating`
- `cancelled`

推荐流转：

- 创建订单 -> 待支付
- 支付成功 -> 待接受或直接进行中
- 服务方确认 -> 进行中
- 服务方提交完成 -> 待确认
- 买方确认 -> 已完成
- 发起退款 -> 退款中
- 退款成功 -> 已退款
- 争议升级 -> 仲裁中
- 未支付超时 -> 已取消

说明：
首版为了简化，也可以在支付后直接跳到 `in_progress`，不单独保留 `pending_accept` 的用户可见流程。

## 9. API 设计原则

### 9.1 接口风格

建议使用 REST 风格：

- 基础路径：`/api/v1`
- 鉴权方式：JWT + Refresh Token
- 返回格式：统一 JSON

### 9.2 统一返回结构建议

成功：

```json
{
  "code": 0,
  "message": "ok",
  "data": {}
}
```

失败：

```json
{
  "code": 1001,
  "message": "invalid parameter",
  "data": null
}
```

### 9.3 分页结构建议

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "items": [],
    "page": 1,
    "page_size": 20,
    "total": 120,
    "has_more": true
  }
}
```

## 10. API 草案

## 10.1 Auth

### `POST /api/v1/auth/sms/send`

用途：
发送短信验证码。

请求字段：

- `phone`
- `scene`

### `POST /api/v1/auth/login`

用途：
验证码登录。

请求字段：

- `phone`
- `code`

返回字段：

- `access_token`
- `refresh_token`
- `user`
- `is_profile_completed`

### `POST /api/v1/auth/refresh`

用途：
刷新登录态。

### `POST /api/v1/auth/logout`

用途：
退出登录。

## 10.2 Me / Users

### `GET /api/v1/me`

用途：
获取当前用户信息。

### `PATCH /api/v1/me`

用途：
更新个人资料。

请求字段建议：

- `nickname`
- `avatar_url`
- `city_code`
- `bio`
- `tag_ids`

### `GET /api/v1/users/{id}`

用途：
查看用户公开主页。

返回建议：

- 基础资料
- 信用分
- 认证状态
- 评价概览
- 完成单数

### `POST /api/v1/me/verifications`

用途：
提交认证申请。

## 10.3 Tags / Metadata

### `GET /api/v1/tags`

用途：
获取标签列表。

查询参数建议：

- `tag_type`

### `GET /api/v1/meta/categories`

用途：
获取分类配置。

### `GET /api/v1/meta/cities`

用途：
获取城市配置。

## 10.4 Listings

### `POST /api/v1/listings`

用途：
创建任务或交换。

请求字段：

- `listing_type`
- `title`
- `description`
- `category_code`
- `tag_ids`
- `city_code`
- `service_mode`
- `budget_type`
- `budget_amount`
- `exchange_offer_text`
- `exchange_want_text`
- `location_text`
- `longitude`
- `latitude`
- `start_time`
- `end_time`
- `images`
- `is_urgent`
- `visibility`
- `submit_for_review`

### `GET /api/v1/listings`

用途：
获取首页列表。

查询参数建议：

- `listing_type`
- `city_code`
- `keyword`
- `category_code`
- `tag_id`
- `service_mode`
- `budget_min`
- `budget_max`
- `sort`
- `page`
- `page_size`

### `GET /api/v1/listings/{id}`

用途：
获取详情。

返回建议：

- 发布内容详情
- 发布者信息摘要
- 图片
- 当前用户相关状态
  - 是否已申请
  - 是否已收藏
  - 是否可申请

### `PATCH /api/v1/listings/{id}`

用途：
编辑草稿或可编辑内容。

### `POST /api/v1/listings/{id}/submit-review`

用途：
提交审核。

### `POST /api/v1/listings/{id}/close`

用途：
主动关闭发布。

### `POST /api/v1/listings/{id}/favorite`

用途：
收藏。

### `DELETE /api/v1/listings/{id}/favorite`

用途：
取消收藏。

## 10.5 Applications

### `POST /api/v1/listings/{id}/applications`

用途：
提交申请。

请求字段：

- `message`
- `quoted_price`
- `available_start_time`
- `portfolio_urls`

### `GET /api/v1/me/applications`

用途：
查看我发出的申请。

### `GET /api/v1/listings/{id}/applications`

用途：
查看某条发布收到的申请。

权限：
仅发布者或管理员可访问。

### `GET /api/v1/applications/{id}`

用途：
查看单个申请详情。

### `POST /api/v1/applications/{id}/accept`

用途：
接受申请。

效果：

- 将该申请标记为 `accepted`
- 更新 `listings.accepted_application_id`
- 关闭其他竞争申请
- 可选择触发创建会话或订单草稿

### `POST /api/v1/applications/{id}/reject`

用途：
拒绝申请。

### `POST /api/v1/applications/{id}/withdraw`

用途：
申请人撤回申请。

## 10.6 Chats

### `GET /api/v1/chats`

用途：
获取会话列表。

### `GET /api/v1/chats/{id}/messages`

用途：
获取消息列表。

### `POST /api/v1/chats/{id}/messages`

用途：
发送消息。

请求字段：

- `message_type`
- `text_content`
- `image_url`
- `payload`

### `POST /api/v1/chats/by-listing/{listing_id}`

用途：
按发布内容获取或创建会话。

说明：
可简化客户端首次发消息流程。

## 10.7 Orders

### `POST /api/v1/orders`

用途：
创建订单或交换确认单。

请求字段：

- `listing_id`
- `application_id`
- `scheduled_at`
- `amount_total`
- `remark`

### `GET /api/v1/me/orders`

用途：
获取我的订单列表。

查询参数建议：

- `role`
- `status`
- `page`
- `page_size`

### `GET /api/v1/orders/{id}`

用途：
获取订单详情。

### `POST /api/v1/orders/{id}/pay`

用途：
创建支付单。

请求字段：

- `payment_channel`

### `POST /api/v1/orders/{id}/accept`

用途：
服务方接受订单。

### `POST /api/v1/orders/{id}/deliver`

用途：
服务方提交完成。

请求字段建议：

- `delivery_note`
- `delivery_images`

### `POST /api/v1/orders/{id}/confirm`

用途：
买方确认完成。

### `POST /api/v1/orders/{id}/refund`

用途：
申请退款。

请求字段建议：

- `reason_code`
- `description`

### `POST /api/v1/orders/{id}/cancel`

用途：
取消订单。

## 10.8 Reviews

### `POST /api/v1/orders/{id}/reviews`

用途：
提交评价。

请求字段：

- `score`
- `tags`
- `content`
- `images`
- `is_anonymous`

### `GET /api/v1/orders/{id}/reviews`

用途：
查看订单评价。

## 10.9 Reports

### `POST /api/v1/reports`

用途：
提交举报。

请求字段：

- `target_type`
- `target_id`
- `reason_code`
- `description`
- `evidence_urls`

### `GET /api/v1/me/reports`

用途：
查看我提交的举报记录。

## 10.10 Admin

### `POST /api/v1/admin/login`

用途：
后台登录。

### `GET /api/v1/admin/listings`

用途：
后台查看发布内容。

### `POST /api/v1/admin/listings/{id}/approve`

用途：
审核通过。

### `POST /api/v1/admin/listings/{id}/reject`

用途：
审核驳回。

### `GET /api/v1/admin/reports`

用途：
查看举报列表。

### `POST /api/v1/admin/reports/{id}/resolve`

用途：
处理举报。

### `GET /api/v1/admin/orders`

用途：
查看订单与争议单。

### `POST /api/v1/admin/orders/{id}/arbitrate`

用途：
处理仲裁。

## 11. 接口与数据对象映射建议

为了减少前后端反复对字段解释，建议尽早统一 DTO 命名。

例如：

- `ListingSummaryDto`
- `ListingDetailDto`
- `ApplicationDetailDto`
- `OrderSummaryDto`
- `OrderDetailDto`
- `UserProfileDto`

首页列表不要直接返回所有详情字段，避免后续性能和兼容成本增加。

## 12. 首版权限规则建议

### 普通用户

可以：

- 浏览公开内容
- 创建自己的发布
- 申请他人发布
- 管理自己的资料、申请、订单、举报

不可以：

- 查看别人收到的申请
- 操作不属于自己的订单
- 修改他人的发布

### 管理员

可以：

- 审核内容
- 处理举报
- 处理订单争议
- 封禁和解封用户

## 13. 首版非功能要求建议

### 安全

- 登录态必须有过期机制
- 验证码发送需要限流
- 关键操作要做权限校验
- 图片上传要做类型和大小限制

### 性能

- 首页列表接口响应目标建议小于 500ms
- 会话消息列表必须分页
- 图片走 CDN

### 可观测性

- 关键业务动作要写操作日志
- 订单状态流转必须可追踪
- 后台审核动作必须有审计日志

## 14. 当前建议结论

到这一步，我们已经形成了从产品构想到研发输入的三层文档：

- [01-mvp-launch-plan.md](/Users/dreamyyxt/Projects/Nodoubt/docs/01-mvp-launch-plan.md)
- [02-page-prototype-checklist.md](/Users/dreamyyxt/Projects/Nodoubt/docs/02-page-prototype-checklist.md)
- [03-data-schema-and-api.md](/Users/dreamyyxt/Projects/Nodoubt/docs/03-data-schema-and-api.md)

如果继续往前推进，最合适的下一步有两个：

1. 我直接帮你输出 NestJS 模块拆分和项目目录结构
2. 我直接开始初始化项目代码骨架

如果你想保持稳一点，我建议先做第 1 个。
