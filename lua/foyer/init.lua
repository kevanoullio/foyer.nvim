local M = {}

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
      { icon = " ", key = "f", desc = "Find File", action = function() M.pick("files") end },
      { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
      { icon = " ", key = "g", desc = "Find Text", action = function() M.pick("live_grep") end },
      { icon = " ", key = "r", desc = "Recent Files", action = function() M.pick("oldfiles") end },
      { icon = " ", key = "c", desc = "Config", action = function() M.pick("files", { cwd = vim.fn.stdpath("config") }) end },
      { icon = " ", key = "s", desc = "Restore Session", action = function() M.restore_session() end },
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

function M.pick(cmd, opts)
  opts = opts or {}
  local cwd = opts.cwd

  local ok_snacks, snacks = pcall(require, "snacks")
  if ok_snacks and snacks.picker then
    local picker_opts = cwd and { cwd = cwd } or {}
    if cmd == "files" then
      snacks.picker.files(picker_opts)
    elseif cmd == "live_grep" then
      snacks.picker.grep(picker_opts)
    elseif cmd == "oldfiles" then
      snacks.picker.recent(picker_opts)
    end
    return
  end

  local ok_telescope, builtin = pcall(require, "telescope.builtin")
  if ok_telescope then
    local telescope_opts = cwd and { cwd = cwd } or {}
    if cmd == "files" then
      builtin.find_files(telescope_opts)
    elseif cmd == "live_grep" then
      builtin.live_grep(telescope_opts)
    elseif cmd == "oldfiles" then
      builtin.oldfiles(telescope_opts)
    end
    return
  end

  local ok_fzf, fzf = pcall(require, "fzf-lua")
  if ok_fzf then
    local fzf_opts = cwd and { cwd = cwd } or {}
    if cmd == "files" then
      fzf.files(fzf_opts)
    elseif cmd == "live_grep" then
      fzf.live_grep(fzf_opts)
    elseif cmd == "oldfiles" then
      fzf.oldfiles(fzf_opts)
    end
  end
end

function M.restore_session()
  local session_plugins = {
    { name = "persistence", mod = "persistence", cmd = function() require("persistence").load() end },
    { name = "persisted", mod = "persisted", cmd = function() require("persisted").load() end },
    { name = "neovim-session-manager", mod = "session_manager", cmd = function() vim.cmd("SessionManager load_current_dir_session") end },
    { name = "possession", mod = "possession", cmd = function() vim.cmd("PossessionLoadCwd") end },
    { name = "mini.sessions", mod = "mini.sessions", cmd = function() require("mini.sessions").read() end },
    { name = "auto-session", mod = "auto_session", cmd = function() vim.cmd("AutoSession restore") end },
  }

  for _, plugin in ipairs(session_plugins) do
    local ok, mod = pcall(require, plugin.mod)
    if ok then
      plugin.cmd()
      return
    end
  end

  vim.notify("No session plugin found", vim.log.levels.WARN)
end

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
