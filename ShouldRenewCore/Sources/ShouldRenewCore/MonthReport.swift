import Foundation

public struct MonthReportEntry: Identifiable, Equatable, Sendable {
    public var id: String { subscriptionID.uuidString }
    public let subscriptionID: UUID
    public let emoji: String
    public let name: String
    public let amountText: String
    public let cycleTitle: String
    public let chargeDayText: String
    public let usageMark: Int?
    public let lowUsage: Bool
}

public struct MonthReport: Equatable, Sendable {
    public let monthTitle: String
    public let count: Int
    /// 本月将扣合计（按主币种粗算，含 ≈ 前缀）
    public let totalText: String
    /// 每月折算合计（按主币种粗算）
    public let monthlyTotalText: String
    public let entries: [MonthReportEntry]
    /// 建议复查：低使用条目
    public let reviewEntries: [MonthReportEntry]
    /// 建议复查的每月金额合计
    public let reviewSavingsText: String
}

/// 月报数据构建（需求 6.6：本月笔数、金额、低使用条目、建议节省金额）
public enum MonthReportBuilder {
    public static func build(
        items: [Subscription],
        mainCurrency: CurrencyCode,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> MonthReport {
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let monthTitle = "\(year)年\(month)月"

        let monthCharges = items.filter { item in
            item.status == .active && calendar.isDate(item.nextChargeOn, equalTo: now, toGranularity: .month)
        }.sorted { $0.nextChargeOn < $1.nextChargeOn }

        let entries = monthCharges.map { entry(for: $0, calendar: calendar) }

        let totalCNY = monthCharges.reduce(Decimal.zero) { $0 + ExchangeRates.convert($1.amount, from: $1.currency, to: mainCurrency) }
        let totalText = "\(mainCurrency.symbol)\(text(ExchangeRates.rounded(totalCNY, in: mainCurrency)))"

        let active = items.filter { $0.status == .active }
        let monthlyCNY = active.reduce(Decimal.zero) { $0 + ExchangeRates.convert($1.monthlyEquivalent, from: $1.currency, to: mainCurrency) }
        let monthlyTotalText = "\(mainCurrency.symbol)\(text(ExchangeRates.rounded(monthlyCNY, in: mainCurrency)))"

        let reviewItems = active.filter { ($0.usageMark ?? 5) <= 1 }.sorted { $0.nextChargeOn < $1.nextChargeOn }
        let reviewEntries = reviewItems.map { entry(for: $0, calendar: calendar) }
        let savingsCNY = reviewItems.reduce(Decimal.zero) { $0 + ExchangeRates.convert($1.monthlyEquivalent, from: $1.currency, to: mainCurrency) }
        let reviewSavingsText = "\(mainCurrency.symbol)\(text(ExchangeRates.rounded(savingsCNY, in: mainCurrency)))"

        return MonthReport(
            monthTitle: monthTitle,
            count: monthCharges.count,
            totalText: totalText,
            monthlyTotalText: monthlyTotalText,
            entries: entries,
            reviewEntries: reviewEntries,
            reviewSavingsText: reviewSavingsText
        )
    }

    static func entry(for item: Subscription, calendar: Calendar) -> MonthReportEntry {
        let day = calendar.component(.day, from: item.nextChargeOn)
        return MonthReportEntry(
            subscriptionID: item.id,
            emoji: item.emoji,
            name: item.name,
            amountText: item.amountText,
            cycleTitle: item.cycle.title,
            chargeDayText: "\(day)日扣",
            usageMark: item.usageMark,
            lowUsage: (item.usageMark ?? 5) <= 1
        )
    }

    static func text(_ amount: Decimal) -> String {
        NSDecimalNumber(decimal: amount).stringValue
    }
}
