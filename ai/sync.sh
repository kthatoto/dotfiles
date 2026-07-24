#!/usr/bin/env bash
# Claude Code と Codex CLI の設定を共有するための symlink を張り直す。
# skill / コマンドを追加・削除したら実行する。冪等。
set -euo pipefail

AI_DIR="$HOME/dotfiles/ai"
CLAUDE_DIR="$HOME/.claude"
CODEX_DIR="$HOME/.codex"
AGENTS_SKILLS="$HOME/.agents/skills"
EXCLUDE_FILE="$AI_DIR/claude-only.txt"

log() { printf '%s\n' "$*"; }

# 1. 共通指示ファイル: ~/.codex/AGENTS.md -> dotfiles/ai/AGENTS.md
#    （Claude Code 側は ~/.claude/CLAUDE.md が @import で読み込む）
mkdir -p "$CODEX_DIR"
ln -sfn "$AI_DIR/AGENTS.md" "$CODEX_DIR/AGENTS.md"
log "AGENTS.md -> linked"

# 2. skills: ~/.agents/skills/<name> -> ~/.claude/skills/<name>
#    ディレクトリ丸ごとではなく skill 単位で張る（Claude Code が .claude/skills に
#    内部ファイルを書くため、丸ごと symlink すると Codex 側が壊れる）
mkdir -p "$AGENTS_SKILLS"

# 除外リスト読み込み
exclude=()
if [[ -f "$EXCLUDE_FILE" ]]; then
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(printf '%s' "$line" | tr -d '[:space:]')"
    [[ -n "$line" ]] && exclude+=("$line")
  done < "$EXCLUDE_FILE"
fi

is_excluded() {
  local name="$1"
  for e in "${exclude[@]+"${exclude[@]}"}"; do
    [[ "$e" == "$name" ]] && return 0
  done
  return 1
}

# 既存の symlink を掃除（実体ディレクトリには触らない）
shopt -s nullglob
for link in "$AGENTS_SKILLS"/*; do
  [[ -L "$link" ]] && rm "$link"
done

linked=0
skipped=0
for dir in "$CLAUDE_DIR"/skills/*/; do
  name="$(basename "$dir")"
  [[ "$name" == .* ]] && continue
  [[ -f "$dir/SKILL.md" ]] || continue
  if is_excluded "$name"; then
    skipped=$((skipped + 1))
    continue
  fi
  ln -sfn "${dir%/}" "$AGENTS_SKILLS/$name"
  linked=$((linked + 1))
done
log "skills -> $linked linked, $skipped claude-only"

# 3. コマンド: ~/.codex/prompts/<name>.md -> ~/.claude/commands/<name>.md
#    Codex では /prompts:<name> で呼ぶ
mkdir -p "$CODEX_DIR/prompts"
for link in "$CODEX_DIR"/prompts/*; do
  [[ -L "$link" ]] && rm "$link"
done
cmds=0
cmds_skipped=0
for f in "$CLAUDE_DIR"/commands/*.md; do
  name="$(basename "$f" .md)"
  if is_excluded "$name"; then
    cmds_skipped=$((cmds_skipped + 1))
    continue
  fi
  ln -sfn "$f" "$CODEX_DIR/prompts/$(basename "$f")"
  cmds=$((cmds + 1))
done
log "prompts -> $cmds linked, $cmds_skipped claude-only"
shopt -u nullglob

log ""
log "MCP は codex mcp add で登録済み（冪等でないため sync 対象外）。"
log "確認: codex mcp list"
