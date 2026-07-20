# RecaLoop Agent Rules

## UI変更時の必須ルール

UIを追加・変更する場合は、作業前に必ず`UI_STRUCTURE_GUIDE.md`を確認してください。

- 画面固有・コンポーネント固有スタイルは、原則としてSCSS Modulesで管理する
- TSXとSCSSの対応が分かるファイル配置にする
- class名は画面上の役割が分かる名前にする
- `globals.css`へページ固有スタイルを増やしすぎない
- 共通コンポーネントのvariantは必要最低限にする
- 見た目だけのために不要なラッパーを増やさない
- 構造に影響する変更を行った場合は`UI_STRUCTURE_GUIDE.md`も更新する

既存のSupabase処理、認証、学習ロジック、ルーティングをUI整理のついでに変更しないでください。
