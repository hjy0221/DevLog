import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel

    init(viewModel: TodayViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DSColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        header

                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 220)
                        } else if let summary = viewModel.summary {
                            DailySummaryCard(summary: summary)
                            DailyNoteSection(date: summary.date)
                            recentActivitySection(summary.activities)
                            if summary.isSample { connectionPreview }
                        } else if let errorMessage = viewModel.errorMessage {
                            ContentUnavailableView("로드 실패", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                        }
                    }
                    .padding(DSSpacing.md)
                }
            }
            .navigationTitle("DevLog")
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text("Good evening")
                .font(DSTypography.callout)
                .foregroundStyle(DSColor.textSecondary)

            Text("오늘 무엇을 개발했나요?")
                .font(DSTypography.largeTitle)
                .foregroundStyle(DSColor.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func recentActivitySection(_ activities: [DevelopmentActivity]) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("최근 작업")
                    .font(DSTypography.headline)
                    .foregroundStyle(DSColor.textPrimary)

                ForEach(activities.prefix(5)) { activity in
                    ActivityRow(activity: activity)
                }
            }
        }
    }

    private var connectionPreview: some View {
        SurfaceCard {
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: "link")
                    .font(.headline)
                    .foregroundStyle(DSColor.success)
                    .frame(width: 36, height: 36)
                    .background(DSColor.successSoft)
                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))

                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text("샘플 데이터")
                        .font(DSTypography.headline)
                        .foregroundStyle(DSColor.textPrimary)

                    Text("GitHub 계정이 아직 연결되지 않았습니다.")
                        .font(DSTypography.callout)
                        .foregroundStyle(DSColor.textSecondary)
                }
            }
        }
    }
}
