local M = {}
local align = require("foyer.lib.align")

function M.render(canvas, width, height, start_row)
  local config = require("foyer").config.footer
  if not config.text or config.text == "" then return end

  -- Calculate horizontal centering offset
  local col_offset = align.col(width, #config.text, "center")
  local start_col = math.max(1, 1 + col_offset)
  canvas:blend({ config.text }, start_row, start_col, true, config.hl)
end

return M
