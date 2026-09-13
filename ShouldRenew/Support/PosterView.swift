import SwiftUI
import ShouldRenewCore

// MARK: - 9:16 月报海报（需求 5.1 / 6.6：生成一张静图，保存到相册）

struct PosterView: View {
    let report: MonthReport

    var body: some View {
        ZStack {
            Xuma.teal
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(Copy.App.name)
                        .font(.system(size: 30, weight: .bold))
                    Spacer()
                    Text(report.monthTitle)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Xuma.ivory.opacity(0.75))
                }
                Text("AI 会员月报")
                    .font(.system(size: 17))
                    .foregroundStyle(Xuma.ivory.opacity(0.6))
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text(Copy.Report.chargesLine(report.count))
                        .font(.system(size: 17))
                        .foregroundStyle(Xuma.ivory.opacity(0.65))
                    Text(report.totalText)
                        .font(.system(size: 64, weight: .heavy))
                }
                .padding(.top, 36)

                Rectangle().fill(.white.opacity(0.15)).frame(height: 1).padding(.vertical, 24)

                if report.entries.isEmpty {
                    Text(Copy.Report.empty)
                        .font(.system(size: 17))
                        .foregroundStyle(.white.opacity(0.5))
                } else {
                    VStack(spacing: 14) {
                        ForEach(report.entries) { entry in
                            HStack(spacing: 10) {
                                Text(entry.emoji).font(.system(size: 20))
                                Text(entry.name)
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundStyle(Xuma.ivory)
                                if entry.lowUsage {
                                    Text(Copy.Report.lowUsageTag)
                                        .font(.system(size: 12, weight: .semibold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.85), in: Capsule())
                                        .foregroundStyle(.black)
                                }
                                Spacer()
                                Text("\(entry.amountText) · \(entry.chargeDayText)")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Xuma.ivory.opacity(0.7))
                            }
                        }
                    }
                }

                Spacer(minLength: 0)

                if !report.reviewEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(Copy.Report.reviewTitle) · \(Copy.Report.reviewLine(report.reviewEntries.count, report.reviewSavingsText))")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.orange)
                        ForEach(report.reviewEntries) { entry in
                            Text("· \(entry.name)  本月\(usageText(entry.usageMark))")
                                .font(.system(size: 15))
                                .foregroundStyle(Xuma.ivory.opacity(0.8))
                        }
                    }
                    .padding(.bottom, 24)
                }

                Text(Copy.App.tagline)
                    .font(.system(size: 15))
                    .foregroundStyle(Xuma.ivory.opacity(0.55))
            }
            .padding(36)
            .foregroundStyle(Xuma.ivory)
        }
    }

    private func usageText(_ usageMark: Int?) -> String {
        guard let usageMark else { return "使用情况未标记" }
        return usageMark == 0 ? "没用过" : "用了 \(usageMark) 次"
    }
}

/// 海报渲染（ImageRenderer，1080×1920）
@MainActor
enum ReportPoster {
    static let posterWidth: CGFloat = 540
    static let posterHeight: CGFloat = 960

    static func render(report: MonthReport) -> UIImage? {
        let renderer = ImageRenderer(
            content: PosterView(report: report)
                .frame(width: posterWidth, height: posterHeight)
        )
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: posterWidth, height: posterHeight)
        return renderer.uiImage
    }
}

// MARK: - 相册保存

@MainActor
final class PhotoSaver: NSObject {
    private static var pending: [PhotoSaver] = []
    private var completion: ((Bool) -> Void)?

    static func save(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        let saver = PhotoSaver()
        saver.completion = completion
        pending.append(saver)
        UIImageWriteToSavedPhotosAlbum(
            image,
            saver,
            #selector(PhotoSaver.image(_:didFinishSavingWithError:contextInfo:)),
            nil
        )
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let success = error == nil
        let completion = self.completion
        self.completion = nil
        Self.pending.removeAll { $0 === self }
        DispatchQueue.main.async {
            completion?(success)
        }
    }
}
