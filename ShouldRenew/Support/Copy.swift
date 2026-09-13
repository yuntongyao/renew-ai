import Foundation
import ShouldRenewCore

/// 全部用户可见文案集中于此（需求 8：文案资源抽离，P1 加英文时仅替换本文件）
enum Copy {
    enum App {
        static let name = "续吗"
        static let tagline = "到期前问一句：这笔 AI 会员还该不该续。"
    }

    enum Tab {
        static let today = "今日"
        static let list = "清单"
        static let add = "添加"
        static let report = "月报"
        static let settings = "设置"
    }

    enum Today {
        static let title = "今日"
        static let navTitle = Copy.App.name
        static let monthChargesLabel = "本月已记录"
        static func chargesSummary(_ count: Int) -> String { "\(count) 笔" }
        static func nextChargeDays(_ days: Int) -> String {
            days <= 0 ? "下一笔今天扣" : "下一笔还有 \(days) 天"
        }
        static let suggestionBadge = "该不该续"
        static func suggestionChargeIn(_ days: Int) -> String {
            days <= 0 ? "今天扣款" : "\(days) 天后扣款"
        }
        static let upcomingHeader = "即将到期"
        static func upcomingDays(_ days: Int) -> String {
            days <= 0 ? "今天" : "\(days) 天"
        }
        static let emptyText = "先把正在扣的 AI 会员加进来，到期我们再问你一声。"
        static let emptyButton = "添加第一个"
    }

    enum List {
        static let title = "清单"
        static let filterAll = "全部"
        static let filterSoon = "即将到期"
        static let filterTrial = "试用中"
        static let filterCancelPending = "已取消待到期"
        static let empty = "还没有订阅，从模板添加一个 AI 会员。"
        static func chargeIn(_ days: Int) -> String {
            days <= 0 ? "今天扣" : "\(days)天后扣"
        }
        static let usageNone = "没用过"
        static func usageTimes(_ count: Int) -> String { "本月\(count)次" }
    }

    enum Add {
        static let title = "添加订阅"
        static let editTitle = "编辑订阅"
        static let sectionTemplate = "模板"
        static let custom = "自定义"
        static let sectionDetails = "详情"
        static let name = "名称"
        static let amount = "金额"
        static let currency = "币种"
        static let cycle = "周期"
        static let nextCharge = "下次扣款日"
        static let channel = "扣款渠道"
        static let purpose = "用途标签"
        static let purposeOptional = "用途标签（选填）"
        static let notes = "备注（选填）"
        static let close = "取消"
        static let save = "保存"
        static let pricePlaceholderHint = "模板价格为占位，请以实际扣款为准。"
    }

    enum Paywall {
        static let title = "免费版最多 3 条"
        static let message = "先记最贵的几个 AI 会员就够了。Pro 可添加无限条（内购暂未接入，本期仅提示）。"
        static let ok = "知道了"
    }

    enum Common {
        static let done = "完成"
    }

    enum Decision {
        static let title = "决策"
        static func headline(_ name: String) -> String { "「\(name)」续吗？" }
        static let amount = "金额"
        static let nextCharge = "下次扣款"
        static let channel = "扣款渠道"
        static let usage = "本月用过几次（选填）"
        static let usageSkip = "暂不记"
        static let usageNone = "没用过"
        static let usageCustomLabel = "或手动填入"
        static let usageCustomPlaceholder = "次数"
        static let usageUnit = "次"
        static let renew = "续"
        static let cancelFirst = "先取消"
        static let snooze = "再想 1 天"
        static let renewedToast = "已选择续，本周期不再提醒。"
        static let snoozedToast = "已推迟 1 天，明天再问你。"
        static let edit = "编辑"
    }

    enum Guide {
        static let title = "取消步骤"
        static func header(_ channel: String, _ name: String) -> String { "通过\(channel)取消「\(name)」" }
        static let openHelp = "打开官方帮助页"
        static let markCancelled = "我已取消"
        static let footer = "本应用不会代你操作账号。标记后本周期不再提醒，状态变为「周期结束后停止」。"
        static let offlineHint = "链接打不开也能照文字步骤完成，指南可离线阅读。"
    }

    enum Report {
        static let title = "月报"
        static func chargesLine(_ count: Int) -> String { "本月将扣 \(count) 笔" }
        static let monthlyEquivalent = "折合每月"
        static let reviewTitle = "建议复查"
        static func reviewLine(_ count: Int, _ savings: String) -> String { "\(count) 项 · 约 \(savings)/月" }
        static let lowUsageTag = "低使用"
        static let empty = "本月暂无可回顾的订阅。"
        static let noReview = "暂无低使用条目。在决策页标记「本月用过几次」后会出现在这里。"
        static let savePoster = "保存 9:16 海报"
        static let sharePoster = "分享海报"
        static let posterSaved = "已保存到相册"
        static let posterSaveFailed = "保存失败，请检查相册权限"
        static let posterDenied = "未获得相册权限，请到系统设置中开启"
        static let rendering = "海报生成中…"
    }

    enum Settings {
        static let title = "设置"
        static let sectionNotification = "通知"
        static let permission = "通知权限"
        static let permissionOn = "已开启"
        static let permissionOff = "未开启"
        static let requestPermission = "开启通知权限"
        static let reminderDaysHeader = "到期前提醒"
        static let reminderDaysFooter = "到期前 7 / 3 / 1 天上午 9:30 提醒一次；同一订阅同一天只推一条。全部关闭后请在今日页查看倒计时。"
        static func reminderDay(_ days: Int) -> String { "\(days)天前" }
        static let scheduledCount = "已排程提醒"
        static func scheduled(_ count: Int) -> String { "\(count) 条" }
        static let reschedule = "重新排程"
        static let sectionPreference = "偏好"
        static let mainCurrency = "合计主币种"
        static let mainCurrencyFooter = "多币种列表按原币展示，合计按固定汇率粗算。"
        static let sectionData = "数据"
        static let localItems = "本地订阅"
        static let dataNote = "订阅数据仅保存在本机（Documents/subscriptions.json），无账号、无后端、无广告。"
        static let sectionAbout = "关于"
        static let about = "免费版可用 3 条订阅；Pro（未接入）解锁无限条与自定义提醒。"
        static let disclaimer = "本应用只提供取消步骤信息，不代你取消，也不保证各平台页面长期不变。"
    }

    enum Notification {
        static let title = ReminderPlanner.notificationTitle
    }
}

/// 展示格式化助手
enum Format {
    /// 本月合计：全同币种精确显示，混币种按固定汇率折算主币种并加 ≈
    static func monthTotal(_ items: [Subscription], main: CurrencyCode) -> String {
        if items.isEmpty { return "\(main.symbol)0" }
        let currencies = Set(items.map(\.currency))
        if currencies.count == 1, let only = currencies.first {
            let sum = items.reduce(Decimal.zero) { $0 + $1.amount }
            return "\(only.symbol)\(NSDecimalNumber(decimal: sum).stringValue)"
        }
        let converted = items.reduce(Decimal.zero) {
            $0 + ExchangeRates.convert($1.amount, from: $1.currency, to: main)
        }
        return ExchangeRates.approxText(converted, from: main, to: main)
    }
}
