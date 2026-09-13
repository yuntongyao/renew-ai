import SwiftUI
import ShouldRenewCore

/// 清单（§5.4）：生效中 → 已标记续费 → 已取消（默认折叠）；点按进编辑，滑动取消/删除
struct ListView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var notifier: NotificationScheduler
    @EnvironmentObject private var settings: AppSettings
    @State private var showAdd = false
    @State private var editItem: Subscription?
    @State private var showCanceled = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if store.items.isEmpty {
                    ContentUnavailableView(
                        Copy.List.title,
                        systemImage: "tray",
                        description: Text(Copy.List.empty)
                    )
                } else {
                    listContent
                }
            }
            .background(Xuma.pageBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle(Copy.List.title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { addTapped() } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddSubscriptionView() }
            .navigationDestination(item: $editItem) { _ in
                AddSubscriptionView(item: editItem)
            }
            .alert(Copy.Paywall.title, isPresented: $showPaywall) {
                Button(Copy.Paywall.close, role: .cancel) {}
            } message: {
                Text(Copy.Paywall.message)
            }
        }
    }

    /// 「+」尊重免费上限（§5.4）
    private func addTapped() {
        guard store.canAdd else {
            showPaywall = true
            return
        }
        showAdd = true
    }

    private var listContent: some View {
        List {
            let active = store.activeItems()
            let decided = store.items.filter { $0.status == .decidedRenew }.sorted { $0.nextChargeAt < $1.nextChargeAt }
            let canceled = store.items.filter { $0.status == .canceled }.sorted { $0.nextChargeAt < $1.nextChargeAt }

            if !active.isEmpty {
                Section(Copy.List.sectionActive) {
                    ForEach(active) { item in
                        row(item, countdownTeal: true)
                            .swipeActions(edge: .trailing) {
                                Button(Copy.List.swipeCancel) {
                                    store.markCanceled(item.id)
                                    notifier.reschedule(items: store.items, enabled: settings.notificationEnabled)
                                }
                                .tint(.red)
                            }
                    }
                }
            }
            if !decided.isEmpty {
                Section(Copy.List.sectionDecidedRenew) {
                    ForEach(decided) { item in
                        row(item, countdownTeal: true)
                            .swipeActions(edge: .trailing) {
                                Button(Copy.List.swipeCancel) {
                                    store.markCanceled(item.id)
                                    notifier.reschedule(items: store.items, enabled: settings.notificationEnabled)
                                }
                                .tint(.red)
                            }
                    }
                }
            }
            if !canceled.isEmpty {
                Section {
                    if showCanceled {
                        ForEach(canceled) { item in
                            row(item, countdownTeal: false)
                                .swipeActions(edge: .trailing) {
                                    Button(Copy.List.swipeDelete, role: .destructive) {
                                        store.remove(item.id)
                                    }
                                }
                        }
                    }
                } header: {
                    Button {
                        withAnimation { showCanceled.toggle() }
                    } label: {
                        HStack {
                            Text("\(Copy.List.sectionCanceled)（\(canceled.count)）")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: showCanceled ? "chevron.down" : "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func row(_ item: Subscription, countdownTeal: Bool) -> some View {
        Button {
            editItem = item
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(Xuma.ink)
                    Text("\(item.priceText) · \(item.cycle.label) · \(item.channel.label)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(Copy.Today.daysLeft(max(item.daysUntilCharge(), 0)))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(countdownTeal ? Xuma.teal : Color.secondary)
            }
        }
    }
}
