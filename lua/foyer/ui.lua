local M = {}
local Canvas = require("foyer.canvas")

M.bufnr = nil

--- Window ID where foyer is displayed.
M.winid = nil

--- Saved window options to restore when leaving the foyer buffer.
M.saved_wo = nil

--- Default margin value applied to all sides when not explicitly configured.
local DEFAULT_MARGIN = 0

--- Default padding value applied to all sides when not explicitly configured.
local DEFAULT_PADDING = 2

--- Normalizes a padding or margin config value into a {top, bot, left, right} table.
--- Accepts a number (applied to all sides) or a table with any subset of keys.
---
--- @param val number|table
--- @return {top: number, bot: number, left: number, right: number}
local function normalize_padding(val)
  if type(val) == "number" then
    return { top = val, bot = val, left = val, right = val }
  end
  return {
    top = val.top or DEFAULT_PADDING,
    bot = val.bot or DEFAULT_PADDING,
    left = val.left or DEFAULT_PADDING,
    right = val.right or DEFAULT_PADDING,
  }
end

--- Normalizes a margin config value into a {top, bot, left, right} table.
---
--- @param val number|table
--- @return {top: number, bot: number, left: number, right: number}
local function normalize_margin(val)
  if type(val) == "number" then
    return { top = val, bot = val, left = val, right = val }
  end
  return {
    top = val.top or DEFAULT_MARGIN,
    bot = val.bot or DEFAULT_MARGIN,
    left = val.left or DEFAULT_MARGIN,
    right = val.right or DEFAULT_MARGIN,
  }
end

--- Computes content zone positions based on configured percentages.
--- Zones are allocated sequentially from top to bottom within the content area.
--- Remaining space is distributed as equal top/bottom margin to each zone.
---
---@param usable {width: number, height: number}
---@param config {header: table, menu: table, stats: table, footer: table}
---@return {header: {row: number, height: number}, menu: {row: number, height: number}, stats: {row: number, height: number}, footer: {row: number, height: number}}
local function compute_content_zones(usable, config)
  local layers = {
    { key = "header", zone = config.header.zone },
    { key = "menu", zone = config.menu.zone },
    { key = "stats", zone = config.stats.zone },
    { key = "footer", zone = config.footer.zone },
  }

  -- Normalize all padding and margin values
  for _, layer in ipairs(layers) do
    layer.zone.padding = normalize_padding(layer.zone.padding)
    layer.zone.margin = normalize_margin(layer.zone.margin)
  end

  -- Calculate total percentage and remaining space
  local total_pct = 0
  for _, layer in ipairs(layers) do
    total_pct = total_pct + layer.zone.percentage
  end

  local remaining_pct = math.max(0, 1.0 - total_pct)
  local remaining_lines = math.floor(remaining_pct * usable.height)
  local margin_per_zone = math.floor(remaining_lines / (#layers * 2))

  -- Distribute remaining space as equal top/bottom margin
  for _, layer in ipairs(layers) do
    layer.zone.margin.top = layer.zone.margin.top + margin_per_zone
    layer.zone.margin.bot = layer.zone.margin.bot + margin_per_zone
  end

  -- Compute zone positions
  local zones = {}
  local current_row = 1

  for _, layer in ipairs(layers) do
    local zone_height = math.max(1, math.floor(usable.height * layer.zone.percentage))
    zones[layer.key] = {
      row = current_row + layer.zone.margin.top,
      height = zone_height,
    }
      current_row = current_row + zone_height
  end

  return zones
end

M.compute_zones = compute_content_zones

--- Opens the Foyer dashboard in a new scratch buffer or switches to an existing one.
--- If called on startup (reusing the initial empty buffer), it repurposes that
--- buffer instead of creating an extra one. Creates the buffer, configures window
--- options, triggers render, and sets up dynamic resizing on VimResized.
--- @return nil
function M.open()
  if M.bufnr and vim.api.nvim_buf_is_valid(M.bufnr) then
    vim.api.nvim_set_current_buf(M.bufnr)
    return
  end

  -- Reuse the initial empty buffer if it exists, to avoid leaving a stale
  -- empty buffer behind when foyer is closed. This matches how snacks/dashboard
  -- behave (no extra empty buffer after picking a file).
  local cur_buf = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_get_name(cur_buf) == "" and vim.bo[cur_buf].buftype == "" then
    M.bufnr = cur_buf
  else
    M.bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(M.bufnr)
  end

  -- Set safe buffer options for a pristine, non-file screen
  local opts = {
    bufhidden = "wipe",
    buftype = "nofile",
    swapfile = false,
    filetype = "foyer",
    modifiable = false,
  }
  for k, v in pairs(opts) do vim.bo[M.bufnr][k] = v end
  vim.bo[M.bufnr].syntax = "OFF"

  -- Track which window displays the foyer buffer, so we can restore
  -- window options on the correct window (not whatever is current).
  -- This mirrors how snacks.dashboard isolates its options via its own window.
  M.winid = vim.api.nvim_get_current_win()

  -- Save current window options on the foyer window so we can restore them
  -- when a real file is opened.
  M.saved_wo = {
    number = vim.wo[M.winid].number,
    relativenumber = vim.wo[M.winid].relativenumber,
    signcolumn = vim.wo[M.winid].signcolumn,
    foldcolumn = vim.wo[M.winid].foldcolumn,
    cursorline = vim.wo[M.winid].cursorline,
  }

  -- Clean window layout options on the foyer window
  vim.wo[M.winid].number = false
  vim.wo[M.winid].relativenumber = false
  vim.wo[M.winid].signcolumn = "no"
  vim.wo[M.winid].foldcolumn = "0"
  vim.wo[M.winid].cursorline = true

  M.render()

  -- Global BufEnter autocmd: restores window options on the foyer window
  -- when a real file buffer is opened.
  --
  -- Why global BufEnter instead of BufLeave/BufWipeout on the foyer buffer:
  -- When a picker opens, focus shifts away from foyer (firing BufLeave), but the
  -- foyer buffer is still visible in its window behind the picker. A restore at
  -- that point would cause ghost line numbers while the picker is active.
  --
  -- Instead, we wait for a BufEnter of a "real" file (buftype == "") and restore
  -- on M.winid at that moment. By this time, the file buffer has loaded, the
  -- window is ready, and the options will take effect immediately.
  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(ev)
      if not M.saved_wo then return end

      -- Only restore when entering a "real" file buffer (not pickers, terminals, help, etc.)
      local is_real_file = vim.bo[ev.buf].buftype == ""
      if not is_real_file then return end

      -- Restore only if the foyer window is still valid
      if M.winid and vim.api.nvim_win_is_valid(M.winid) then
        vim.wo[M.winid].number = M.saved_wo.number
        vim.wo[M.winid].relativenumber = M.saved_wo.relativenumber
        vim.wo[M.winid].signcolumn = M.saved_wo.signcolumn
        vim.wo[M.winid].foldcolumn = M.saved_wo.foldcolumn
        vim.wo[M.winid].cursorline = M.saved_wo.cursorline
      end

      -- One-time restore guard
      M.saved_wo = nil
    end,
  })

  -- Dynamic resizing listener
  vim.api.nvim_create_autocmd("VimResized", {
    buffer = M.bufnr,
    callback = function()
      M.render()
    end,
  })
end

--- Renders all dashboard layers onto the canvas and pushes them to the buffer.
--- Clears previous highlights, then applies new ones from the flush output.
--- Finally attaches interactive navigation to the menu rows.
--- @return nil
function M.render()
  if not M.bufnr or not vim.api.nvim_buf_is_valid(M.bufnr) then return end

  -- Clear any stale debug overlays from previous renders
  vim.api.nvim_buf_clear_namespace(M.bufnr,
    vim.api.nvim_create_namespace("foyer_debug"), 0, -1)

  -- Get usable terminal dimensions (accounts for cmdheight and statusline)
  local screen = require("foyer.lib.screen")
  local usable = screen.usable()

  -- Compute content zone positions
  local config = require("foyer").config
  local content_zones = compute_content_zones(usable, config)

  -- Log zone measurements to file
  if config.log and config.log.enabled and config.log.zones then
    local log = require("foyer.lib.log")
    log.log(config.log.file, os.date("%Y-%m-%d %H:%M:%S"))
    for _, key in ipairs({ "header", "menu", "stats", "footer" }) do
      local z = content_zones[key]
      local c = config[key] and config[key].zone or {}
      local pad = c.padding or {}
      local marg = c.margin or {}
      log.log(config.log.file,
        string.format("  [%s] row=%d h=%d pad={t=%d,b=%d,l=%d,r=%d} margin={t=%d,b=%d,l=%d,r=%d}",
          key, z.row, z.height,
          pad.top or 0, pad.bot or 0, pad.left or 0, pad.right or 0,
          marg.top or 0, marg.bot or 0, marg.left or 0, marg.right or 0))
    end
    log.sep(config.log.file)
  end

  -- Create a fresh empty virtual canvas
  local canvas = Canvas.new(usable.width, usable.height)

  -- Step 1: Render backdrop (background, opaque, covers full screen)
  require("foyer.layers.background").render(canvas, usable.width, usable.height)

  -- Step 2: Render content zones sequentially on top (transparent composition)
  require("foyer.layers.content.header").render(canvas, usable.width, usable.height, content_zones.header)

  -- Step 3: Render menu layer (returns interactive lines for keymap binding)
  local _, interactive_lines = require("foyer.layers.content.menu").render(canvas, usable.width, usable.height, content_zones.menu)
  interactive_lines = interactive_lines or {}

  -- Step 4: Render stats layer
  local stats_config = require("foyer").config.stats
  require("foyer.layers.content.stats").render(canvas, usable.width, usable.height, content_zones.stats, stats_config, M.bufnr)

  -- Step 5: Render footer layer
  require("foyer.layers.content.footer").render(canvas, usable.width, usable.height, content_zones.footer)

  -- Push contents from canvas matrix memory onto Neovim screen
  local text_lines, highlights = canvas:flush()

  vim.bo[M.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(M.bufnr, 0, -1, false, text_lines)
  vim.bo[M.bufnr].modifiable = false

  -- Draw zone boundary overlays on the buffer
  if config.debug and config.debug.enabled and config.debug.zones then
    require("foyer.lib.debug").draw_zones(M.bufnr, content_zones, usable.width, config)
  end

  -- Clean old highlights and write down new layer colors
  local ns = vim.api.nvim_create_namespace("foyer_highlights")
  vim.api.nvim_buf_clear_namespace(M.bufnr, ns, 0, -1)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_set_extmark(M.bufnr, ns, hl.row, hl.start_col, {
      end_col = hl.end_col,
      hl_group = hl.hl_group,
    })
  end

  -- Mount core navigation and tracking listeners
  require("foyer.interactive").attach(M.bufnr, interactive_lines)
end

return M
