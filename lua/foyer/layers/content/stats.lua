local M = {}

--- Formats a number with comma separators (e.g. 1234 -> "1,234").
---@param n number
---@return string
local function fmt_num(n)
  local s = tostring(n)
  local changed
  repeat
    s, changed = s:gsub("(%d)(%d%d%d)(%d%d%d)$", "%1,%2,%3")
  until not changed
  return s
end

--- Renders plugin and filesystem stats within the stats content zone.
--- Plugin stats are rendered synchronously; filesystem stats are computed
--- asynchronously and call M.update when complete.
---@param canvas table Canvas instance
---@param width number Canvas width
---@param _ number Unused canvas height
---@param zone {row: number, height: number} Content zone bounds
---@param config table Stats layer config (show, path, depth, etc.)
---@param bufnr number Buffer handle for async updates
---@return number, {} Content row and empty interaction table
function M.render(canvas, width, _, zone, config, bufnr)
  local show = config.show
  if not show then return zone.row, {} end

  local has_any = show.plugins_loaded or show.plugin_load_time or
                  show.folders or show.hidden_folders or
                  show.files or show.hidden_files
  if not has_any then return zone.row, {} end

  local pad = config.zone.padding
  local inner_top = zone.row + pad.top
  local inner_height = math.max(1, zone.height - pad.top - pad.bot)

  local line_count = 0
  if show.plugins_loaded or show.plugin_load_time then line_count = line_count + 1 end
  if show.folders or show.hidden_folders or show.files or show.hidden_files then line_count = line_count + 1 end

  local line_height = line_count * 2

  local content_row
  if inner_height > line_height then
    content_row = inner_top + math.floor((inner_height - line_height) / 2)
  else
    content_row = inner_top
  end

  local row = content_row
  local fs_stats_row = nil
  local hl = config.hl_text or "Comment"

  -- Plugin stats line
  if show.plugins_loaded or show.plugin_load_time then
    local parts = {}
    if show.plugins_loaded then
      local ok, stats = pcall(require, "lazy.stats")
      if ok and stats.stats then
        local s = stats.stats()
        table.insert(parts, string.format("Neovim loaded %d/%d plugins", s.loaded, s.count))
      end
    end
    if show.plugin_load_time then
      local ok, stats = pcall(require, "lazy.stats")
      if ok and stats.stats then
        local s = stats.stats()
        table.insert(parts, string.format("in %.2fms", s.startuptime))
      end
    end
    if #parts > 0 then
      local text = table.concat(parts, " ")
      local col_offset = require("foyer.lib.align").col(width, #text, "center")
      local start_col = 1 + pad.left + col_offset
      canvas:blend({ text }, row, start_col, false, hl)
    end
    row = row + 2
  end

  -- Filesystem stats line
  if show.folders or show.hidden_folders or show.files or show.hidden_files then
    local path = config.path or vim.fn.getcwd()
    local depth = config.depth or 3

    -- Placeholder
    fs_stats_row = row
    local placeholder = "\226\128\147 computing..."
    local col_offset = require("foyer.lib.align").col(width, #placeholder, "center")
    local start_col = 1 + pad.left + col_offset
    canvas:blend({ placeholder }, row, start_col, false, hl)

    --- Recursively walks a directory tree up to a given depth and counts
    --- folders and files (including hidden items).
    ---@param p string Starting directory path
    ---@param d integer Maximum recursion depth
    ---@return integer, integer, integer, integer folders, hidden_folders, files, hidden_files
    local function scan(p, d)
      local folders = 0
      local hidden_folders = 0
      local files = 0
      local hidden_files = 0

      local function recurse(dir, in_hidden)
        local handle = vim.uv.fs_scandir(dir)
        if not handle then return end
        local entry
        while true do
          entry = vim.uv.fs_scandir_next(handle)
          if not entry then break end
          local child_path = vim.fn.joinpath(dir, entry.name)
          local stat = vim.uv.fs_stat(child_path)
          if stat and stat.type == "directory" then
            local child_hidden = in_hidden or (entry.name:sub(1, 1) == ".")
            folders = folders + 1
            if child_hidden then hidden_folders = hidden_folders + 1 end
            if d > 1 then recurse(child_path, child_hidden) end
          elseif stat and stat.type == "file" then
            files = files + 1
            if in_hidden then hidden_files = hidden_files + 1 end
          end
        end
      end

      recurse(p, false)
      return folders, hidden_folders, files, hidden_files
    end

    -- Deferred scan so it doesn't block initial render
    vim.defer_fn(function()
      local folders, hidden_folders, files, hidden_files = scan(path, depth)
      if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return end
      M.update(bufnr, fs_stats_row, folders, hidden_folders, files, hidden_files, config, hl)
    end, 10)

    row = row + 2
  end

  return content_row, {}
end

--- Updates the buffer with computed filesystem stats, replacing the
--- "computing..." placeholder line.
---@param bufnr number Buffer handle
---@param fs_row number 1-indexed row in the buffer to update
---@param folders number Folder count
---@param hidden_folders number Hidden folder count
---@param files number File count
---@param hidden_files number Hidden file count
---@param config table Stats layer config (show flags)
---@param hl string Highlight group
function M.update(bufnr, fs_row, folders, hidden_folders, files, hidden_files, config, hl)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local parts = {}
  if config.show.folders and config.show.hidden_folders then
    table.insert(parts, string.format("%s folders (%s hidden)", fmt_num(folders), fmt_num(hidden_folders)))
  elseif config.show.folders then
    table.insert(parts, string.format("%s folders", fmt_num(folders)))
  elseif config.show.hidden_folders then
    table.insert(parts, string.format("%s hidden", fmt_num(hidden_folders)))
  end

  if config.show.files and config.show.hidden_files then
    table.insert(parts, string.format("%s files (%s hidden)", fmt_num(files), fmt_num(hidden_files)))
  elseif config.show.files then
    table.insert(parts, string.format("%s files", fmt_num(files)))
  elseif config.show.hidden_files then
    table.insert(parts, string.format("%s hidden", fmt_num(hidden_files)))
  end

  local text = table.concat(parts, "  ")

  local line_idx = fs_row - 1
  if line_idx >= 0 and line_idx < #lines then
    vim.bo[bufnr].modifiable = true
    lines[line_idx + 1] = text
    vim.api.nvim_buf_set_lines(bufnr, line_idx, line_idx + 1, false, lines)
    vim.bo[bufnr].modifiable = false
  end
end

return M
