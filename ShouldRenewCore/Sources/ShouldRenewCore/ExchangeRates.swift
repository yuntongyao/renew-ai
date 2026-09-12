import Foundation

/// 固定汇率表（需求 8：合计可按用户主币种粗算，固定汇率表即可）
public enum ExchangeRates {
    /// 1 单位外币 ≈ 多少人民币
    public static let cnyPerUnit: [CurrencyCode: Decimal] = [
        .CNY: 1,
        .USD: 7.2,
        .SGD: 5.3,
    ]

    public static func convert(_ amount: Decimal, from: CurrencyCode, to: CurrencyCode) -> Decimal {
        guard from != to else { return amount }
        let inCNY = amount * (cnyPerUnit[from] ?? 1)
        let targetRate = cnyPerUnit[to] ?? 1
        guard targetRate > 0 else { return inCNY }
        return inCNY / targetRate
    }

    /// 按主币种粗算并取整（金额展示用）
    public static func rounded(_ amount: Decimal, in currency: CurrencyCode) -> Decimal {
        let rounded = NSDecimalNumber(decimal: amount)
            .rounding(accordingToBehavior: NSDecimalNumberHandler(
                roundingMode: .plain,
                scale: 0,
                raiseOnExactness: false,
                raiseOnOverflow: false,
                raiseOnUnderflow: false,
                raiseOnDivideByZero: false
            ))
        return rounded.decimalValue
    }

    /// 原币金额折算为主币种后的展示文本，如 "≈ ¥144"
    public static func approxText(_ amount: Decimal, from: CurrencyCode, to main: CurrencyCode) -> String {
        let converted = convert(amount, from: from, to: main)
        return "≈ \(main.symbol)\(NSDecimalNumber(decimal: rounded(converted, in: main)).stringValue)"
    }
}
