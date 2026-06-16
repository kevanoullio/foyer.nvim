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
    },
  },
  footer = {
    text = "Welcome back. Time to build.",
    hl = "Comment",
  },
}

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
