import Foundation
import ShouldRenewCore

/// 全部用户可见文案（文案库 §10 + 各屏所需），集中于此便于 P1 加英文
enum Copy {
    enum App {
        static let name = "续吗"
        static let about = "续吗帮你在一笔 AI 订阅下次扣款前做决定：续，还是先取消。要取消就跟着渠道步骤走一遍，回来点「我已取消」。数据只存在这台手机上。"
    }

    enum Tab {
        static let today = "今日"
        static let list = "清单"
        static let settings = "设置"
    }

    enum Today {
        static let navTitle = App.name
        static let empty = "最近没有要决定的"
        static let ctaAdd = "添加 AI 会员"
        static let eyebrow = "该不该续"
        static let upcomingHeader = "即将到期"
        static let renewedToast = "已标记续费"
        static let snoozedToast = "已推迟 1 天，明天再问。"
        static let undo = "撤销"
        static let reactivate = "改主意了？改回生效中"

        static func chargeIn(_ days: Int) -> String {
            days <= 0 ? "今天扣款" : "\(days) 天后扣款"
        }

        static func daysLeft(_ days: Int) -> String {
            days <= 0 ? "今天" : "\(days) 天"
        }

        static func overlap(_ a: String, _ b: String, _ purpose: Purpose) -> String {
            "\(a) 和 \(b) 都偏\(purpose.label)，要不要只留一个？"
        }
    }

    enum Decision {
        static let renew = "续"
        static let cancel = "先取消"
        static let snooze = "再想 1 天"
        static let detailTitle = "决策"
        static func guideTitle(_ name: String) -> String { "取消 \(name)" }
    }

    enum Guide {
        static let done = "我已取消"
        static let keep = "还是续"
        static let footer = "本应用不会代你操作账号；指南可离线照做。"
    }

    enum Paywall {
        static let title = "免费可记 3 个 AI 会员"
        static let message = "免费额度已用完。解锁后可添加更多 AI 会员，并支持自定义提醒。"
        static let unlock = "解锁 Pro"
        static let unlockNote = "内购尚未接入，本期仅作提示。"
        static let close = "知道了"
    }

    enum Add {
        static let title = "添加订阅"
        static let editTitle = "编辑订阅"
        static let pickCatalog = "选择 AI 会员"
        static let custom = "自定义"
        static let name = "名称"
        static let price = "价格"
        static let currency = "币种"
        static let cycle = "周期"
        static let nextCharge = "下次扣款日"
        static let channel = "扣款渠道"
        static let purpose = "用途"
        static let save = "保存"
        static let close = "取消"
        static let errorName = "请填写名称"
        static let errorPrice = "价格需大于 0"
        static let pricePlaceholderHint = "模板价格为占位，请以实际扣款为准。"
    }

    enum List {
        static let title = "清单"
        static let sectionActive = "生效中"
        static let sectionDecidedRenew = "已标记续费"
        static let sectionCanceled = "已取消"
        static let empty = "还没有订阅，添加一个 AI 会员。"
        static let swipeCancel = "取消订阅"
        static let swipeReactivate = "改回生效中"
        static let swipeDelete = "删除"
        static let cancelToast = "已取消订阅"
    }

    enum Settings {
        static let title = "设置"
        static let sectionNotification = "通知"
        static let notificationToggle = "到期前提醒（7/3/1 天 09:30）"
        static let notificationFooter = "同一订阅同一天只推一条；可在系统设置中关闭通知权限。"
        static let sectionPreference = "偏好"
        static let defaultCurrency = "新订阅默认币种"
        static let currencyFooter = "金额按你输入时原样保存；此开关只影响新自定义订阅的默认币种。"
        static let sectionUnlock = "解锁"
        static let unlockRow = "免费可记 3 个 AI 会员"
        static let sectionAbout = "关于"
    }
}
