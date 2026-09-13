import SwiftUI
import UIKit
import ShouldRenewCore

/// 设置（§5.5）：通知开关 / 默认币种 / 关于；解锁入口按上架要求移除（免费 10 条）
struct SettingsView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var notifier: NotificationScheduler
    @EnvironmentObject private var settings: AppSettings

    private var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0.0"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(Copy.Settings.notificationToggle, isOn: $settings.notificationEnabled)
                    if settings.notificationEnabled && !notifier.authorized {
                        Text(Copy.Settings.permissionDeniedFooter)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button(Copy.Settings.openSystemSettings) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
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

                Section(Copy.Settings.sectionAbout) {
                    LabeledContent(Copy.Settings.versionLabel, value: appVersion)
                    Text(Copy.App.about)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(Copy.Settings.title)
            .task { await notifier.refreshAuthorization() }
        }
    }
}
