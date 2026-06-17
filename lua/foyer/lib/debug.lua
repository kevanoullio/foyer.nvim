local M = {}

---@alias FoyerDebugZone {row: number, height: number}
---@alias FoyerDebugZones table<string, FoyerDebugZone>

--- Pastel highlight groups for zone visualisation.
--- Margin (shared), padding (shared), and four zone-specific border colours.
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

--- Draw a 1-char-thick border around each zone (top / bottom full-width,
--- left / right columns) plus fills for margin and padding bands.
---
--- Layout per zone (top to bottom):
---   margin top        — full-row margin fill
---   BORDER TOP        — full-row zone colour
---   padding top       — zone-colour edges, padding fill between (pad.top-1 rows)
---   content           — zone-colour edges, transparent between
---   padding bottom    — zone-colour edges, padding fill between (pad.bot-1 rows)
---   BORDER BOTTOM     — full-row zone colour
---   margin bottom     — full-row margin fill
---
--- The top/bottom border steals one row from the adjacent padding band.
---
---@param bufnr number
---@param zones FoyerDebugZones
---@param width number Canvas width in columns
---@param config table Top-level config (for padding / margin values)
function M.draw_zones(bufnr, zones, width, config)
  local ns = vim.api.nvim_create_namespace("foyer_debug")

  vim.api.nvim_set_hl(0, HL.margin.name,  { bg = HL.margin.bg })
  vim.api.nvim_set_hl(0, HL.padding.name, { bg = HL.padding.bg })
  for _, z in pairs(HL.zones) do
    vim.api.nvim_set_hl(0, z.name, { bg = z.bg })
  end

  local buf_line_count = vim.api.nvim_buf_line_count(bufnr)
  if buf_line_count == 0 then return end

  local function clamp(row)
    return math.max(0, math.min(row - 1, buf_line_count - 1))
  end

  local function full_row(row, hl)
    if row < 0 or row >= buf_line_count then return end
    vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
      end_col = width, hl_group = hl,
    })
  end

  local function fill_padding_row(row, zone_hl)
    if row < 0 or row >= buf_line_count then return end
    vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
      end_col = 1, hl_group = zone_hl,
    })
    if width > 2 then
      vim.api.nvim_buf_set_extmark(bufnr, ns, row, 1, {
        end_col = width - 1, hl_group = HL.padding.name,
      })
    end
    if width > 1 then
      vim.api.nvim_buf_set_extmark(bufnr, ns, row, width - 1, {
        end_col = width, hl_group = zone_hl,
      })
    end
  end

  local function fill_content_row(row, zone_hl)
    if row < 0 or row >= buf_line_count then return end
    vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
      end_col = 1, hl_group = zone_hl,
    })
    if width > 1 then
      vim.api.nvim_buf_set_extmark(bufnr, ns, row, width - 1, {
        end_col = width, hl_group = zone_hl,
      })
    end
  end

  for _, name in ipairs({ "header", "menu", "stats", "footer" }) do
    local zone = zones[name]
    local zone_hl = HL.zones[name]
    if not zone or not zone_hl then return end

    local cfg = config[name] and config[name].zone
    local pad = (cfg and cfg.padding) or { top = 0, bot = 0 }
    local margin = (cfg and cfg.margin) or { top = 0, bot = 0 }

    local top = zone.row
    local bot = zone.row + zone.height - 1

    -- Margin top
    for r = top - margin.top, top - 1 do
      full_row(clamp(r), HL.margin.name)
    end

    -- Top border (steals outermost padding row)
    full_row(clamp(top), zone_hl.name)

    -- Padding top (pad.top - 1 rows between border and content)
    for r = top + 1, top + pad.top - 1 do
      fill_padding_row(clamp(r), zone_hl.name)
    end

    -- Content (between padding bands)
    for r = top + pad.top, bot - pad.bot do
      fill_content_row(clamp(r), zone_hl.name)
    end

    -- Padding bottom (pad.bot - 1 rows between content and border)
    for r = bot - pad.bot + 1, bot - 1 do
      fill_padding_row(clamp(r), zone_hl.name)
    end

    -- Bottom border (steals outermost padding row)
    full_row(clamp(bot), zone_hl.name)

    -- Margin bottom
    for r = bot + 1, bot + margin.bot do
      full_row(clamp(r), HL.margin.name)
    end

    -- Label on first content / padding / border row
    local label_row = clamp(math.max(top + pad.top, top + 1, top))
    local label = string.format(" %s(h=%d,r=%d) ", name, zone.height, zone.row)
    vim.api.nvim_buf_set_extmark(bufnr, ns, label_row, 0, {
      virt_text = { { label, zone_hl.name } },
    })
  end
end

return M
