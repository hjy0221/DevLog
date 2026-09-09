import Foundation

final class StubProtocol: URLProtocol {
    static var status = 200
    static var body = Data()
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@main struct ContributionsChecks {
    static func main() async throws {
        let fixture = """
        {
          "totalRepositoriesWithContributedCommits":1,
          "restrictedContributionsCount":2,
          "commitContributionsByRepository":[{
            "repository":{"id":"r1","nameWithOwner":"alice/app","description":null,"primaryLanguage":{"name":"Swift"}},
            "contributions":{"nodes":[{"occurredAt":"2026-09-09T12:00:00Z","commitCount":7,"url":"https://github.com/alice/app/commits"}],"pageInfo":{"hasNextPage":false}}
          }],
          "pullRequestContributions":{"nodes":[{"occurredAt":"2026-09-09T13:00:00Z","pullRequest":{"id":"p1","title":"Add login","url":"https://github.com/alice/app/pull/1","repository":{"id":"r1","nameWithOwner":"alice/app","description":null,"primaryLanguage":null}}}],"pageInfo":{"hasNextPage":false}},
          "issueContributions":{"nodes":[null,{"occurredAt":"2026-09-09T14:00:00Z","issue":{"id":"i1","title":"Bug","url":"https://github.com/bob/app/issues/1","repository":{"id":"r2","nameWithOwner":"bob/app","description":null,"primaryLanguage":null}}}],"pageInfo":{"hasNextPage":false}}
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let collection = try decoder.decode(ContributionCollection.self, from: Data(fixture.utf8))
        var normalized = NormalizedContributions()
        normalized.append(collection)
        normalized.append(collection)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = ISO8601DateFormatter().date(from: "2026-09-09T12:00:00Z")!
        let summary = normalized.summary(for: date, calendar: calendar)
        precondition(summary.activities.count == 3, "deduplication")
        precondition(summary.commitCount == 7, "aggregate commit count")
        precondition(summary.pullRequestCount == 1 && summary.issueCount == 1)
        precondition(summary.repositoryCount == 2, "owner-qualified names")
        precondition(!summary.isSample && summary.notice != nil)
        precondition(summary.activities.allSatisfy { $0.url != nil })
        precondition(normalized.summary(for: date.addingTimeInterval(86400), calendar: calendar).commitCount == 0)
        precondition(normalized.projects(in: calendar.dateInterval(of: .day, for: date)!).count == 2)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubProtocol.self]
        let session = URLSession(configuration: config)
        let client = GitHubGraphQL(token: "test-only", session: session)
        StubProtocol.body = Data(#"{"data":{"viewer":{"login":"alice"}}}"#.utf8)
        let login = try await client.viewer()
        precondition(login == "alice")
        StubProtocol.status = 401
        do { _ = try await client.viewer(); fatalError("401 accepted") }
        catch { precondition(error.localizedDescription.contains("만료")) }
        StubProtocol.status = 200
        StubProtocol.body = Data(#"{"data":{"viewer":{"login":"alice"}},"errors":[{"message":"denied"}]}"#.utf8)
        do { _ = try await client.viewer(); fatalError("partial errors accepted") }
        catch { precondition(error is GitHubFailure) }
        let oauth = GitHubDeviceOAuth(session: session)
        StubProtocol.body = Data(#"{"error":"access_denied"}"#.utf8)
        let code = GitHubDeviceOAuth.Code(device_code: "test", user_code: "TEST", verification_uri: URL(string: "https://github.com/login/device")!, expires_in: 10, interval: 1)
        do { _ = try await oauth.waitForToken(code: code, clientID: "test"); fatalError("denial accepted") }
        catch { precondition(error.localizedDescription.contains("취소")) }
        let task = Task { try await oauth.waitForToken(code: code, clientID: "test") }
        task.cancel()
        do { _ = try await task.value; fatalError("cancellation ignored") }
        catch { precondition(error is CancellationError) }
        print("PASS: normalization, aggregate counts, deduplication, dates, repository identity, HTTP/GraphQL errors, OAuth denial/cancellation")
        let store = GitHubTokenStore(service: "com.hajaeyun.DevLog.tests." + UUID().uuidString)
        defer { try? store.delete() }
        try store.save("test-token-one")
        let first = try store.read()
        precondition(first == "test-token-one")
        try store.save("test-token-two")
        let updated = try store.read()
        precondition(updated == "test-token-two")
        try store.delete()
        let removed = try store.read()
        precondition(removed == nil)
        print("PASS: isolated Keychain save, read, update, delete")
    }
}
