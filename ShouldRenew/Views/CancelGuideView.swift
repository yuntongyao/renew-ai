import SwiftUI
import ShouldRenewCore

/// 取消指南（§5.3）：四步 + 我已取消（主）/ 还是续（次）；只给步骤，不代取消
struct CancelGuideView: View {
    @Environment(\.dismiss) private var dismiss
    let item: Subscription
    var onDone: () -> Void
    var onKeep: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(CancelGuide.steps(channel: item.channel)) { step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(step.index)")
                                .font(.headline.monospacedDigit())
                                .frame(width: 24)
                                .foregroundStyle(Xuma.teal)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.title)
                                    .font(.subheadline)
                                    .foregroundStyle(Xuma.ink)
                                if !step.body.isEmpty {
                                    Text(step.body)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .xumaCard()

                Text(Copy.Guide.footer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    Button(Copy.Guide.done) {
                        onDone()
                        dismiss()
                    }
                    .buttonStyle(XumaPrimaryButtonStyle())

                    Button(Copy.Guide.keep) {
                        onKeep()
                        dismiss()
                    }
                    .buttonStyle(XumaSecondaryButtonStyle())
                }
            }
            .padding()
        }
        .background(Xuma.pageBackground)
        .navigationTitle(Copy.Decision.guideTitle(item.name))
        .navigationBarTitleDisplayMode(.inline)
    }
}
