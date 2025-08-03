require("mason").setup()
require("mason-lspconfig").setup()

local lspconfig = require("lspconfig")

local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr }
  local map = vim.keymap.set
  map("n", "gd", vim.lsp.buf.definition, opts)
  map("n", "gr", vim.lsp.buf.references, opts)
  map("n", "K", vim.lsp.buf.hover, opts)
  map("n", "<leader>rn", vim.lsp.buf.rename, opts)
  map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
end

local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Lua
lspconfig.lua_ls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

-- Ruby (Shopify Ruby LSP)
lspconfig.ruby_lsp.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

-- RuboCop LSP (非推奨でなければ)
lspconfig.rubocop.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

-- Sorbet
lspconfig.sorbet.setup({
  cmd = { "srb", "tc", "--lsp" },
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = lspconfig.util.root_pattern("sorbet", ".git"),
})

-- TypeScript
lspconfig.tsserver.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

-- Vue (Volar)
lspconfig.vue_ls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

-- YAML
lspconfig.yamlls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

-- TypeSpec (tsp)
lspconfig.tsp_server.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

-- Markdown (zk)
lspconfig.zk.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})
