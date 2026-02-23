########################################
# terminal-bg main
#
# リポジトリごとに背景色・背景画像を自動切替
#
# テスト観点:
#   - git repo 内: repos セクションから色/画像を取得
#   - git repo 外: default 設定を使用
#   - per_repo override: .terminal-bg ファイルが最優先（色のみ）
#   - image null: 画像設定を送信しない
#   - image 指定あり: SetBackgroundImageFile を送信
########################################

_TERMINAL_BG_DIR="$HOME/dotfiles/scripts/terminal-bg"
_TERMINAL_BG_CONFIG="$_TERMINAL_BG_DIR/config.yaml"

########################################
# YAML パーサー（ネスト対応）
########################################

# トップレベルキーの値を取得
# Usage: _yaml_get_top "key"
function _yaml_get_top() {
  local key="$1"
  [[ ! -f "$_TERMINAL_BG_CONFIG" ]] && return
  awk -v key="$key" '
    # コメント行をスキップ
    /^[[:space:]]*#/ { next }
    # key: value の形式（トップレベル、インデントなし）
    $0 ~ "^" key ":[[:space:]]" {
      sub("^" key ":[[:space:]]*", "")
      gsub(/["'"'"']/, "")  # クォート除去
      gsub(/[[:space:]]*$/, "")  # 末尾空白除去
      print
      exit
    }
  ' "$_TERMINAL_BG_CONFIG"
}

# ネストしたキーの値を取得
# Usage: _yaml_get_nested "section" "key" "subkey"
# Example: _yaml_get_nested "repos" "rakushifu" "color"
function _yaml_get_nested() {
  local section="$1" key="$2" subkey="$3"
  [[ ! -f "$_TERMINAL_BG_CONFIG" ]] && return
  awk -v section="$section" -v key="$key" -v subkey="$subkey" '
    BEGIN { in_section = 0; in_key = 0 }
    # コメント行をスキップ
    /^[[:space:]]*#/ { next }
    # セクション開始
    $0 ~ ("^" section ":") { in_section = 1; next }
    # セクション終了（インデントなしで空行でない行）
    in_section && /^[^[:space:]]/ { in_section = 0; in_key = 0 }
    # キー開始（2スペースインデント）
    in_section {
      pattern = "^  " key ":$"
      if ($0 ~ pattern || $0 ~ ("^  " key ":[[:space:]]*$")) { in_key = 1; next }
    }
    # キー終了（2スペースインデントの別キー）
    in_key && /^  [^[:space:]]/ { in_key = 0 }
    # サブキーの値を取得（4スペースインデント）
    in_key {
      pattern = "^[[:space:]]+" subkey ":"
      if ($0 ~ pattern) {
        sub(/^[[:space:]]+[^:]+:[[:space:]]*/, "")
        gsub(/["'"'"']/, "")  # クォート除去
        gsub(/[[:space:]]*$/, "")  # 末尾空白除去
        if ($0 != "null" && $0 != "") print
        exit
      }
    }
  ' "$_TERMINAL_BG_CONFIG"
}

# default セクションの値を取得
# Usage: _yaml_get_default "color" or _yaml_get_default "image"
function _yaml_get_default() {
  local subkey="$1"
  [[ ! -f "$_TERMINAL_BG_CONFIG" ]] && return
  awk -v subkey="$subkey" '
    BEGIN { in_default = 0 }
    # コメント行をスキップ
    /^[[:space:]]*#/ { next }
    # default セクション開始（末尾の空白を柔軟に）
    /^default:/ { in_default = 1; next }
    # セクション終了（インデントなしで空行でない行）
    in_default && /^[^[:space:]]/ { exit }
    # サブキーの値を取得（2スペースインデント）
    in_default {
      # "  color: value" 形式にマッチ
      pattern = "^[[:space:]]+" subkey ":"
      if ($0 ~ pattern) {
        sub(/^[[:space:]]+[^:]+:[[:space:]]*/, "")
        gsub(/["'"'"']/, "")  # クォート除去
        gsub(/[[:space:]]*$/, "")  # 末尾空白除去
        if ($0 != "null" && $0 != "") print
        exit
      }
    }
  ' "$_TERMINAL_BG_CONFIG"
}

########################################
# 背景設定関数
########################################

# 背景色を設定
# Usage: _term_bg_set_color "#RRGGBB"
function _term_bg_set_color() {
  local hex="$1"
  # 空文字または不正値はスキップ
  [[ -z "$hex" || ! "$hex" =~ ^#[0-9A-Fa-f]{6}$ ]] && return
  # #RRGGBB -> RRGGBB
  local rgb="${hex:1:6}"
  # iTerm2 専用エスケープシーケンス（他ターミナルでは無害）
  printf "\033]1337;SetColors=bg=%s\007" "$rgb"
}

# 背景画像を設定
# Usage: _term_bg_set_image "/path/to/image.png"
function _term_bg_set_image() {
  local path="$1"
  # 空文字はスキップ（画像なしの場合は何もしない）
  [[ -z "$path" ]] && return
  # パスを展開（~ など）
  path="${path/#\~/$HOME}"
  # ファイル存在確認
  [[ ! -f "$path" ]] && return
  # パスを base64 エンコード（iTerm2 の仕様）
  local encoded=$(printf '%s' "$path" | /usr/bin/base64)
  # iTerm2 専用エスケープシーケンス
  printf "\033]1337;SetBackgroundImageFile=%s\007" "$encoded"
}

# 背景画像をクリア
# Usage: _term_bg_clear_image
function _term_bg_clear_image() {
  # /dev/null を送ると画像がクリアされる
  printf "\033]1337;SetBackgroundImageFile=%s\007" "$(printf '/dev/null' | /usr/bin/base64)"
}

########################################
# メイン更新関数
########################################

function _term_bg_update() {
  local root repo_name
  local color image
  local default_color default_image
  local per_repo_file local_color

  # デフォルト値を取得
  default_color=$(_yaml_get_default "color")
  default_image=$(_yaml_get_default "image")
  per_repo_file=$(_yaml_get_top "per_repo_file")

  # git リポジトリ外の場合
  root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    _term_bg_set_color "$default_color"
    # デフォルトで画像指定があれば設定、なければクリア
    if [[ -n "$default_image" ]]; then
      _term_bg_set_image "$default_image"
    else
      _term_bg_clear_image
    fi
    return
  }

  repo_name="${root:t}"

  # repo 設定を取得
  color=$(_yaml_get_nested "repos" "$repo_name" "color")
  image=$(_yaml_get_nested "repos" "$repo_name" "image")

  # デフォルトにフォールバック
  [[ -z "$color" ]] && color="$default_color"
  [[ -z "$image" ]] && image="$default_image"

  # .terminal-bg ローカルファイルが最優先（色のみ上書き）
  if [[ -n "$per_repo_file" && -f "$root/$per_repo_file" ]]; then
    local_color=$(tr -d '\n' < "$root/$per_repo_file")
    # #RRGGBB 形式の検証
    if [[ "$local_color" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
      color="$local_color"
    fi
    # 不正値の場合は無視してフォールバック
  fi

  # 色設定 → 画像設定 の順で適用
  _term_bg_set_color "$color"
  if [[ -n "$image" ]]; then
    _term_bg_set_image "$image"
  else
    _term_bg_clear_image
  fi
}

########################################
# フック登録
########################################

# cd フック (chpwd_functions を使って他のプラグインと共存)
chpwd_functions+=(_term_bg_update)

# 初期表示
_term_bg_update
