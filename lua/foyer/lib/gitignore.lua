local M = {}

--- Converts a gitignore glob pattern (without leading `/` or trailing `/`)
--- into a Lua string pattern.
---@param glob string
---@return string
local function glob_to_lua(glob)
  local pat = glob
  pat = pat:gsub("%.", "%%.")
  pat = pat:gsub("%*%*", "{DS}")
  pat = pat:gsub("%*", "[^/]-")
  pat = pat:gsub("{DS}", ".*")
  pat = pat:gsub("%?", ".")
  return pat
end

--- Parses a single .gitignore line and returns a matcher function.
--- The matcher returns `true` if the entry should be ignored,
--- `false` if it should be un-ignored (negation), or `nil` if the
--- pattern does not apply.
---@param line string
---@return fun(relpath: string, name: string, is_dir: boolean): boolean|nil
local function parse_line(line)
  line = line:match("^%s*(.-)%s*$")
  if not line or line == "" or line:sub(1, 1) == "#" then return nil end

  local negate = false
  if line:sub(1, 1) == "!" then
    negate = true
    line = line:sub(2)
  end

  local dir_only = line:sub(-1) == "/"
  if dir_only then line = line:sub(1, -2) end

  local anchored = line:sub(1, 1) == "/"
  if anchored then line = line:sub(2) end

  local has_slash = line:find("/", 1, true)
  local has_glob = line:find("[*?[]")

  if not has_glob then
    if not has_slash and not anchored then
      return function(_, name, _)
        if name == line then return not negate end
        return nil
      end
    else
      return function(relpath, _, is_dir)
        if dir_only and not is_dir then return nil end
        if relpath == line or relpath:sub(-#line - 1) == "/" .. line then
          return not negate
        end
        return nil
      end
    end
  end

  local lua_pat = glob_to_lua(line)
  if not has_slash and not anchored then
    return function(_, name, _)
      if name:match("^" .. lua_pat .. "$") then
        return not negate
      end
      return nil
    end
  end

  return function(relpath, _, is_dir)
    if dir_only and not is_dir then return nil end
    if relpath:match(lua_pat .. "$") or relpath:match("^" .. lua_pat) then
      return not negate
    end
    return nil
  end
end

--- Reads a .gitignore file and returns a list of matcher functions.
---@param filepath string Path to the .gitignore file
---@return fun(relpath: string, name: string, is_dir: boolean): boolean|nil[]
local function load_matchers(filepath)
  local matchers = {}
  local file = io.open(filepath, "r")
  if not file then return matchers end
  for raw in file:lines() do
    local m = parse_line(raw)
    if m then table.insert(matchers, m) end
  end
  file:close()
  return matchers
end

--- Creates an ignore checker by parsing .gitignore files directly.
--- The returned checker works synchronously.
---@param root string Scan root directory
---@return { is_ignored: fun(relpath: string, name: string, is_dir: boolean): boolean, flush: nil }
function M.create_file_checker(root)
  local matchers = {}
  local gitignore_path = vim.fs.joinpath(root, ".gitignore")
  if vim.uv.fs_stat(gitignore_path) then
    matchers = load_matchers(gitignore_path)
  end

  ---@param relpath string Relative path from scan root
  ---@param name string Entry basename
  ---@param is_dir boolean True if entry is a directory
  ---@return boolean
  local function is_ignored(relpath, name, is_dir)
    local result = false
    for _, m in ipairs(matchers) do
      local r = m(relpath, name, is_dir)
      if r ~= nil then result = r end
    end
    return result
  end

  return { is_ignored = is_ignored, flush = nil }
end

--- Creates an ignore checker using `git check-ignore`.
--- Returns a checker with a `flush` method that must be called periodically
--- to populate the internal cache from the git subprocess.
---@param git_root string Git repository root
---@param scan_root string Scan root (for computing relative paths)
---@return { is_ignored: fun(relpath: string, name: string, is_dir: boolean): boolean, flush: fun(cb: fun())? }
function M.create_git_checker(git_root, scan_root)
  local cache = {}
  local pending = {}
  local flushing = false

  ---@param relpath string
  ---@param name string
  ---@param _is_dir boolean
  ---@return boolean
  local function is_ignored(relpath, name, _is_dir)
    if cache[relpath] ~= nil then return cache[relpath] end
    pending[relpath] = true
    return false
  end

  --- Sends all pending paths to `git check-ignore` and calls the
  --- callback when done. Must be called periodically from the
  --- async scan loop.
  ---@param cb fun()
  local function flush(cb)
    if flushing then
      if cb then vim.defer_fn(cb, 1) end
      return
    end
    local paths = vim.tbl_keys(pending)
    if #paths == 0 then
      pending = {}
      if cb then vim.defer_fn(cb, 1) end
      return
    end

    flushing = true
    local batch = pending
    pending = {}

    local args = { "git", "-C", git_root, "check-ignore", "--", unpack(paths) }
    vim.system(args, { text = true }, function(result)
      if result.code == 0 then
        for line in (result.stdout or ""):gmatch("[^\r\n]+") do
          cache[line] = true
        end
      end
      for _, p in ipairs(paths) do
        if cache[p] == nil then cache[p] = false end
      end
      flushing = false
      if cb then cb() end
    end)
  end

  return { is_ignored = is_ignored, flush = flush }
end

--- Creates an ignore checker for the given root directory.
--- Tries `git check-ignore` first; falls back to manual .gitignore parsing.
---@param root string Scan root directory
---@return { is_ignored: fun(relpath: string, name: string, is_dir: boolean): boolean, flush: fun(cb: fun())? }
function M.checker(root)
  local ok, git_root = pcall(vim.fs.root, root, ".git")
  if ok and git_root then
    return M.create_git_checker(git_root, root)
  end
  return M.create_file_checker(root)
end

return M
