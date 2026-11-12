# DevLog

[日本語](README.ja.md) · [English](README.md) · [한국어](README.ko.md)

This is a SwiftUI iOS app that organizes GitHub development activities into a development log on the Today, Calendar, and Projects screens.

## Current features

- Today: Summary of today’s commits, PRs, issues, repository numbers and activities
- Calendar: Activity amount and activity list by date
- Projects: Recent activities and weekly statistics by repository
- GitHub login: Device Flow, GitHub app launch first, web fallback
- Secure token storage: iOS Keychain
- Real data: GraphQL `ContributionsCollection`
- Offline development: mock data before connecting to GitHub
- Development notes by date: saved based on `AppStorage`

## run

1. Open `DevLog.xcodeproj` in Xcode.
2. Select your Apple Team under Signing & Capabilities.
3. Select iPhone or iOS Simulator as the launch target.
4. Click Build and Run.

Your project's GitHub OAuth Client ID is included in `Info.plist` via the `GITHUB_OAUTH_CLIENT_ID` build settings. The Client Secret is not included in the iOS app.

## GitHub connection

Create an OAuth App in GitHub Developer Settings and enable Device Flow. Enter your Client ID into Xcode Build Settings, then press `GitHub로 로그인` in the app's Account tab.

The verification code will be displayed in DevLog. Just open `github.com/login/device` in the GitHub app or on the web and enter the code. Once approved, save the token to Keychain and load the actual activity.

For detailed scope and permissions, please refer to [GitHub Connection Documentation](outputs/GitHub-Connection.md).

## Structure

```text
DevLog/
  App/                  앱 진입점과 탭 구조
  Domain/               활동, 요약, 저장소 모델
  Services/             GitHub API, OAuth, Keychain, mock 서비스
  DesignSystem/         토큰, 공통 컴포넌트, 화면 패턴
  Features/             Today, Calendar, Projects, Account
Tests/                  GraphQL 정규화와 인증 오류 검증
```

The screen relies on the `GitHubActivityServicing` protocol. The actual GitHub service and mock service can be replaced, allowing UI testing and offline development.

## Data normalization

Convert daily commit aggregation by repository, created PRs, and created issues from `ContributionsCollection` to `DevelopmentActivity`. The activity includes the repository's `owner/name`, the time it occurred, the source URL, and the activity type. Commits maintain the daily quantity provided by the GitHub API and do not scale with individual commit titles.

## Verification

```sh
swiftc -parse-as-library \
  DevLog/Domain/GitHubModels.swift \
  DevLog/Services/GitHubActivityServicing.swift \
  DevLog/Services/GitHubAuthentication.swift \
  DevLog/Services/GitHubContributionsService.swift \
  Tests/ContributionsChecks.swift \
  -o work/contributions-checks
work/contributions-checks

xcodebuild -project DevLog.xcodeproj \
  -scheme DevLog \
  -destination 'generic/platform=iOS Simulator' build
```

Validation code verifies aggregate counts, date separation, deduplication, storage identification, HTTP/GraphQL errors, OAuth revocation, and Keychain save/update/delete.

## Next steps

- Refresh token renewal of expiring GitHub tokens
- SwiftData-based activity cache and offline playback
- Technology stack and weekly trends based on GitHub API responses
- View actual commit details and summarize changed files
- Portfolio document export

## License

MVP of the personal development history app. You must follow the respective terms and policies of the Apple SDK and GitHub API you use.
