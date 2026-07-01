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

--- Extracts a single character from a string at a given 0-based character index.
--- Uses vim.fn.strcharpart for correct UTF-8 multi-byte character handling.
--- @param s string The source string
--- @param char_idx number 0-based character index
--- @return string Single character (may be multi-byte)
local function char_at(s, char_idx)
  return vim.fn.strcharpart(s, char_idx, 1)
end

--- Blends an array of strings into the canvas grid.
--- Operates at the character level (not byte level) so that multi-byte UTF-8
--- characters (e.g. Nerd Font icons) occupy exactly one canvas column each,
--- matching the terminal's display behavior.
--- Highlight extmarks use byte positions (required by Neovim), not character
--- counts, so we compute byte ranges from the actual grid cell content.
--- @param lines table Array of strings representing the graphic asset
--- @param start_row number 1-indexed top coordinate
--- @param start_col number 1-indexed left coordinate
--- @param transparent boolean If true, ' ' chars in lines will NOT overwrite background data
--- @param hl_group string|nil Optional highlight group for this asset layer
function Canvas:blend(lines, start_row, start_col, transparent, hl_group)
  for r_offset, line in ipairs(lines) do
    local target_r = start_row + r_offset - 1
    if target_r > self.height then break end

    local char_count = vim.fn.strchars(line)
    local first_c = nil
    local last_c = nil

    for c_offset = 0, char_count - 1 do
      local target_c = start_col + c_offset
      if target_c > self.width then break end
      if target_c < 1 then
        goto continue
      end

      local char = char_at(line, c_offset)

      if not (transparent and char == " ") then
        if self.grid[target_r] then
          self.grid[target_r][target_c] = char
        end
      end

      if first_c == nil then first_c = target_c end
      last_c = target_c

      ::continue::
    end

    -- Save highlights bound to this row segment.
    -- Use byte positions derived from the grid (not character counts),
    -- so multi-byte characters produce correct extmark ranges.
    if hl_group and self.grid[target_r] and first_c then
      local byte_start = 0
      for c = 1, first_c - 1 do
        byte_start = byte_start + #self.grid[target_r][c]
      end

      local byte_pos = byte_start
      for c = first_c, last_c do
        byte_pos = byte_pos + #self.grid[target_r][c]
      end

      table.insert(self.highlights, {
        row = target_r - 1,
        start_col = byte_start,
        end_col = byte_pos,
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
