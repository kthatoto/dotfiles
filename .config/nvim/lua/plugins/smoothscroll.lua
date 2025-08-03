return {
  "karb94/neoscroll.nvim",
  event = "WinScrolled",
  config = function()
    require("neoscroll").setup({
      -- デフォルトで true
      mappings = { '<C-u>', '<C-d>', '<C-b>', '<C-f>' },
      hide_cursor = true,
      stop_eof = true,
      easing_function = "quadratic", -- "sine" など他にも可
    })

    local t = {}
    t['<C-u>'] = { 'scroll', { '-vim.wo.scroll', 'true', '100' } }
    t['<C-d>'] = { 'scroll', { 'vim.wo.scroll', 'true', '100' } }
    t['<C-b>'] = { 'scroll', { '-vim.api.nvim_win_get_height(0)', 'true', '150' } }
    t['<C-f>'] = { 'scroll', { 'vim.api.nvim_win_get_height(0)', 'true', '150' } }
    require('neoscroll.config').set_mappings(t)
  end
}
