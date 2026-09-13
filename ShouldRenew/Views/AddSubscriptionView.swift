import SwiftUI
import ShouldRenewCore

/// 添加/编辑（§5.2）：先选目录（10 项，含自定义）→ 同一表单；保存校验名称/价格/日期
struct AddSubscriptionView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var notifier: NotificationScheduler
    @Environment(\.dismiss) private var dismiss

    let editing: Subscription?

    @State private var draft = Catalog.makeDraft(Catalog.item(id: "custom")!)
    @State private var showForm = false
    @State private var showPaywall = false
    @State private var validationMessage: String?

    init(item: Subscription? = nil) {
        editing = item
    }

    var body: some View {
        NavigationStack {
            Group {
                if editing != nil || showForm {
                    form
                } else {
                    catalogList
                }
            }
            .background(Xuma.pageBackground)
            .navigationTitle(editing != nil ? Copy.Add.editTitle : (showForm ? Copy.Add.title : Copy.Add.pickCatalog))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Copy.Add.close) {
                        if showForm && editing == nil {
                            showForm = false   // 从表单回目录
                        } else {
                            dismiss()
                        }
                    }
                }
                if editing != nil || showForm {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(Copy.Add.save) { save() }
                    }
                }
            }
            .alert(Copy.Paywall.title, isPresented: $showPaywall) {
                Button(Copy.Paywall.close, role: .cancel) {}
            } message: {
                Text(Copy.Paywall.message)
            }
        }
    }

    // MARK: - 目录列表（§5.2.1）

    private var catalogList: some View {
        List {
            ForEach(Catalog.items) { catalogItem in
                Button {
                    select(catalogItem)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(catalogItem.name)
                                .font(.headline)
                                .foregroundStyle(Xuma.ink)
                            Text("\(catalogItem.currency.symbol)\(catalogItem.defaultPrice) · \(catalogItem.cycle.label) · \(catalogItem.purpose.label)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func select(_ catalogItem: CatalogItem) {
        var draftItem = Catalog.makeDraft(catalogItem)
        if catalogItem.id == Catalog.customID {
            draftItem.currency = settings.defaultCurrency
        }
        // 演示录制用：新订阅默认 3 天后扣款，决策卡立即可见
        if ProcessInfo.processInfo.arguments.contains("--uitest-demo") {
            draftItem.nextChargeAt = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? draftItem.nextChargeAt
        }
        draft = draftItem
        showForm = true
    }

    // MARK: - 表单（§5.2.3）

    private var form: some View {
        Form {
            Section(Copy.Add.name) {
                TextField(Copy.Add.name, text: $draft.name)
            }
            Section {
                TextField(Copy.Add.price, value: $draft.price, format: .number)
                    .keyboardType(.decimalPad)
                Picker(Copy.Add.currency, selection: $draft.currency) {
                    ForEach(Currency.allCases) { Text($0.rawValue.uppercased()).tag($0) }
                }
                Picker(Copy.Add.cycle, selection: $draft.cycle) {
                    ForEach(Cycle.allCases) { Text($0.label).tag($0) }
                }
                Picker(Copy.Add.channel, selection: $draft.channel) {
                    ForEach(Channel.allCases) { Text($0.label).tag($0) }
                }
                DatePicker(Copy.Add.nextCharge, selection: $draft.nextChargeAt, in: Self.dateRange, displayedComponents: .date)
                Picker(Copy.Add.purpose, selection: $draft.purpose) {
                    ForEach(Purpose.allCases) { Text($0.label).tag($0) }
                }
            } footer: {
                Text(Copy.Add.pricePlaceholderHint)
            }
            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .scrollContentBackground(.hidden)
        .onAppear(perform: prefillIfNeeded)
    }

    private static var dateRange: ClosedRange<Date> {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        return yesterday...Date.distantFuture
    }

    private func prefillIfNeeded() {
        guard let editing else { return }
        draft = editing
    }

    // MARK: - 保存（§5.2.4 校验）

    private func save() {
        draft.name = draft.name.trimmingCharacters(in: .whitespaces)
        guard !draft.name.isEmpty else {
            validationMessage = Copy.Add.errorName
            return
        }
        guard draft.price > 0 else {
            validationMessage = Copy.Add.errorPrice
            return
        }
        validationMessage = nil

        if let editing {
            var updated = draft
            updated.id = editing.id
            updated.createdAt = editing.createdAt
            updated.updatedAt = Date()
            store.update(updated)
        } else {
            guard store.canAdd else {
                showPaywall = true
                return
            }
            store.add(draft)
        }
        notifier.reschedule(items: store.items, enabled: settings.notificationEnabled)
        dismiss()
    }
}
