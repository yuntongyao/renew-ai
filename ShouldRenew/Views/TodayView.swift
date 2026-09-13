import SwiftUI
import ShouldRenewCore

/// 今日页（需求 6.1，视觉按 design/xuma-assets/today-page.png 定稿）
struct TodayView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var notifier: NotificationScheduler
    @State private var showAdd = false
    @State private var decisionItem: Subscription?
    @State private var renewedToast = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(Copy.Today.navTitle)
                        .font(.largeTitle.bold())
                        .foregroundStyle(Xuma.teal)

                    if let next = store.nextItem {
                        summaryCard(next)
                        suggestionCard(next)
                        upcomingSection
                    } else {
                        empty
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Xuma.pageBackground)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddSubscriptionView() }
            .navigationDestination(item: $decisionItem) { target in
                DecisionView(item: target)
            }
        }
    }

    private var monthCharges: [Subscription] { store.chargesThisMonth() }

    /// 顶部墨绿金额卡
    private func summaryCard(_ next: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Copy.Today.monthChargesLabel)
                .font(.subheadline)
                .foregroundStyle(Xuma.ivory.opacity(0.8))
            Text(Format.monthTotal(monthCharges, main: settings.mainCurrency))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(Xuma.ivory)
            Text(Copy.Today.nextChargeDays(max(next.daysUntilCharge, 0)))
                .font(.subheadline)
                .foregroundStyle(Xuma.ivory.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Xuma.teal, in: RoundedRectangle(cornerRadius: 24))
    }

    /// 主建议卡：该不该续「X」？+ 续 / 先取消 内联按钮
    private func suggestionCard(_ next: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Copy.Today.suggestionBadge)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Xuma.teal)

            Text(next.emoji + " " + next.name)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text("\(next.amountText) · \(next.cycle.title) · \(next.channel.title)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(Copy.Today.suggestionChargeIn(max(next.daysUntilCharge, 0)))
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                Button {
                    store.markRenewed(next.id)
                    reschedule()
                    renewedToast = true
                } label: {
                    Text(Copy.Decision.renew)
                }
                .buttonStyle(XumaPrimaryButtonStyle())

                Button {
                    decisionItem = next
                } label: {
                    Text(Copy.Decision.cancelFirst)
                }
                .buttonStyle(XumaSecondaryButtonStyle())
            }
            .padding(.top, 4)

            if renewedToast {
                Text(Copy.Decision.renewedToast)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .xumaCard()
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture { decisionItem = next }
    }

    /// 即将到期：除最近一笔外的后续订阅
    @ViewBuilder
    private var upcomingSection: some View {
        let upcoming = Array(store.activeSorted.filter { $0.status == .active }.dropFirst().prefix(5))
        if !upcoming.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(Copy.Today.upcomingHeader)
                    .font(.headline)
                    .foregroundStyle(.primary)
                ForEach(upcoming) { item in
                    Button {
                        decisionItem = item
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.emoji + " " + item.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(item.amountText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(Copy.Today.upcomingDays(max(item.daysUntilCharge, 0)))
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

    private var empty: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Copy.Today.navTitle)
                .font(.largeTitle.bold())
                .foregroundStyle(Xuma.teal)
            VStack(alignment: .leading, spacing: 12) {
                Text(Copy.Today.emptyText)
                    .foregroundStyle(.secondary)
                Button(Copy.Today.emptyButton) { showAdd = true }
                    .buttonStyle(XumaPrimaryButtonStyle())
            }
            .xumaCard()
        }
    }

    private func reschedule() {
        notifier.reschedule(items: store.items, reminderDays: settings.sortedReminderDays)
    }
}
