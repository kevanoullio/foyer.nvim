local M = {}

function M.render(canvas, width, start_row)
  local config = require("foyer").config.footer
  if not config.text or config.text == "" then return end

  local start_col = math.max(1, math.floor((width - #config.text) / 2))
  canvas:blend({ config.text }, start_row, start_col, true, config.hl)
end

return M
