# AI エージェント共通設定

Claude Code と Codex CLI で指示ファイル・skills・コマンドを共有するための置き場。

## 構成

```
~/dotfiles/ai/
  AGENTS.md               共通指示（実体）
  claude-only.txt         Codex に共有しない skill / コマンド名リスト
  sync.sh                 symlink を張り直す（冪等）
  README.md
```

symlink の張られ方:

| パス | 実体 | 使うツール |
|---|---|---|
| `~/.codex/AGENTS.md` | `~/dotfiles/ai/AGENTS.md` | Codex |
| `~/.claude/CLAUDE.md` | 実ファイル（`@~/dotfiles/ai/AGENTS.md` を import） | Claude Code |
| `~/.agents/skills/<name>` | `~/.claude/skills/<name>` | Codex |
| `~/.codex/prompts/<name>.md` | `~/.claude/commands/<name>.md` | Codex |

skill の実体は `~/.claude/skills/` のまま。Codex 側は `~/.agents/skills/` から読むので、
skill ごとに個別 symlink を張っている（ディレクトリ丸ごと symlink すると Claude Code が
`.claude/skills` に書く内部ファイルで Codex 側が壊れるため）。

## 運用

skill やコマンドを追加・削除・リネームしたら:

```sh
~/dotfiles/ai/sync.sh
```

Codex 用に共有したくない skill / コマンド（Claude Code 固有のツールや MCP に依存するもの）は
`claude-only.txt` に名前を1行ずつ書く。コマンドは拡張子なしで書く。

現状の共有数: skills 21/31、コマンド 2/5。

## 共有していないもの

| 項目 | 理由 |
|---|---|
| `~/.claude/agents/` (subagent) | Codex は別機構。互換性なし |
| `~/.claude/settings.json` の hooks | Codex の hooks は別フォーマット |
| `~/.claude/memory/` | Claude Code 固有。Codex の memories 機能とは別 |
| `~/.claude/rules/` | Claude Code が自動読み込みする仕組み。Codex にはない |
| MCP | 形式が違う（JSON / TOML）。`codex mcp add` で個別登録済み |

## MCP

Codex 側は `codex mcp add` で登録済み。確認は `codex mcp list`。

登録済み: chrome-browser, godot, sentry, notion (OAuth), freee (OAuth)

未登録:

- `figma-full` — トークン直書き & プロジェクト固有のため見送り
- Slack / Gmail / Calendar / claude-in-chrome / computer-use — Claude Code 固有で移植不可

vibe-tree は Claude 側からも削除済み（2026-07-24、未使用のため）。

追加するとき:

```sh
codex mcp add <name> -- <command> <args...>     # stdio
codex mcp add <name> --url <url>                # streamable http
codex mcp login <name>                          # OAuth が必要な場合
```
