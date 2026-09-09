# DevLog GitHub 연결

## 설정

Apple 계정 로그인은 iPhone 서명용입니다. GitHub 앱 연결은 별도입니다.

1. https://github.com/settings/developers 에서 본인 소유 OAuth App을 등록합니다.
2. 해당 앱의 Enable Device Flow를 켭니다.
3. 개발자가 Xcode Target의 Build Settings에서 GITHUB_OAUTH_CLIENT_ID에 Client ID를 설정하고 빌드합니다. 일반 사용자 화면에는 등록 정보 입력란이 없습니다.
4. DevLog 계정 탭에서 GitHub로 로그인을 누릅니다. iOS Universal Link로 GitHub 앱을 먼저 열고, 인증 경로를 처리할 앱이 없으면 내장 Safari 인증창으로 전환합니다. 표시된 코드를 GitHub 인증 페이지에 입력하고 요청 권한을 확인해 승인합니다.
5. 앱이 승인을 감지하면 Today, Calendar, Projects가 실제 데이터로 전환됩니다.

Client Secret은 앱에 넣지 않습니다. 토큰은 기기 잠금 해제 시에만 읽을 수 있는 Keychain에 저장하며, 다른 기기로 동기화하지 않습니다.
Client ID는 비밀이 아니므로 개발자가 앱 빌드 설정에 보관합니다. hjy0221 소유의 DevLog OAuth App 등록과 Device Flow 활성화를 완료했으며 Client ID를 Debug/Release에 적용했습니다. Info.plist에 빌드 설정을 치환해 포함합니다. 이 기기에서 연결 해제하면 로컬 토큰을 삭제합니다.
GitHub 측 권한까지 철회하려면 계정 화면의 GitHub 앱 권한 관리 링크를 사용합니다.

앱 설치 여부만으로 GitHub 앱 안에서 인증이 완료됨을 보장하지는 않습니다. GitHub와 iOS가 해당 Universal Link를 처리해야 합니다. 앱이 열려도 인증을 지원하지 않는 경우 DevLog의 웹에서 인증하기로 계속할 수 있습니다. GitHub 앱 로그인 세션이나 토큰을 직접 가져오지는 않습니다. 앱에서 승인한 뒤 DevLog로 돌아오면 진행 중인 인증 확인이 재개됩니다.

## 현재 수집 범위

- read:user 권한을 요청합니다. repo 권한은 요청하지 않습니다.
- ContributionsCollection의 저장소별 일별 커밋 수를 표시합니다. 개별 커밋 제목이나 전체 브랜치 이력은 수집하지 않습니다.
- PR과 issue는 생성 기여입니다. 병합, 종료, 댓글 이벤트 수가 아닙니다.
- 제목과 원문 링크를 제공하며 저장소는 owner/name으로 구분합니다.
- PR/issue 페이지를 끝까지 가져오고 안정적인 ID로 중복을 제거합니다.
- 접근할 수 없는 비공개 기여는 통계에 포함하지 않으며 일별 요약에 안내합니다.
- Projects는 이번 주 기여가 있는 저장소입니다. 전체 저장소 목록이나 완성도 추정치가 아닙니다.
- 요약 문장은 실제 집계에 기반한 템플릿입니다. AI가 코드를 분석한 설명은 아닙니다.
- 토큰 만료 시 다시 연결합니다. refresh token 자동 갱신은 아직 구현하지 않았습니다.

## 검증

실제 OAuth 승인 및 GraphQL 원격 응답 검증은 본인의 Client ID와 계정 승인이 필요합니다.
테스트 응답으로 집계 수, 날짜 분리, 중복 제거, 동일 이름의 서로 다른 저장소,
HTTP 401, GraphQL 부분 오류, OAuth 거절/취소, 별도 Keychain 항목의 저장/조회/갱신/삭제를 확인합니다.

프로젝트 루트에서:

```sh
swiftc -parse-as-library DevLog/Domain/GitHubModels.swift DevLog/Services/GitHubActivityServicing.swift DevLog/Services/GitHubAuthentication.swift DevLog/Services/GitHubContributionsService.swift Tests/ContributionsChecks.swift -o work/contributions-checks
work/contributions-checks
xcodebuild -project DevLog.xcodeproj -scheme DevLog -destination 'generic/platform=iOS Simulator' build
```

## 공식 문서

- https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps
- https://docs.github.com/en/graphql/reference/users
