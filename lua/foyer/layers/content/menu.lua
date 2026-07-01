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

  -- Measure column widths across all items.
  -- Use vim.fn.strchars() for correct character-count measurement
  -- (critical for multi-byte UTF-8 icons like Nerd Font symbols).
  local max_icon_w = 0
  local max_desc_w = 0
  local max_key_w = 0
  local prepared = {}

  for _, item in ipairs(config.items) do
    local icon = item.icon or ""
    local desc = item.desc or ""
    local key_display = item.key and ("[" .. item.key .. "]") or ""
    local icon_w = vim.fn.strchars(icon)
    local desc_w = vim.fn.strchars(desc)
    local key_w = vim.fn.strchars(key_display)
    if icon_w > max_icon_w then max_icon_w = icon_w end
    if desc_w > max_desc_w then max_desc_w = desc_w end
    if key_w > max_key_w then max_key_w = key_w end
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

  -- Extra horizontal padding inserted between the desc column and the key column.
  -- The total rendered block width grows by (h_shift * 2): h_shift on the left of
  -- icon+desc and h_shift on the right of the keymap, so the block stays centered.
  local h_shift = config.h_shift or 0

  -- Compute horizontal position within the padded zone.
  -- The content block is centered within the effective width (total width minus
  -- horizontal padding), then offset by pad.left so it respects zone margins.
  local block_width = max_icon_w + 2 + max_desc_w + 2 + max_key_w + (h_shift * 2)
  local effective_width = width - pad.left - pad.right
  local col_offset = align.col(effective_width, block_width, "center")
  local start_col = 1 + pad.left + col_offset

  for idx, item in ipairs(prepared) do
    local row = menu_row + (idx - 1) * 2

    local icon_col = start_col
    local desc_col = start_col + max_icon_w + 2
    local key_col = start_col + max_icon_w + 2 + max_desc_w + 2 + (h_shift * 2)

    -- Right-align key within its column (handles variable-width keys)
    key_col = key_col + (max_key_w - vim.fn.strchars(item.key_display))

    canvas:blend({ item.icon }, row, icon_col, true, config.hl_icon)
    canvas:blend({ item.desc }, row, desc_col, true, config.hl_desc)
    canvas:blend({ item.key_display }, row, key_col, true, config.hl_key)

    table.insert(interactive_lines, {
      row = row,
      col = desc_col,
      key = item.raw.key,
      action = item.raw.action,
    })
  end

  return menu_row + (#prepared * 2), interactive_lines
end

return M
