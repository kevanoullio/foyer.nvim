local M = {}

--- Append a line to the given log file.
---@param filepath string Path to the log file
---@param ... any Values to concatenate into the line
function M.log(filepath, ...)
  local fd = io.open(filepath, "a+")
  if not fd then return end
  local parts = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    parts[#parts + 1] = type(v) == "string" and v or vim.inspect(v)
  end
  fd:write(table.concat(parts, "  ") .. "\n")
  fd:close()
end

--- Write a batch separator between render cycles.
---@param filepath string Path to the log file
function M.sep(filepath)
  local fd = io.open(filepath, "a+")
  if not fd then return end
  fd:write("\n----------------------\n")
  fd:close()
end

return M
