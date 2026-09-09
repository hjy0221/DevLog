import Foundation

protocol GitHubAPIClienting {
    func get<T: Decodable>(_ endpoint: GitHubEndpoint) async throws -> T
}

struct GitHubEndpoint {
    let path: String
    let queryItems: [URLQueryItem]

    init(path: String, queryItems: [URLQueryItem] = []) {
        self.path = path
        self.queryItems = queryItems
    }
}

struct GitHubAPIClient: GitHubAPIClienting {
    private let baseURL = URL(string: "https://api.github.com")!
    private let session: URLSession
    private let accessTokenProvider: () async -> String?

    init(
        session: URLSession = .shared,
        accessTokenProvider: @escaping () async -> String?
    ) {
        self.session = session
        self.accessTokenProvider = accessTokenProvider
    }

    func get<T: Decodable>(_ endpoint: GitHubEndpoint) async throws -> T {
        var components = URLComponents(
            url: baseURL.appending(path: endpoint.path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        if let token = await accessTokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}
