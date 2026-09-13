import SwiftUI
import ShouldRenewCore

/// TabView：今日 / 清单 / 设置，无其他入口（§4）
struct RootView: View {
    enum Tab: Hashable {
        case today, list, settings
    }

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var notifier: NotificationScheduler
    @State private var selection: Tab = .today

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tabItem { Label(Copy.Tab.today, systemImage: "sun.max") }
                .tag(Tab.today)
            ListView()
                .tabItem { Label(Copy.Tab.list, systemImage: "list.bullet.rectangle") }
                .tag(Tab.list)
            SettingsView()
                .tabItem { Label(Copy.Tab.settings, systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTodayFromNotification)) { _ in
            selection = .today
        }
        .onChange(of: settings.notificationEnabled) { _, enabled in
            if enabled {
                Task {
                    await notifier.requestAuthorization()
                    notifier.reschedule(items: store.items, enabled: enabled)
                }
            } else {
                notifier.reschedule(items: store.items, enabled: false)
            }
        }
    }
}
