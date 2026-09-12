import SwiftUI
import ShouldRenewCore

/// 今日页（需求 6.1）：本月已记录花费、距下一笔扣款天数、一条主建议
struct TodayView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var settings: AppSettings
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if let next = store.nextItem {
                        NavigationLink {
                            DecisionView(item: next)
                        } label: {
                            suggestionCard(next)
                        }
                        .buttonStyle(.plain)
                    } else {
                        empty
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Copy.Today.navTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddSubscriptionView() }
        }
    }

    private var monthCharges: [Subscription] { store.chargesThisMonth() }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Copy.Today.monthChargesLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(Format.monthTotal(monthCharges, main: settings.mainCurrency))
                .font(.system(size: 34, weight: .bold))
            if !monthCharges.isEmpty {
                Text(Copy.Today.chargesSummary(monthCharges.count))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if let next = store.nextItem {
                Text(Copy.Today.nextChargeDays(max(next.daysUntilCharge, 0)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func suggestionCard(_ item: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Copy.Today.suggestionBadge)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 0.72, green: 0.42, blue: 0.16))
            HStack(spacing: 8) {
                Text(item.emoji).font(.title2)
                Text(Copy.Decision.headline(item.name))
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
            Text("\(item.amountText) · \(item.cycle.title) · \(item.channel.title)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Text(ReminderPlanner.dayText(item.daysUntilCharge) + "扣 \(item.amountText)")
                    .font(.headline)
                Spacer()
                Text(Copy.Today.goDecide)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.72, green: 0.42, blue: 0.16))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Copy.Today.emptyText)
                .foregroundStyle(.secondary)
            Button(Copy.Today.emptyButton) { showAdd = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
