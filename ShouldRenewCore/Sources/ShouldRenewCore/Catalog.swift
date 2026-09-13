import Foundation

/// 预置目录（§3 MVP catalog，id 与表格逐项一致；不做通用订阅目录）
public enum Catalog {
    public static let customID = "custom"

    public static let items: [CatalogItem] = [
        CatalogItem(id: "chatgpt-plus", name: "ChatGPT Plus", defaultPrice: 20, currency: .usd, cycle: .monthly, purpose: .chat, defaultChannel: .website),
        CatalogItem(id: "claude-pro", name: "Claude Pro", defaultPrice: 20, currency: .usd, cycle: .monthly, purpose: .chat, defaultChannel: .website),
        CatalogItem(id: "cursor-pro", name: "Cursor Pro", defaultPrice: 20, currency: .usd, cycle: .monthly, purpose: .coding, defaultChannel: .website),
        CatalogItem(id: "gemini-advanced", name: "Gemini Advanced", defaultPrice: 19.99, currency: .usd, cycle: .monthly, purpose: .chat, defaultChannel: .website),
        CatalogItem(id: "github-copilot", name: "GitHub Copilot", defaultPrice: 10, currency: .usd, cycle: .monthly, purpose: .coding, defaultChannel: .website),
        CatalogItem(id: "midjourney", name: "Midjourney", defaultPrice: 10, currency: .usd, cycle: .monthly, purpose: .image, defaultChannel: .website),
        CatalogItem(id: "perplexity-pro", name: "Perplexity Pro", defaultPrice: 20, currency: .usd, cycle: .monthly, purpose: .search, defaultChannel: .website),
        CatalogItem(id: "kimi-member", name: "Kimi 会员", defaultPrice: 49, currency: .cny, cycle: .monthly, purpose: .chat, defaultChannel: .wechat),
        CatalogItem(id: "tongyi", name: "通义会员", defaultPrice: 49, currency: .cny, cycle: .monthly, purpose: .chat, defaultChannel: .alipay),
        CatalogItem(id: "custom", name: "自定义", defaultPrice: 0, currency: .usd, cycle: .monthly, purpose: .other, defaultChannel: .website),
    ]

    public static func item(id: String) -> CatalogItem? {
        items.first { $0.id == id }
    }

    /// 由目录项生成订阅草稿；自定义项名称留空待填
    public static func makeDraft(
        _ item: CatalogItem,
        nextChargeAt: Date? = nil,
        calendar: Calendar = .current
    ) -> Subscription {
        let chargeAt = nextChargeAt
            ?? calendar.date(byAdding: .day, value: item.cycle == .monthly ? 30 : 365, to: Date())
            ?? Date()
        return Subscription(
            catalogId: item.id,
            name: item.id == customID ? "" : item.name,
            price: item.defaultPrice,
            currency: item.currency,
            cycle: item.cycle,
            channel: item.defaultChannel,
            purpose: item.purpose,
            nextChargeAt: chargeAt
        )
    }
}
