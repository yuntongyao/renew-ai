import SwiftUI
import ShouldRenewCore

struct RootView: View {
    enum Tab: Hashable {
        case today, list, add, report, settings
    }

    struct DecisionTarget: Identifiable {
        let id = UUID()
        let item: Subscription
    }

    enum Sheet: Identifiable {
        case add
        case decision(DecisionTarget)
        var id: String {
            switch self {
            case .add: return "add"
            case .decision(let target): return "decision-\(target.id.uuidString)"
            }
        }
    }

    @EnvironmentObject private var store: SubscriptionStore
    @State private var selection: Tab = .today
    @State private var sheet: Sheet?

    var body: some View {
        TabView(selection: tabSelection) {
            TodayView()
                .tabItem { Label(Copy.Tab.today, systemImage: "sun.max") }
                .tag(Tab.today)
            ListView()
                .tabItem { Label(Copy.Tab.list, systemImage: "list.bullet.rectangle") }
                .tag(Tab.list)
            Color.clear
                .tabItem { Label(Copy.Tab.add, systemImage: "plus.circle.fill") }
                .tag(Tab.add)
            ReportView()
                .tabItem { Label(Copy.Tab.report, systemImage: "chart.pie") }
                .tag(Tab.report)
            SettingsView()
                .tabItem { Label(Copy.Tab.settings, systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        .sheet(item: $sheet) { current in
            switch current {
            case .add:
                AddSubscriptionView()
            case .decision(let target):
                DecisionView(item: target.item)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDecisionFromNotification)) { note in
            guard let id = note.object as? UUID,
                  let item = store.item(with: id) else { return }
            sheet = .decision(DecisionTarget(item: item))
        }
    }

    /// 「添加」不是真页面：点中即弹添加面板（需求 6：五个一级入口）
    private var tabSelection: Binding<Tab> {
        Binding(
            get: { selection },
            set: { newValue in
                if newValue == .add {
                    sheet = .add
                } else {
                    selection = newValue
                }
            }
        )
    }
}
