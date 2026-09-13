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
    /// 手动填入的使用次数文本；0–5 走分段按钮，更大的数走这里
    @State private var customUsageText = ""
    @FocusState private var usageFieldFocused: Bool

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
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(Copy.Common.done) { usageFieldFocused = false }
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
        .onAppear(perform: syncCustomUsageText)
    }

    /// 本月使用次数（选填）：分段快选 0–5，或手动填入任意正数（反馈 3 调整）
    private var usagePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Copy.Decision.usage)
                .font(.subheadline)

            Picker(Copy.Decision.usage, selection: usageSegmentBinding) {
                Text(Copy.Decision.usageSkip).tag(-1)
                Text(Copy.Decision.usageNone).tag(0)
                ForEach(1...5, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 8) {
                Text(Copy.Decision.usageCustomLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                TextField(Copy.Decision.usageCustomPlaceholder, text: $customUsageText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(.subheadline.monospacedDigit())
                    .focused($usageFieldFocused)
                    .frame(maxWidth: 120)
                    .onChange(of: customUsageText) { _, text in
                        commitCustomUsage(text)
                    }
                Text(Copy.Decision.usageUnit)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    /// 分段选择：未标记高亮「暂不记」；大于 5 的手动值不高亮任何段
    private var usageSegmentBinding: Binding<Int> {
        Binding(
            get: {
                guard let mark = item.usageMark else { return -1 }
                return (0...5).contains(mark) ? mark : -2
            },
            set: { newValue in
                usageFieldFocused = false
                if customUsageText != "" { customUsageText = "" }
                store.setUsage(item.id, mark: newValue < 0 ? nil : newValue)
            }
        )
    }

    /// 手动输入实时落库；仅接受非负整数，清空不影响已存值
    private func commitCustomUsage(_ text: String) {
        guard let value = Int(text), value >= 0 else { return }
        store.setUsage(item.id, mark: value)
    }

    private func syncCustomUsageText() {
        if let mark = item.usageMark, !(0...5).contains(mark) {
            customUsageText = "\(mark)"
        }
    }

    private func reschedule() {
        notifier.reschedule(items: store.items, reminderDays: settings.sortedReminderDays)
    }
}
