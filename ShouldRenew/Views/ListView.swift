import SwiftUI
import ShouldRenewCore

/// 清单页（需求 6.2）：卡片（图标/名称/价格周期/倒计时/渠道小标）+ 筛选 + 本月合计
struct ListView: View {
    enum Filter: String, CaseIterable, Identifiable {
        case all, soon, trial, cancelPending
        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return Copy.List.filterAll
            case .soon: return Copy.List.filterSoon
            case .trial: return Copy.List.filterTrial
            case .cancelPending: return Copy.List.filterCancelPending
            }
        }
    }

    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var settings: AppSettings
    @State private var filter: Filter = .all
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 筛选器放在 List 之外，避免 List 行内分段控件在导航返回后影响列表刷新
                Picker(Copy.List.title, selection: $filter) {
                    ForEach(Filter.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if filtered.isEmpty {
                    ContentUnavailableView(
                        Copy.List.title,
                        systemImage: "tray",
                        description: Text(Copy.List.empty)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    listContent
                }
            }
            .background(Xuma.pageBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle(Copy.List.title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddSubscriptionView() }
        }
    }

    private var filtered: [Subscription] {
        switch filter {
        case .all:
            return store.activeSorted
        case .soon:
            return store.activeSorted.filter { $0.status == .active && (0...7).contains($0.daysUntilCharge) }
        case .trial:
            return store.activeSorted.filter { $0.status == .active && $0.cycle == .trial }
        case .cancelPending:
            return store.activeSorted.filter { $0.status == .cancelPending }
        }
    }

    private var monthCharges: [Subscription] { store.chargesThisMonth() }

    private var listContent: some View {
        List {
            Section {
                ForEach(filtered) { item in
                    NavigationLink {
                        DecisionView(item: item)
                    } label: {
                        row(item)
                    }
                }
                .onDelete { offsets in
                    for offset in offsets { store.delete(filtered[offset].id) }
                }
            } header: {
                Text("\(Copy.Today.monthChargesLabel) \(Format.monthTotal(monthCharges, main: settings.mainCurrency))")
            }
        }
    }

    private func row(_ item: Subscription) -> some View {
        HStack(spacing: 12) {
            Text(item.emoji)
                .font(.title2)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.headline)
                    if item.status == .cancelPending {
                        Text(item.status.title)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2), in: Capsule())
                            .foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 6) {
                    Text("\(item.amountText)/\(item.cycle.title) · \(item.channel.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if let usage = item.usageMark {
                        // 已标次数：≤1 次橙色（对应月报「低使用」），其余灰色
                        Text(usage == 0 ? Copy.List.usageNone : Copy.List.usageTimes(usage))
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                usage <= 1 ? Color.orange.opacity(0.18) : Color.gray.opacity(0.15),
                                in: Capsule()
                            )
                            .foregroundStyle(usage <= 1 ? Color.orange : .secondary)
                    }
                }
            }
            Spacer()
            Text(Copy.List.chargeIn(max(item.daysUntilCharge, 0)))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Xuma.teal)
        }
        .padding(.vertical, 2)
    }
}
