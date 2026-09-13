import Foundation

public struct GuideStep: Identifiable, Equatable, Sendable {
    public var id: Int { index }
    public let index: Int
    public let title: String
    public let body: String

    public init(index: Int, title: String, body: String = "") {
        self.index = index
        self.title = title
        self.body = body
    }
}

/// 取消指南（§5.3，步骤文案逐字采用；只提供步骤，不代取消）
public enum CancelGuide {
    public static func steps(channel: Channel) -> [GuideStep] {
        switch channel {
        case .apple:
            return [
                GuideStep(index: 1, title: "打开设置 → Apple ID → 订阅"),
                GuideStep(index: 2, title: "找到对应项目"),
                GuideStep(index: 3, title: "点取消订阅，确认不再续期"),
                GuideStep(index: 4, title: "回到续吗，点「我已取消」"),
            ]
        case .wechat:
            return [
                GuideStep(index: 1, title: "微信 → 我 → 服务 → 钱包 → 支付设置 → 自动续费"),
                GuideStep(index: 2, title: "找到对应商户 / 会员"),
                GuideStep(index: 3, title: "关闭自动续费"),
                GuideStep(index: 4, title: "回到续吗，点「我已取消」"),
            ]
        case .alipay:
            return [
                GuideStep(index: 1, title: "支付宝 → 我的 → 设置 → 支付设置 → 免密支付 / 自动续费"),
                GuideStep(index: 2, title: "找到对应商户"),
                GuideStep(index: 3, title: "关闭协议"),
                GuideStep(index: 4, title: "回到续吗，点「我已取消」"),
            ]
        case .website:
            return [
                GuideStep(index: 1, title: "登录该产品官网账号与账单页"),
                GuideStep(index: 2, title: "关闭 Auto-renew / Cancel plan"),
                GuideStep(index: 3, title: "保存确认邮件或截图"),
                GuideStep(index: 4, title: "回到续吗，点「我已取消」"),
            ]
        }
    }
}
