import SwiftUI

struct ActivityRow: View {
    let activity: DevelopmentActivity

    var body: some View {
        if let url = activity.url {
            Link(destination: url) { row }.buttonStyle(.plain)
        } else {
            row
        }
    }

    private var row: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: activity.kind.iconName)
                .font(.callout.weight(.semibold))
                .foregroundStyle(DSColor.accent)
                .frame(width: 32, height: 32)
                .background(DSColor.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(activity.title)
                    .font(DSTypography.callout)
                    .foregroundStyle(DSColor.textPrimary)
                    .lineLimit(1)

                Text(activity.isDailyAggregate ? "\(activity.repositoryName) · 일별 집계" : "\(activity.repositoryName) · \(activity.occurredAt.formatted(date: .omitted, time: .shortened))")
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColor.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, DSSpacing.xxs)
    }
}
