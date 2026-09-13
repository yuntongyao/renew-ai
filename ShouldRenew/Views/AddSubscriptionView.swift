import SwiftUI
import ShouldRenewCore

/// 添加/编辑订阅（需求 6.3，≤4 屏、20 秒内完成）
struct AddSubscriptionView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var notifier: NotificationScheduler
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    let editing: Subscription?

    @State private var draft = Subscription(name: "", amount: 20)
    @State private var pickedKey: String?
    @State private var showPaywall = false

    init(item: Subscription? = nil) {
        editing = item
    }

    var body: some View {
        NavigationStack {
            Form {
                if editing == nil {
                    Section {
                        Picker(Copy.Add.sectionTemplate, selection: $pickedKey) {
                            Text(Copy.Add.custom).tag(String?.none)
                            ForEach(sharedCatalog.templates) { template in
                                Text("\(template.emoji) \(template.name)").tag(Optional(template.key))
                            }
                        }
                    } footer: {
                        Text(Copy.Add.pricePlaceholderHint)
                    }
                }

                Section(Copy.Add.sectionDetails) {
                    TextField(Copy.Add.name, text: $draft.name)
                    TextField(Copy.Add.amount, value: $draft.amount, format: .number)
                        .keyboardType(.decimalPad)
                    Picker(Copy.Add.currency, selection: $draft.currency) {
                        ForEach(CurrencyCode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker(Copy.Add.cycle, selection: $draft.cycle) {
                        ForEach(BillingCycle.allCases) { Text($0.title).tag($0) }
                    }
                    DatePicker(Copy.Add.nextCharge, selection: $draft.nextChargeOn, displayedComponents: .date)
                    Picker(Copy.Add.channel, selection: $draft.channel) {
                        ForEach(PayChannel.allCases) { Text($0.title).tag($0) }
                    }
                    Picker(editing == nil ? Copy.Add.purpose : Copy.Add.purposeOptional, selection: Binding(
                        get: { draft.purpose ?? .other },
                        set: { draft.purpose = $0 }
                    )) {
                        ForEach(PurposeTag.allCases) { Text($0.title).tag($0) }
                    }
                    TextField(Copy.Add.notes, text: $draft.notes)
                }
            }
            .navigationTitle(editing == nil ? Copy.Add.title : Copy.Add.editTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Copy.Add.close) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Copy.Add.save) { save() }
                        .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: pickedKey) { _, key in
                // 选中模板即带入默认价、周期、渠道、用途（需求 6.3）；编辑模式不重置草稿
                guard editing == nil,
                      let key,
                      let template = sharedCatalog.template(forKey: key) else { return }
                draft = sharedCatalog.makeDraft(from: template)
            }
            .onAppear(perform: prefillIfNeeded)
            .alert(Copy.Paywall.title, isPresented: $showPaywall) {
                Button(Copy.Paywall.ok, role: .cancel) {}
            } message: {
                Text(Copy.Paywall.message)
            }
        }
    }

    private func prefillIfNeeded() {
        guard let editing else { return }
        draft = editing
        pickedKey = editing.templateKey
    }

    private func save() {
        draft.name = draft.name.trimmingCharacters(in: .whitespaces)

        if let editing {
            var updated = draft
            updated.id = editing.id
            updated.createdAt = editing.createdAt
            store.update(updated)
        } else {
            guard store.canAddFree else {
                showPaywall = true
                return
            }
            store.add(draft)
        }

        store.refreshStatuses()
        notifier.reschedule(items: store.items, reminderDays: settings.sortedReminderDays)
        dismiss()
    }
}
