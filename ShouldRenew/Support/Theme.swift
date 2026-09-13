import SwiftUI

/// 定稿色（design/xuma-assets）：底 #2F5D56，字 #F2EBE0
enum Xuma {
    /// 主色（卡片、主按钮、选中态）
    static let teal = Color(red: 47 / 255, green: 93 / 255, blue: 86 / 255)
    /// 主按钮按下态
    static let tealPressed = Color(red: 36 / 255, green: 72 / 255, blue: 67 / 255)
    /// 主文字（深底上的字）
    static let ivory = Color(red: 242 / 255, green: 235 / 255, blue: 224 / 255)
    /// 次按钮底（薄荷）
    static let mint = Color(red: 232 / 255, green: 240 / 255, blue: 237 / 255)
    /// 页面底色
    static let pageBackground = Color(red: 244 / 255, green: 247 / 255, blue: 246 / 255)
}

/// 主按钮：teal 底 + ivory 字，按下转深（对应 primary-renew / primary-renew-pressed 切图）
struct XumaPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Xuma.ivory)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                configuration.isPressed ? Xuma.tealPressed : Xuma.teal,
                in: RoundedRectangle(cornerRadius: 14)
            )
    }
}

/// 次按钮：薄荷底 + teal 字（对应 secondary-cancel 切图）
struct XumaSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Xuma.teal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                configuration.isPressed ? Xuma.mint.opacity(0.65) : Xuma.mint,
                in: RoundedRectangle(cornerRadius: 14)
            )
    }
}

/// 白色圆角卡片
struct XumaCardBackground: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func xumaCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(XumaCardBackground(cornerRadius: cornerRadius))
    }
}
