import Foundation

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published private(set) var days: [CalendarDayActivity] = []
    @Published var selectedDate = Date()
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let activityService: GitHubActivityServicing

    var selectedDay: CalendarDayActivity? {
        days.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    init(activityService: GitHubActivityServicing) {
        self.activityService = activityService
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            days = try await activityService.fetchCalendarDays(containing: selectedDate)
        } catch {
            days = []
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func select(_ day: CalendarDayActivity) {
        selectedDate = day.date
    }

    func moveMonth(by offset: Int) async {
        guard !isLoading,
              let start = Calendar.current.dateInterval(of: .month, for: selectedDate)?.start,
              let next = Calendar.current.date(byAdding: .month, value: offset, to: start) else { return }
        selectedDate = next
        days = []
        await load()
    }
}
