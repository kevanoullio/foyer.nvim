local M = {}
local align = require("foyer.lib.align")

function M.render(canvas, width, height, zone)
  local config = require("foyer").config.header
  if not config.art or #config.art == 0 then return zone.row end

  -- Measure longest line to determine content width
  local max_len = 0
  for _, line in ipairs(config.art) do
    if #line > max_len then max_len = #line end
  end

  -- Compute position within zone using configured alignment (default: center)
  local pos = align.position(zone.height, width, #config.art, max_len,
    config.position.row or "center", config.position.col or "center")
  local start_row = zone.row + pos.row
  local start_col = 1 + pos.col

  -- Apply to layout compositor using active transparency masking rules (true)
  canvas:blend(config.art, start_row, start_col, true, config.hl)

  return start_row + #config.art
end

return M
