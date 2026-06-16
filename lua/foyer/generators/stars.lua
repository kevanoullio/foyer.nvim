local M = {}

function M.generate(width, height)
  local lines = {}
  math.randomseed(width + height)

  local star_chars = { ".", "*", "✦", " ", " ", " ", " " }

  for r = 1, height do
    local chars = {}
    for c = 1, width do
      if math.random() < 0.04 then
        chars[c] = star_chars[math.random(1, #star_chars)]
      else
        chars[c] = " "
      end
    end
    lines[r] = table.concat(chars)
  end
  return lines
end

return M
