import SwiftUI

/// 定稿色（§7 视觉表）：teal #2F5D56 / ivory #F2EBE0 / page #F4F7F6 / soft #E8F0ED / ink #1C2826
enum Xuma {
    /// 主色（标题、主按钮、选中 Tab）
    static let teal = Color(red: 47 / 255, green: 93 / 255, blue: 86 / 255)
    /// 主按钮按下态
    static let tealPressed = Color(red: 36 / 255, green: 72 / 255, blue: 67 / 255)
    /// 深底上的文字
    static let ivory = Color(red: 242 / 255, green: 235 / 255, blue: 224 / 255)
    /// 页面底色
    static let pageBackground = Color(red: 244 / 255, green: 247 / 255, blue: 246 / 255)
    /// 次按钮底
    static let soft = Color(red: 232 / 255, green: 240 / 255, blue: 237 / 255)
    /// 主要文字
    static let ink = Color(red: 28 / 255, green: 40 / 255, blue: 38 / 255)
}

/// 主按钮：capsule、teal 填充、ivory 文字、高 48–52（§7）
struct XumaPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Xuma.ivory)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                configuration.isPressed ? Xuma.tealPressed : Xuma.teal,
                in: Capsule()
            )
    }
}

/// 次按钮：soft 底 + teal 文字
struct XumaSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Xuma.teal)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                configuration.isPressed ? Xuma.soft.opacity(0.65) : Xuma.soft,
                in: Capsule()
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
