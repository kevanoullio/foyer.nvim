local M = {}

--- Tries installed pickers in order: snacks -> fzf-lua -> telescope -> mini.pick.
--- Calls the first one that loads and exits. Falls back to a notification.
---@param cmd string Picker command: "files", "live_grep", "oldfiles", "projects"
---@param opts? {cwd?: string} Options forwarded to the picker
---@return boolean true if a picker was found and executed
local function pick(cmd, opts)
  opts = opts or {}
  local picker_opts = opts.cwd and { cwd = opts.cwd } or {}

  -- Map command names to each picker's actual source/function names.
  -- Different pickers use different names for the same operation.
  local aliases = {
    live_grep = { snacks = "grep", telescope = "live_grep", fzf_lua = "live_grep", mini_pick = "grep" },
    oldfiles  = { snacks = "recent", telescope = "oldfiles", fzf_lua = "oldfiles", mini_pick = "oldfiles" },
    files     = { snacks = "files", telescope = "find_files", fzf_lua = "files", mini_pick = "files" },
  }

  local try = {
    -- Snacks picker first (LazyVim default, highest priority)
    function()
      local snacks = require("snacks")
      if cmd == "projects" then
        return snacks.picker.projects()
      end
      local source = (aliases[cmd] and aliases[cmd].snacks) or cmd
      return snacks.picker[source](picker_opts)
    end,
    -- External pickers
    function()
      local source = (aliases[cmd] and aliases[cmd].fzf_lua) or cmd
      return require("fzf-lua")[source](picker_opts)
    end,
    function()
      local builtin = require("telescope.builtin")
      local source = (aliases[cmd] and aliases[cmd].telescope) or cmd
      return builtin[source](picker_opts)
    end,
    function()
      local source = (aliases[cmd] and aliases[cmd].mini_pick) or cmd
      return require("mini.pick").builtin[source](picker_opts)
    end,
  }

  for _, fn in ipairs(try) do
    local ok, _ = pcall(fn)
    if ok then return true end
  end

  vim.notify("No picker found for " .. cmd, vim.log.levels.WARN)
  return false
end

--- Restores the last session using whichever session plugin is installed.
--- Tries persistence, persisted, session-manager, possession, mini.sessions,
--- and auto-session in that order. Falls back to a notification.
---@return boolean true if a session was restored
function M.restore_session()
  local plugins = {
    { mod = "persistence",     cmd = function(mod) mod.load() end },
    { mod = "persisted",       cmd = function(mod) mod.load() end },
    { mod = "session_manager", cmd = function() vim.cmd("SessionManager load_current_dir_session") end },
    { mod = "possession",      cmd = function() vim.cmd("PossessionLoadCwd") end },
    { mod = "mini.sessions",   cmd = function(mod) mod.read() end },
    { mod = "auto_session",    cmd = function() vim.cmd("AutoSession restore") end },
  }

  for _, plugin in ipairs(plugins) do
    local ok, mod = pcall(require, plugin.mod)
    if ok and mod then
      plugin.cmd(mod)
      return true
    end
  end

  vim.notify("No session plugin found", vim.log.levels.WARN)
  return false
end

M.config = {
  -- Background backdrop options:
  --   type = "file"      Load a static .txt file, centered on screen.
  --                        Falls back to "blank" if path is missing or unreadable.
  --          "generated" Procedurally generated art from a built-in theme.
  --          "blank"     No background (default).
  --
  --   path  Path to a .txt file (only for type = "file").
  --   theme Theme name   (only for type = "generated").
  --                        Available: "stars", "waves"
  --   hl    Highlight group applied to every background cell.
  background = {
    type = "blank",
    path = nil,
    theme = "stars",
    hl = "Comment",
    position = {
      row = "center",
      col = "center",
    },
  },

  header = {
    art = {
      " ██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗          Z ",
      " ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║      Z     ",
      " ██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║   z        ",
      " ██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║ z          ",
      " ███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║            ",
      " ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝            ",
    },
    hl = "Title",
    position = {
      row = "center",
      col = "center",
    },
    zone = {
      percentage = 0.30,
      padding = { top = 1, bot = 1, left = 1, right = 1 },
      margin = { top = 0, bot = 0, left = 0, right = 0 },
    },
  },

  menu = {
    items = {
      { icon = " ", key = "f", desc = "Find File", action = function() pick("files") end },
      { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
      { icon = " ", key = "p", desc = "Projects", action = function() pick("projects") end },
      { icon = " ", key = "g", desc = "Find Text", action = function() pick("live_grep") end },
      { icon = " ", key = "r", desc = "Recent Files", action = function() pick("oldfiles") end },
      { icon = " ", key = "c", desc = "Config", action = function() pick("files", { cwd = vim.fn.stdpath("config") }) end },
      { icon = " ", key = "s", desc = "Restore Session", action = M.restore_session },
      { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
      { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
      { icon = " ", key = "q", desc = "Quit", action = ":qa" },
    },
    position = {
      row = "center",
      col = "center",
    },
    zone = {
      percentage = 0.40,
      padding = { top = 1, bot = 1, left = 1, right = 1 },
      margin = { top = 0, bot = 0, left = 0, right = 0 },
    },
    hl_icon = "Special",
    hl_desc = "Normal",
    hl_key = "Keyword",
    -- Horizontal shift: moves icon+desc left and key right (each by this many chars),
    -- widening the gap between description and keymap. Set to 0 for default centered layout.
    h_shift = 10,
  },

  stats = {
    show = {
      plugins_loaded = true,
      plugin_load_time = true,
      folders = false,
      hidden_folders = false,
      files = false,
      hidden_files = false,
    },
    path = nil,
    depth = 3,
    max_entries = 5000,
    batch_size = 50,
    use_gitignore = true,
    ignore_patterns = {},
    skip_dirs = {
      "node_modules", ".git", ".cache", "__pycache__",
      ".venv", "vendor", ".next", "target", "build", "dist",
    },
    position = {
      row = "center",
      col = "center",
    },
    zone = {
      percentage = 0.15,
      padding = { top = 1, bot = 1, left = 1, right = 1 },
      margin = { top = 0, bot = 0, left = 0, right = 0 },
    },
    hl_text = "Comment",
  },

  footer = {
    text = "Welcome back. Time to build.",
    hl = "Comment",
    position = {
      row = "center",
      col = "center",
    },
    zone = {
      percentage = 0.15,
      padding = { top = 1, bot = 1, left = 1, right = 1 },
      margin = { top = 0, bot = 0, left = 0, right = 0 },
    },
  },

  debug = {
    enabled = false,
    zones = false,
  },

  log = {
    enabled = false,
    zones = false,
    -- nil resolves to stdpath("state")/foyer/foyer-debug.log at runtime
    file = nil,
  },
}

--- Sets up foyer.nvim with the given options.
--- Merges user config with defaults, creates the VimEnter autocmd to show the
--- dashboard on startup, and exposes the `:Foyer` user command.
---@param opts? table User configuration table (merged into M.config)
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Automatically trigger Foyer on VimEnter if starting with an empty buffer
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      if vim.fn.argc() == 0 and vim.api.nvim_buf_get_name(0) == "" and vim.bo.buftype == "" then
        require("foyer.ui").open()
      end
    end,
  })

  -- Expose user command
  vim.api.nvim_create_user_command("Foyer", function()
    require("foyer.ui").open()
  end, {})

  -- Debug command
  vim.api.nvim_create_user_command("FoyerDebug", function()
    local config = require("foyer").config
    local screen = require("foyer.lib.screen")
    local usable = screen.usable()

    local lines = {
      "## Foyer Debug",
      string.format("Canvas: %dx%d", usable.width, usable.height),
      string.format("Total zone pct: %.2f",
        config.header.zone.percentage + config.menu.zone.percentage +
        config.stats.zone.percentage + config.footer.zone.percentage),
      string.format("Debug enabled: %s", tostring(config.debug.enabled)),
      string.format("Debug zones: %s", tostring(config.debug.zones)),
      string.format("Log enabled: %s", tostring(config.log.enabled)),
      string.format("Log zones: %s", tostring(config.log.zones)),
      string.format("Log file: %s", tostring(config.log.file)),
      "",
      "=== Zone Configs ===",
    }

    for _, key in ipairs({ "header", "menu", "stats", "footer" }) do
      local z = config[key].zone
      lines[#lines + 1] = string.format("%s: pct=%.2f pad={t=%d,b=%d,l=%d,r=%d} margin={t=%d,b=%d,l=%d,r=%d}",
        key, z.percentage, z.padding.top, z.padding.bot,
        z.padding.left, z.padding.right, z.margin.top, z.margin.bot,
        z.margin.left, z.margin.right)
    end

    -- Compute live zones (reuses ui.lua logic)
    local function normalize_padding(val)
      if type(val) == "number" then
        return { top = val, bot = val, left = val, right = val }
      end
      return {
        top = val.top or 2,
        bot = val.bot or 2,
        left = val.left or 2,
        right = val.right or 2,
      }
    end

    local function normalize_margin(val)
      if type(val) == "number" then
        return { top = val, bot = val, left = val, right = val }
      end
      return {
        top = val.top or 0,
        bot = val.bot or 0,
        left = val.left or 0,
        right = val.right or 0,
      }
    end

    local layers = {
      { key = "header", zone = config.header.zone },
      { key = "menu",   zone = config.menu.zone },
      { key = "stats",  zone = config.stats.zone },
      { key = "footer", zone = config.footer.zone },
    }

    for _, layer in ipairs(layers) do
      layer.zone.padding = normalize_padding(layer.zone.padding)
      layer.zone.margin = normalize_margin(layer.zone.margin)
    end

    local total_pct = 0
    for _, layer in ipairs(layers) do
      total_pct = total_pct + layer.zone.percentage
    end

    local remaining_pct = math.max(0, 1.0 - total_pct)
    local remaining_lines = math.floor(remaining_pct * usable.height)
    local margin_per_zone = math.floor(remaining_lines / (#layers * 2))

    for _, layer in ipairs(layers) do
      layer.zone.margin.top = layer.zone.margin.top + margin_per_zone
      layer.zone.margin.bot = layer.zone.margin.bot + margin_per_zone
    end

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

    lines[#lines + 1] = ""
    lines[#lines + 1] = "=== Computed Zones ==="
    for _, key in ipairs({ "header", "menu", "stats", "footer" }) do
      local z = zones[key]
      lines[#lines + 1] = string.format("%s: row=%d height=%d (row+height=%d)", key, z.row, z.height, z.row + z.height)
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = string.format("Next after footer: row %d (canvas height: %d)", current_row, usable.height)

    if current_row > usable.height + 1 then
      lines[#lines + 1] = string.format("OVERFLOW: content extends %d lines past canvas", current_row - usable.height - 1)
    end

    local footer = zones.footer
    if footer and footer.row + footer.height > usable.height then
      lines[#lines + 1] = string.format("WARNING: footer zone extends %d lines beyond canvas",
        footer.row + footer.height - usable.height)
    end

    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Foyer Debug" })
  end, { desc = "Debug Foyer dashboard layout" })
end

return M
