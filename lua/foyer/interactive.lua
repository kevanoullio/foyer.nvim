local M = {}

--- Attaches cursor navigation, Enter binding, and key shortcuts to the dashboard buffer.
--- Converts 1-indexed canvas coordinates into 0-indexed cursor positions internally.
---@param bufnr number Buffer handle
---@param interactive_rows {row: number, col: number, key?: string, action: string|function}[] Menu rows from dashboard render
function M.attach(bufnr, interactive_rows)
  if #interactive_rows == 0 then return end

  -- Normalize 1-indexed canvas rows to 0-indexed cursor rows
  local cursor_rows = {}
  for _, item in ipairs(interactive_rows) do
    table.insert(cursor_rows, {
      row = item.row - 1,
      col = item.col - 1,
      key = item.key,
      action = item.action,
    })
  end

  -- Sort rows to find safe top/bottom boundaries
  table.sort(cursor_rows, function(a, b) return a.row < b.row end)

  local row_map = {}
  for _, item in ipairs(cursor_rows) do
    row_map[item.row] = item.action
  end

  -- Force cursor onto the first valid option immediately
  vim.api.nvim_win_set_cursor(0, { cursor_rows[1].row, cursor_rows[1].col })

  -- Setup navigation boundaries hook
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = bufnr,
    callback = function()
      local curr_row = vim.api.nvim_win_get_cursor(0)[1]

      -- Check if cursor stepped out of a valid menu interaction line
      if not row_map[curr_row] then
        local target_row = cursor_rows[1].row
        local min_dist = math.abs(curr_row - target_row)

        for _, item in ipairs(cursor_rows) do
          local dist = math.abs(curr_row - item.row)
          if dist < min_dist then
            min_dist = dist
            target_row = item.row
          end
        end

        -- Find target column for locking alignment
        local target_col = 0
        for _, item in ipairs(cursor_rows) do
          if item.row == target_row then
            target_col = item.col
            break
          end
        end

        vim.api.nvim_win_set_cursor(0, { target_row, target_col })
      end
    end,
  })

  -- Map executing action via Enter key
  vim.keymap.set("n", "<CR>", function()
    local curr_row = vim.api.nvim_win_get_cursor(0)[1]
    local action = row_map[curr_row]
    if action then
      if type(action) == "string" then
        vim.cmd(action)
      elseif type(action) == "function" then
        action()
      end
    end
  end, { buffer = bufnr, silent = true, nowait = true })

  -- Map structural key hotkeys dynamically based on menu preferences
  for _, item in ipairs(cursor_rows) do
    if item.key and item.key ~= "" then
      vim.keymap.set("n", item.key, function()
        if type(item.action) == "string" then
          vim.cmd(item.action)
        elseif type(item.action) == "function" then
          item.action()
        end
      end, { buffer = bufnr, silent = true, nowait = true })
    end
  end
end

return M
