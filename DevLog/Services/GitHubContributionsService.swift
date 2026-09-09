import Foundation
import CryptoKit

struct GitHubGraphQL {
    let token: String
    var session: URLSession = .shared
    struct Envelope<T: Decodable>: Decodable {
        let data: T?
        let errors: [Failure]?
        struct Failure: Decodable { let message: String }
    }
    func execute<T: Decodable>(_ query: String, variables: [String: String] = [:]) async throws -> T {
        var request = URLRequest(url: URL(string: "https://api.github.com/graphql")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("DevLog-iOS", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query, "variables": variables])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        switch http.statusCode {
        case 200: break
        case 401: throw GitHubFailure.message("GitHub 인증이 만료되었습니다. 계정에서 다시 연결해 주세요.")
        case 403, 429: throw GitHubFailure.message("GitHub 접근 권한 또는 요청 제한을 확인해 주세요. 잠시 후 다시 시도할 수 있습니다.")
        default: throw GitHubFailure.message("GitHub 서버 오류입니다. 잠시 후 다시 시도해 주세요.")
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(Envelope<T>.self, from: data)
        guard envelope.errors?.isEmpty != false, let value = envelope.data else {
            throw GitHubFailure.message("GitHub 기여를 가져오지 못했습니다. 토큰 권한과 사용량을 확인해 주세요.")
        }
        return value
    }
    func viewer() async throws -> String {
        struct Response: Decodable { let viewer: User }
        struct User: Decodable { let login: String }
        let result: Response = try await execute("query { viewer { login } }")
        return result.viewer.login
    }
}

struct ContributionRepository: Decodable {
    let id: String
    let nameWithOwner: String
    let description: String?
    let primaryLanguage: Language?
    struct Language: Decodable { let name: String }
}
struct ContributionPage<T: Decodable>: Decodable {
    let nodes: [T?]
    let pageInfo: PageInfo
    struct PageInfo: Decodable { let hasNextPage: Bool; let endCursor: String? }
}
struct ContributionCollection: Decodable {
    let totalRepositoriesWithContributedCommits: Int
    let restrictedContributionsCount: Int
    let commitContributionsByRepository: [CommitGroup]
    let pullRequestContributions: ContributionPage<Pull>
    let issueContributions: ContributionPage<Issue>
    struct CommitGroup: Decodable {
        let repository: ContributionRepository
        let contributions: ContributionPage<Commit>
    }
    struct Commit: Decodable { let occurredAt: Date; let commitCount: Int; let url: URL }
    struct Item: Decodable {
        let id: String; let title: String; let url: URL; let repository: ContributionRepository
    }
    struct Pull: Decodable { let occurredAt: Date; let pullRequest: Item }
    struct Issue: Decodable { let occurredAt: Date; let issue: Item }
}

struct NormalizedContributions {
    var activities: [DevelopmentActivity] = []
    var repositories: [String: ContributionRepository] = [:]
    var restricted = false

    static func stableID(_ value: String) -> UUID {
        let bytes = Array(SHA256.hash(data: Data(value.utf8)).prefix(16))
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
    mutating func append(_ collection: ContributionCollection) {
        restricted = restricted || collection.restrictedContributionsCount > 0
        for group in collection.commitContributionsByRepository {
            let repo = group.repository
            repositories[repo.nameWithOwner] = repo
            for commit in group.contributions.nodes.compactMap({ $0 }) {
                activities.append(DevelopmentActivity(
                    id: Self.stableID("commit:\(repo.id):\(commit.occurredAt.timeIntervalSince1970)"),
                    kind: .commit, repositoryName: repo.nameWithOwner,
                    title: "\(commit.commitCount) commits · 일별 기여", occurredAt: commit.occurredAt,
                    url: commit.url, count: commit.commitCount, isDailyAggregate: true))
            }
        }
        for pull in collection.pullRequestContributions.nodes.compactMap({ $0 }) {
            append(pull.pullRequest, kind: .pullRequest, date: pull.occurredAt)
        }
        for issue in collection.issueContributions.nodes.compactMap({ $0 }) {
            append(issue.issue, kind: .issue, date: issue.occurredAt)
        }
        activities = Array(Dictionary(activities.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }).values)
            .sorted { $0.occurredAt > $1.occurredAt }
    }
    private mutating func append(_ item: ContributionCollection.Item, kind: ActivityKind, date: Date) {
        repositories[item.repository.nameWithOwner] = item.repository
        activities.append(DevelopmentActivity(id: Self.stableID(item.id), kind: kind,
            repositoryName: item.repository.nameWithOwner, title: item.title, occurredAt: date, url: item.url))
    }
    func projects(in interval: DateInterval) -> [RepositoryActivity] {
        let filtered = activities.filter { $0.occurredAt >= interval.start && $0.occurredAt < interval.end }
        return Dictionary(grouping: filtered, by: \.repositoryName).compactMap { name, entries in
            guard let repo = repositories[name] else { return nil }
            return RepositoryActivity(id: Self.stableID(repo.id), name: name,
                owner: String(name.split(separator: "/").first ?? ""), primaryLanguage: repo.primaryLanguage?.name ?? "—",
                summary: repo.description ?? "", weeklyCommitCount: entries.filter { $0.kind == .commit }.reduce(0) { $0 + $1.count },
                weeklyPullRequestCount: entries.filter { $0.kind == .pullRequest }.count,
                weeklyIssueCount: entries.filter { $0.kind == .issue }.count,
                progress: 0, recentActivities: entries)
        }.sorted { $0.name < $1.name }
    }
    func summary(for date: Date, calendar: Calendar = .current) -> DailyDevelopmentSummary {
        let interval = calendar.dateInterval(of: .day, for: date)!
        let items = activities.filter { $0.occurredAt >= interval.start && $0.occurredAt < interval.end }
        let commits = items.filter { $0.kind == .commit }.reduce(0) { $0 + $1.count }
        let pulls = items.filter { $0.kind == .pullRequest }.count
        let issues = items.filter { $0.kind == .issue }.count
        return DailyDevelopmentSummary(id: Self.stableID("day:\(interval.start)"), date: date,
            headline: items.isEmpty ? "기록된 기여가 없습니다" : "오늘의 개발 기록",
            narrative: "커밋 \(commits)개, 새 PR \(pulls)개, 새 issue \(issues)개를 기록했습니다.",
            activities: items, repositories: projects(in: interval), isSample: false,
            notice: restricted ? "조회 기간에 접근할 수 없는 비공개 기여가 있습니다. 표시된 통계에서 제외됩니다." : nil)
    }
}

actor GitHubContributionsService: GitHubActivityServicing {
    let client: GitHubGraphQL
    init(token: String) { client = GitHubGraphQL(token: token) }
    func fetchTodaySummary() async throws -> DailyDevelopmentSummary {
        let date = Date()
        return try await fetch(interval: Calendar.current.dateInterval(of: .day, for: date)!).summary(for: date)
    }
    func fetchCalendarDays(containing date: Date) async throws -> [CalendarDayActivity] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: date)!
        let values = try await fetch(interval: interval)
        return (calendar.range(of: .day, in: .month, for: date)!).map { day in
            let date = calendar.date(byAdding: .day, value: day - 1, to: interval.start)!
            return CalendarDayActivity(id: NormalizedContributions.stableID("day:\(date)"), date: date,
                                       summary: values.summary(for: date))
        }
    }
    func fetchRepositories() async throws -> [RepositoryActivity] {
        let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!
        return try await fetch(interval: interval).projects(in: interval)
    }
    private func fetch(interval: DateInterval) async throws -> NormalizedContributions {
        guard interval.start < Date() else { return NormalizedContributions() }
        return try await fetch(from: interval.start, to: min(interval.end.addingTimeInterval(-1), Date()))
    }
    // Repository groups lack a cursor; narrow the window only if that limit is exceeded.
    private func fetch(from: Date, to: Date) async throws -> NormalizedContributions {
        struct Response: Decodable {
            let viewer: Viewer
            struct Viewer: Decodable { let contributionsCollection: ContributionCollection }
        }
        let formatter = ISO8601DateFormatter()
        let response: Response = try await client.execute(Self.query, variables: [
            "from": formatter.string(from: from), "to": formatter.string(from: to)])
        let collection = response.viewer.contributionsCollection
        if collection.totalRepositoriesWithContributedCommits > 100 ||
            collection.commitContributionsByRepository.contains(where: { $0.contributions.pageInfo.hasNextPage }) {
            guard to.timeIntervalSince(from) > 2 else {
                throw GitHubFailure.message("이 시간대의 활동이 조회 한도를 초과했습니다. 전체 통계를 표시할 수 없습니다.")
            }
            let middle = Date(timeIntervalSince1970: floor((from.timeIntervalSince1970 + to.timeIntervalSince1970) / 2))
            var left = try await fetch(from: from, to: middle)
            let right = try await fetch(from: middle.addingTimeInterval(1), to: to)
            left.activities += right.activities
            left.activities = Array(Dictionary(left.activities.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a }).values)
                .sorted { $0.occurredAt > $1.occurredAt }
            left.repositories.merge(right.repositories, uniquingKeysWith: { a, _ in a })
            left.restricted = left.restricted || right.restricted
            return left
        }
        var result = NormalizedContributions()
        result.append(collection)
        var pullPage = collection.pullRequestContributions.pageInfo
        var issuePage = collection.issueContributions.pageInfo
        var seen = Set<String>()
        while pullPage.hasNextPage || issuePage.hasNextPage {
            try Task.checkCancellation()
            var variables = ["from": formatter.string(from: from), "to": formatter.string(from: to)]
            if pullPage.hasNextPage {
                guard let cursor = pullPage.endCursor else { throw URLError(.cannotParseResponse) }
                variables["pullCursor"] = cursor
            }
            if issuePage.hasNextPage {
                guard let cursor = issuePage.endCursor else { throw URLError(.cannotParseResponse) }
                variables["issueCursor"] = cursor
            }
            let key = (variables["pullCursor"] ?? "") + ":" + (variables["issueCursor"] ?? "")
            guard seen.insert(key).inserted else { throw URLError(.cannotParseResponse) }
            let page: Response = try await client.execute(Self.query, variables: variables)
            let next = page.viewer.contributionsCollection
            result.append(next)
            if pullPage.hasNextPage { pullPage = next.pullRequestContributions.pageInfo }
            if issuePage.hasNextPage { issuePage = next.issueContributions.pageInfo }
        }
        return result
    }
    static let query = """
    query($from: DateTime!, $to: DateTime!, $pullCursor: String, $issueCursor: String) {
      viewer {
        contributionsCollection(from: $from, to: $to) {
          totalRepositoriesWithContributedCommits restrictedContributionsCount
          commitContributionsByRepository(maxRepositories: 100) {
            repository { ...Repo }
            contributions(first: 100) { nodes { occurredAt commitCount url } pageInfo { hasNextPage } }
          }
          pullRequestContributions(first: 100, after: $pullCursor, excludeFirst: false, excludePopular: false) {
            nodes { occurredAt pullRequest { id title url repository { ...Repo } } }
            pageInfo { hasNextPage endCursor }
          }
          issueContributions(first: 100, after: $issueCursor, excludeFirst: false, excludePopular: false) {
            nodes { occurredAt issue { id title url repository { ...Repo } } }
            pageInfo { hasNextPage endCursor }
          }
        }
      }
    }
    fragment Repo on Repository { id nameWithOwner description primaryLanguage { name } }
    """
}
