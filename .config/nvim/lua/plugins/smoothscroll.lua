return {
  "karb94/neoscroll.nvim",
  event = "WinScrolled",
  config = function()
    require("neoscroll").setup({
      mappings = { '<C-u>', '<C-d>' },
      hide_cursor = true,
      stop_eof = true,
      respect_scrolloff = false,
      cursor_scrolls_alone = true,
      easing_function = "quadratic",
    })

    local scroll = require("neoscroll").scroll

    vim.keymap.set("n", "<C-u>", function()
      scroll(-vim.wo.scroll, {
        move_cursor = true,
        duration = 100,
        easing = "quadratic",
      })
    end, { silent = true, desc = "Smooth scroll up" })

    vim.keymap.set("n", "<C-d>", function()
      scroll(vim.wo.scroll, {
        move_cursor = true,
        duration = 100,
        easing = "quadratic",
      })
    end, { silent = true, desc = "Smooth scroll down" })
  end,
}
