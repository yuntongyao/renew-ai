import Foundation

public struct GuideStep: Identifiable, Equatable, Sendable {
    public var id: Int { index }
    public let index: Int
    public let text: String
}

/// 取消指南：按渠道预置步骤，本地 JSON，可离线阅读（需求 7.4）
public struct CancelGuideStore: Sendable {
    private let stepsByChannel: [String: [String]]

    public init(bundle: Bundle? = nil) {
        let source = bundle ?? .module
        let decoder = JSONDecoder()
        if let url = source.url(forResource: "guides", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let loaded = try? decoder.decode(GuideFile.self, from: data) {
            stepsByChannel = loaded.channels.mapValues(\.steps)
        } else {
            stepsByChannel = [:]
        }
    }

    public func steps(for channel: PayChannel, product: String) -> [GuideStep] {
        let raw = stepsByChannel[channel.rawValue] ?? []
        return raw.enumerated().map { index, text in
            GuideStep(index: index + 1, text: text.replacingOccurrences(of: "{name}", with: product))
        }
    }

    /// 官方帮助页链接（静态表，可维护；链接打不开时文字步骤仍完整可读）
    public func helpURL(for subscription: Subscription, catalog: CatalogStore) -> URL? {
        if let key = subscription.templateKey,
           let template = catalog.template(forKey: key),
           let link = template.guideURL {
            return URL(string: link)
        }
        return nil
    }

    private struct GuideFile: Codable {
        var channels: [String: ChannelGuide]
    }

    private struct ChannelGuide: Codable {
        var steps: [String]
    }
}
