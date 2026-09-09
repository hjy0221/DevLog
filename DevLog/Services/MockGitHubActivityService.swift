import Foundation

struct MockGitHubActivityService: GitHubActivityServicing {
    private let calendar = Calendar.current

    func fetchTodaySummary() async throws -> DailyDevelopmentSummary {
        try await Task.sleep(for: .milliseconds(180))
        return makeDailySummary(for: Date(), dayOffset: 0)
    }

    func fetchCalendarDays(containing date: Date) async throws -> [CalendarDayActivity] {
        try await Task.sleep(for: .milliseconds(160))
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        let range = calendar.range(of: .day, in: .month, for: date) ?? 1..<31

        return range.compactMap { day -> CalendarDayActivity? in
            guard let currentDate = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else {
                return nil
            }

            let dayOffset = calendar.dateComponents([.day], from: currentDate, to: Date()).day ?? 0
            let hasActivity = dayOffset >= 0 && (day + dayOffset) % 3 != 1
            let summary = hasActivity ? makeDailySummary(for: currentDate, dayOffset: dayOffset) : nil

            return CalendarDayActivity(id: UUID(), date: currentDate, summary: summary)
        }
    }

    func fetchRepositories() async throws -> [RepositoryActivity] {
        try await Task.sleep(for: .milliseconds(140))
        return makeRepositories(referenceDate: Date())
    }

    private func makeDailySummary(for date: Date, dayOffset: Int) -> DailyDevelopmentSummary {
        let repositories = makeRepositories(referenceDate: date)
        let activities = repositories.flatMap(\.recentActivities)
            .filter { calendar.isDate($0.occurredAt, inSameDayAs: date) }

        return DailyDevelopmentSummary(
            id: UUID(),
            date: date,
            headline: dayOffset == 0 ? "Today의 개발 기록" : "개발 흐름 정리",
            narrative: "SwiftUI 화면 구조를 정리하고 GitHub 활동을 일기형 요약으로 변환하는 데이터 흐름을 구현했습니다.",
            activities: activities.isEmpty ? fallbackActivities(for: date) : activities,
            repositories: repositories
        )
    }

    private func makeRepositories(referenceDate: Date) -> [RepositoryActivity] {
        [
            RepositoryActivity(
                id: UUID(),
                name: "DevLog-iOS",
                owner: "hajaeyun",
                primaryLanguage: "Swift",
                summary: "Today, Calendar, Projects를 잇는 SwiftUI 앱 구조를 만들고 있습니다.",
                weeklyCommitCount: 18,
                weeklyPullRequestCount: 3,
                weeklyIssueCount: 5,
                progress: 0.62,
                recentActivities: [
                    activity(.commit, "Create reusable DailySummary pattern", referenceDate, hour: 20, minute: 18, repository: "DevLog-iOS"),
                    activity(.pullRequest, "Wire MVP navigation tabs", referenceDate, hour: 18, minute: 42, repository: "DevLog-iOS"),
                    activity(.issue, "Define OAuth boundary for GitHub connection", referenceDate, hour: 15, minute: 5, repository: "DevLog-iOS")
                ]
            ),
            RepositoryActivity(
                id: UUID(),
                name: "TinyLang-C",
                owner: "hajaeyun",
                primaryLanguage: "C",
                summary: "Lexer 토큰 처리와 오류 케이스를 정리하는 컴파일러 실험 프로젝트입니다.",
                weeklyCommitCount: 12,
                weeklyPullRequestCount: 1,
                weeklyIssueCount: 2,
                progress: 0.48,
                recentActivities: [
                    activity(.commit, "Handle invalid number token", referenceDate, hour: 14, minute: 22, repository: "TinyLang-C"),
                    activity(.commit, "Add TOKEN_NUMBER branch", referenceDate, hour: 13, minute: 51, repository: "TinyLang-C")
                ]
            ),
            RepositoryActivity(
                id: UUID(),
                name: "Portfolio-Lab",
                owner: "hajaeyun",
                primaryLanguage: "TypeScript",
                summary: "개발 일지에서 포트폴리오 문장으로 넘어가는 실험을 담고 있습니다.",
                weeklyCommitCount: 7,
                weeklyPullRequestCount: 2,
                weeklyIssueCount: 1,
                progress: 0.36,
                recentActivities: [
                    activity(.commit, "Draft project impact section", referenceDate, hour: 11, minute: 9, repository: "Portfolio-Lab")
                ]
            )
        ]
    }

    private func fallbackActivities(for date: Date) -> [DevelopmentActivity] {
        [
            activity(.commit, "Refine development journal summary", date, hour: 17, minute: 30, repository: "DevLog-iOS"),
            activity(.issue, "Review weekly progress metrics", date, hour: 10, minute: 15, repository: "Portfolio-Lab")
        ]
    }

    private func activity(
        _ kind: ActivityKind,
        _ title: String,
        _ date: Date,
        hour: Int,
        minute: Int,
        repository: String
    ) -> DevelopmentActivity {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let occurredAt = calendar.date(
            from: DateComponents(
                year: components.year,
                month: components.month,
                day: components.day,
                hour: hour,
                minute: minute
            )
        ) ?? date

        return DevelopmentActivity(
            kind: kind,
            repositoryName: repository,
            title: title,
            occurredAt: occurredAt,
            url: nil
        )
    }
}
