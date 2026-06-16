local M = {}

function M.render(canvas, width, start_row)
  local config = require("foyer").config.header
  if not config.art or #config.art == 0 then return start_row end

  -- Calculate horizontal offset for dynamic text centering bounds
  local max_len = 0
  for _, line in ipairs(config.art) do
    if #line > max_len then max_len = #line end
  end
  local start_col = math.max(1, math.floor((width - max_len) / 2))

  -- Apply to layout compositor using active transparency masking rules (true)
  canvas:blend(config.art, start_row, start_col, true, config.hl)

  return start_row + #config.art
end

return M
