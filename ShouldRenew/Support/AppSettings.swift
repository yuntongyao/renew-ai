import Foundation
import Combine
import ShouldRenewCore

/// 预置目录（本地 JSON），全局共用一份
let sharedCatalog = CatalogStore()
let sharedGuideStore = CancelGuideStore()

/// 用户偏好：提醒天数与合计主币种（需求 5.1 提醒可配置 / 8 多币种粗算）
@MainActor
final class AppSettings: ObservableObject {
    static let availableReminderDays: [Int] = [7, 3, 1]
    private static let reminderDaysKey = "settings.reminderDays"
    private static let mainCurrencyKey = "settings.mainCurrency"

    @Published var reminderDays: Set<Int> {
        didSet { defaults.set(Array(reminderDays), forKey: Self.reminderDaysKey) }
    }

    @Published var mainCurrency: CurrencyCode {
        didSet { defaults.set(mainCurrency.rawValue, forKey: Self.mainCurrencyKey) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // 区分「从未设置」与「用户全部关闭」：后者不能被默认值复活
        if defaults.object(forKey: Self.reminderDaysKey) != nil {
            let storedDays = defaults.array(forKey: Self.reminderDaysKey) as? [Int] ?? []
            reminderDays = Set(storedDays.filter { Self.availableReminderDays.contains($0) })
        } else {
            reminderDays = Set(ReminderPlanner.defaultReminderDays)
        }
        if let raw = defaults.string(forKey: Self.mainCurrencyKey),
           let currency = CurrencyCode(rawValue: raw) {
            mainCurrency = currency
        } else {
            mainCurrency = .CNY
        }
    }

    /// 降序（7 → 3 → 1）；全部关闭则返回空数组
    var sortedReminderDays: [Int] {
        reminderDays.sorted(by: >)
    }
}
