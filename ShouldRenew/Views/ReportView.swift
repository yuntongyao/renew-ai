import SwiftUI
import ShouldRenewCore

/// 月报页（需求 6.6）：本月笔数、金额、低使用条目、建议复查；导出 9:16 海报
struct ReportView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var settings: AppSettings

    @State private var poster: UIImage?
    @State private var saveResult: SaveResult?

    enum SaveResult: Identifiable {
        case saved, failed, denied
        var id: Int { hashValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summary
                    reviewSection
                    posterButtons
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Copy.Report.title)
            .task { renderPosterIfNeeded() }
            .alert(item: $saveResult) { result in
                switch result {
                case .saved:
                    return Alert(title: Text(Copy.Report.posterSaved))
                case .failed:
                    return Alert(title: Text(Copy.Report.posterSaveFailed))
                case .denied:
                    return Alert(title: Text(Copy.Report.posterDenied))
                }
            }
        }
    }

    private var report: MonthReport {
        MonthReportBuilder.build(items: store.items, mainCurrency: settings.mainCurrency)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(report.monthTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(Copy.Report.chargesLine(report.count))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(report.totalText)
                .font(.system(size: 34, weight: .bold))
            HStack(spacing: 4) {
                Text(Copy.Report.monthlyEquivalent)
                Text(report.monthlyTotalText).bold()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            if !report.entries.isEmpty {
                VStack(spacing: 10) {
                    ForEach(report.entries) { entry in
                        HStack(spacing: 10) {
                            Text(entry.emoji)
                            Text(entry.name).font(.subheadline.weight(.medium))
                            if entry.lowUsage {
                                Text(Copy.Report.lowUsageTag)
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2), in: Capsule())
                                    .foregroundStyle(.orange)
                            }
                            Spacer()
                            Text("\(entry.amountText) · \(entry.chargeDayText)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Copy.Report.reviewTitle)
                .font(.headline)
            if report.reviewEntries.isEmpty {
                Text(Copy.Report.noReview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(Copy.Report.reviewLine(report.reviewEntries.count, report.reviewSavingsText))
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                ForEach(report.reviewEntries) { entry in
                    HStack {
                        Text("· \(entry.emoji) \(entry.name)")
                            .font(.subheadline)
                        Spacer()
                        Text(entry.usageText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var posterButtons: some View {
        VStack(spacing: 12) {
            Button {
                guard let poster else { return }
                PhotoSaver.save(poster) { success in
                    saveResult = success ? .saved : .failed
                }
            } label: {
                Label(poster == nil ? Copy.Report.rendering : Copy.Report.savePoster,
                      systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(poster == nil)

            if let poster {
                ShareLink(
                    item: Image(uiImage: poster),
                    preview: SharePreview(Copy.App.name, image: Image(uiImage: poster))
                ) {
                    Label(Copy.Report.sharePoster, systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
            }
        }
    }

    @MainActor
    private func renderPosterIfNeeded() {
        guard poster == nil else { return }
        poster = ReportPoster.render(report: report)
    }
}

private extension MonthReportEntry {
    var usageText: String {
        guard let usageMark else { return "未标记" }
        return usageMark == 0 ? "没用过" : "用了 \(usageMark) 次"
    }
}
