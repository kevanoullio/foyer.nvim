local M = {}

local generators = {
  stars = require("foyer.generators.stars"),
  waves = require("foyer.generators.waves"),
}

function M.generate(theme, width, height)
  local gen = generators[theme]
  if not gen then
    return nil
  end
  return gen.generate(width, height)
end

return M
