require("mason").setup()
require("mason-lspconfig").setup()

local lspconfig = require("lspconfig")

-- 汎用 on_attach
local on_attach = function(_, bufnr)
  local map = function(keys, func)
    vim.keymap.set("n", keys, func, { buffer = bufnr })
  end
  map("gd", vim.lsp.buf.definition)
  map("K", vim.lsp.buf.hover)
  map("<leader>rn", vim.lsp.buf.rename)
end

-- TypeScript
lspconfig.tsserver.setup({ on_attach = on_attach })

-- Vue (Volar)
lspconfig.volar.setup({
  on_attach = on_attach,
  filetypes = { "vue" },
})

-- Ruby (Shopify Ruby LSP)
lspconfig.ruby_lsp.setup({ on_attach = on_attach })

-- Sorbet
lspconfig.sorbet.setup({
  cmd = { "srb", "tc", "--lsp" },
  on_attach = on_attach,
  root_dir = lspconfig.util.root_pattern("sorbet", ".git"),
})
