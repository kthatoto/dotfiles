# terminal-bg

リポジトリごとにiTerm2の背景色・背景画像を自動切替するzshプラグイン。
`cd` するたびに現在のgitリポジトリを判定し、`config.yaml` に基づいて背景を変更する。

## ファイル構成

```
terminal-bg/
├── config.yaml          # リポジトリ名 → 色/画像のマッピング定義
├── main.sh              # zshフック（cdで自動発火）
├── generate-pattern.sh  # チェック柄PNG生成スクリプト
├── patterns/            # 背景画像ファイル
└── README.md
```

## パターン追加手順

### 1. 背景画像の生成（任意）

```bash
./generate-pattern.sh <名前> <色1> <色2> [サイズ(default:20)]
```

例:
```bash
./generate-pattern.sh myrepo '#1e1e3f' '#3f1e1e' 20
```

`patterns/<名前>.png` にチェック柄PNGが生成される。`magick` (ImageMagick) が必要。

### 2. config.yaml にエントリ追加

```yaml
repos:
  リポジトリ名:
    color: "#RRGGBB"
    image: "~/dotfiles/scripts/terminal-bg/patterns/xxx.png"
```

- `color`: 背景色（必須）
- `image`: 背景画像パス（任意、`null` で画像なし）

## 優先順位

1. リポジトリルートの `.terminal-bg` ファイル（色のみ上書き、`#RRGGBB` 形式）
2. `config.yaml` の `repos` セクション
3. `config.yaml` の `default` セクション
