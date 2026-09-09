import SwiftUI

struct StatItem: View {
    let title: String
    let value: String
    let iconName: String

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Image(systemName: iconName)
                .font(.headline)
                .foregroundStyle(DSColor.accent)
                .frame(width: 28, height: 28)
                .background(DSColor.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(DSColor.textPrimary)

            Text(title)
                .font(DSTypography.caption)
                .foregroundStyle(DSColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
