local M = {}

local FOLDER_CAP = 500
local FILE_CAP = 5000

--- Formats a number with comma separators (e.g. 1234 -> "1,234").
--- When capped is true, appends "+" instead (e.g. "500+").
---@param n number
---@param cap number
---@param capped boolean
---@return string
local function fmt_num(n, cap, capped)
  if capped then return cap .. "+" end
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
    local max_entries = config.max_entries or 5000
    local batch_size = config.batch_size or 50
    local skip_dirs = {}
    for _, name in ipairs(config.skip_dirs or {
      "node_modules", ".git", ".cache", "__pycache__",
      ".venv", "vendor", ".next", "target", "build", "dist",
    }) do
      skip_dirs[name] = true
    end

    -- Placeholder
    fs_stats_row = row
    local placeholder = "\226\128\147 computing..."
    local col_offset = require("foyer.lib.align").col(width, #placeholder, "center")
    local start_col = 1 + pad.left + col_offset
    canvas:blend({ placeholder }, row, start_col, false, hl)

    -- Create ignore checker
    local ignore_checker
    if config.use_gitignore then
      local ok, gi = pcall(require, "foyer.lib.gitignore")
      if ok then
        ignore_checker = gi.checker(path)
      end
    end

    local ignore_patterns = config.ignore_patterns or {}

    --- Asynchronously walks a directory tree in cooperative batches so the
    --- Neovim event loop can process input between chunks.
    ---@param root string Root directory to scan
    ---@param max_depth integer Maximum recursion depth
    ---@param batch integer Entries per defer_fn tick
    ---@param max_entries integer Total entry limit
    ---@param skip table<string, true> Directory names to skip recursion into
    ---@param ignore_checker { is_ignored: fun(relpath: string, name: string, is_dir: boolean): boolean, flush: fun(cb: fun())? }|nil
    ---@param ignore_patterns string[] Lua patterns for custom ignores
    ---@param cb fun(folders: integer, hidden_folders: integer, files: integer, hidden_files: integer, capped: {f: boolean, hf: boolean, fi: boolean, hi: boolean})
    local function async_scan(root, max_depth, batch, max_entries, skip, ignore_checker, ignore_patterns, cb)
      local result = { f = 0, hf = 0, fi = 0, hi = 0 }
      local dirs = { { path = root, hidden = false, depth = max_depth, relpath = "" } }
      local total = 0
      local current
      local handle

      local done, finalize, flush_and_process, process_next_batch, scan_next_dir
      local capped = { f = false, hf = false, fi = false, hi = false }

      done = function()
        cb(result.f, result.hf, result.fi, result.hi, capped)
      end

      finalize = function(collected, dir_done)
        for _, item in ipairs(collected) do
          if skip[item.name] then goto skip end

          local child_path = vim.fs.joinpath(current.path, item.name)
          local stat = vim.uv.fs_stat(child_path)

          if ignore_checker and ignore_checker.is_ignored(item.relpath, item.name, stat and stat.type == "directory") then
            goto skip end

          for _, pat in ipairs(ignore_patterns) do
            if item.relpath:match(pat) then goto skip end
          end

          if stat then
            if stat.type == "directory" then
              local ch = current.hidden or (item.name:sub(1, 1) == ".")
              result.f = result.f + 1
              if ch then result.hf = result.hf + 1 end
              if result.f >= FOLDER_CAP then capped.f = true end
              if result.hf >= FOLDER_CAP then capped.hf = true end
              if capped.f and capped.fi then return done() end
              if not skip[item.name] then
                table.insert(dirs, { path = child_path, hidden = ch, depth = current.depth - 1, relpath = item.relpath })
              end
            else
              result.fi = result.fi + 1
              if current.hidden then result.hi = result.hi + 1 end
              if result.fi >= FILE_CAP then capped.fi = true end
              if result.hi >= FILE_CAP then capped.hi = true end
              if capped.f and capped.fi then return done() end
            end
          end

          ::skip::
        end

        if dir_done then vim.defer_fn(scan_next_dir, 1)
        else vim.defer_fn(process_next_batch, 1) end
      end

      flush_and_process = function(collected, dir_done)
        if #collected == 0 then
          if dir_done then vim.defer_fn(scan_next_dir, 1)
          else vim.defer_fn(process_next_batch, 1) end
          return
        end

        if ignore_checker and ignore_checker.flush then
          for _, item in ipairs(collected) do
            ignore_checker.is_ignored(item.relpath, item.name, false)
          end
          ignore_checker.flush(function() finalize(collected, dir_done) end)
        else
          finalize(collected, dir_done)
        end
      end

      process_next_batch = function()
        local collected = {}
        for _ = 1, batch do
          local entry = vim.uv.fs_scandir_next(handle)
          if not entry then
            flush_and_process(collected, true)
            return
          end

          total = total + 1
          if total >= max_entries then return done() end

          table.insert(collected, { name = entry, relpath = vim.fs.joinpath(current.relpath or "", entry) })
        end
        flush_and_process(collected, false)
      end

      scan_next_dir = function()
        if total >= max_entries or #dirs == 0 then return done() end

        current = table.remove(dirs, 1)
        if current.depth <= 0 then
          vim.defer_fn(scan_next_dir, 1)
          return
        end

        handle = vim.uv.fs_scandir(current.path)
        if not handle then
          vim.defer_fn(scan_next_dir, 1)
          return
        end

        process_next_batch()
      end

      vim.defer_fn(scan_next_dir, 100)
    end

    async_scan(path, depth, batch_size, max_entries, skip_dirs, ignore_checker, ignore_patterns, function(folders, hidden_folders, files, hidden_files, capped)
      if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return end
      M.update(bufnr, fs_stats_row, folders, hidden_folders, files, hidden_files, config, capped)
    end)

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
---@param capped? {f: boolean, hf: boolean, fi: boolean, hi: boolean}
function M.update(bufnr, fs_row, folders, hidden_folders, files, hidden_files, config, capped)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  capped = capped or { f = false, hf = false, fi = false, hi = false }

  local parts = {}
  if config.show.folders and config.show.hidden_folders then
    table.insert(parts, string.format("%s folders (%s hidden)",
      fmt_num(folders, FOLDER_CAP, capped.f), fmt_num(hidden_folders, FOLDER_CAP, capped.hf)))
  elseif config.show.folders then
    table.insert(parts, string.format("%s folders", fmt_num(folders, FOLDER_CAP, capped.f)))
  elseif config.show.hidden_folders then
    table.insert(parts, string.format("%s hidden", fmt_num(hidden_folders, FOLDER_CAP, capped.hf)))
  end

  if config.show.files and config.show.hidden_files then
    table.insert(parts, string.format("%s files (%s hidden)",
      fmt_num(files, FILE_CAP, capped.fi), fmt_num(hidden_files, FILE_CAP, capped.hi)))
  elseif config.show.files then
    table.insert(parts, string.format("%s files", fmt_num(files, FILE_CAP, capped.fi)))
  elseif config.show.hidden_files then
    table.insert(parts, string.format("%s hidden", fmt_num(hidden_files, FILE_CAP, capped.hi)))
  end

  local text = table.concat(parts, "  ")

  local line_idx = fs_row - 1
  if line_idx >= 0 and line_idx < #lines then
    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, line_idx, line_idx + 1, false, { text })
    vim.bo[bufnr].modifiable = false
  end
end

return M
