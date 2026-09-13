import Foundation

public struct PlannedReminder: Identifiable, Equatable, Sendable {
    public var id: String { identifier }
    public let identifier: String
    public let subscriptionID: UUID
    public let fireAt: Date
    public let title: String
    public let body: String
}

/// 提醒排程（§6）：nextChargeAt 前 7/3/1 天，本地时间 09:30；
/// 文案固定为「{name} {n} 天后扣 {currencySymbol}{price}，续吗？」；
/// 已过期的时间点直接跳过（验收 A2）；canceled / decidedRenew / snoozed 不提醒。
public enum ReminderPlanner {
    public static let dayOffsets = [7, 3, 1]
    public static let morningHour = 9
    public static let morningMinute = 30

    public static let notificationTitle = "续吗"

    public static func body(name: String, priceText: String, days: Int) -> String {
        "\(name) \(days) 天后扣 \(priceText)，续吗？"
    }

    public static func reminders(
        items: [Subscription],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [PlannedReminder] {
        var result: [PlannedReminder] = []
        for item in items where item.status == .active {
            let chargeStart = calendar.startOfDay(for: item.nextChargeAt)
            for offset in dayOffsets {
                guard let day = calendar.date(byAdding: .day, value: -offset, to: chargeStart),
                      let fire = calendar.date(
                        bySettingHour: morningHour,
                        minute: morningMinute,
                        second: 0,
                        of: day
                      ) else { continue }
                guard fire > now else { continue }

                result.append(PlannedReminder(
                    identifier: "renew.\(item.id.uuidString).\(offset)",
                    subscriptionID: item.id,
                    fireAt: fire,
                    title: notificationTitle,
                    body: body(name: item.name, priceText: item.priceText, days: offset)
                ))
            }
        }
        return result
    }
}
