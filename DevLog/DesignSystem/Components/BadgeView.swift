import SwiftUI

struct BadgeView: View {
    let title: String
    let iconName: String?
    let style: BadgeStyle

    enum BadgeStyle {
        case accent
        case success
        case warning
        case neutral

        var foreground: Color {
            switch self {
            case .accent: DSColor.accent
            case .success: DSColor.success
            case .warning: DSColor.warning
            case .neutral: DSColor.textSecondary
            }
        }

        var background: Color {
            switch self {
            case .accent: DSColor.accentSoft
            case .success: DSColor.successSoft
            case .warning: DSColor.warningSoft
            case .neutral: DSColor.elevatedSurface
            }
        }
    }

    var body: some View {
        HStack(spacing: DSSpacing.xxs) {
            if let iconName {
                Image(systemName: iconName)
                    .font(.caption2.weight(.semibold))
            }

            Text(title)
                .font(DSTypography.caption)
                .lineLimit(1)
        }
        .foregroundStyle(style.foreground)
        .padding(.horizontal, DSSpacing.xs)
        .padding(.vertical, DSSpacing.xxs)
        .background(style.background)
        .clipShape(Capsule())
    }
}
