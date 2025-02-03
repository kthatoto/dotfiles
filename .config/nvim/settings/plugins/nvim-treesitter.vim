lua << EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "typespec" },
  highlight = {
    enable = true,  -- ハイライトを有効化
    additional_vim_regex_highlighting = false, -- これが `true` だと干渉することがある
  },
}
EOF
