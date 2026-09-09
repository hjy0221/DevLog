import Foundation
import Security

enum GitHubFailure: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let text) = self { return text }; return nil }
}

struct GitHubTokenStore {
    var service = "com.hajaeyun.DevLog.github"
    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: "oauth"]
    }
    func read() throws -> String? {
        var q = query
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw GitHubFailure.message("보안 저장소를 열 수 없습니다. 기기를 잠금 해제해 주세요.")
        }
        return String(data: data, encoding: .utf8)
    }
    func save(_ token: String) throws {
        let data = Data(token.utf8)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var q = query
            q[kSecValueData as String] = data
            q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            guard SecItemAdd(q as CFDictionary, nil) == errSecSuccess else {
                throw GitHubFailure.message("토큰을 안전하게 저장하지 못했습니다.")
            }
        } else if status != errSecSuccess {
            throw GitHubFailure.message("토큰을 안전하게 저장하지 못했습니다.")
        }
    }
    func delete() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw GitHubFailure.message("연결 정보를 삭제하지 못했습니다.")
        }
    }
}

struct GitHubDeviceOAuth {
    struct Code: Decodable {
        let device_code: String
        let user_code: String
        let verification_uri: URL
        let expires_in: Int
        let interval: Int
    }
    struct Token: Decodable {
        let access_token: String?
        let error: String?
    }
    let session: URLSession
    init(session: URLSession = .shared) { self.session = session }

    func requestCode(clientID: String) async throws -> Code {
        try await post("device/code", values: ["client_id": clientID, "scope": "read:user"])
    }
    func waitForToken(code: Code, clientID: String) async throws -> String {
        let deadline = Date().addingTimeInterval(Double(code.expires_in))
        var interval = max(1, code.interval)
        while Date() < deadline {
            try await Task.sleep(for: .seconds(interval))
            try Task.checkCancellation()
            let reply: Token = try await post("oauth/access_token", values: [
                "client_id": clientID, "device_code": code.device_code,
                "grant_type": "urn:ietf:params:oauth:grant-type:device_code"])
            if let token = reply.access_token, !token.isEmpty { return token }
            switch reply.error {
            case "authorization_pending": continue
            case "slow_down": interval += 5
            case "access_denied": throw GitHubFailure.message("GitHub 연결을 취소했습니다.")
            case "expired_token": throw GitHubFailure.message("인증 코드가 만료되었습니다. 다시 연결해 주세요.")
            default: throw GitHubFailure.message("GitHub 인증을 완료하지 못했습니다. 앱 등록 설정을 확인해 주세요.")
            }
        }
        throw GitHubFailure.message("인증 코드가 만료되었습니다. 다시 연결해 주세요.")
    }
    private func post<T: Decodable>(_ path: String, values: [String: String]) async throws -> T {
        var request = URLRequest(url: URL(string: "https://github.com/login/\(path)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(values)
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw GitHubFailure.message("GitHub 인증 서버에 연결할 수 없습니다.")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
