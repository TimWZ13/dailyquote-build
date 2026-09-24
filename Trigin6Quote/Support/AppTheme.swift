import SwiftUI

/// 自适应主题：跟随系统明暗模式
/// 浅色模式：冷白背景 + 深炭文字，对比度高
/// 深色模式：深炭背景 + 米白文字，非全黑
/// ©️Trigin
enum AppTheme {

    // MARK: - 核心强调色（米黄，用于装饰/图标/按钮背景）
    static let accent = Color(red: 0.96, green: 0.87, blue: 0.70)
    static let accentDeep = Color(red: 0.90, green: 0.78, blue: 0.55)

    // MARK: - 强调色用于文字（浅色模式下用深金棕色，确保可读性）
    static func accentText(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .light: return Color(red: 0.55, green: 0.42, blue: 0.18) // 深金棕色，在浅色背景上清晰可读
        default: return Color(red: 0.96, green: 0.87, blue: 0.70)     // 米黄色，在深色背景上清晰可读
        }
    }

    // MARK: - 完全不透明背景（用于遮挡系统按钮等）
    static func solidBackground(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .light: return Color(red: 0.94, green: 0.94, blue: 0.95)  // 冷白
        default: return Color(red: 0.12, green: 0.12, blue: 0.13)       // 深炭
        }
    }

    // MARK: - 动态背景（浅色改为冷色调，减少米黄感）
    static func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        switch scheme {
        case .light:
            return LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.96, blue: 0.97),  // 冷白
                    Color(red: 0.93, green: 0.93, blue: 0.94),  // 浅灰
                    Color(red: 0.90, green: 0.90, blue: 0.91)   // 灰白
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.10, blue: 0.11),
                    Color(red: 0.13, green: 0.13, blue: 0.14),
                    Color(red: 0.16, green: 0.15, blue: 0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - 动态卡片背景（提高不透明度，增强与背景的分离感）
    static func cardBackground(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .light:
            return Color(red: 0.99, green: 0.99, blue: 1.0).opacity(0.95)  // 近白，高不透明度
        default:
            return Color(red: 0.22, green: 0.22, blue: 0.24).opacity(0.75)
        }
    }

    static func cardBorder(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .light:
            return Color(red: 0.68, green: 0.68, blue: 0.70).opacity(0.60)
        default:
            return Color(red: 0.42, green: 0.42, blue: 0.44).opacity(0.40)
        }
    }

    // MARK: - 动态文字（提高对比度）
    static func textPrimary(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .light: return Color(red: 0.10, green: 0.10, blue: 0.11)  // 接近纯黑
        default: return Color(red: 0.98, green: 0.97, blue: 0.96)
        }
    }

    static func textSecondary(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .light: return Color(red: 0.30, green: 0.30, blue: 0.32)  // 深灰
        default: return Color(red: 0.78, green: 0.77, blue: 0.75)
        }
    }

    static func textTertiary(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .light: return Color(red: 0.45, green: 0.45, blue: 0.47)  // 中灰
        default: return Color(red: 0.56, green: 0.55, blue: 0.54)
        }
    }

    // MARK: - 动态按钮背景
    static func buttonBackground(for scheme: ColorScheme, isHovering: Bool) -> Color {
        switch scheme {
        case .light:
            return isHovering
                ? Color(red: 0.88, green: 0.88, blue: 0.90).opacity(0.80)
                : Color(red: 0.88, green: 0.88, blue: 0.90).opacity(0.20)
        default:
            return isHovering
                ? Color(red: 0.30, green: 0.30, blue: 0.32).opacity(0.65)
                : Color(red: 0.30, green: 0.30, blue: 0.32).opacity(0.12)
        }
    }

    static func buttonBorder(for scheme: ColorScheme, isHovering: Bool) -> Color {
        switch scheme {
        case .light:
            return isHovering
                ? Color(red: 0.65, green: 0.65, blue: 0.68).opacity(0.75)
                : Color(red: 0.65, green: 0.65, blue: 0.68).opacity(0.28)
        default:
            return isHovering
                ? Color(red: 0.50, green: 0.50, blue: 0.52).opacity(0.50)
                : Color(red: 0.50, green: 0.50, blue: 0.52).opacity(0.18)
        }
    }

    // MARK: - 圆角
    static let cornerRadius: CGFloat = 14
    static let cardCornerRadius: CGFloat = 24
}
