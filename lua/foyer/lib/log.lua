local M = {}

--- Resolves a log file path. If nil or empty, defaults to
--- stdpath("state")/foyer/foyer-debug.log.
---@param filepath string|nil
---@return string
function M.resolve(filepath)
  if filepath and filepath ~= "" then
    return filepath
  end
  local state_dir = vim.fn.stdpath("state")
  local log_dir = state_dir "/foyer"
  vim.fn.mkdir(log_dir, "p")
  return log_dir "/foyer-debug.log"
end

--- Append a line to the given log file.
---@param filepath string|nil Path to the log file (nil = default location)
---@param ... any Values to concatenate into the line
function M.log(filepath, ...)
  local resolved = M.resolve(filepath)
  local fd = io.open(resolved, "a+")
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
---@param filepath string|nil Path to the log file (nil = default location)
function M.sep(filepath)
  local resolved = M.resolve(filepath)
  local fd = io.open(resolved, "a+")
  if not fd then return end
  fd:write("\n----------------------\n")
  fd:close()
end

return M
