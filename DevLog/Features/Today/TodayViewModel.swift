import Foundation

@MainActor
final class TodayViewModel: ObservableObject {
    @Published private(set) var summary: DailyDevelopmentSummary?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let activityService: GitHubActivityServicing

    init(activityService: GitHubActivityServicing) {
        self.activityService = activityService
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            summary = try await activityService.fetchTodaySummary()
        } catch {
            summary = nil
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
