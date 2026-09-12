import SwiftUI
import ShouldRenewCore

/// 决策页（需求 6.4）：该不该续「X」？主按钮 续 / 先取消，次按钮 再想 1 天
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

    private var usagePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Copy.Decision.usage)
                .font(.subheadline)
            Picker(Copy.Decision.usage, selection: Binding(
                get: { item.usageMark ?? -1 },
                set: { newValue in
                    store.setUsage(item.id, mark: newValue < 0 ? nil : newValue)
                }
            )) {
                Text(Copy.Decision.usageSkip).tag(-1)
                Text(Copy.Decision.usageNone).tag(0)
                ForEach(1...5, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func reschedule() {
        notifier.reschedule(items: store.items, reminderDays: settings.sortedReminderDays)
    }
}
