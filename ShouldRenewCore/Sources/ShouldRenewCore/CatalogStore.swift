import Foundation

/// 预置目录：本地 JSON（需求 7.2 / 10，后续可热更新）
public struct CatalogStore: Sendable {
    public let templates: [ProductTemplate]

    public init(bundle: Bundle? = nil) {
        let source = bundle ?? .module
        let decoder = JSONDecoder()
        if let url = source.url(forResource: "catalog", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let loaded = try? decoder.decode(TemplateFile.self, from: data) {
            templates = loaded.templates
        } else {
            templates = []
        }
    }

    public func template(forKey key: String?) -> ProductTemplate? {
        guard let key else { return nil }
        return templates.first { $0.key == key }
    }

    /// 由模板生成订阅草稿：带默认价、默认周期、主取消渠道、用途标签（价格仅占位，以用户填写为准）
    public func makeDraft(from template: ProductTemplate) -> Subscription {
        Subscription(
            name: template.name,
            templateKey: template.key,
            emoji: template.emoji,
            amount: template.defaultAmount,
            currency: template.currency,
            cycle: template.cycle,
            channel: template.channel,
            purpose: template.purpose
        )
    }

    public func makeDraft(templateKey: String) -> Subscription? {
        guard let template = template(forKey: templateKey) else { return nil }
        return makeDraft(from: template)
    }

    private struct TemplateFile: Codable {
        var templates: [ProductTemplate]
    }
}
