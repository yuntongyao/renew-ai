import Foundation
import Combine

/// 本地仓库（§3）：Documents/subscriptions.json，Codable，ObservableObject。
/// 旧版（v0.1 PRD）数据在加载时做一次字段迁移，不丢用户已录入内容。
@MainActor
public final class SubscriptionStore: ObservableObject {
    @Published public private(set) var items: [Subscription] = []

    /// 免费上限：统计 status != canceled 的条目
    public static let freeLimit = 10

    private let fileURL: URL
    private let calendar: Calendar

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    public init(filename: String = "subscriptions.json", directory: URL? = nil, calendar: Calendar = .current) {
        self.calendar = calendar
        let dir = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = dir.appendingPathComponent(filename)
        load()
    }

    // MARK: - 查询

    /// 生效中的订阅，按 nextChargeAt 升序
    public func activeItems() -> [Subscription] {
        items
            .filter { $0.status == .active }
            .sorted { $0.nextChargeAt < $1.nextChargeAt }
    }

    /// Today 决策卡候选：active 且 0...14 天内最早扣款（snooze 到期后先被 refresh 转回 active）
    public func upcomingDecision(now: Date = Date()) -> Subscription? {
        activeItems().first { (0...14).contains($0.daysUntilCharge(now: now, calendar: calendar)) }
    }

    /// 「即将到期」：决策卡之外的 active 条目，最多 3 条
    public func upcoming(excluding id: UUID?, limit: Int = 3, now: Date = Date()) -> [Subscription] {
        Array(
            activeItems()
                .filter { $0.id != id }
                .prefix(limit)
        )
    }

    /// 重叠提示：同一 purpose 有 2+ 条 active，返回最早两条（验收 A6）
    public func overlapHint() -> (Subscription, Subscription, Purpose)? {
        let active = activeItems()
        for purpose in Purpose.allCases {
            let group = active.filter { $0.purpose == purpose }
            if group.count >= 2, let a = group.first, let b = group.dropFirst().first {
                return (a, b, purpose)
            }
        }
        return nil
    }

    public var canAdd: Bool {
        items.filter { $0.status != .canceled }.count < Self.freeLimit
    }

    public func item(with id: UUID) -> Subscription? {
        items.first { $0.id == id }
    }

    // MARK: - 变更

    public func add(_ item: Subscription) {
        items.append(item)
        persist()
    }

    public func update(_ item: Subscription) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = item
        updated.updatedAt = Date()
        items[index] = updated
        persist()
    }

    /// 彻底删除（已取消分区的滑动删除）
    public func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    /// 续 → decidedRenew；nextChargeAt 过后由 refresh 滚动并转回 active（§3 规则）
    public func markRenewed(_ id: UUID) {
        mutate(id) { $0.status = .decidedRenew }
    }

    /// 我已取消 → canceled；不再出现在 Today 与提醒
    public func markCanceled(_ id: UUID) {
        mutate(id) { $0.status = .canceled }
    }

    /// 反悔/撤销：decidedRenew 或 snoozed → active，重新进决策卡与提醒
    public func markActive(_ id: UUID) {
        mutate(id) {
            $0.status = .active
            $0.snoozeUntil = nil
        }
    }

    /// 再想 1 天 → snoozed，snoozeUntil = now + 1 天；到期由 refresh 转回 active
    public func markSnoozed(_ id: UUID, now: Date = Date()) {
        mutate(id) {
            $0.status = .snoozed
            $0.snoozeUntil = calendar.date(byAdding: .day, value: 1, to: now)
        }
    }

    /// 状态生命周期维护（启动 / 回前台 / 任意变更后调用）：
    /// - decidedRenew 且 nextChargeAt 已过 → 按周期滚动到未来并转回 active
    /// - snoozed 且 snoozeUntil 已到 → 转回 active
    public func refresh(now: Date = Date()) {
        let today = calendar.startOfDay(for: now)
        var changed = false
        for index in items.indices {
            switch items[index].status {
            case .decidedRenew:
                var charge = items[index].nextChargeAt
                var rolled = false
                while calendar.startOfDay(for: charge) < today {
                    charge = items[index].cycle.advance(charge, calendar: calendar)
                    rolled = true
                }
                if rolled {
                    items[index].nextChargeAt = charge
                    items[index].status = .active
                    items[index].updatedAt = now
                    changed = true
                }
            case .snoozed:
                if let until = items[index].snoozeUntil, until <= now {
                    items[index].status = .active
                    items[index].snoozeUntil = nil
                    items[index].updatedAt = now
                    changed = true
                }
            case .active, .canceled:
                break
            }
        }
        if changed { persist() }
    }

    private func mutate(_ id: UUID, _ change: (inout Subscription) -> Void) {
        guard var item = items.first(where: { $0.id == id }) else { return }
        change(&item)
        update(item)
    }

    // MARK: - 持久化与迁移

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Subscription].self, from: data) {
            items = decoded
            return
        }
        // 旧版 v0.1 数据迁移
        if let legacy = try? decoder.decode([LegacySubscription].self, from: data) {
            items = legacy.map(\.migrated)
            persist()
        }
    }

    private func persist() {
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

// MARK: - 旧版数据（v0.1 PRD 字段），仅用于迁移

private struct LegacySubscription: Decodable {
    struct LegacyCurrency: Decodable {}
    let id: UUID
    let name: String
    let templateKey: String?
    let amount: Decimal
    let currencyRaw: String
    let cycleRaw: String
    let nextChargeOn: Date
    let channelRaw: String
    let purposeRaw: String?
    let statusRaw: String
    let renewedForChargeOn: Date?
    let snoozedForChargeOn: Date?
    let snoozeRequestedAt: Date?
    let createdAt: Date?

    enum Keys: String, CodingKey {
        case id, name, templateKey, emoji, amount, currency, cycle
        case nextChargeOn, channel, purpose, usageMark, status, notes
        case createdAt, renewedForChargeOn, snoozedForChargeOn, snoozeRequestedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        templateKey = try c.decodeIfPresent(String.self, forKey: .templateKey)
        amount = try c.decode(Decimal.self, forKey: .amount)
        currencyRaw = try c.decodeIfPresent(String.self, forKey: .currency) ?? "USD"
        cycleRaw = try c.decodeIfPresent(String.self, forKey: .cycle) ?? "monthly"
        nextChargeOn = try c.decode(Date.self, forKey: .nextChargeOn)
        channelRaw = try c.decodeIfPresent(String.self, forKey: .channel) ?? "official"
        purposeRaw = try c.decodeIfPresent(String.self, forKey: .purpose)
        statusRaw = try c.decodeIfPresent(String.self, forKey: .status) ?? "active"
        renewedForChargeOn = try c.decodeIfPresent(Date.self, forKey: .renewedForChargeOn)
        snoozedForChargeOn = try c.decodeIfPresent(Date.self, forKey: .snoozedForChargeOn)
        snoozeRequestedAt = try c.decodeIfPresent(Date.self, forKey: .snoozeRequestedAt)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
    }

    var migrated: Subscription {
        let currency: Currency = currencyRaw == "CNY" ? .cny : .usd
        let cycle: Cycle = cycleRaw == "yearly" ? .yearly : .monthly
        let channel: Channel
        switch channelRaw {
        case "apple": channel = .apple
        case "wechat": channel = .wechat
        case "alipay": channel = .alipay
        default: channel = .website   // official / google / other → website
        }
        let purpose: Purpose
        switch purposeRaw {
        case "coding": purpose = .coding
        case "image": purpose = .image
        case "search": purpose = .search
        case "writing": purpose = .chat
        case "video": purpose = .image
        default: purpose = .other
        }
        let catalogId: String
        if let key = templateKey {
            // 新目录里改了名的两项
            let renamed = ["kimi": "kimi-member", "qwen": "tongyi", "wenxin": "ernie", "windsurf": "windsurf-pro"]
            let mapped = renamed[key] ?? key.replacingOccurrences(of: "_", with: "-")
            catalogId = Catalog.item(id: mapped)?.id ?? Catalog.customID
        } else {
            catalogId = Catalog.customID
        }
        let status: Status
        if renewedForChargeOn != nil {
            status = .decidedRenew
        } else if snoozedForChargeOn != nil {
            status = .snoozed
        } else {
            switch statusRaw {
            case "cancelPending", "ended": status = .canceled
            default: status = .active
            }
        }
        let snoozeUntil: Date? = status == .snoozed
            ? (snoozeRequestedAt ?? Date()).addingTimeInterval(86_400)
            : nil
        return Subscription(
            id: id,
            catalogId: catalogId,
            name: name,
            price: amount,
            currency: currency,
            cycle: cycle,
            channel: channel,
            purpose: purpose,
            nextChargeAt: nextChargeOn,
            status: status,
            snoozeUntil: snoozeUntil,
            createdAt: createdAt ?? Date(),
            updatedAt: Date()
        )
    }
}
