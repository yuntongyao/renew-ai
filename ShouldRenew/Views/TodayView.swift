import SwiftUI
import ShouldRenewCore

/// 今日页（§5.1）：决策卡 / 空态 / 即将到期 / 重叠提示；不是财务面板
struct TodayView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var notifier: NotificationScheduler
    @EnvironmentObject private var settings: AppSettings
    @State private var showAdd = false
    @State private var detailItem: Subscription?
    @State private var showGuide = false
    @State private var guideItem: Subscription?
    @State private var renewedItemID: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(Copy.Today.navTitle)
                        .font(.largeTitle.bold())
                        .foregroundStyle(Xuma.teal)

                    if let decision = store.upcomingDecision() {
                        DecisionCard(
                            item: decision,
                            onRenew: {
                                store.markRenewed(decision.id)
                                notifier.reschedule(items: store.items, enabled: settings.notificationEnabled)
                                renewedItemID = decision.id
                            },
                            onCancel: {
                                guideItem = decision
                                showGuide = true
                            }
                        )
                    } else {
                        empty
                    }

                    if let renewedID = renewedItemID {
                        HStack(spacing: 12) {
                            Text(Copy.Today.renewedToast)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Button(Copy.Today.undo) {
                                store.markActive(renewedID)
                                notifier.reschedule(items: store.items, enabled: settings.notificationEnabled)
                                renewedItemID = nil
                            }
                            .font(.footnote.weight(.semibold))
                        }
                        .transition(.opacity)
                    }

                    upcomingSection

                    if let (a, b, purpose) = store.overlapHint() {
                        Text(Copy.Today.overlap(a.name, b.name, purpose))
                            .font(.footnote)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Xuma.soft, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(Xuma.ink)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Xuma.pageBackground)
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) { AddSubscriptionView() }
            .navigationDestination(item: $detailItem) { _ in
                DecisionDetailView(item: $detailItem)
            }
            .navigationDestination(isPresented: $showGuide) {
                CancelGuideView(item: guideItem ?? placeholder) {
                    store.markCanceled((guideItem ?? placeholder).id)
                    notifier.reschedule(items: store.items, enabled: settings.notificationEnabled)
                } onKeep: {
                    store.markRenewed((guideItem ?? placeholder).id)
                    notifier.reschedule(items: store.items, enabled: settings.notificationEnabled)
                }
            }
        }
    }

    private var placeholder: Subscription {
        Subscription(catalogId: "custom", name: "", price: 0, currency: .usd, cycle: .monthly, channel: .website, purpose: .other, nextChargeAt: Date())
    }

    /// 空态（§5.1.3）
    private var empty: some View {
        VStack(spacing: 16) {
            Text(Copy.Today.empty)
                .font(.headline)
                .foregroundStyle(.secondary)
            Button(Copy.Today.ctaAdd) { showAdd = true }
                .buttonStyle(XumaPrimaryButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
    }

    /// 即将到期：决策卡之外最多 3 条（§5.1.4）
    @ViewBuilder
    private var upcomingSection: some View {
        let upcoming = store.upcoming(excluding: store.upcomingDecision()?.id)
        if !upcoming.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(Copy.Today.upcomingHeader)
                    .font(.headline)
                    .foregroundStyle(Xuma.ink)
                ForEach(upcoming) { item in
                    Button {
                        detailItem = item
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                    .foregroundStyle(Xuma.ink)
                                Text(item.priceText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(Copy.Today.daysLeft(max(item.daysUntilCharge(), 0)))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Xuma.teal)
                        }
                        .xumaCard(cornerRadius: 16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
