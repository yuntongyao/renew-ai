import SwiftUI
import ShouldRenewCore

/// 决策页（需求 6.4）：「X」续吗？主按钮 续 / 先取消，次按钮 再想 1 天
struct DecisionView: View {
    enum Toast {
        case renewed, snoozed
    }

    enum Sheet: Identifiable {
        case guide(Subscription)
        case edit(Subscription)
        var id: String {
            switch self {
            case .guide: return "guide"
            case .edit: return "edit"
            }
        }
    }

    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var notifier: NotificationScheduler
    @EnvironmentObject private var settings: AppSettings
    @State var item: Subscription
    @State private var sheet: Sheet?
    @State private var toast: Toast?
    /// 拖动中的实时次数；松手才落库，避免拖动期间反复写盘
    @State private var draggingUsage: Double?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(Copy.Decision.headline(item.name))
                    .font(.title.bold())

                if item.status == .cancelPending {
                    Label(item.status.title, systemImage: "checkmark.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    LabeledContent(Copy.Decision.amount, value: "\(item.amountText) / \(item.cycle.title)")
                    LabeledContent(Copy.Decision.nextCharge, value: item.nextChargeOn.formatted(date: .abbreviated, time: .omitted))
                    LabeledContent(Copy.Decision.channel, value: item.channel.title)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                usagePicker

                VStack(spacing: 12) {
                    Button {
                        store.markRenewed(item.id)
                        reschedule()
                        toast = .renewed
                    } label: {
                        Text(Copy.Decision.renew)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        sheet = .guide(item)
                    } label: {
                        Text(Copy.Decision.cancelFirst)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button(Copy.Decision.snooze) {
                        store.markSnoozed(item.id)
                        reschedule()
                        toast = .snoozed
                    }
                }

                if let toast {
                    Text(toast == .renewed ? Copy.Decision.renewedToast : Copy.Decision.snoozedToast)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Copy.Decision.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(Copy.Decision.edit) { sheet = .edit(item) }
            }
        }
        .sheet(item: $sheet) { current in
            switch current {
            case .guide(let target):
                CancelGuideView(item: target)
            case .edit(let target):
                AddSubscriptionView(item: target)
            }
        }
        .onReceive(store.objectWillChange) { _ in
            if let fresh = store.item(with: item.id) {
                item = fresh
            }
        }
    }

    /// 本月使用次数滑动条（反馈 3）：拖动实时显示次数，上限为模型字段可表示的最大值
    private var usagePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(Copy.Decision.usage)
                    .font(.subheadline)
                Spacer()
                Text(usageDisplay)
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .contentTransition(.numericText())
            }
            Slider(
                value: Binding(
                    get: { draggingUsage ?? Double(item.usageMark ?? 0) },
                    set: { draggingUsage = $0 }
                ),
                in: 0...Double(Int.max)
            ) { editing in
                if !editing {
                    store.setUsage(item.id, mark: Int((draggingUsage ?? 0).rounded()))
                    draggingUsage = nil
                }
            }
            if item.usageMark != nil {
                Button(Copy.Decision.usageClear) {
                    store.setUsage(item.id, mark: nil)
                }
                .font(.footnote)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var usageDisplay: String {
        if draggingUsage == nil && item.usageMark == nil { return Copy.Decision.usageUntouched }
        let value = Int((draggingUsage ?? Double(item.usageMark ?? 0)).rounded())
        return Copy.Decision.usageTimes(value)
    }

    private func reschedule() {
        notifier.reschedule(items: store.items, reminderDays: settings.sortedReminderDays)
    }
}
