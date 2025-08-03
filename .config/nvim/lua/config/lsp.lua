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

local servers = {
  "lua_ts",
  "ruby_lsp",
  "rubocop",
  "ts_ls",
  "vue_ls",
  "tailwindcss",
  "tsp_server",
  "yamlls", -- yaml
  "zk", -- markdown
  "prettier",
}
for _, server in ipairs(servers) do
  lspconfig[server].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

-- Sorbet
lspconfig.sorbet.setup({
  cmd = { "srb", "tc", "--lsp" },
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = lspconfig.util.root_pattern("sorbet", ".git"),
})
