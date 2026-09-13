import Foundation

/// 预置目录（§3 MVP catalog，id 与表格逐项一致；不做通用订阅目录）
public enum Catalog {
    public static let customID = "custom"

    public static let items: [CatalogItem] = [
        // 对话
        CatalogItem(id: "chatgpt-plus", name: "ChatGPT Plus", defaultPrice: 20, currency: .usd, cycle: .monthly, purpose: .chat, defaultChannel: .website),
        CatalogItem(id: "chatgpt-pro", name: "ChatGPT Pro", defaultPrice: 200, currency: .usd, cycle: .monthly, purpose: .chat, defaultChannel: .website),
        CatalogItem(id: "claude-pro", name: "Claude Pro", defaultPrice: 20, currency: .usd, cycle: .monthly, purpose: .chat, defaultChannel: .website),
        CatalogItem(id: "claude-max", name: "Claude Max", defaultPrice: 100, currency: .usd, cycle: .monthly, purpose: .chat, defaultChannel: .website),
        CatalogItem(id: "gemini-advanced", name: "Gemini Advanced", defaultPrice: 19.99, currency: .usd, cycle: .monthly, purpose: .chat, defaultChannel: .website),
        CatalogItem(id: "grok", name: "SuperGrok", defaultPrice: 30, currency: .usd, cycle: .monthly, purpose: .chat, defaultChannel: .website),
        CatalogItem(id: "poe", name: "Poe", defaultPrice: 19.99, currency: .usd, cycle: .monthly, purpose: .chat, defaultChannel: .website),
        CatalogItem(id: "kimi-member", name: "Kimi 会员", defaultPrice: 49, currency: .cny, cycle: .monthly, purpose: .chat, defaultChannel: .wechat),
        CatalogItem(id: "tongyi", name: "通义会员", defaultPrice: 49, currency: .cny, cycle: .monthly, purpose: .chat, defaultChannel: .alipay),
        CatalogItem(id: "doubao", name: "豆包会员", defaultPrice: 69, currency: .cny, cycle: .monthly, purpose: .chat, defaultChannel: .wechat),
        CatalogItem(id: "ernie", name: "文心一言会员", defaultPrice: 59.9, currency: .cny, cycle: .monthly, purpose: .chat, defaultChannel: .website),
        CatalogItem(id: "zhipu", name: "智谱清言会员", defaultPrice: 69, currency: .cny, cycle: .monthly, purpose: .chat, defaultChannel: .website),
        // 写代码
        CatalogItem(id: "cursor-pro", name: "Cursor Pro", defaultPrice: 20, currency: .usd, cycle: .monthly, purpose: .coding, defaultChannel: .website),
        CatalogItem(id: "github-copilot", name: "GitHub Copilot", defaultPrice: 10, currency: .usd, cycle: .monthly, purpose: .coding, defaultChannel: .website),
        CatalogItem(id: "windsurf-pro", name: "Windsurf Pro", defaultPrice: 15, currency: .usd, cycle: .monthly, purpose: .coding, defaultChannel: .website),
        CatalogItem(id: "jetbrains-ai", name: "JetBrains AI", defaultPrice: 10, currency: .usd, cycle: .monthly, purpose: .coding, defaultChannel: .website),
        // 出图 / 视频 / 音频 / 效率
        CatalogItem(id: "midjourney", name: "Midjourney", defaultPrice: 10, currency: .usd, cycle: .monthly, purpose: .image, defaultChannel: .website),
        CatalogItem(id: "jimeng", name: "即梦会员", defaultPrice: 69, currency: .cny, cycle: .monthly, purpose: .image, defaultChannel: .alipay),
        CatalogItem(id: "runway", name: "Runway", defaultPrice: 15, currency: .usd, cycle: .monthly, purpose: .other, defaultChannel: .website),
        CatalogItem(id: "kling", name: "可灵会员", defaultPrice: 66, currency: .cny, cycle: .monthly, purpose: .other, defaultChannel: .wechat),
        CatalogItem(id: "suno", name: "Suno", defaultPrice: 10, currency: .usd, cycle: .monthly, purpose: .other, defaultChannel: .website),
        CatalogItem(id: "elevenlabs", name: "ElevenLabs", defaultPrice: 22, currency: .usd, cycle: .monthly, purpose: .other, defaultChannel: .website),
        CatalogItem(id: "notion-ai", name: "Notion AI", defaultPrice: 10, currency: .usd, cycle: .monthly, purpose: .other, defaultChannel: .website),
        // 搜索
        CatalogItem(id: "perplexity-pro", name: "Perplexity Pro", defaultPrice: 20, currency: .usd, cycle: .monthly, purpose: .search, defaultChannel: .website),
        CatalogItem(id: "metaso", name: "秘塔AI搜索", defaultPrice: 49, currency: .cny, cycle: .monthly, purpose: .search, defaultChannel: .alipay),
        // 自定义
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
