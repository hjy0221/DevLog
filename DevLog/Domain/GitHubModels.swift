import Foundation

enum ActivityKind: String, CaseIterable, Identifiable {
    case commit
    case pullRequest
    case issue

    var id: String { rawValue }

    var title: String {
        switch self {
        case .commit: "Commit"
        case .pullRequest: "Pull Request"
        case .issue: "Issue"
        }
    }

    var iconName: String {
        switch self {
        case .commit: "arrow.trianglehead.branch"
        case .pullRequest: "arrow.triangle.pull"
        case .issue: "smallcircle.filled.circle"
        }
    }
}

struct DevelopmentActivity: Identifiable, Hashable {
    let id: UUID
    let kind: ActivityKind
    let repositoryName: String
    let title: String
    let occurredAt: Date
    let url: URL?
    var count: Int = 1
    var isDailyAggregate: Bool = false

    init(
        id: UUID = UUID(),
        kind: ActivityKind,
        repositoryName: String,
        title: String,
        occurredAt: Date,
        url: URL? = nil,
        count: Int = 1,
        isDailyAggregate: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.repositoryName = repositoryName
        self.title = title
        self.occurredAt = occurredAt
        self.url = url
        self.count = count
        self.isDailyAggregate = isDailyAggregate
    }
}

struct RepositoryActivity: Identifiable, Hashable {
    let id: UUID
    let name: String
    let owner: String
    let primaryLanguage: String
    let summary: String
    let weeklyCommitCount: Int
    let weeklyPullRequestCount: Int
    let weeklyIssueCount: Int
    let progress: Double
    let recentActivities: [DevelopmentActivity]
}

struct DailyDevelopmentSummary: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let headline: String
    let narrative: String
    let activities: [DevelopmentActivity]
    let repositories: [RepositoryActivity]
    var isSample: Bool = true
    var notice: String? = nil

    var commitCount: Int {
        activities.filter { $0.kind == .commit }.reduce(0) { $0 + $1.count }
    }

    var pullRequestCount: Int {
        activities.filter { $0.kind == .pullRequest }.count
    }

    var issueCount: Int {
        activities.filter { $0.kind == .issue }.count
    }

    var repositoryCount: Int {
        Set(activities.map(\.repositoryName)).count
    }
}

struct CalendarDayActivity: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let summary: DailyDevelopmentSummary?

    var intensity: Int {
        guard let summary else { return 0 }
        return min(summary.activities.reduce(0) { $0 + $1.count }, 5)
    }
}
