import SwiftUI
import ShouldRenewCore

/// 取消指南（需求 6.5 / 7.4）：按渠道 4 步 + 可选官方链接，可离线阅读
struct CancelGuideView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var notifier: NotificationScheduler
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    let item: Subscription

    private var steps: [GuideStep] {
        sharedGuideStore.steps(for: item.channel, product: item.name)
    }

    private var helpURL: URL? {
        sharedGuideStore.helpURL(for: item, catalog: sharedCatalog)
    }

    var body: some View {
        NavigationStack {
            List {
                Section(Copy.Guide.header(item.channel.title, item.name)) {
                    ForEach(steps) { step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(step.index)")
                                .font(.headline.monospacedDigit())
                                .frame(width: 24)
                                .foregroundStyle(.tint)
                            Text(step.text)
                        }
                        .padding(.vertical, 2)
                    }

                    if let helpURL {
                        Link(destination: helpURL) {
                            Label(Copy.Guide.openHelp, systemImage: "safari")
                        }
                    }
                }

                Section {
                    Button {
                        store.markCancelPending(item.id)
                        notifier.reschedule(items: store.items, reminderDays: settings.sortedReminderDays)
                        dismiss()
                    } label: {
                        Text(Copy.Guide.markCancelled)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Copy.Guide.offlineHint)
                        Text(Copy.Guide.footer)
                    }
                }
            }
            .navigationTitle(Copy.Guide.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Copy.Add.close) { dismiss() }
                }
            }
        }
    }
}
