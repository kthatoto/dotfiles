# Codex 併用構成 監査レポート（2026-07-24）

## 結論

**この構成は基本設計としては健全で、このまま使い始めてよい。ただし使う前に直すべき項目が 3 件、
最優先で検証すべき未検証事項が 1 件ある。**

- 基本設計（実体は `~/.claude` 側に置き、Codex へは skill 単位の symlink / AGENTS.md は dotfiles 実体 + Claude 側 @import）は妥当。
  `@~/dotfiles/ai/AGENTS.md` の import 記法は **Claude Code で実際に解決されることを本セッションで確認済み**
  （システムが AGENTS.md の内容を読み込んでいた）。
- sync.sh はサンドボックス（fake HOME）で実際に実行して検証した。冪等性・リネーム追従・実体ディレクトリ不干渉は確認できたが、
  **フェイルオープンな壊れ方が 3 パターン実証できた**（後述）。
- 一方で、**「Codex が `~/.agents/skills` を読む」という構成全体の前提そのものが未検証**（codex login 未実行のため）。
  ここが違っていたら skill 共有は丸ごと空振りになるので、login 後の最初の確認事項にすること。
- 監査の副産物として、今回の構成と無関係に壊れていた既存資産（rules のリンク切れ、gstack 参照の腐敗、
  settings.json のデフォルトモデル書き換わり）が複数見つかった。

---

## 今すぐ直すべき（3件）

### 1. デフォルトモデルが Fable に書き換わっている

- **対象**: `~/.claude/settings.json:166` / `~/.claude/CLAUDE.md:8`
- **問題**: settings.json の model が `"claude-fable-5[1m]"` になっている。CLAUDE.md:8 の「デフォルトは Opus（settings.json で設定、fast mode 有効）」と矛盾。
  本日この監査のために `/model` で Fable に切り替えた際、「新セッションのデフォルト」として保存されたのが原因（切替時の表示で確認）。
- **失敗シナリオ**: 明日以降の全セッションが黙って Fable で起動し、日常タスク（Opus 想定）のコストが跳ね上がる。コスト削減という Codex 併用の目的と真逆。
- **直し方**: 監査確認後に `/model` で Opus に戻す（「デフォルトとして保存」される状態で）。

### 2. sync.sh: 除外リストが読めないと全 skill が黙って Codex に共有される（フェイルオープン）

- **対象**: `~/dotfiles/ai/sync.sh:27-33`
- **問題**: `claude-only.txt` が存在しない場合、`if [[ -f ]]` ガードにより除外リストが空のまま正常終了する。
  また、リスト内の名前が実在する skill と一致するかの検査がなく、typo・リネームずれも無警告。
- **失敗シナリオ**（fake HOME で実証済み）: dotfiles の配置換えやファイル名変更で claude-only.txt が見えなくなった状態で sync.sh を実行 →
  「skills -> 31 linked, 0 claude-only」と出て、除外していたはずの 9 skill（slack-ask 等）が Codex に共有される。
  出力を注視していなければ気づかない。skill を claude-only.txt に書いたままリネームした場合も同様に静かに共有側へ漏れる。
- **直し方**: (a) EXCLUDE_FILE が無ければ `exit 1`。(b) ループ後に「exclude に書かれていたが一致しなかった名前」を集計して警告する。

### 3. sync.sh: 他ツールが張った symlink も無差別に削除する

- **対象**: `~/dotfiles/ai/sync.sh:45-47`（skills）, `sync.sh:67-69`(prompts)
- **問題**: 掃除フェーズが `~/.agents/skills/` / `~/.codex/prompts/` 内の **すべての symlink** を削除する。自分が張ったもの（リンク先が `~/.claude/skills` / `~/.claude/commands`）に限定していない。
- **失敗シナリオ**（実証済み）: 将来 `npx skills add` や他の agent ツールが `~/.agents/skills/` に symlink 形式で skill を入れる → 次の sync.sh 実行で黙って消える。
  実体ディレクトリは消えないことも確認済みなので、現時点の実害はゼロだが、`~/.agents/skills` は複数ツールが共用する場所なので「何ヶ月後かに静かに壊れる」典型パターン。
- **直し方**: 削除条件を `[[ -L "$link" && "$(readlink "$link")" == "$CLAUDE_DIR"/* ]]` にする（prompts 側も同様）。

---

## 直した方がよい

### 4. sync.sh: ソース側が空だと全リンクを消してリンク 0 本で正常終了する

- **対象**: `sync.sh:44-47` + `sync.sh:51`
- **問題**: `~/.claude/skills/` が存在しない（または空・マウント前・新マシン）場合、nullglob により対象 0 件。掃除フェーズは先に走るので、既存 22 本を消して 0 本張り直し、`rc=0` で終わる（実証済み）。
- **失敗シナリオ**: 新マシンで dotfiles を先に展開して sync.sh を実行、あるいは ~/.claude を移行中に実行 → Codex 側の skill が全滅し、エラーも出ない。
- **直し方**: リンク対象が 0 件なら掃除前に abort する（`compgen -G "$CLAUDE_DIR/skills/*/SKILL.md" >/dev/null || exit 1` 相当のガード）。

### 5. sync.sh: `~/.agents/skills/` に同名の実体ディレクトリがあると symlink がその中にネストして作られる

- **対象**: `sync.sh:59`
- **問題**: `ln -sfn` はリンク名が「実体ディレクトリ」の場合、上書きせずその**内部**にリンクを作る。実証: `~/.agents/skills/foo/`（実体）がある状態で同名 skill を link すると `~/.agents/skills/foo/foo -> ...` ができ、Codex からは古い実体側が見え続ける。
- **失敗シナリオ**: 他ツールで入れた skill と同名の skill を ~/.claude/skills に作る → sync.sh は「linked」とカウントするのに Codex には反映されず、ゴミリンクが残る。
- **直し方**: link 前に `[[ -e "$AGENTS_SKILLS/$name" && ! -L "$AGENTS_SKILLS/$name" ]]` なら警告してスキップ。

### 6. claude-only.txt: skill とコマンドの除外名前空間が共有されている

- **対象**: `sync.sh:35-41`（`is_excluded` を L55 と L74 の両方で使用）
- **問題**: 除外は「名前」だけで判定され、skill 用かコマンド用かを区別しない。実証: skill 名 `b` を除外すると同名コマンド `b.md` も除外される。
- **失敗シナリオ**: 将来 `sessions` や `plan` という名前の skill を作ると、コマンド用の除外エントリに巻き込まれて黙って Codex から外れる（逆も同様）。
- **直し方**: claude-only.txt を `skill:名前` / `cmd:名前` のように区別するか、少なくとも README にこの挙動を明記する。

### 7. 共有中の careful / freeze は本体機能（hook）が Codex で動かない → claude-only へ

- **対象**: `~/.claude/skills/careful/SKILL.md:13-18`, `~/.claude/skills/freeze/SKILL.md:14-24`
- **問題**: 両 skill の中核は frontmatter の `hooks: PreToolUse`（`${CLAUDE_SKILL_DIR}/bin/check-*.sh` による Bash/Edit/Write のブロック）。これは Claude Code の skill-hooks 機構で、Codex には存在しない。
- **失敗シナリオ**: Codex で「careful mode で」と頼む → skill 本文（説明書）だけ読まれ、**強制ガードが効いていないのに効いている気になる**。安全系 skill だけに、静かな劣化の中で最も筋が悪い。
- **直し方**: `claude-only.txt` に `careful` と `freeze` を追加して sync.sh を再実行（監査後にユーザー判断で）。

### 8. gstack 参照の腐敗（Codex 以前に Claude 側でも壊れている）

- **対象**: 共有中の investigate / plan-eng-review / review / ship（例: `investigate/SKILL.md` の preamble、`review/SKILL.md` の `~/.claude/skills/gstack/bin/gstack-telemetry-log` 等）、careful / freeze の `~/.gstack/analytics` 追記
- **問題**: これらの skill は `~/.claude/skills/gstack/bin/*` のスクリプト群を呼ぶが、**`~/.claude/skills/gstack` は存在しない**（`ls` で確認済み。`~/.gstack` のデータディレクトリだけ残存）。上流（ECC 系）から取り込んだ際の残骸と推測。
- **失敗シナリオ**: skill 起動のたびに preamble のスクリプト呼び出しが失敗し、モデルがエラー処理に手数を使う。Codex 側では「Claude 固有依存」に見えるが、実際は両環境共通の腐敗。
- **直し方**: 共有可否の判定変更ではなく、skill 側から gstack 参照を削るのが本筋（別タスク。skill-stocktake の対象候補）。
- **対応済み(2026-07-24)**: careful / freeze / investigate / plan-eng-review / review / ship の SKILL.md から gstack 参照を全除去（`grep -rn gstack */SKILL.md` ゼロ件）。各 `SKILL.md.tmpl` は削除し SKILL.md を実体の正典化（`{{PREAMBLE}}` 展開で gstack が再注入されるのを防ぐ。`bun run gen:skill-docs` はこの環境で未運用）。preamble / telemetry / Contributor Mode を丸ごと削除、Completeness Principle は `CC+gstack`→`AI-assisted coding` に de-brand して温存、body の gstack-* bin 呼び出し（review-log / diff-scope / config get codex_reviews / slug 等）は死んだ配管として除去し人間向け手順は温存。freeze の state dir は `$HOME/.gstack` → `$HOME/.claude/freeze` に変更（check-freeze.sh・investigate と協調）。`.gstack/no-test-bootstrap` → `.claude/no-test-bootstrap`。残置: hook 本体 check-careful.sh / check-freeze.sh の `~/.gstack/analytics` 追記のみ（fail-silent・SKILL.md スコープ外・要否はユーザー判断）。

### 9. Git Workflow の二重管理: AGENTS.md と rules/git-workflow.md

- **対象**: `~/dotfiles/ai/AGENTS.md:16-38` と `~/.claude/rules/git-workflow.md`（全文がほぼ同内容）
- **問題**: Claude Code は両方を読むため完全な重複。片方だけ直すと静かに矛盾する（既に差分あり: rules 側だけ「Attribution disabled globally via ~/.claude/settings.json」と書かれているが、settings.json に該当キーは無い＝記述自体も陳腐化している。grep で確認済み）。
- **失敗シナリオ**: 数ヶ月後に AGENTS.md 側だけコミット形式を変更 → Claude は新旧両方の指示を同時に読み、挙動が不定になる。
- **直し方**: `rules/git-workflow.md` を削除（内容は AGENTS.md に完全包含されている。attribution の行は事実と不一致なので消してよい。attribution を本当に無効化したいなら settings.json に設定を入れるのが先）。
- **対応済み(2026-07-24)**: `~/.claude/rules/git-workflow.md` を削除（AGENTS.md の Git Workflow 節に完全包含を確認。attribution 行は事実不一致のため復活させず、settings.json への設定追加もしていない）。

### 10. rules/ の腐敗（共有可否とは独立の既存問題）

- **対象**:
  - `coding-style.md:10` / `hooks.md:10` / `patterns.md:10` / `security.md:10` / `testing.md:10` — `../common/*.md` への継承リンクが 5 本ともリンク切れ（`~/.claude/rules/common/` は存在しない。確認済み）
  - `testing.md:18` — 参照する `e2e-runner` agent が `~/.claude/agents/`（9 ファイル）に存在しない
  - `hooks.md` — 記載の Prettier/tsc hook は実際の settings.json の hooks 構成（guard / log / compact-suggest 系）と一致しない
- **失敗シナリオ**: モデルが存在しない common ルールや agent を前提に振る舞う。指示ファイルの信頼性が下がる。
- **直し方**: リンク行と e2e-runner 記述を削除、hooks.md は削除か実態に合わせて書き直し。
- **対応済み(2026-07-24)**: coding-style / patterns / security / testing の `../common/*.md` 継承リンク行を削除、testing の e2e-runner「Agent Support」節を削除。hooks.md は実 hooks（pretooluse-guard / log-skill-usage 系のグローバルハーネス hook で、TS/JS スコープの rules ではない）と一致せず記載も全陳腐化のためファイルごと削除。削除前に rules/ 全体を scratchpad へ退避。

### 11. AGENTS.md:3-4 の括弧書きが読み手（特に Codex）に不明瞭

- **対象**: `AGENTS.md:3-4` 「ツール固有の設定は各ツールの指示ファイル（Claude Code: `~/.claude/CLAUDE.md` / Codex: このファイルの後ろに続く記述なし）に置く」
- **問題**: 「このファイルの後ろに続く記述なし」が文として壊れており、Codex 固有設定の置き場所が定義されていない。
- **直し方**: 「Codex 固有の設定は現状なし。必要になったら `~/.codex/` 配下に置く」等に書き直す。

---

## 判断待ち（好みの問題）

### 12. rules/ の汎用部分を Codex に共有しないことによる品質低下

coding-style.md（TS 型付け・Zod）、patterns.md、ruby.md、security.md:12-24、testing.md:14 は完全にツール非依存で、
**Codex で TS/Ruby を書くときの出力品質は実際にこの分だけ落ちる**。ただし rules は `paths:` frontmatter による
条件付き読み込みで効いており、AGENTS.md に丸ごと入れると全セッション常時ロードになって「指示は小さいほど効く」に反する。

- 推奨: AGENTS.md には入れず、まず #10 の腐敗掃除だけやる。Codex を TS/Ruby の実装に本格投入する段階になったら、
  対象リポジトリの AGENTS.md（プロジェクト単位）に必要な節だけ移す。

### 13. AGENTS.md の Knowledge Wiki / サブエージェント記述は Codex には実行不能

- `AGENTS.md:46`（サブエージェント委譲）と `AGENTS.md:50-62`（Knowledge Wiki）は、Codex に同等機構（Task tool、memory ディレクトリ）が構成されていない。
- 失敗シナリオ: Codex が「メモリに保存」を独自解釈して勝手な場所にファイルを作る、程度。実害は小さい。
- 推奨: 当面放置でよい。気になるなら「(Claude Code のみ)」と 1 語添える。

### 14. AskUserQuestion 依存の共有 skill（ship / review / plan-eng-review / investigate）

対話フローの大半を AskUserQuestion（Claude Code 固有ツール）で組んでいるが、本文のワークフロー自体は汎用。
Codex では平文の質問に劣化するだけで、破綻はしない見込み（未検証）。共有継続で妥当。

### 15. Codex 側に安全ガードが無い

Claude 側の `pretooluse-guard.sh`（Bash 全コマンドに介入）に相当するものが Codex に無く、`config.toml` には
mcp_servers 以外の設定（approval_policy / sandbox_mode）が一切書かれていない＝ Codex デフォルト任せ。
Codex は独自の sandbox/承認機構を持つので「危険」ではないが、意図した設定なのか未決定なのかが config から読み取れない。

- 推奨: 日常運用に乗せる前に `codex` を一度起動して承認モードを確認し、決めた値を config.toml に明示する。

### 16. MCP の未移植分と README の記載漏れ

Codex に移植済みの 5 個（chrome-browser / godot / notion / freee / sentry-stdio）は Claude 側の定義と一致していることを確認した。
除外判断も妥当: vibe-tree（Claude Code 連携前提・ローカル DB env 依存）、figma-full（`--figma-token` に生トークン直書き。
そもそも Claude 側でもコマンドライン引数にトークンが平文で載っており、これ自体別途直す価値あり）。

ただし README.md:57-61 の「未登録」リストに載っていない未移植分がある: **playwright**（プロジェクト別）、**figma (http)**（プロジェクト別）、
**sentry の http/OAuth 版**（`https://mcp.sentry.dev/mcp`。Codex に移植したのは stdio 版のみで別物）。
- 推奨: 使う予定がないならそれで良いが、README の未登録リストに 3 行追記しておくと後で「移植したつもり」事故を防げる。

### 17. x-bookmarks は参照先 MCP がどちらの環境にも登録されていない

`x-bookmarks/SKILL.md` は「Chrome DevTools MCP」のツール名（list_pages / select_page / evaluate_script）を指定するが、
この名前のツールを持つ MCP は Claude 側にも Codex 側にも現在登録されていない（登録済みの chrome-browser は
list_tabs / switch_tab / evaluate と別名）。共有可否の問題ではなく skill 自体の更新が必要。

- **対応済み(2026-07-24)**: `x-bookmarks/SKILL.md` と `~/ghq/kthatoto/home/CLAUDE.md` の X Bookmarks 節を、登録済み chrome-browser MCP のツール名（list_pages→list_tabs / select_page→switch_tab(index指定) / evaluate_script→evaluate / navigate / get_content）に書き換え。スクレイピング JS 本体は温存（tool 名の整合のみ）。
- **未決(ユーザー判断待ち)**: グローバルメモリ `~/.claude/memory/reference_chrome_devtools_mcp.md`（chrome-devtools-mcp `--autoConnect` の setup 手順）と `feedback_chrome_devtools_background.md`（「Chrome DevTools MCP(background:true) を使う」嗜好）は、上記の登録済み chrome-browser とは**別 MCP（公式 chrome-devtools-mcp、list_pages 系）**を指しており、現在このセッションでは chrome-devtools-mcp のツールは読み込まれていない。x-bookmarks を chrome-browser に寄せた一方でメモリは chrome-devtools-mcp を指したままなので、「chrome-browser に統一」か「chrome-devtools-mcp を再登録して正典に戻す」かはユーザーの tooling 判断。掃除タスクでは勝手に書き換えず残置した。

---

## 未検証・要ユーザー操作（codex login 後に確認する順）

1. **【最重要】Codex が `~/.agents/skills/` の symlink された skill を実際に認識・発動するか。**
   codex-cli 0.145.0 の `--help` にも skills ディレクトリへの言及はなく、この構成全体の前提が現状未確認。
   確認方法: login 後に Codex を起動し、共有 skill 名（例: gws）に触れるタスクを振って skill が読まれるか見る。
2. `/prompts:plan` / `/prompts:skill-create` が symlink 先の内容で動くか。
3. `codex mcp login notion` / `codex mcp login freee`（OAuth。`~/.codex/` に auth.json は無く、両方未認証状態と推測される）。
4. sentry MCP（stdio 版・env なし）が認証まわりでツール呼び出しに成功するか。必要な認証方式は npm メタデータからは確認できなかった。
5. chrome-browser MCP（puppeteer-core 製の自作サーバー）が Codex から起動・接続できるか（Chrome の起動状態に依存）。
6. AskUserQuestion 依存 skill（#14）が Codex 上で実用に耐える劣化度か。

---

## skill / コマンド判定の変更提案一覧

| 名前 | 現状 | 推奨 | 理由 |
|---|---|---|---|
| careful | 共有 | **claude-only** | 本体が PreToolUse hook（Codex で強制が効かない安全系。#7） |
| freeze | 共有 | **claude-only** | 同上（Edit/Write ブロックが本体。#7） |
| search-first | 除外 | **共有可** | 除外理由の researcher agent は **Claude 側の ~/.claude/agents/ にも存在しない**（確認済み）。本文は rg/npm/GitHub 検索の汎用ワークフローで Codex でも成立 |
| x-bookmarks | 共有 | 判断待ち | 参照 MCP がどちらにも未登録（#17）。skill 修正が先 |
| plan（コマンド） | 共有 | 判断待ち | planner agent 前提。Codex ではインライン計画に劣化するが本文は使える |
| codebase-onboarding | 除外 | 判断待ち（弱い過剰除外） | 本文は汎用オンボーディング分析。生成先を CLAUDE.md→AGENTS.md に読み替えれば Codex でも価値がある |
| 上記以外の共有 17 個 | 共有 | 維持 | 固有依存なし、または劣化が軽微（game-creation / skill-creator の subagent 記述、mcp-builder の WebFetch は Codex が代替手段で吸収できる範囲） |
| 上記以外の除外 6 個 + save/resume/sessions | 除外 | 維持 | /compact・~/.claude 監査・Claude 固有 MCP・session 機構が本体で、判定どおり |

## 検証済みで問題なしだった点（安心材料）

- `@~/dotfiles/ai/AGENTS.md` import は Claude Code で解決されている（本セッションで実証）
- CLAUDE.md の分割で内容の欠落なし（バックアップとの差分を精査。移動された全項目が AGENTS.md に存在）
- sync.sh の冪等性、skill リネーム追従、実体ディレクトリ不干渉、claude-only.txt のインラインコメント処理、`set -u` と空配列の回避（`sync.sh:37`）はいずれもサンドボックスで動作確認済み
- symlink 22 本 / prompts 2 本の張り先はすべて正しい（ls で全件確認）
- agents / hooks / memory / settings.json を共有しない判断は妥当（Codex に対応機構がない or 別フォーマット）
