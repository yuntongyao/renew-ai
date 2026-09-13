import Foundation
import UserNotifications
import ShouldRenewCore

/// 本地通知调度（§6）：启动与任意变更后全量重排；canceled 条目随全量重排自然移除
@MainActor
final class NotificationScheduler: ObservableObject {
    @Published var authorized = false

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

    /// 全量重排：先清后排；开关关闭或未授权时只清不排
    func reschedule(items: [Subscription], enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard enabled, authorized else { return }

        for reminder in ReminderPlanner.reminders(items: items, now: Date()) {
            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminder.fireAt
            )
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
            center.add(request)
        }
    }
}
