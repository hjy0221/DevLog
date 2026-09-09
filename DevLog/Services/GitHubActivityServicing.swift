import Foundation

protocol GitHubActivityServicing {
    func fetchTodaySummary() async throws -> DailyDevelopmentSummary
    func fetchCalendarDays(containing date: Date) async throws -> [CalendarDayActivity]
    func fetchRepositories() async throws -> [RepositoryActivity]
}
