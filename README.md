# DevLog

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
