import SwiftUI

struct RepositoryRow: View {
    let repository: RepositoryActivity

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                HStack(alignment: .top, spacing: DSSpacing.sm) {
                    Image(systemName: "folder.fill")
                        .font(.title3)
                        .foregroundStyle(DSColor.accent)
                        .frame(width: 36, height: 36)
                        .background(DSColor.accentSoft)
                        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))

                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        Text(repository.name)
                            .font(DSTypography.headline)
                            .foregroundStyle(DSColor.textPrimary)

                        Text(repository.summary)
                            .font(DSTypography.callout)
                            .foregroundStyle(DSColor.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: DSSpacing.xs)

                    BadgeView(title: repository.primaryLanguage, iconName: nil, style: .neutral)
                }

                HStack(spacing: DSSpacing.sm) {
                    CompactMetric(value: repository.weeklyCommitCount, title: "commits")
                    CompactMetric(value: repository.weeklyPullRequestCount, title: "PRs")
                    CompactMetric(value: repository.weeklyIssueCount, title: "issues")
                }
            }
        }
    }
}

private struct CompactMetric: View {
    let value: Int
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
            Text("\(value)")
                .font(.subheadline.bold())
                .foregroundStyle(DSColor.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundStyle(DSColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
