import SwiftUI
import SafariServices

@MainActor
final class GitHubConnection: ObservableObject {
    @Published private(set) var service: GitHubActivityServicing = MockGitHubActivityService()
    @Published private(set) var login: String?
    @Published private(set) var revision = UUID()
    @Published var error: String?
    @Published var code: GitHubDeviceOAuth.Code?
    @Published var busy = false
    @Published var showsAuthorization = false

    private var task: Task<Void, Never>?
    private let store = GitHubTokenStore()
    private var didRestore = false

    func restore() async {
        guard !didRestore else { return }
        didRestore = true
        do {
            if let token = try store.read() { try await activate(token, save: false) }
        } catch { self.error = error.localizedDescription }
    }
    private func activate(_ token: String, save: Bool = true) async throws {
        let login = try await GitHubGraphQL(token: token).viewer()
        try Task.checkCancellation()
        if save { try store.save(token) }
        self.login = login
        service = GitHubContributionsService(token: token)
        revision = UUID()
    }
    func connect() {
        guard !busy else { return }
        let configured = Bundle.main.object(forInfoDictionaryKey: "GitHubOAuthClientID") as? String ?? ""
        let clientID = configured.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clientID.isEmpty, !clientID.contains("$(") else {
            error = "GitHub 로그인이 아직 준비되지 않았습니다. 잠시 후 다시 시도해 주세요."
            return
        }
        error = nil
        busy = true
        task = Task {
            defer { busy = false; showsAuthorization = false; code = nil }
            do {
                let oauth = GitHubDeviceOAuth()
                let code = try await oauth.requestCode(clientID: clientID)
                try Task.checkCancellation()
                self.code = code
                await openAuthorization()
                try Task.checkCancellation()
                let token = try await oauth.waitForToken(code: code, clientID: clientID)
                try await activate(token)
            } catch is CancellationError {
            } catch { self.error = error.localizedDescription }
        }
    }
    func openAuthorization() async {
        guard let currentCode = code else { return }
        _ = await UIApplication.shared.open(
            URL(string: "https://github.com/login/device")!,
            options: [.universalLinksOnly: true])
        guard !Task.isCancelled, code?.device_code == currentCode.device_code else { return }
        // GitHub Mobile may open successfully without displaying the device code.
        // Keep the code visible in DevLog so the user can copy it there.
        showsAuthorization = true
    }
    func cancel() { task?.cancel() }
    func disconnect() {
        cancel()
        do {
            try store.delete()
            login = nil
            service = MockGitHubActivityService()
            revision = UUID()
            error = nil
        } catch { self.error = error.localizedDescription }
    }
}

struct GitHubAccountView: View {
    @EnvironmentObject private var connection: GitHubConnection
    var body: some View {
        NavigationStack {
            Form {
                if let login = connection.login {
                    Section("GitHub") {
                        Label(login, systemImage: "person.crop.circle")
                        Text("공개 저장소의 기여를 연결했습니다.")
                        Button("이 기기에서 연결 해제", role: .destructive) { connection.disconnect() }
                        Link("GitHub 앱 권한 관리", destination: URL(string: "https://github.com/settings/applications")!)
                    }
                } else {
                    Section {
                        Button { connection.connect() } label: {
                            Label("GitHub로 로그인", systemImage: "person.crop.circle.badge.checkmark")
                        }
                        .disabled(connection.busy)
                    } header: {
                        Text("GitHub 연결")
                    } footer: {
                        Text("GitHub에서 로그인하고 공개 개발 활동의 연결을 승인합니다.")
                    }
                }
                if let code = connection.code {
                    Section("GitHub 인증") {
                        Text(code.user_code).font(.title.monospaced()).textSelection(.enabled)
                        Button("GitHub 인증 계속하기") {
                            Task { await connection.openAuthorization() }
                        }
                        Button("웹에서 인증하기") { connection.showsAuthorization = true }
                        ProgressView("승인 대기 중")
                        Button("취소", role: .cancel) { connection.cancel() }
                    }
                } else if connection.busy {
                    ProgressView("연결 중")
                }
                if let error = connection.error {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("계정")
            .sheet(isPresented: $connection.showsAuthorization) {
                if let code = connection.code {
                    GitHubAuthorizationSheet(code: code.user_code)
                }
            }
        }
    }
}

private struct GitHubAuthorizationSheet: View {
    let code: String
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GitHub 인증 코드").font(.caption)
                    Text(code).font(.title3.monospaced().bold()).textSelection(.enabled)
                }
                Spacer()
                Button {
                    UIPasteboard.general.setItems([[UIPasteboard.typeAutomatic: code]],
                        options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(300)])
                    copied = true
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(copied ? "코드 복사됨" : "인증 코드 복사")
                .help("인증 코드 복사")
            }
            .padding()
            Divider()
            GitHubSignInBrowser()
        }
        .presentationDragIndicator(.visible)
    }
}

private struct GitHubSignInBrowser: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: URL(string: "https://github.com/login/device")!)
    }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
