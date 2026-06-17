local M = {}
local align = require("foyer.lib.align")
local loader = require("foyer.loader")
local generators = require("foyer.generators")

function M.render(canvas, width, height)
  local config = require("foyer").config.background
  local bg_lines
  local start_row, start_col

  if config.type == "file" then
    bg_lines = loader.read_lines(config.path)
    if not bg_lines then
      return
    end
  elseif config.type == "generated" then
    bg_lines = generators.generate(config.theme, width, height)
    if not bg_lines then
      return
    end
  else
    return
  end

  local art_height = #bg_lines
  local art_width = 0
  for _, line in ipairs(bg_lines) do
    if #line > art_width then
      art_width = #line
    end
  end

  -- Compute centered position using alignment helpers
  local pos = align.position(height, width, art_height, art_width, "center", "center")
  start_row = math.max(1, 1 + pos.row)
  start_col = math.max(1, 1 + pos.col)

  canvas:blend(bg_lines, start_row, start_col, false, config.hl)
end

return M
