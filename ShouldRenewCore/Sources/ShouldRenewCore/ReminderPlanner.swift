import Foundation

public struct PlannedReminder: Identifiable, Equatable, Sendable {
    public var id: String { identifier }
    public let identifier: String
    public let subscriptionID: UUID
    public let fireAt: Date
    public let title: String
    public let body: String
}

/// 提醒排程规划（纯逻辑，需求 7.3 / 6.4）：
/// - 到期前 N 天（默认 7/3/1）各推一条，同一订阅同一天只推一次；
/// - 用户点「续」后本周期不再推；
/// - 点「再想 1 天」后标准提醒让位给一条次日提醒；
/// - 错过上午档且尚未扣款时补推（两分钟后），配合已发记录去重。
public enum ReminderPlanner {
    public static let defaultReminderDays: [Int] = [7, 3, 1]
    public static let morningHour = 9
    public static let morningMinute = 30
    /// 错过常规时间后的补推延迟
    public static let bumpDelay: TimeInterval = 120

    /// 通知标题：问句，不是账单数字（需求 2.1 / 9）
    public static let notificationTitle = "续吗？"

    /// 文案模板：{name} {今天|明天|后天|N天后}扣 {amount}{currency}。这个月你还用吗？
    public static func body(name: String, amountText: String, daysBefore: Int) -> String {
        "\(name) \(dayText(daysBefore))扣 \(amountText)。这个月你还用吗？"
    }

    public static func dayText(_ days: Int) -> String {
        switch days {
        case ..<0: return "今天"
        case 0: return "今天"
        case 1: return "明天"
        case 2: return "后天"
        default: return "\(days)天后"
        }
    }

    /// 标准提醒计划
    public static func standardReminders(
        items: [Subscription],
        reminderDays: [Int],
        now: Date,
        sentKeys: Set<String> = [],
        calendar: Calendar = .current
    ) -> [PlannedReminder] {
        let days = reminderDays.filter { $0 > 0 }.sorted(by: >)
        var result: [PlannedReminder] = []

        for item in items where item.status == .active {
            // 本周期已决策（续 / snooze）则不再排标准提醒
            if item.renewedThisCycle(calendar: calendar) { continue }
            if item.snoozedThisCycle(calendar: calendar) { continue }

            let chargeStart = calendar.startOfDay(for: item.nextChargeOn)
            for day in days {
                let reminderDay = calendar.date(byAdding: .day, value: -day, to: chargeStart)
                guard let reminderDay,
                      var fire = calendar.date(
                        bySettingHour: morningHour,
                        minute: morningMinute,
                        second: 0,
                        of: reminderDay
                      ) else { continue }

                if fire <= now {
                    // 当天错过上午档且尚未扣款 → 稍后补推；更早的不再补
                    guard now < chargeStart, calendar.isDate(fire, inSameDayAs: now) else { continue }
                    fire = now.addingTimeInterval(bumpDelay)
                }

                let key = sentKey(item: item, daysBefore: day, chargeStart: chargeStart)
                if sentKeys.contains(key) { continue }

                let gap = calendar.dateComponents([.day], from: calendar.startOfDay(for: fire), to: chargeStart).day ?? 0
                result.append(PlannedReminder(
                    identifier: "\(item.id.uuidString)-d\(day)",
                    subscriptionID: item.id,
                    fireAt: fire,
                    title: notificationTitle,
                    body: body(name: item.name, amountText: item.amountText, daysBefore: gap)
                ))
            }
        }
        return result
    }

    /// 「再想 1 天」：以用户点按钮的时刻为基准，一天后同一时刻再问。
    /// 已过期（重启后补排太晚）返回 nil，避免反复顺延。
    public static func snoozeReminder(
        for item: Subscription,
        now: Date,
        calendar: Calendar = .current
    ) -> PlannedReminder? {
        let requestedAt = item.snoozeRequestedAt ?? now
        guard let fire = calendar.date(byAdding: .day, value: 1, to: requestedAt), fire > now else {
            return nil
        }
        let chargeStart = calendar.startOfDay(for: item.nextChargeOn)
        let gap = calendar.dateComponents([.day], from: calendar.startOfDay(for: fire), to: chargeStart).day ?? 0
        return PlannedReminder(
            identifier: "\(item.id.uuidString)-snooze",
            subscriptionID: item.id,
            fireAt: fire,
            title: notificationTitle,
            body: body(name: item.name, amountText: item.amountText, daysBefore: gap)
        )
    }

    /// 已发去重键：同一订阅、同一次扣款日、同一档位只发一次
    public static func sentKey(item: Subscription, daysBefore: Int, chargeStart: Date) -> String {
        let dayStamp = Int(chargeStart.timeIntervalSince1970 / 86_400)
        return "\(item.id.uuidString)|d\(daysBefore)|c\(dayStamp)"
    }

    /// 由计划出的提醒反查去重键（标识符形如 "<uuid>-d7"）
    public static func sentKey(matching reminder: PlannedReminder, items: [Subscription]) -> String? {
        guard let item = items.first(where: { $0.id == reminder.subscriptionID }) else { return nil }
        let suffix = reminder.identifier.dropFirst(item.id.uuidString.count)
        guard suffix.hasPrefix("-d"), let day = Int(suffix.dropFirst(2)) else { return nil }
        return sentKey(item: item, daysBefore: day, chargeStart: Calendar.current.startOfDay(for: item.nextChargeOn))
    }
}
