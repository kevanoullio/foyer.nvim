local M = {}
local _log_file = "./foyer-debug.log"

---@alias FoyerDebugZone {row: number, height: number}
---@alias FoyerDebugZones table<string, FoyerDebugZone>

--- Append timestamped message to the debug log file.
---@param ... any
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

--- Pastel highlight groups for zone vizualisation.
--- Margin and padding are shared across all zones; each zone gets its own
--- distinct pastel border colour.
local HL = {
  margin  = { bg = "#E8E8E8", name = "FoyerDebugMargin" },
  padding = { bg = "#FFFACD", name = "FoyerDebugPadding" },
  zones   = {
    header = { bg = "#FFC8A2", name = "FoyerDebugHeader" },
    menu   = { bg = "#A8E6CF", name = "FoyerDebugMenu" },
    stats  = { bg = "#A0D2F4", name = "FoyerDebugStats" },
    footer = { bg = "#D7BDE2", name = "FoyerDebugFooter" },
  },
}

--- Render the full zone extent (margin → padding → content) as coloured
--- extmarks on the buffer. Each row in a zone is painted with the appropriate
--- highlight group based on whether it falls in the margin, padding, or
--- content band.
---
---@param bufnr number
---@param zones FoyerDebugZones
---@param width number Canvas width in columns
---@param config table Top-level config (for padding / margin values)
function M.draw_zones(bufnr, zones, width, config)
  local ns = vim.api.nvim_create_namespace("foyer_debug")

  -- Define highlight groups
  vim.api.nvim_set_hl(0, HL.margin.name,  { bg = HL.margin.bg })
  vim.api.nvim_set_hl(0, HL.padding.name, { bg = HL.padding.bg })
  for _, zone in pairs(HL.zones) do
    vim.api.nvim_set_hl(0, zone.name, { bg = zone.bg })
  end

  local buf_line_count = vim.api.nvim_buf_line_count(bufnr)
  if buf_line_count == 0 then return end

  local function extmark_row(row)
    return math.max(0, math.min(row - 1, buf_line_count - 1))
  end

  for _, name in ipairs({ "header", "menu", "stats", "footer" }) do
    local zone = zones[name]
    local zone_hl = HL.zones[name]
    if not zone or not zone_hl then return end

    local pad = (config[name] and config[name].zone and config[name].zone.padding) or { top = 0, bot = 0, left = 0, right = 0 }
    local margin = (config[name] and config[name].zone and config[name].zone.margin) or { top = 0, bot = 0, left = 0, right = 0 }

    local full_top = extmark_row(zone.row - margin.top)
    local content_top = zone.row + pad.top
    local content_bot = zone.row + zone.height - pad.bot - 1
    local full_bot = extmark_row(zone.row + zone.height + margin.bot - 1)

    -- Helper to paint a span of rows with a highlight group
    ---@param from_row integer 0-indexed start
    ---@param to_row integer 0-indexed end (inclusive)
    ---@param hl_group string
    local function paint_rows(from_row, to_row, hl_group)
      for r = math.max(0, from_row), math.min(to_row, buf_line_count - 1) do
        vim.api.nvim_buf_set_extmark(bufnr, ns, r, 0, {
          end_col = width,
          hl_group = hl_group,
          hl_eol = true,
        })
      end
    end

    -- Margin top
    if margin.top > 0 then
      paint_rows(full_top, extmark_row(zone.row - 1), HL.margin.name)
    end

    -- Padding top
    if pad.top > 0 then
      paint_rows(extmark_row(zone.row), extmark_row(zone.row + pad.top - 1), HL.padding.name)
    end

    -- Content (zone border)
    local content_start = extmark_row(content_top)
    local content_end = extmark_row(content_bot)
    if content_start <= content_end then
      paint_rows(content_start, content_end, zone_hl.name)
    end

    -- Padding bottom
    if pad.bot > 0 then
      paint_rows(extmark_row(zone.row + zone.height - pad.bot), extmark_row(zone.row + zone.height - 1), HL.padding.name)
    end

    -- Margin bottom
    if margin.bot > 0 then
      paint_rows(extmark_row(zone.row + zone.height), full_bot, HL.margin.name)
    end

    -- Zone label virt_text on the first content row
    local label_row = math.max(extmark_row(zone.row + pad.top), full_top)
    local label = string.format(" %s(h=%d,r=%d) ", name, zone.height, zone.row)
    vim.api.nvim_buf_set_extmark(bufnr, ns, label_row, 0, {
      virt_text = { { label, zone_hl.name } },
    })
  end
end

return M
