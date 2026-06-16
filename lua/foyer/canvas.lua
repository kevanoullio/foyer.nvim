local M = {}
local Canvas = {}
Canvas.__index = Canvas

function M.new(width, height)
  local self = setmetatable({}, Canvas)
  self.width = width
  self.height = height
  self.grid = {}
  self.highlights = {} -- Stores: { row, start_col, end_col, hl_group }

  -- Allocate an empty grid
  for r = 1, height do
    self.grid[r] = {}
    for c = 1, width do
      self.grid[r][c] = " "
    end
  end
  return self
end

--- Blends an array of strings into the canvas grid
--- @param lines table Array of strings representing the graphic asset
--- @param start_row number 1-indexed top coordinate
--- @param start_col number 1-indexed left coordinate
--- @param transparent boolean If true, ' ' chars in lines will NOT overwrite background data
--- @param hl_group string|nil Optional highlight group for this asset layer
function Canvas:blend(lines, start_row, start_col, transparent, hl_group)
  for r_offset, line in ipairs(lines) do
    local target_r = start_row + r_offset - 1
    if target_r > self.height then break end

    -- Convert string line to characters handling UTF-8 safely if possible
    -- Simplification: iterate via byte sequences or subchars
    for c_offset = 1, #line do
      local target_c = start_col + c_offset - 1
      if target_c > self.width then break end

      local char = line:sub(c_offset, c_offset)

      if not (transparent and char == " ") then
        if self.grid[target_r] then
          self.grid[target_r][target_c] = char
        end
      end
    end

    -- Save highlights bound to this row segment
    if hl_group and self.grid[target_r] then
      table.insert(self.highlights, {
        row = target_r - 1, -- Neovim API relies on 0-indexed rows
        start_col = start_col - 1,
        end_col = start_col + #line - 1,
        hl_group = hl_group,
      })
    end
  end
end

--- Flattens the memory grid matrix into a table of printable string rows
function Canvas:flush()
  local out = {}
  for r = 1, self.height do
    out[r] = table.concat(self.grid[r])
  end
  return out, self.highlights
end

return M
