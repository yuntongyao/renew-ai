import Foundation

// MARK: - 枚举（xuma-prd-for-ai.md §3，字段与取值逐项对应）

public enum Currency: String, Codable, CaseIterable, Identifiable, Sendable {
    case usd, cny
    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .usd: return "$"
        case .cny: return "¥"
        }
    }
}

public enum Cycle: String, Codable, CaseIterable, Identifiable, Sendable {
    case monthly, yearly
    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .monthly: return "月付"
        case .yearly: return "年付"
        }
    }

    /// 扣款日向前滚动一个周期
    public func advance(_ date: Date, calendar: Calendar = .current) -> Date {
        switch self {
        case .monthly: return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly: return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
}

public enum Channel: String, Codable, CaseIterable, Identifiable, Sendable {
    case apple, wechat, alipay, website
    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .apple: return "App Store"
        case .wechat: return "微信"
        case .alipay: return "支付宝"
        case .website: return "官网"
        }
    }
}

public enum Purpose: String, Codable, CaseIterable, Identifiable, Sendable {
    case coding, chat, image, search, other
    public var id: String { rawValue }

    /// 文案库 §10
    public var label: String {
        switch self {
        case .coding: return "写代码"
        case .chat: return "对话"
        case .image: return "出图"
        case .search: return "搜索"
        case .other: return "其他"
        }
    }
}

public enum Status: String, Codable, Sendable {
    case active
    case decidedRenew
    case canceled
    case snoozed
}

// MARK: - 订阅

public struct Subscription: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var catalogId: String
    public var name: String
    public var price: Decimal
    public var currency: Currency
    public var cycle: Cycle
    public var channel: Channel
    public var purpose: Purpose
    public var nextChargeAt: Date
    public var status: Status
    public var snoozeUntil: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        catalogId: String,
        name: String,
        price: Decimal,
        currency: Currency,
        cycle: Cycle,
        channel: Channel,
        purpose: Purpose,
        nextChargeAt: Date,
        status: Status = .active,
        snoozeUntil: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.catalogId = catalogId
        self.name = name
        self.price = price
        self.currency = currency
        self.cycle = cycle
        self.channel = channel
        self.purpose = purpose
        self.nextChargeAt = nextChargeAt
        self.status = status
        self.snoozeUntil = snoozeUntil
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var priceText: String {
        "\(currency.symbol)\(NSDecimalNumber(decimal: price).stringValue)"
    }

    /// 距下次扣款的天数（按自然日）
    public func daysUntilCharge(now: Date = Date(), calendar: Calendar = .current) -> Int {
        calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: nextChargeAt)
        ).day ?? 0
    }
}

// MARK: - 目录项

public struct CatalogItem: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var defaultPrice: Decimal
    public var currency: Currency
    public var cycle: Cycle
    public var purpose: Purpose
    public var defaultChannel: Channel

    public init(
        id: String,
        name: String,
        defaultPrice: Decimal,
        currency: Currency,
        cycle: Cycle,
        purpose: Purpose,
        defaultChannel: Channel
    ) {
        self.id = id
        self.name = name
        self.defaultPrice = defaultPrice
        self.currency = currency
        self.cycle = cycle
        self.purpose = purpose
        self.defaultChannel = defaultChannel
    }
}
