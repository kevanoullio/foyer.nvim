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
  },
  menu = {
    items = {
      { icon = " ", key = "f", desc = "Find File",       action = function() M.pick("files") end },
      { icon = " ", key = "n", desc = "New File",        action = ":ene | startinsert" },
      { icon = " ", key = "g", desc = "Find Text",       action = function() M.pick("live_grep") end },
      { icon = " ", key = "r", desc = "Recent Files",    action = function() M.pick("oldfiles") end },
      { icon = " ", key = "c", desc = "Config",          action = ":e $MYVIMRC" },
      { icon = "󰒲 ", key = "l", desc = "Lazy",            action = ":Lazy" },
      { icon = " ", key = "q", desc = "Quit",            action = ":qa" },
    },
    hl_icon = "Special",
    hl_desc = "Normal",
    hl_key = "Keyword",
  },
  footer = {
    text = "Welcome back. Time to build.",
    hl = "Comment",
  },
}

function M.pick(cmd)
  local ok_snacks, snacks = pcall(require, "snacks")
  if ok_snacks and snacks.picker then
    if cmd == "files" then snacks.picker.files()
    elseif cmd == "live_grep" then snacks.picker.grep()
    elseif cmd == "oldfiles" then snacks.picker.recent()
    end
    return
  end

  local ok_telescope, builtin = pcall(require, "telescope.builtin")
  if ok_telescope then
    if cmd == "files" then builtin.find_files()
    elseif cmd == "live_grep" then builtin.live_grep()
    elseif cmd == "oldfiles" then builtin.oldfiles()
    end
    return
  end

  local ok_fzf, fzf = pcall(require, "fzf-lua")
  if ok_fzf then
    if cmd == "files" then fzf.files()
    elseif cmd == "live_grep" then fzf.live_grep()
    elseif cmd == "oldfiles" then fzf.oldfiles()
    end
  end
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
