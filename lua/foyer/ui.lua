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

  -- Get usable terminal dimensions (accounts for cmdheight and statusline)
  local screen = require("foyer.lib.screen")
  local usable = screen.usable()
  local width = usable.width
  local height = usable.height

  -- Create a fresh empty virtual canvas
  local canvas = Canvas.new(width, height)

  -- Step 1: Render background layer (Opaque)
  require("foyer.layers.background").render(canvas, width, height)

  -- Step 2: Render foreground components sequentially using composition math (Transparent)
  local config = require("foyer").config
  local align = require("foyer.lib.align")

  -- Header: vertically centered in upper portion of screen
  local header_height = #config.header.art
  local header_row = math.max(1, math.floor((height - header_height) / 3))
  local current_row = require("foyer.layers.header").render(canvas, width, header_row) + 3

  -- Menu: vertically positioned within remaining space with configurable alignment
  local menu_items = config.menu.items
  local menu_height = menu_items and (#menu_items * 2) or 0
  local remaining_space = height - current_row
  local menu_row_offset = remaining_space > menu_height
    and align.row(remaining_space, menu_height, config.menu.row_align or "center")
    or 0
  local menu_row = math.max(1, current_row + menu_row_offset)
  local interactive_lines

  -- Footer: positioned at bottom of screen
  local footer_row = math.max(1, height - 1)

  -- Render menu and footer
  current_row, interactive_lines = require("foyer.layers.menu").render(canvas, width, height, menu_row)
  require("foyer.layers.footer").render(canvas, width, height, footer_row)

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
