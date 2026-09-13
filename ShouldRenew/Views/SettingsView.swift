import SwiftUI
import ShouldRenewCore

/// 设置（§5.5）：通知开关 / 默认币种 / 解锁（占位）/ 关于
struct SettingsView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var notifier: NotificationScheduler
    @EnvironmentObject private var settings: AppSettings
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(Copy.Settings.notificationToggle, isOn: $settings.notificationEnabled)
                } header: {
                    Text(Copy.Settings.sectionNotification)
                } footer: {
                    Text(Copy.Settings.notificationFooter)
                }

                Section {
                    Picker(Copy.Settings.defaultCurrency, selection: $settings.defaultCurrency) {
                        ForEach(Currency.allCases) { Text($0.rawValue.uppercased()).tag($0) }
                    }
                } header: {
                    Text(Copy.Settings.sectionPreference)
                } footer: {
                    Text(Copy.Settings.currencyFooter)
                }

                Section(Copy.Settings.sectionUnlock) {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Text(Copy.Settings.unlockRow)
                                .foregroundStyle(Xuma.ink)
                            Spacer()
                            Text(Copy.Paywall.unlock)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(Copy.Settings.sectionAbout) {
                    Text(Copy.App.about)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(Copy.Settings.title)
            .task { await notifier.refreshAuthorization() }
            .sheet(isPresented: $showPaywall) { PaywallStubSheet() }
        }
    }
}

/// 付费占位（§2：stub only，不做 StoreKit；禁用按钮 + 文案）
struct PaywallStubSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text(Copy.Paywall.title)
                .font(.title2.bold())
                .foregroundStyle(Xuma.ink)
            Text(Copy.Paywall.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(Copy.Paywall.unlock) {}
                .buttonStyle(XumaPrimaryButtonStyle())
                .disabled(true)
                .opacity(0.5)
            Text(Copy.Paywall.unlockNote)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Button(Copy.Paywall.close) { dismiss() }
                .font(.subheadline)
        }
        .padding(24)
        .presentationDetents([.medium])
    }
}
