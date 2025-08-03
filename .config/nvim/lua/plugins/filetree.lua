return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  keys = {
    { "<C-n>", "<CMD>NvimTreeOpen<CR>", desc = "ファイルツリーを開く" },
    { "<C-i>", "<CMD>NvimTreeFindFile<CR>", desc = "現在のファイルをツリーで表示" },
  },
  config = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    vim.opt.termguicolors = true

    require("nvim-tree").setup({
      view = { width = 40 },
      update_focused_file = { enable = true },
      -- open_on_setup は削除！
    })

    -- Neovim起動時に自動でnvim-treeを開く（推奨方法）
    local function open_nvim_tree(data)
      -- 実ファイル or 無名バッファ 以外なら無視
      local real_file = vim.fn.filereadable(data.file) == 1
      local no_name = data.file == "" and vim.bo[data.buf].buftype == ""

      if not real_file and not no_name then
        return
      end

      require("nvim-tree.api").tree.open()
    end

    vim.api.nvim_create_autocmd("VimEnter", {
      callback = open_nvim_tree,
    })

    vim.api.nvim_create_autocmd("BufEnter", {
      nested = true,
      callback = function()
        local wins = vim.api.nvim_list_wins()
        local tabwins = {}
        for _, win in ipairs(wins) do
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.bo[buf].filetype
          if ft ~= "NvimTree" then
            table.insert(tabwins, win)
          end
        end
        -- NvimTree だけになったら終了
        if #tabwins == 0 then
          vim.cmd("quit")
        end
      end,
    })
  end,
}
