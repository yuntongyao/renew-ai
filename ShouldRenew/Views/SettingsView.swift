import SwiftUI
import ShouldRenewCore

/// 设置页：通知权限、提醒天数、主币种、数据说明（需求 5.1 提醒可配置 / 8 隐私）
struct SettingsView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var notifier: NotificationScheduler
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        NavigationStack {
            List {
                notificationSection
                preferenceSection
                dataSection
                aboutSection
            }
            .navigationTitle(Copy.Settings.title)
            .task { await notifier.refreshAuthorization() }
            .onChange(of: settings.reminderDays) { _, _ in
                notifier.reschedule(items: store.items, reminderDays: settings.sortedReminderDays)
            }
        }
    }

    private var notificationSection: some View {
        Section {
            LabeledContent(Copy.Settings.permission, value: notifier.authorized ? Copy.Settings.permissionOn : Copy.Settings.permissionOff)
            if !notifier.authorized {
                Button(Copy.Settings.requestPermission) {
                    Task {
                        await notifier.requestAuthorization()
                        notifier.reschedule(items: store.items, reminderDays: settings.sortedReminderDays)
                    }
                }
            }
            ForEach(AppSettings.availableReminderDays.reversed(), id: \.self) { day in
                Toggle(Copy.Settings.reminderDay(day), isOn: dayBinding(day))
            }
            LabeledContent(Copy.Settings.scheduledCount, value: Copy.Settings.scheduled(notifier.pendingCount))
            Button(Copy.Settings.reschedule) {
                notifier.reschedule(items: store.items, reminderDays: settings.sortedReminderDays)
            }
        } header: {
            Text(Copy.Settings.sectionNotification)
        } footer: {
            Text(Copy.Settings.reminderDaysFooter)
        }
    }

    private func dayBinding(_ day: Int) -> Binding<Bool> {
        Binding(
            get: { settings.reminderDays.contains(day) },
            set: { isOn in
                if isOn {
                    settings.reminderDays.insert(day)
                } else {
                    settings.reminderDays.remove(day)
                }
            }
        )
    }

    private var preferenceSection: some View {
        Section {
            Picker(Copy.Settings.mainCurrency, selection: $settings.mainCurrency) {
                ForEach(CurrencyCode.allCases) { Text($0.rawValue).tag($0) }
            }
        } header: {
            Text(Copy.Settings.sectionPreference)
        } footer: {
            Text(Copy.Settings.mainCurrencyFooter)
        }
    }

    private var dataSection: some View {
        Section {
            LabeledContent(Copy.Settings.localItems, value: "\(store.items.count)")
            Text(Copy.Settings.dataNote)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text(Copy.Settings.sectionData)
        }
    }

    private var aboutSection: some View {
        Section(Copy.Settings.sectionAbout) {
            LabeledContent(Copy.App.name, value: "v0.1.0")
            Text(Copy.Settings.about)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(Copy.Settings.disclaimer)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
