local M = {}

function M.generate(width, height)
  math.randomseed(width + height)
  local lines = {}

  for r = 1, height do
    local chars = {}
    local phase = (r - 1) * 0.5

    for c = 1, width do
      local wave = math.sin((c - 1) * 0.15 + phase)
      local p = math.random()

      if wave > 0.6 then
        chars[c] = "~"
      elseif wave > 0.2 then
        chars[c] = "-"
      elseif wave < -0.6 then
        chars[c] = "~"
      elseif wave < -0.2 then
        chars[c] = "-"
      elseif p < 0.01 then
        chars[c] = "."
      else
        chars[c] = " "
      end
    end
    lines[r] = table.concat(chars)
  end
  return lines
end

return M
