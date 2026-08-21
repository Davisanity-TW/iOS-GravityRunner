---
name: ios-gravityrunner-commit-log
description: >
  專用於 iOS-GravityRunner 原生 SwiftUI／SpriteKit 專案。開始任何新 backlog 前，先檢查 Issue & Expectation Tracker 是否有更高優先級的 Issue／Exception；每當 backlog 項目完成或使用者列出的 bug/issue 修正並驗證後，建立獨立 Git commit、自動 push 到目前 origin 分支、在對話中以 100 字內繁體中文說明改動，並將 SHA、日期與 80 字內、以遊戲玩家易懂角度撰寫的繁體中文摘要追加到指定 Notion commit 表格；Notion 更新成功後原文輸出該摘要。
---

# iOS GravityRunner Commit Log

## 固定目標

- Git repository：`https://github.com/Davisanity-TW/iOS-GravityRunner.git`
- Notion page：`https://app.notion.com/p/Repo-commit-3c34461aa44e80dca41fea79f30add40?source=copy_link`
- Notion page ID：`3c34461aa44e80dca41fea79f30add40`
- Issue／Exception Tracker：`https://app.notion.com/p/3c34461aa44e8013bf55ffc28c6d93b2?v=5344461aa44e83cfa15908f476a9700a&source=copy_link`
- 使用 Conventional Commits；Notion「說明」最多 80 個中文字，優先描述玩家能感受到的功能、操作、畫面或遊戲體驗，避免只寫技術實作名詞；對話說明 100 字內繁體中文。

## 開始新 backlog 前置檢查

每次準備開始一個新的 backlog 項目時，必須先 fetch 上方的 **Gravity Runner－Issue & Expectation Tracker**，檢查所有尚未完成的 Issue／Exception 及其 Priority、Severity、Blocker 或截止資訊。

1. 若存在比目前 backlog 更優先、會阻擋開發或影響玩家體驗的 Issue／Exception，立即暫停原 backlog，優先處理該 Issue／Exception。
2. 若沒有更高優先級項目，才依 Task Board 的順序開始原定 backlog。
3. 將本次檢查結果簡短記在進度說明；若優先級無法判定，先回報判斷依據，不要自行跳過。

## 收尾流程

只有 backlog／bug／issue 已完成且驗證通過時執行：

1. 確認 repo 根目錄與 `origin` 指向 `Davisanity-TW/iOS-GravityRunner`。
2. 只 stage 本次變更，檢查 `git diff --cached`，不得納入 unrelated 變更。
3. 執行相稱驗證；原生專案優先使用 `xcodebuild -project ios/GravityRunner/GravityRunner.xcodeproj -scheme GravityRunner -sdk iphonesimulator build` 與測試。
4. 建立一次獨立 Conventional Commits commit，不 amend。
5. 確認目前分支後執行 `git push origin HEAD`；禁止 force push。
6. 用 `git log -1 --format='%H%n%h%n%ad%n%s' --date=short` 取得資料。
7. 先 fetch Notion page；首次使用或不確定語法時讀取 `notion://docs/enhanced-markdown-spec`。在既有表格追加一列；若沒有表格，建立日期、Commit、說明三欄表格。避免同一 SHA 重複記錄。說明應讓遊戲玩家看懂，例如「玩家現在可以拖曳地圖查看關卡，並用雙指縮放尋找細節」，不要只寫「新增 EditorCanvas pan／zoom 狀態」。
8. 再次 fetch Notion 確認新列存在，取得該列「說明」的原文；僅在 push 成功且 Notion 更新、驗證都成功後，在對話中逐字輸出 `Notion 說明：<原文>`，不可改寫或省略。
9. 最後回報 commit SHA、push、驗證、Notion 狀態，以及 100 字內繁中改動說明；同時保留上一點的 Notion 說明原文輸出。

## 失敗處理

- repo、stage 範圍或驗證不明：停止並回報。
- push 失敗：保留本地 commit，回報 SHA 與待重試的 push，不重複 commit。
- Notion 寫入失敗：保留 commit，回報待補登 SHA，不捏造成功。
- 不因純討論或未完成半成品 commit。
