import SwiftUI

struct DevLogRootView: View {
    @StateObject private var connection = GitHubConnection()

    var body: some View {
        TabView {
            TodayView(viewModel: TodayViewModel(activityService: connection.service))
                .tabItem {
                    Label("Today", systemImage: "doc.text.magnifyingglass")
                }

            CalendarView(viewModel: CalendarViewModel(activityService: connection.service))
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            ProjectsView(viewModel: ProjectsViewModel(activityService: connection.service))
                .tabItem {
                    Label("Projects", systemImage: "folder")
                }
            GitHubAccountView()
                .tabItem { Label("계정", systemImage: "person.crop.circle") }
        }
        .id(connection.revision)
        .environmentObject(connection)
        .tint(DSColor.accent)
        .task { await connection.restore() }
    }
}
