local M = {}

function M.render(canvas, width, start_row)
  local config = require("foyer").config.menu
  local interactive_lines = {}

  if not config.items or #config.items == 0 then return start_row, {} end

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

  -- Center the icon/desc/key block horizontally
  local icon_gap = 2
  local key_gap = 2
  local block_width = max_icon_w + icon_gap + max_desc_w + key_gap + max_key_w
  local start_col = math.max(1, math.floor((width - block_width) / 2))

  for idx, item in ipairs(prepared) do
    local row = start_row + (idx - 1) * 2

    local icon_col = start_col
    local desc_col = start_col + max_icon_w + icon_gap
    local key_col = start_col + max_icon_w + icon_gap + max_desc_w + key_gap

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

  return start_row + (#prepared * 2), interactive_lines
end

return M
