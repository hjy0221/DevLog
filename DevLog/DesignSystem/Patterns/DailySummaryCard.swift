import SwiftUI

struct DailySummaryCard: View {
    let summary: DailyDevelopmentSummary

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        Text(summary.headline)
                            .font(DSTypography.title)
                            .foregroundStyle(DSColor.textPrimary)

                        Text(summary.date.formatted(date: .complete, time: .omitted))
                            .font(DSTypography.callout)
                            .foregroundStyle(DSColor.textSecondary)
                    }

                    Spacer()

                    BadgeView(title: summary.isSample ? "샘플" : "GitHub", iconName: "bolt.fill", style: .accent)
                }

                Text(summary.narrative)
                    .font(DSTypography.body)
                    .foregroundStyle(DSColor.textPrimary)
                    .lineSpacing(3)
                if let notice = summary.notice {
                    Text(notice).font(.caption).foregroundStyle(DSColor.textSecondary)
                }

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.sm), count: 2),
                    spacing: DSSpacing.sm
                ) {
                    StatItem(title: "Commits", value: "\(summary.commitCount)", iconName: "arrow.trianglehead.branch")
                    StatItem(title: "Pull Requests", value: "\(summary.pullRequestCount)", iconName: "arrow.triangle.pull")
                    StatItem(title: "Issues", value: "\(summary.issueCount)", iconName: "smallcircle.filled.circle")
                    StatItem(title: "Repositories", value: "\(summary.repositoryCount)", iconName: "folder")
                }
            }
        }
    }
}

struct DailyNoteSection: View {
    @AppStorage private var note: String

    init(date: Date) {
        let calendar = Calendar(identifier: .gregorian)
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let key = "daily-note.\(parts.year!).\(parts.month!).\(parts.day!)"
        _note = AppStorage(wrappedValue: "", key)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Label("나의 개발 메모", systemImage: "square.and.pencil")
                .font(DSTypography.headline)
            TextField("배운 점, 고민, 다음 할 일", text: $note, axis: .vertical)
                .lineLimit(4...12)
                .padding(DSSpacing.md)
                .background(DSColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm))
                .accessibilityLabel("날짜별 개발 메모")
        }
    }
}
