#!/bin/zsh
########################################
# チェック柄パターン生成スクリプト
#
# Usage: ./generate-pattern.sh <name> <color1> <color2> [size]
# Example: ./generate-pattern.sh rakushifu-a "#1e1e3f" "#3f1e1e" 20
########################################

set -e

NAME="$1"
COLOR1="$2"
COLOR2="$3"
SIZE="${4:-20}"  # デフォルト 20px

PATTERN_DIR="$HOME/dotfiles/scripts/terminal-bg/patterns"

if [[ -z "$NAME" || -z "$COLOR1" || -z "$COLOR2" ]]; then
  echo "Usage: $0 <name> <color1> <color2> [size]"
  echo "Example: $0 rakushifu-a '#1e1e3f' '#3f1e1e' 20"
  exit 1
fi

mkdir -p "$PATTERN_DIR"

HALF=$((SIZE / 2))
OUTPUT="$PATTERN_DIR/${NAME}.png"

# チェック柄を生成（2x2 のタイル）
magick -size "${SIZE}x${SIZE}" xc:"$COLOR1" \
  -fill "$COLOR2" \
  -draw "rectangle 0,0 $((HALF-1)),$((HALF-1))" \
  -draw "rectangle ${HALF},${HALF} $((SIZE-1)),$((SIZE-1))" \
  "$OUTPUT"

echo "Generated: $OUTPUT"
