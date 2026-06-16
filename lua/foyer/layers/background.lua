local M = {}
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

  start_row = math.max(1, math.floor((height - art_height) / 2))
  start_col = math.max(1, math.floor((width - art_width) / 2))

  canvas:blend(bg_lines, start_row, start_col, false, config.hl)
end

return M
