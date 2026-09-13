import SwiftUI
import ShouldRenewCore

@main
struct ShouldRenewApp: App {
    /// UI 测试专用：独立空库 + 不弹通知权限框
    private static let isUITest = ProcessInfo.processInfo.arguments.contains("--uitest-fresh")

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = SubscriptionStore(
        filename: Self.isUITest ? "uitest-subscriptions.json" : "subscriptions.json"
    )
    @StateObject private var notifier = NotificationScheduler()
    @StateObject private var settings = AppSettings()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(notifier)
                .environmentObject(settings)
                .tint(Xuma.teal)
                .preferredColorScheme(.light)
                .task {
                    if Self.isUITest {
                        await notifier.refreshAuthorization()
                    } else {
                        await notifier.requestAuthorization()
                    }
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
