local M = {}
local align = require("foyer.lib.align")
local loader = require("foyer.loader")
local generators = require("foyer.generators")

function M.render(canvas, width, height, zone)
  local config = require("foyer").config.background
  local bg_lines

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

  -- Compute centered position within zone using configured alignment
  local pos = align.position(zone.height, width, art_height, art_width,
    config.position.row or "center", config.position.col or "center")
  local start_row = zone.row + pos.row
  local start_col = 1 + pos.col

  canvas:blend(bg_lines, start_row, start_col, false, config.hl)
end

return M
