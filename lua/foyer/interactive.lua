local M = {}

--- Attaches cursor navigation, Enter binding, and key shortcuts to the dashboard buffer.
--- Canvas rows are 1-indexed and passed through as-is for cursor positioning (1-indexed).
--- Canvas columns are pre-computed byte indices (0-indexed) by the menu layer.
---@param bufnr number Buffer handle
---@param interactive_rows {row: number, col: number, key?: string, action: string|function}[] Menu rows from dashboard render
function M.attach(bufnr, interactive_rows)
  if #interactive_rows == 0 then return end

  -- Column values are already 0-indexed byte indices from the menu layer
  local cursor_rows = {}
  for _, item in ipairs(interactive_rows) do
    table.insert(cursor_rows, {
      row = item.row,
      col = item.col,
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

  -- Sorted list of valid menu row numbers for quick lookup
  local sorted_rows = {}
  for _, item in ipairs(cursor_rows) do
    table.insert(sorted_rows, item.row)
  end
  table.sort(sorted_rows)

  -- Column lookup: row -> col
  local row_col_map = {}
  for _, item in ipairs(cursor_rows) do
    row_col_map[item.row] = item.col
  end

  -- Track previous cursor row to determine navigation direction
  local prev_row = nil

  --- Finds the next valid menu row in the given direction.
  --- @param from_row number Current (invalid) cursor row
  --- @param direction number 1 for down, -1 for up
  --- @return number target row
  local function find_next_row_in_direction(from_row, direction)
    if direction == 1 then
      -- Moving down: find first valid row strictly above from_row, or wrap to first
      for _, r in ipairs(sorted_rows) do
        if r >= from_row then
          return r
        end
      end
      return sorted_rows[1]
    else
      -- Moving up: find last valid row strictly below from_row, or wrap to last
      for i = #sorted_rows, 1, -1 do
        if sorted_rows[i] <= from_row then
          return sorted_rows[i]
        end
      end
      return sorted_rows[#sorted_rows]
    end
  end

  --- Finds the nearest valid menu row (used when direction is unknown).
  --- @param from_row number Current cursor row
  --- @return number target row
  local function find_nearest_row(from_row)
    local target_row = sorted_rows[1]
    local min_dist = math.abs(from_row - target_row)

    for _, r in ipairs(sorted_rows) do
      local dist = math.abs(from_row - r)
      if dist < min_dist then
        min_dist = dist
        target_row = r
      end
    end
    return target_row
  end

  -- Force cursor onto the first valid option immediately
  vim.api.nvim_win_set_cursor(0, { cursor_rows[1].row, cursor_rows[1].col })
  prev_row = cursor_rows[1].row

  -- Setup navigation boundaries hook with direction-aware snapping
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = bufnr,
    callback = function()
      local curr_row = vim.api.nvim_win_get_cursor(0)[1]

      -- If cursor is on a valid menu row, just update tracking
      if row_map[curr_row] then
        prev_row = curr_row
        return
      end

      -- Cursor landed on an invalid row (e.g. gap between items).
      -- Determine direction of travel and snap forward, not backward.
      local direction = 1 -- default: down
      if prev_row ~= nil then
        if curr_row < prev_row then
          direction = -1
        end
      end

      local target_row
      if prev_row == nil then
        -- First move (shouldn't happen, but safety net)
        target_row = find_nearest_row(curr_row)
      else
        target_row = find_next_row_in_direction(curr_row, direction)
      end

      -- Preserve current row if we'd snap back to where we came from
      -- (e.g. at boundary, direction is down but no row below exists)
      if direction == 1 and target_row < prev_row then
        -- We're at the bottom; stay on prev_row
        target_row = prev_row
      elseif direction == -1 and target_row > prev_row then
        -- We're at the top; stay on prev_row
        target_row = prev_row
      end

      local target_col = row_col_map[target_row] or 0
      vim.api.nvim_win_set_cursor(0, { target_row, target_col })
      prev_row = target_row
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
