local M = {}

-- Quickfix を使わず定義へジャンプ。1件→即ジャンプ、複数→inputlistで選択
function M.goto_definition_no_qf()
  if vim.tbl_isempty(vim.lsp.get_active_clients({ bufnr = 0 })) then
    vim.notify("LSP がこのバッファに接続していません", vim.log.levels.WARN)
    return
  end

  local util   = vim.lsp.util
  local params = util.make_position_params(0, "utf-8")

  vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result)
    if err then
      vim.notify(("LSP: %s"):format(err.message or err), vim.log.levels.ERROR)
      return
    end

    local list = (type(result) == "table" and result.uri) and { result }
               or (vim.tbl_islist(result) and result or {})
    local locs = {}
    for _, r in ipairs(list) do
      if r.uri and r.range then
        table.insert(locs, { uri = r.uri, range = r.range }) -- Location
      elseif r.targetUri and (r.targetSelectionRange or r.targetRange) then
        table.insert(locs, { uri = r.targetUri, range = r.targetSelectionRange or r.targetRange }) -- LocationLink
      end
    end

    if #locs == 0 then
      vim.notify("定義が見つかりません", vim.log.levels.INFO)
      return
    end

    local function jump(loc)
      util.jump_to_location(loc, "utf-8", true) -- reuse_win=true
      vim.cmd("silent! cclose")                  -- 念のためQFを閉じる
    end

    if #locs == 1 then
      jump(locs[1])
      return
    end

    local menu, items = { "定義を選択:" }, {}
    for i, l in ipairs(locs) do
      local fname = vim.fn.fnamemodify(vim.uri_to_fname(l.uri), ":.")
      local s = l.range.start
      local row, col = s.line + 1, s.character + 1
      local preview = ""
      local ok, bufnr = pcall(vim.uri_to_bufnr, l.uri)
      if ok then
        if not vim.api.nvim_buf_is_loaded(bufnr) then pcall(vim.fn.bufload, bufnr) end
        preview = (vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""):gsub("^%s+", "")
      end
      items[i] = l
      menu[#menu+1] = string.format("%d. %s:%d:%d  %s", i, fname, row, col, preview)
    end
    local idx = vim.fn.inputlist(menu)
    if idx >= 1 and idx <= #items then
      jump(items[idx])
    end
  end)
end

return M
