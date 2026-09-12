import Foundation
import UserNotifications
import ShouldRenewCore

/// 已发通知去重记录：防止补推提醒在每次打开 App 时重复投递
struct NotificationSentLog {
    private static let storageKey = "notification.sentKeys"
    /// 键格式 "uuid|dN|c<dayStamp>"，按扣款日时间戳清理 90 天前的旧键
    private static let retentionDays = 90
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var keys: Set<String> {
        Set(defaults.stringArray(forKey: Self.storageKey) ?? [])
    }

    func mark(_ newKeys: [String], now: Date = Date()) {
        let cutoff = now.timeIntervalSince1970 - Double(Self.retentionDays) * 86_400
        let kept = keys.filter { key in
            guard let stamp = key.split(separator: "|").last.flatMap({ Double($0.dropFirst()) }) else { return true }
            return stamp * 86_400 >= cutoff
        }
        defaults.set(Array(Set(kept).union(newKeys)).sorted(), forKey: Self.storageKey)
    }
}

/// 本地通知调度（需求 7.3：系统本地通知，不走自建推送）。
/// reschedule 是唯一入口：全量重排标准提醒，并为 snoozed 周期恢复同一条次日提醒。
@MainActor
final class NotificationScheduler: ObservableObject {
    @Published var authorized = false
    @Published var pendingCount = 0

    func requestAuthorization() async {
        do {
            authorized = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            authorized = false
        }
    }

    func refreshAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    /// 按当前订阅与提醒天数重排（幂等；先清后排，snooze 按持久化的请求时刻恢复）
    func reschedule(items: [Subscription], reminderDays: [Int]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        guard authorized else {
            pendingCount = 0
            return
        }

        let log = NotificationSentLog()
        let now = Date()
        var planned = ReminderPlanner.standardReminders(
            items: items,
            reminderDays: reminderDays,
            now: now,
            sentKeys: log.keys
        )

        // 「再想 1 天」：恢复（而非重新计时）当天已请求的次日提醒
        for item in items where item.status == .active && item.snoozedThisCycle() {
            if let snooze = ReminderPlanner.snoozeReminder(for: item, now: now) {
                planned.append(snooze)
            }
        }

        for reminder in planned {
            add(reminder)
        }

        // 只有已错过常规档期的补推需要记录（未来的常规提醒改主意时仍可调整）
        let delivered = planned
            .filter { $0.fireAt.timeIntervalSince(now) <= ReminderPlanner.bumpDelay + 30 }
            .compactMap { ReminderPlanner.sentKey(matching: $0, items: items) }
        log.mark(delivered)

        pendingCount = planned.count
    }

    private func add(_ reminder: PlannedReminder) {
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireAt)
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        content.userInfo = ["subscriptionID": reminder.subscriptionID.uuidString]
        let request = UNNotificationRequest(
            identifier: reminder.identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    func updatePendingCount() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        pendingCount = requests.count
    }
}
