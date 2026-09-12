import Foundation

// MARK: - 枚举（对应需求 7.1 订阅对象字段）

public enum BillingCycle: String, Codable, CaseIterable, Identifiable, Sendable {
    case monthly, yearly, quarterly, trial
    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .monthly: return "月付"
        case .yearly: return "年付"
        case .quarterly: return "季付"
        case .trial: return "试用"
        }
    }

    /// 默认下次扣款日距今天数（模板草稿用）
    public var defaultDaysOut: Int {
        switch self {
        case .monthly: return 30
        case .quarterly: return 90
        case .yearly: return 365
        case .trial: return 7
        }
    }

    /// 折算为每月的倍率（月报粗算用）
    public var monthsPerCharge: Decimal {
        switch self {
        case .monthly: return 1
        case .quarterly: return 3
        case .yearly: return 12
        case .trial: return 0
        }
    }
}

public enum PayChannel: String, Codable, CaseIterable, Identifiable, Sendable {
    case official, apple, google, wechat, alipay, other
    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .official: return "官网"
        case .apple: return "App Store"
        case .google: return "Google Play"
        case .wechat: return "微信"
        case .alipay: return "支付宝"
        case .other: return "其他"
        }
    }
}

public enum PurposeTag: String, Codable, CaseIterable, Identifiable, Sendable {
    case writing, coding, image, video, search, other
    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .writing: return "写作"
        case .coding: return "编程"
        case .image: return "生图"
        case .video: return "视频"
        case .search: return "搜索"
        case .other: return "其他"
        }
    }
}

public enum SubStatus: String, Codable, CaseIterable, Sendable {
    case active
    case cancelPending
    case ended

    public var title: String {
        switch self {
        case .active: return "生效中"
        case .cancelPending: return "周期结束后停止"
        case .ended: return "已结束"
        }
    }
}

public enum CurrencyCode: String, Codable, CaseIterable, Identifiable, Sendable {
    case CNY, USD, SGD
    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .CNY: return "¥"
        case .USD: return "$"
        case .SGD: return "S$"
        }
    }
}

// MARK: - 订阅

public struct Subscription: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var templateKey: String?
    public var emoji: String
    public var amount: Decimal
    public var currency: CurrencyCode
    public var cycle: BillingCycle
    public var nextChargeOn: Date
    public var channel: PayChannel
    public var purpose: PurposeTag?
    public var usageMark: Int?
    public var status: SubStatus
    public var notes: String
    public var createdAt: Date
    /// 本周期已选择「续」时的下次扣款日；与本字段一致的周期不再提醒
    public var renewedForChargeOn: Date?
    /// 本周期已「再想 1 天」时的下次扣款日；标准提醒让位给 snooze
    public var snoozedForChargeOn: Date?
    /// 点「再想 1 天」的时刻；重排时按它恢复同一条次日提醒，不会顺延
    public var snoozeRequestedAt: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        templateKey: String? = nil,
        emoji: String = "🤖",
        amount: Decimal,
        currency: CurrencyCode = .CNY,
        cycle: BillingCycle = .monthly,
        nextChargeOn: Date? = nil,
        channel: PayChannel = .official,
        purpose: PurposeTag? = nil,
        usageMark: Int? = nil,
        status: SubStatus = .active,
        notes: String = "",
        createdAt: Date = Date(),
        renewedForChargeOn: Date? = nil,
        snoozedForChargeOn: Date? = nil,
        snoozeRequestedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.templateKey = templateKey
        self.emoji = emoji
        self.amount = amount
        self.currency = currency
        self.cycle = cycle
        self.nextChargeOn = nextChargeOn
            ?? Calendar.current.date(byAdding: .day, value: cycle.defaultDaysOut, to: Date())
            ?? Date()
        self.channel = channel
        self.purpose = purpose
        self.usageMark = usageMark
        self.status = status
        self.notes = notes
        self.createdAt = createdAt
        self.renewedForChargeOn = renewedForChargeOn
        self.snoozedForChargeOn = snoozedForChargeOn
        self.snoozeRequestedAt = snoozeRequestedAt
    }

    /// 兼容旧版本本地数据：缺失字段按默认值补齐，不丢用户已录入的订阅
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        templateKey = try container.decodeIfPresent(String.self, forKey: .templateKey)
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji) ?? "🤖"
        amount = try container.decode(Decimal.self, forKey: .amount)
        currency = try container.decodeIfPresent(CurrencyCode.self, forKey: .currency) ?? .CNY
        cycle = try container.decodeIfPresent(BillingCycle.self, forKey: .cycle) ?? .monthly
        nextChargeOn = try container.decode(Date.self, forKey: .nextChargeOn)
        channel = try container.decodeIfPresent(PayChannel.self, forKey: .channel) ?? .official
        purpose = try container.decodeIfPresent(PurposeTag.self, forKey: .purpose)
        usageMark = try container.decodeIfPresent(Int.self, forKey: .usageMark)
        status = try container.decodeIfPresent(SubStatus.self, forKey: .status) ?? .active
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        renewedForChargeOn = try container.decodeIfPresent(Date.self, forKey: .renewedForChargeOn)
        snoozedForChargeOn = try container.decodeIfPresent(Date.self, forKey: .snoozedForChargeOn)
        snoozeRequestedAt = try container.decodeIfPresent(Date.self, forKey: .snoozeRequestedAt)
    }

    public var daysUntilCharge: Int {        Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: nextChargeOn)
        ).day ?? 0
    }

    public var amountText: String {
        "\(currency.symbol)\(NSDecimalNumber(decimal: amount).stringValue)"
    }

    /// 是否已在本周期点了「续」
    public func renewedThisCycle(calendar: Calendar = .current) -> Bool {
        guard let renewed = renewedForChargeOn else { return false }
        return calendar.isDate(renewed, inSameDayAs: nextChargeOn)
    }

    /// 是否已在本周期点了「再想 1 天」
    public func snoozedThisCycle(calendar: Calendar = .current) -> Bool {
        guard let snoozed = snoozedForChargeOn else { return false }
        return calendar.isDate(snoozed, inSameDayAs: nextChargeOn)
    }

    /// 折算为每月金额（原币）
    public var monthlyEquivalent: Decimal {
        let months = cycle.monthsPerCharge
        guard months > 0 else { return 0 }
        return amount / months
    }
}

// MARK: - 预置目录模板（需求 7.2）

public struct ProductTemplate: Identifiable, Codable, Equatable, Sendable {
    public var id: String { key }
    public var key: String
    public var name: String
    public var emoji: String
    public var defaultAmount: Decimal
    public var currency: CurrencyCode
    public var cycle: BillingCycle
    public var channel: PayChannel
    public var purpose: PurposeTag
    public var guideURL: String?

    public init(
        key: String,
        name: String,
        emoji: String,
        defaultAmount: Decimal,
        currency: CurrencyCode,
        cycle: BillingCycle,
        channel: PayChannel,
        purpose: PurposeTag,
        guideURL: String? = nil
    ) {
        self.key = key
        self.name = name
        self.emoji = emoji
        self.defaultAmount = defaultAmount
        self.currency = currency
        self.cycle = cycle
        self.channel = channel
        self.purpose = purpose
        self.guideURL = guideURL
    }
}
