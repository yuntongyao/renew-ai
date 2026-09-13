import SwiftUI
import ShouldRenewCore

/// 决策卡（§5.1 Decision card fields），今日页与详情页共用
struct DecisionCard: View {
    let item: Subscription
    var onRenew: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Copy.Today.eyebrow)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Xuma.teal)

            Text(item.name)
                .font(.title2.bold())
                .foregroundStyle(Xuma.ink)

            Text("\(item.priceText) · \(item.cycle.label) · \(item.channel.label)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(Copy.Today.chargeIn(max(item.daysUntilCharge(), 0)))
                .font(.headline)
                .foregroundStyle(Xuma.ink)

            HStack(spacing: 12) {
                Button(Copy.Decision.renew, action: onRenew)
                    .buttonStyle(XumaPrimaryButtonStyle())
                Button(Copy.Decision.cancel, action: onCancel)
                    .buttonStyle(XumaSecondaryButtonStyle())
            }
            .padding(.top, 4)
        }
        .xumaCard()
    }
}

/// 决策详情：今日「即将到期」行点入；卡片动作 + 再想 1 天（§2 Snooze 1 day）
struct DecisionDetailView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var notifier: NotificationScheduler
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @Binding var decisionItem: Subscription?
    @State private var item: Subscription
    @State private var showGuide = false
    @State private var toast: String?

    init(item: Binding<Subscription?>) {
        _decisionItem = item
        let current = item.wrappedValue ?? Subscription(
            catalogId: "custom", name: "", price: 0, currency: .usd,
            cycle: .monthly, channel: .website, purpose: .other, nextChargeAt: Date()
        )
        _item = State(initialValue: current)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DecisionCard(
                    item: item,
                    onRenew: {
                        store.markRenewed(item.id)
                        notifier.reschedule(items: store.items, enabled: settings.notificationEnabled)
                        withAnimation { toast = Copy.Today.renewedToast }
                    },
                    onCancel: { showGuide = true }
                )

                if item.status == .decidedRenew {
                    Button(Copy.Today.reactivate) {
                        store.markActive(item.id)
                        notifier.reschedule(items: store.items, enabled: settings.notificationEnabled)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Xuma.teal)
                }

                Button(Copy.Decision.snooze) {
                    store.markSnoozed(item.id)
                    notifier.reschedule(items: store.items, enabled: settings.notificationEnabled)
                    withAnimation { toast = Copy.Today.snoozedToast }
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .foregroundStyle(Xuma.teal)

                if let toast {
                    Text(toast)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }
            }
            .padding()
        }
        .background(Xuma.pageBackground)
        .navigationTitle(Copy.Decision.detailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(store.objectWillChange) { _ in
            if let fresh = store.item(with: item.id) {
                item = fresh
                // 从指南标记「我已取消」回到这里后，直接出栈回今日
                if fresh.status == .canceled {
                    decisionItem = nil
                }
            }
        }
        .navigationDestination(isPresented: $showGuide) {
            CancelGuideView(item: item) {
                store.markCanceled(item.id)
                notifier.reschedule(items: store.items, enabled: settings.notificationEnabled)
            } onKeep: {
                store.markRenewed(item.id)
                notifier.reschedule(items: store.items, enabled: settings.notificationEnabled)
            }
        }
    }
}
