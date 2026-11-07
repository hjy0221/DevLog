# DevLog

[日本語](https://github.com/hjy0221/DevLog#%E6%97%A5%E6%9C%AC%E8%AA%9E) · [English](https://github.com/hjy0221/DevLog#english) · [한국어](https://github.com/hjy0221/DevLog#%ED%95%9C%EA%B5%AD%EC%96%B4)

## 日本語

GitHub開発活動をToday、Calendar、Projects画面の開発日誌にまとめるSwiftUI iOSアプリです。

## 現在の機能

- Today: 今日のコミット、PR、issue、リポジトリ数と活動のまとめ
- カレンダー：日付別の活動量と活動のリスト
- プロジェクト：リポジトリ別の最近の活動と週間統計
- GitHub ログイン: Device Flow、GitHub アプリ優先実行、Web fallback
- 安全なトークンアーカイブ：iOS Keychain
- 実際のデータ：GraphQL `ContributionsCollection`
- オフライン開発：GitHub接続前のmockデータ
- 日付別開発ノート：`AppStorage`ベースの保存

## 実行

1. Xcodeで`DevLog.xcodeproj`を開きます。
2. Signing & Capabilitiesで、自分のApple Teamを選択します。
3. iPhoneまたはiOS Simulatorを実行先として選択します。
4. Build and Run を押します。

プロジェクトのGitHub OAuth Client IDは、`GITHUB_OAUTH_CLIENT_ID`ビルド設定を介して`Info.plist`に含まれています。 Client Secret は iOS アプリには入れません。

## GitHub接続

GitHub Developer Settings で OAuth App を作成し、Device Flow を有効にします。 Client IDをXcode Build Settingsに入力し、アプリのアカウントタブで`GitHub로 로그인`をクリックします。

認証コードはDevLogに表示されます。 GitHubアプリまたはWebで`github.com/login/device`を開き、コードを入力するだけです。承認が完了したら、トークンをKeychainに保存して実際のアクティビティを呼び出します。

詳細な範囲と権限については、[GitHub接続ドキュメント]（outputs/GitHub-Connection.md）を参照してください。

## 構造

```text
DevLog/
  App/                  앱 진입점과 탭 구조
  Domain/               활동, 요약, 저장소 모델
  Services/             GitHub API, OAuth, Keychain, mock 서비스
  DesignSystem/         토큰, 공통 컴포넌트, 화면 패턴
  Features/             Today, Calendar, Projects, Account
Tests/                  GraphQL 정규화와 인증 오류 검증
```

画面は`GitHubActivityServicing`プロトコルに依存します。実際のGitHubサービスとmockサービスを交換でき、UIテストとオフライン開発が可能です。

## データの正規化

`ContributionsCollection`は、デポごとの毎日のコミット集計、生成されたPR、生成されたissueを`DevelopmentActivity`に変換します。アクティビティには、リポジトリの`owner/name`、発生時刻、原文URL、アクティビティの種類が含まれます。コミットはGitHub APIが提供する毎日の数量を保持し、個々のコミットタイトルには拡張しません。

## 検証

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

検証コードは、集計数、日付分離、重複排除、リポジトリ識別、HTTP/GraphQL エラー、OAuth キャンセル、Keychain 保存・更新・削除を確認します。

## 次のステップ

- 期限切れのGitHubトークンのリフレッシュトークンの更新
- SwiftDataベースのアクティビティキャッシュとオフライン再生
- GitHub APIレスポンスベースの技術スタックと毎週の傾向
- 実際のコミット詳細照会と変更ファイルの要約
- ポートフォリオ文書のエクスポート

## ライセンス

個人開発記録アプリのMVPです。使用したApple SDKとGitHub APIの各条件とポリシーに従う必要があります。

## English

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

## 한국어

GitHub 개발 활동을 Today, Calendar, Projects 화면의 개발 일지로 정리하는 SwiftUI iOS 앱입니다.

## 현재 기능

- Today: 오늘의 커밋, PR, issue, 저장소 수와 활동 요약
- Calendar: 날짜별 활동량과 활동 목록
- Projects: 저장소별 최근 활동과 주간 통계
- GitHub 로그인: Device Flow, GitHub 앱 우선 실행, 웹 fallback
- 안전한 토큰 보관: iOS Keychain
- 실제 데이터: GraphQL `ContributionsCollection`
- 오프라인 개발: GitHub 연결 전 mock 데이터
- 날짜별 개발 메모: `AppStorage` 기반 저장

## 실행

1. Xcode에서 `DevLog.xcodeproj`를 엽니다.
2. Signing & Capabilities에서 본인의 Apple Team을 선택합니다.
3. iPhone 또는 iOS Simulator를 실행 대상으로 선택합니다.
4. Build and Run을 누릅니다.

프로젝트의 GitHub OAuth Client ID는 `GITHUB_OAUTH_CLIENT_ID` 빌드 설정을 통해 `Info.plist`에 포함됩니다. Client Secret은 iOS 앱에 넣지 않습니다.

## GitHub 연결

GitHub Developer Settings에서 OAuth App을 만들고 Device Flow를 활성화합니다. Client ID를 Xcode Build Settings에 입력한 후 앱의 계정 탭에서 `GitHub로 로그인`을 누릅니다.

인증코드는 DevLog에 표시됩니다. GitHub 앱 또는 웹에서 `github.com/login/device`를 열고 코드를 입력하면 됩니다. 승인이 완료되면 토큰을 Keychain에 저장하고 실제 활동을 불러옵니다.

자세한 범위와 권한은 [GitHub 연결 문서](outputs/GitHub-Connection.md)를 참고하세요.

## 구조

```text
DevLog/
  App/                  앱 진입점과 탭 구조
  Domain/               활동, 요약, 저장소 모델
  Services/             GitHub API, OAuth, Keychain, mock 서비스
  DesignSystem/         토큰, 공통 컴포넌트, 화면 패턴
  Features/             Today, Calendar, Projects, Account
Tests/                  GraphQL 정규화와 인증 오류 검증
```

화면은 `GitHubActivityServicing` 프로토콜에 의존합니다. 실제 GitHub 서비스와 mock 서비스를 교체할 수 있어 UI 테스트와 오프라인 개발이 가능합니다.

## 데이터 정규화

`ContributionsCollection`에서 저장소별 일별 커밋 집계, 생성한 PR, 생성한 issue를 `DevelopmentActivity`로 변환합니다. 활동에는 저장소의 `owner/name`, 발생 시각, 원문 URL, 활동 종류가 포함됩니다. 커밋은 GitHub API가 제공하는 일별 수량을 유지하며 개별 커밋 제목으로 확장하지 않습니다.

## 검증

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

검증 코드는 집계 수, 날짜 분리, 중복 제거, 저장소 식별, HTTP/GraphQL 오류, OAuth 취소, Keychain 저장·갱신·삭제를 확인합니다.

## 다음 단계

- 만료되는 GitHub 토큰의 refresh token 갱신
- SwiftData 기반 활동 캐시와 오프라인 재생
- GitHub API 응답 기반 기술 스택과 주간 추세
- 실제 커밋 상세 조회와 변경 파일 요약
- 포트폴리오 문서 export

## 라이선스

개인 개발 기록 앱의 MVP입니다. 사용한 Apple SDK와 GitHub API의 각 약관 및 정책을 따라야 합니다.
