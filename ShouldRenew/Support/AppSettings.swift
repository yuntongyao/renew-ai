import Foundation
import Combine
import ShouldRenewCore

/// 用户偏好（§5.5）：通知开关 + 新自定义订阅的默认币种
@MainActor
final class AppSettings: ObservableObject {
    private static let notificationKey = "settings.notificationEnabled"
    private static let currencyKey = "settings.defaultCurrency"

    @Published var notificationEnabled: Bool {
        didSet { defaults.set(notificationEnabled, forKey: Self.notificationKey) }
    }

    /// 只影响新自定义订阅的默认币种；不做汇率换算
    @Published var defaultCurrency: Currency {
        didSet { defaults.set(defaultCurrency.rawValue, forKey: Self.currencyKey) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        notificationEnabled = defaults.object(forKey: Self.notificationKey) as? Bool ?? true
        if let raw = defaults.string(forKey: Self.currencyKey), let currency = Currency(rawValue: raw) {
            defaultCurrency = currency
        } else {
            defaultCurrency = .usd
        }
    }
}
