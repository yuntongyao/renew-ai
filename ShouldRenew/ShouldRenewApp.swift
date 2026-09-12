import SwiftUI
import ShouldRenewCore

@main
struct ShouldRenewApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = SubscriptionStore()
    @StateObject private var notifier = NotificationScheduler()
    @StateObject private var settings = AppSettings()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(notifier)
                .environmentObject(settings)
                .tint(Color(red: 0.72, green: 0.42, blue: 0.16))
                .task {
                    await notifier.requestAuthorization()
                    refresh()
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    refresh()
                }
        }
    }

    /// 取消待到期的订阅过日即结束；提醒按最新数据重排
    private func refresh() {
        store.refreshStatuses()
        notifier.reschedule(items: store.items, reminderDays: settings.sortedReminderDays)
    }
}
