local M = {}
local _log_file = "./foyer-debug.log"

--- Debug module for foyer.nvim.
--- Provides logging and visual zone boundary helpers for diagnosing layout issues.
---
--- @alias FoyerDebugZone {row: number, height: number}
--- @alias FoyerDebugZones table<string, FoyerDebugZone>

--- Append timestamped message to the debug log file.
--- Accepts multiple arguments and pretty prints non-strings using vim.inspect.
---
--- @param ... any Values to log (strings are written as-is, others are inspected)
function M.log(...)
  local fd = io.open(_log_file, "a+")
  if not fd then return end
  local parts = { os.date("%Y-%m-%d %H:%M:%S") }
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    parts[#parts + 1] = type(v) == "string" and v or vim.inspect(v)
  end
  fd:write(table.concat(parts, "  ") .. "\n")
  fd:close()
end

--- Render zone boundaries as colored extmarks on the buffer.
--- This gives a visual overlay so you can see exactly where each zone
--- starts/ends relative to where content is actually placed.
---
--- @param bufnr number Buffer handle
--- @param zones FoyerDebugZones All computed zones keyed by layer name
--- @param width number Canvas width in columns
function M.draw_zones(bufnr, zones, width)
  local ns = vim.api.nvim_create_namespace("foyer_debug")
  local highlight_base = "FoyerDebug"
  local colors = {
    header = { bg = "#FF0000", fg = "#FFFFFF" },
    menu   = { bg = "#00FF00", fg = "#000000" },
    stats  = { bg = "#0000FF", fg = "#FFFFFF" },
    footer = { bg = "#FF00FF", fg = "#000000" },
  }

  -- Define highlight groups
  for name, c in pairs(colors) do
    vim.api.nvim_set_hl(0, highlight_base .. name, {
      fg = c.fg,
      bg = c.bg,
      bold = true,
    })
  end

  for _, name in ipairs({ "header", "menu", "stats", "footer" }) do
    local zone = zones[name]
    local c = colors[name]
    if not zone or not c then return end

    -- Top border line
    vim.api.nvim_buf_add_highlight(bufnr, ns, highlight_base .. name, zone.row, 0, width)
    -- Bottom border line
    local bot_row = zone.row + zone.height - 1
    vim.api.nvim_buf_add_highlight(bufnr, ns, highlight_base .. name, bot_row, 0, width)
    -- Label at left margin
    local label = string.format("%s(h=%d,r=%d)", name, zone.height, zone.row)
    vim.api.nvim_buf_set_extmark(bufnr, ns, zone.row, 0, {
      virt_text = { { label, highlight_base .. name } },
    })
  end
end

return M
