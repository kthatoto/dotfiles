########################################
# terminal-bg main
########################################

_TERMINAL_BG_DIR="$HOME/dotfiles/scripts/terminal-bg"
_TERMINAL_BG_CONFIG="$_TERMINAL_BG_DIR/config.yaml"

function _term_bg_set() {
  local hex="$1"
  # #RRGGBB -> RRGGBB
  local rgb="${hex:1:6}"
  # iTerm2 専用エスケープシーケンス
  printf "\033]1337;SetColors=bg=%s\007" "$rgb"
}

# YAML からトップレベル key を読む（超簡易）
function _yaml_get() {
  sed -n "s/^$1:[[:space:]]*//p" "$_TERMINAL_BG_CONFIG" | tr -d '"'"'"
}

function _term_bg_update() {
  local root repo_name color default_color per_repo_file

  default_color=$(_yaml_get "default")
  per_repo_file=$(_yaml_get "per_repo_file")

  root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    _term_bg_set "$default_color"
    return
  }

  # repo ローカルファイルが最優先
  if [[ -n "$per_repo_file" && -f "$root/$per_repo_file" ]]; then
    _term_bg_set "$(tr -d '\n' < "$root/$per_repo_file")"
    return
  fi

  repo_name="${root:t}"

  # repos セクションから探す
  color=$(awk "
    \$1 == \"repos:\" {in_repos=1; next}
    in_repos && /^[^ ]/ {exit}
    in_repos && \$1 == \"${repo_name}:\" {gsub(/\"/, \"\", \$2); print \$2; exit}
  " "$_TERMINAL_BG_CONFIG")

  if [[ -n "$color" ]]; then
    _term_bg_set "$color"
  else
    _term_bg_set "$default_color"
  fi
}

# cd フック (chpwd_functions を使って他のプラグインと共存)
chpwd_functions+=(_term_bg_update)

# 初期表示
_term_bg_update
