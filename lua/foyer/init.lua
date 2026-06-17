local M = {}

--- Tries installed pickers in order: fzf-lua -> telescope -> mini.pick.
--- Calls the first one that loads and exits. Falls back to a notification.
---@param cmd string Picker command: "files", "live_grep", "oldfiles"
---@param opts? {cwd?: string} Options forwarded to the picker
---@return boolean true if a picker was found and executed
local function pick(cmd, opts)
  opts = opts or {}
  local picker_opts = opts.cwd and { cwd = opts.cwd } or {}

  local try = {
    function() return require("fzf-lua")[cmd](picker_opts) end,
    function()
      local builtin = require("telescope.builtin")
      local fn = cmd == "files" and "find_files" or cmd
      return builtin[fn](picker_opts)
    end,
    function() return require("mini.pick").builtin[cmd](picker_opts) end,
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
  -- Background layer options:
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
    zone = {
      percentage = 1.0,
      padding = { top = 0, bot = 0, left = 0, right = 0 },
      margin = { top = 0, bot = 0, left = 0, right = 0 },
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
      percentage = 0.25,
      padding = { top = 2, bot = 2, left = 2, right = 2 },
      margin = { top = 0, bot = 0, left = 0, right = 0 },
    },
  },

  menu = {
    items = {
      { icon = " ", key = "f", desc = "Find File", action = function() pick("files") end },
      { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
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
      percentage = 0.50,
      padding = { top = 2, bot = 2, left = 2, right = 2 },
      margin = { top = 0, bot = 0, left = 0, right = 0 },
    },
    hl_icon = "Special",
    hl_desc = "Normal",
    hl_key = "Keyword",
  },

  stats = {
    show = {
      plugins_loaded = true,
      plugin_load_time = true,
      folders = true,
      hidden_folders = true,
      files = true,
      hidden_files = true,
    },
    path = nil,
    depth = 3,
    position = {
      row = "center",
      col = "center",
    },
    zone = {
      percentage = 0.15,
      padding = { top = 2, bot = 2, left = 2, right = 2 },
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
      percentage = 0.10,
      padding = { top = 2, bot = 2, left = 2, right = 2 },
      margin = { top = 0, bot = 0, left = 0, right = 0 },
    },
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
end

return M
