local M = {}
local align = require("foyer.lib.align")

function M.render(canvas, width, _, zone)
  local config = require("foyer").config.footer
  if not config.text or config.text == "" then return zone.row end

  -- Apply zone padding
  local pad = config.zone.padding
  local inner_top = zone.row + pad.top
  local inner_height = math.max(1, zone.height - pad.top - pad.bot)

  -- Compute vertical position within the padded zone
  local row_offset = align.row(inner_height, 1, config.position.row or "center")
  local start_row = inner_top + row_offset

  -- Compute horizontal position within the padded zone
  local col_offset = align.col(width, #config.text, "center")
  local start_col = 1 + pad.left + col_offset

  canvas:blend({ config.text }, start_row, start_col, true, config.hl)
  return start_row
end

return M
