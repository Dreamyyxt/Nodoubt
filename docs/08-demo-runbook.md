# No Doubt Demo Runbook

## 1. Start Services

```bash
cd /Users/dreamyyxt/Projects/Nodoubt
pnpm --filter @nodoubt/app-server start
```

```bash
cd /Users/dreamyyxt/Projects/Nodoubt
pnpm dev:mobile:web
```

Optional admin shell:

```bash
cd /Users/dreamyyxt/Projects/Nodoubt
pnpm dev:admin
```

## 2. Demo Accounts

- 默认用户: `13800000000`
- 发布者: `13900000001`
- 交换体验官: `13900000002`
- 验证码: `123456`

## 3. Recommended Demo Path

### Path A: 任务成交闭环

1. 用“默认用户”登录
2. 在首页选择一条 demo 任务
3. 提交申请
4. 退出登录，切到“发布者”
5. 进入对应发布详情
6. 打开“收到的申请”
7. 接受申请并创建订单
8. 切回“默认用户”
9. 在“订单”页执行“开发支付”
10. 切回“发布者”
11. 在“订单”页执行“接单”与“标记交付”
12. 切回“默认用户”
13. 在“订单”页执行“确认完成”

### Path B: 技能交换闭环

1. 用“交换体验官”或“默认用户”登录
2. 进入 demo 交换发布
3. 发起交换申请
4. 切到“发布者”
5. 接受申请
6. 创建金额为 `0` 或补差金额的订单
7. 按订单流转完成整条链路

## 4. What To Show During Demo

- 首页能区分任务与交换
- 我的发布能看到收到的申请数量
- 我的申请能看到我申请过什么
- 订单页能按买方/服务方/进行中/已完成筛选
- 订单详情能展示当前阶段和流转记录
- 后台壳子能说明后续审核、举报、订单观察入口

## 5. Known Positioning

- 这是 MVP 演示链路，不是正式生产版本
- 资金流目前是“开发支付”模拟动作
- 后台当前是静态壳子，主要用于展示信息架构和后续方向
