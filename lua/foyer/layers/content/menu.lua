local M = {}
local align = require("foyer.lib.align")

--- Renders the menu items within their content zone and returns interactive
--- rows for cursor navigation and keyboard bindings.
---@param canvas table Canvas instance
---@param width number Canvas width
---@param _ number Unused canvas height
---@param zone {row: number, height: number} Content zone bounds
---@return number, {row: number, col: number, key?: string, action: string|function}[] Final row after menu, and interactive line definitions
function M.render(canvas, width, _, zone)
  local config = require("foyer").config.menu
  local interactive_lines = {}

  if not config.items or #config.items == 0 then return zone.row, {} end

  -- Measure column widths across all items
  local max_icon_w = 0
  local max_desc_w = 0
  local max_key_w = 0
  local prepared = {}

  for _, item in ipairs(config.items) do
    local icon = item.icon or ""
    local desc = item.desc or ""
    local key_display = item.key and ("[" .. item.key .. "]") or ""
    if #icon > max_icon_w then max_icon_w = #icon end
    if #desc > max_desc_w then max_desc_w = #desc end
    if #key_display > max_key_w then max_key_w = #key_display end
    table.insert(prepared, { icon = icon, desc = desc, key_display = key_display, raw = item })
  end

  -- Apply zone padding
  local pad = config.zone.padding
  local inner_top = zone.row + pad.top
  local inner_height = math.max(1, zone.height - pad.top - pad.bot)

  -- Compute vertical position within the padded zone
  local menu_height = #prepared * 2
  local menu_row
  if inner_height > menu_height then
    menu_row = inner_top + align.row(inner_height, menu_height, config.position.row or "center")
  else
    menu_row = inner_top
  end

  -- Compute horizontal position within the padded zone
  local block_width = max_icon_w + 2 + max_desc_w + 2 + max_key_w
  local col_offset = align.col(width, block_width, "center")
  local start_col = 1 + pad.left + col_offset

  for idx, item in ipairs(prepared) do
    local row = menu_row + (idx - 1) * 2

    local icon_col = start_col
    local desc_col = start_col + max_icon_w + 2
    local key_col = start_col + max_icon_w + 2 + max_desc_w + 2

    -- Right-align key within its column (handles variable-width keys)
    key_col = key_col + (max_key_w - #item.key_display)

    canvas:blend({ item.icon }, row, icon_col, true, config.hl_icon)
    canvas:blend({ item.desc }, row, desc_col, true, config.hl_desc)
    canvas:blend({ item.key_display }, row, key_col, true, config.hl_key)

    table.insert(interactive_lines, {
      row = row,
      col = icon_col,
      key = item.raw.key,
      action = item.raw.action,
    })
  end

  return menu_row + (#prepared * 2), interactive_lines
end

return M
