local M = {}

--- Computes the number of statusline rows based on current vim options.
---
--- @return number Number of rows reserved by the statusline
local function _statusline_rows()
  local rows = 0
  if vim.o.laststatus >= 2 then
    rows = rows + 1
  end
  if vim.o.showtabline == 2 then
    rows = rows + 1
  elseif vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1 then
    rows = rows + 1
  end
  return rows
end

--- Returns the usable terminal dimensions for a full-screen buffer.
--- Accounts for cmdheight and statusline that vim reserves, giving
--- the exact number of rows and columns available for content.
---
--- @return {width: number, height: number} Usable columns and rows
function M.usable()
  local lines = vim.o.lines
  local cols = vim.o.columns
  local cmdheight = vim.o.cmdheight or 1
  local statusline = _statusline_rows()
  return {
    width = cols,
    height = lines - cmdheight - statusline,
  }
end

return M
