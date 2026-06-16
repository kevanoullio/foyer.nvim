local M = {}
local Canvas = require("foyer.canvas")

M.bufnr = nil

function M.open()
  if M.bufnr and vim.api.nvim_buf_is_valid(M.bufnr) then
    vim.api.nvim_set_current_buf(M.bufnr)
    return
  end

  M.bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(M.bufnr)

  -- Set safe buffer options for a pristine, non-file screen
  local opts = {
    bufhidden = "wipe",
    buftype = "nofile",
    swapfile = false,
    filetype = "foyer",
    modifiable = false,
  }
  for k, v in pairs(opts) do vim.bo[M.bufnr][k] = v end

  -- Clean window layout options
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"
  vim.wo.foldcolumn = "0"

  M.render()

  -- Dynamic resizing listener
  vim.api.nvim_create_autocmd("VimResized", {
    buffer = M.bufnr,
    callback = function()
      M.render()
    end,
  })
end

function M.render()
  if not M.bufnr or not vim.api.nvim_buf_is_valid(M.bufnr) then return end

  local width = vim.api.nvim_win_get_width(0)
  local height = vim.api.nvim_win_get_height(0)

  -- Create a fresh empty virtual canvas
  local canvas = Canvas.new(width, height)

  -- Step 1: Render background layer (Opaque)
  -- require("foyer.layers.background").render(canvas, width, height)

  -- Step 2: Render foreground components sequentially using composition math (Transparent)
  local current_row = math.floor(height * 0.15)

  -- Header
  current_row = require("foyer.layers.header").render(canvas, width, current_row) + 3

  -- Menu
  local interactive_lines
  current_row, interactive_lines = require("foyer.layers.menu").render(canvas, width, current_row)

  -- Footer
  require("foyer.layers.footer").render(canvas, width, height - 2)

  -- Push contents from canvas matrix memory onto Neovim screen
  local text_lines, highlights = canvas:flush()

  vim.bo[M.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(M.bufnr, 0, -1, false, text_lines)
  vim.bo[M.bufnr].modifiable = false

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
