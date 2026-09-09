import SwiftUI

struct ProjectsView: View {
    @StateObject private var viewModel: ProjectsViewModel

    init(viewModel: ProjectsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DSColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            Text("Projects")
                                .font(DSTypography.largeTitle)
                                .foregroundStyle(DSColor.textPrimary)

                            Text("이번 주 활동")
                                .font(DSTypography.callout)
                                .foregroundStyle(DSColor.textSecondary)
                        }

                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 240)
                        } else if let errorMessage = viewModel.errorMessage {
                            ContentUnavailableView("로드 실패", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                        } else if viewModel.repositories.isEmpty {
                            ContentUnavailableView("이번 주 활동이 없습니다", systemImage: "folder")
                        } else {
                            ForEach(viewModel.repositories) { repository in
                                NavigationLink {
                                    ProjectDetailView(repository: repository)
                                } label: {
                                    RepositoryRow(repository: repository)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(DSSpacing.md)
                }
            }
            .navigationTitle("Projects")
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }
}

private struct ProjectDetailView: View {
    let repository: RepositoryActivity

    var body: some View {
        ZStack {
            DSColor.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    RepositoryRow(repository: repository)

                    Text("이번 주 활동")
                        .font(DSTypography.headline)
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            weeklyStats
                        }
                        VStack { weeklyStats }
                    }

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Text("최근 활동")
                                .font(DSTypography.headline)
                                .foregroundStyle(DSColor.textPrimary)

                            ForEach(repository.recentActivities) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                    }
                }
                .padding(DSSpacing.md)
            }
        }
        .navigationTitle(repository.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var weeklyStats: some View {
        StatItem(title: "Commits", value: "\(repository.weeklyCommitCount)", iconName: "chevron.left.forwardslash.chevron.right")
        StatItem(title: "Pull Requests", value: "\(repository.weeklyPullRequestCount)", iconName: "arrow.triangle.pull")
        StatItem(title: "Issues", value: "\(repository.weeklyIssueCount)", iconName: "smallcircle.filled.circle")
    }
}
