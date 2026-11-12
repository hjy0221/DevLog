# DevLog

[日本語](README.ja.md) · [English](README.md) · [한국어](README.ko.md)

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
