local M = {}
local align = require("foyer.lib.align")

--- Renders the header art centered within its content zone.
---@param canvas table Canvas instance
---@param width number Canvas width
---@param _ number Unused canvas height
---@param zone {row: number, height: number} Content zone bounds
---@return number Row after the last rendered line
function M.render(canvas, width, _, zone)
  local config = require("foyer").config.header
  if not config.art or #config.art == 0 then return zone.row end

  -- Apply zone padding
  local pad = config.zone.padding
  local inner_height = math.max(1, zone.height - pad.top - pad.bot)

  -- Measure longest line to determine content width
  local max_len = 0
  for _, line in ipairs(config.art) do
    if #line > max_len then max_len = #line end
  end

  -- Compute position within padded zone using configured alignment
  local row_offset = align.row(inner_height, #config.art, config.position.row or "center")
  local col_offset = align.col(width, max_len, config.position.col or "center")
  local start_row = zone.row + pad.top + row_offset
  local start_col = 1 + pad.left + col_offset

  -- Apply to layout compositor using active transparency masking rules (true)
  canvas:blend(config.art, start_row, start_col, true, config.hl)

  return start_row + #config.art
end

return M
