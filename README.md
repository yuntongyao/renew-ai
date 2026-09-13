# 该不该续 (ShouldRenew)

到期前问一句：这笔 AI 会员还该不该续。依据 `renewornot-requirement.docx`（MVP v0.1）实现的 iOS 轻量 App。

## 功能（对应需求 P0）

- **订阅录入**：预置 24 个 AI 产品模板（本地 JSON，可热更新），自定义添加；名称 / 金额 / 币种（CNY/USD/SGD，默认 CNY）/ 周期（月/季/年/试用）/ 下次扣款日 / 扣款渠道（官网、App Store、Google Play、微信、支付宝、其他）/ 用途标签
- **今日**：本月将扣合计（混币种按固定汇率粗算主币种）、距下一笔扣款天数、最近到期的一条主建议
- **清单**：按扣款日排序的卡片（图标 / 价格周期 / 倒计时 / 渠道小标），筛选「全部 / 即将到期 / 试用中 / 已取消待到期」
- **本地提醒**：到期前 7/3/1 天 9:30（可在设置中增减）；错过上午档且未扣款时当天补推一次；同一订阅同一天只推一条；文案为问句（`Claude Pro 后天扣 ¥144。这个月你还用吗？`）
- **决策页**：该不该续「X」？主按钮「续」（关闭本轮提醒）/「先取消」（打开指南），次按钮「再想 1 天」（snooze，次日再问）；选填「本月用过几次 0–5」
- **取消指南**：按渠道 4 步（官网 / Apple / Google Play / 微信扣费服务 / 支付宝免密），可离线阅读，附官方帮助页链接；「我已取消」→ 状态变为「周期结束后停止」，过扣款日自动转「已结束」
- **月报**：本月笔数、金额、低使用条目、建议复查金额；导出 9:16 海报（保存相册 / 分享）
- **免费档**：最多 3 条订阅，第 4 条提示 Pro（内购未接入，仅提示）

明确不做（需求 5.3）：银行/邮箱连接、账号密码或 API Key、代登录代取消、团队分摊、广告。

## 结构

```
ShouldRenew.xcodeproj          iOS 17+ SwiftUI App（com.shouldrenew.app）
ShouldRenew/                   App 壳
  Assets.xcassets              App 图标（1024×1024，暖棕底「续」+ 问号徽标）
  Support/Copy.swift           全部中文文案集中于此（P1 加英文仅改此文件）
  Support/AppSettings.swift    提醒天数、合计主币种（UserDefaults）
  Support/PosterView.swift     9:16 月报海报视图 + ImageRenderer + 相册保存
  Services/NotificationScheduler.swift  本地通知调度（补推去重、snooze）
  Services/AppDelegate.swift   通知点击 → 决策页路由
  Views/                       今日 / 清单 / 添加 / 决策 / 取消指南 / 月报 / 设置
ShouldRenewCore/               SwiftPM 包（纯逻辑，可独立测试）
  Sources/ShouldRenewCore/
    Models.swift               Subscription 与枚举（7.1 字段）
    CatalogStore.swift         预置目录（Resources/catalog.json，24 条）
    CancelGuide.swift          取消指南（Resources/guides.json）
    ReminderPlanner.swift      提醒规划（7/3/1、续后静默、snooze、补推、去重键）
    SubscriptionStore.swift    本地仓库（Documents/subscriptions.json）
    ExchangeRates.swift        固定汇率粗算（1 USD ≈ 7.2 CNY，1 SGD ≈ 5.3 CNY）
    MonthReport.swift          月报数据（笔数 / 金额 / 低使用 / 建议复查）
  Tests/ShouldRenewCoreTests/  23 个 XCTest（核心逻辑）
ShouldRenewUITests/            XCUITest：添加模板 → 清单点入决策 → 返回仍在
```

## 开发

```bash
# 核心逻辑测试（无需模拟器）
cd ShouldRenewCore && swift test

# App 构建
xcodebuild -project ShouldRenew.xcodeproj -scheme ShouldRenew \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# 关键路径 UI 回归
xcodebuild test -project ShouldRenew.xcodeproj -scheme ShouldRenew \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

用 Xcode 打开 `ShouldRenew.xcodeproj`，Cmd+R 运行（真机验证通知需在系统设置中允许通知）。

数据仅存本机 `Documents/subscriptions.json`；旧版本数据（无 emoji/决策字段）可正常解码。UI 测试用 `--uitest-fresh` 启动参数走独立空库，不弹通知权限框。

## 未接入（里程碑 M2/M3）

- StoreKit 内购（Pro 无限条 / 自定义提醒）——免费 3 条已可用
- 截图 OCR、iCloud / JSON 导出、英文界面（P1）
- App 图标与上架素材
