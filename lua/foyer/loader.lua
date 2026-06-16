local M = {}

function M.read_lines(path)
  if not path or path == "" then
    return nil
  end

  local ok, fd = pcall(io.open, path, "r")
  if not ok or not fd then
    return nil
  end

  local lines = {}
  for line in fd:lines() do
    table.insert(lines, line)
  end
  fd:close()

  if #lines == 0 then
    return nil
  end

  return lines
end

return M
