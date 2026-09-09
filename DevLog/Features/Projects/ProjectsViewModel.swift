import Foundation

@MainActor
final class ProjectsViewModel: ObservableObject {
    @Published private(set) var repositories: [RepositoryActivity] = []
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
            repositories = try await activityService.fetchRepositories()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
