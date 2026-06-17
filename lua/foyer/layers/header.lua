local M = {}
local align = require("foyer.lib.align")

function M.render(canvas, width, start_row)
  local config = require("foyer").config.header
  if not config.art or #config.art == 0 then return start_row end

  -- Measure longest line to determine content width
  local max_len = 0
  for _, line in ipairs(config.art) do
    if #line > max_len then max_len = #line end
  end

  -- Calculate horizontal centering offset
  local col_offset = align.col(width, max_len, "center")
  local start_col = math.max(1, 1 + col_offset)

  -- Apply to layout compositor using active transparency masking rules (true)
  canvas:blend(config.art, start_row, start_col, true, config.hl)

  return start_row + #config.art
end

return M
