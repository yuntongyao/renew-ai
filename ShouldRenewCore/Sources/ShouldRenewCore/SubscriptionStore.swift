import Foundation
import Combine

/// 本地订阅仓库：仅存本机 Documents/subscriptions.json（需求 8 隐私）
@MainActor
public final class SubscriptionStore: ObservableObject {
    @Published public private(set) var items: [Subscription] = []

    /// 免费档最多 3 条（需求 11）
    public static let freeLimit = 3

    private let fileURL: URL
    private let calendar: Calendar

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    public init(filename: String = "subscriptions.json", directory: URL? = nil, calendar: Calendar = .current) {
        self.calendar = calendar
        let dir = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = dir.appendingPathComponent(filename)
        load()
    }

    // MARK: - 查询

    /// 按扣款日排序；已结束的不进列表
    public var activeSorted: [Subscription] {
        items
            .filter { $0.status != .ended }
            .sorted { $0.nextChargeOn < $1.nextChargeOn }
    }

    /// 最近一笔到期的订阅（今日页主建议）
    public var nextItem: Subscription? { activeSorted.first }

    public var canAddFree: Bool {
        items.filter { $0.status != .ended }.count < Self.freeLimit
    }

    public func item(with id: UUID) -> Subscription? {
        items.first { $0.id == id }
    }

    /// 本月将扣款的生效中订阅
    public func chargesThisMonth(now: Date = Date()) -> [Subscription] {
        activeSorted.filter { item in
            item.status == .active && calendar.isDate(item.nextChargeOn, equalTo: now, toGranularity: .month)
        }
    }

    /// 低使用条目：自报使用 0–1 次（月报「建议复查」）
    public func lowUsageItems(threshold: Int = 1) -> [Subscription] {
        items.filter { $0.status == .active && ($0.usageMark ?? 5) <= threshold }
    }

    // MARK: - 变更

    public func add(_ item: Subscription) {
        items.append(item)
        persist()
    }

    public func update(_ item: Subscription) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        persist()
    }

    public func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    /// 主按钮「续」：关闭本轮提醒（需求 6.4 / 7.3）
    public func markRenewed(_ id: UUID) {
        mutate(id) { $0.renewedForChargeOn = $0.nextChargeOn; $0.status = .active }
    }

    /// 「我已取消」：状态变为周期结束后停止，本周期不再提醒（需求 6.5 / 12.1）
    public func markCancelPending(_ id: UUID) {
        mutate(id) { $0.status = .cancelPending }
    }

    /// 「再想 1 天」：排一条次日提醒，标准提醒让位；记录请求时刻以便重排时不顺延。
    /// 同一周期重复点击不重新计时；新周期重新计时。
    public func markSnoozed(_ id: UUID) {
        mutate(id) { item in
            let sameCycle = item.snoozedForChargeOn.map { calendar.isDate($0, inSameDayAs: item.nextChargeOn) } ?? false
            item.snoozedForChargeOn = item.nextChargeOn
            if !sameCycle || item.snoozeRequestedAt == nil {
                item.snoozeRequestedAt = Date()
            }
        }
    }

    /// 本月自报使用 0–5 次（选填）
    public func setUsage(_ id: UUID, mark: Int?) {
        mutate(id) { $0.usageMark = mark }
    }

    /// 取消后已过扣款日 → 周期结束
    public func refreshStatuses(now: Date = Date()) {
        let today = calendar.startOfDay(for: now)
        var changed = false
        for index in items.indices where items[index].status == .cancelPending {
            if calendar.startOfDay(for: items[index].nextChargeOn) < today {
                items[index].status = .ended
                changed = true
            }
        }
        if changed { persist() }
    }

    private func mutate(_ id: UUID, _ change: (inout Subscription) -> Void) {
        guard var item = items.first(where: { $0.id == id }) else { return }
        change(&item)
        update(item)
    }

    // MARK: - 持久化

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        items = (try? decoder.decode([Subscription].self, from: data)) ?? []
    }

    private func persist() {
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
