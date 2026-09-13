# 续吗 (ShouldRenew)

> 在下次扣款前，决定续不续；要取消就跟着渠道步骤走完。

依据 `xuma-prd-for-ai.md`（v1.1，实现型 PRD，替代原 renewornot-requirement.docx）实现。local-first，无网络、无账号。

## 功能范围（只做决策闭环）

- **添加**：10 个 AI 会员目录（含自定义），名称/价格/币种（usd|cny）/周期（月|年）/渠道（apple|wechat|alipay|website）/下次扣款日/用途；免费上限 3 条（不计已取消），超限弹禁用付费面板（不做 StoreKit）
- **今日**：决策卡只给 14 天内最近一笔（该不该续 / 价格行 / N 天后扣款 / 续 · 先取消）；无卡显示空态「最近没有要决定的」；「即将到期」最多 3 条；同用途重叠提示「{A} 和 {B} 都偏{X}，要不要只留一个？」
- **动作**：续 → decidedRenew（扣款日过后自动滚动周期转回 active）；先取消 → 渠道指南（apple/wechat/alipay/website 各 4 步逐字文案）→「我已取消」或「还是续」；再想 1 天 → snoozed，次日转回
- **清单**：生效中 → 已标记续费 → 已取消（默认折叠）；点按编辑，滑动取消/删除
- **提醒**：nextChargeAt 前 7/3/1 天 09:30，文案 `{name} {n} 天后扣 {price}，续吗？`，标识符 `renew.{id}.{offset}`，点击进 Today（deep link `shouldrenew://today`）；启动与任意变更后全量重排
- **设置**：通知开关（开启时请求权限）、新订阅默认币种、解锁占位、关于

明确不做（PRD §0/§11）：月报 Tab、饼图/支出分类/年度预测、金额 Hero、多币种换算、银行/邮件同步、通用订阅目录、用量 API。

## 结构

```
ShouldRenew.xcodeproj          iOS 17+ SwiftUI（com.shouldrenew.app，显示名 续吗）
ShouldRenew/
  Assets.xcassets              定稿图标（teal 底「续吗」ivory 字）
  Support/Copy.swift           文案库（§10 + 各屏）
  Support/Theme.swift          视觉令牌：teal/ivory/page/soft/ink + capsule 主次按钮
  Support/AppSettings.swift    通知开关、新订阅默认币种
  Services/                    通知调度（deep link）、UNUserNotificationCenterDelegate
  Views/                       今日（决策卡/空态/即将到期/重叠提示）、决策卡+详情、
                               取消指南、清单（三分区）、添加（目录+表单）、设置
ShouldRenewCore/               SwiftPM 包（纯逻辑，swift test 可跑）
  Models.swift                 §3 数据模型（Subscription/CatalogItem + 枚举）
  Catalog.swift                10 项目录（id 与 PRD 表格逐项一致）
  CancelGuide.swift            四渠道四步指南（§5.3 逐字文案）
  ReminderPlanner.swift        §6 提醒规划（跳过已过期时点）
  SubscriptionStore.swift      JSON 持久化 + 旧版数据迁移 + 上限/重叠/周期滚动
  Tests/                       14 个单测（含验收 A2/A3/A5/A6 对应逻辑）
ShouldRenewUITests/            UI 回归：A1 添加、A7 三 Tab 无月报
design/xuma-assets/            定稿切图与今日页设计稿
```

## 开发

```bash
cd ShouldRenewCore && swift test          # 核心逻辑
xcodebuild -project ShouldRenew.xcodeproj -scheme ShouldRenew \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild test -project ShouldRenew.xcodeproj -scheme ShouldRenew \
  -destination 'platform=iOS Simulator,name=iPhone 17'   # UI 回归
```

数据仅存本机 `Documents/subscriptions.json`；旧版（v0.1）数据自动迁移（币种/周期/渠道/用途/状态逐项映射，用量与汇率字段按新需求丢弃）。
