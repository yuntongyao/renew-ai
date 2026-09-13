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
                    Task {
                        await notifier.refreshAuthorization()
                        refresh()
                    }
                }
        }
    }

    /// 状态生命周期维护 + 全量重排提醒（§6：launch 与任意 mutation 后）
    func refresh() {
        store.refresh()
        notifier.reschedule(items: store.items, enabled: settings.notificationEnabled)
    }
}
