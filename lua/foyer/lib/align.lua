local M = {}

--- Core alignment logic.
--- Returns the offset (padding) needed to position content within a container.
--- Values are unclamped — callers decide whether to apply math.max(0, ...) or math.max(1, ...).
---
--- @param container number Total size of the container (width or height)
--- @param content number Size of the content to position
--- @param position "left" | "center" | "right" | "top" | "bottom" Alignment mode
--- @return number Offset value (unclamped, may be negative)
local function _align(container, content, position)
  if position == "center" then
    return math.floor((container - content) / 2)
  elseif position == "right" then
    return container - content
  end
  -- "left" / "top" / default
  return 0
end

--- Core alignment function.
--- Returns the offset (padding) needed to position content within a container.
--- Values are unclamped — callers decide whether to apply math.max(0, ...) or math.max(1, ...).
---
--- @param container number Total size of the container (width or height)
--- @param content number Size of the content to position
--- @param position "left" | "center" | "right" | "top" | "bottom" Alignment mode
--- @return number Offset value (unclamped, may be negative)
function M.align(container, content, position)
  return _align(container, content, position or "left")
end

--- Convenience wrapper for row positioning.
---
--- @param container number Total height
--- @param content number Content height
--- @param position "top" | "center" | "bottom"
--- @return number Row offset
function M.row(container, content, position)
  return _align(container, content, position or "top")
end

--- Convenience wrapper for column positioning.
---
--- @param container number Total width
--- @param content number Content width
--- @param position "left" | "center" | "right"
--- @return number Column offset
function M.col(container, content, position)
  return _align(container, content, position or "left")
end

--- Computes both row and column offsets in one call.
---
--- @param container_height number Total available height
--- @param container_width number Total available width
--- @param content_height number Content height
--- @param content_width number Content width
--- @param row_align "top" | "center" | "bottom"
--- @param col_align "left" | "center" | "right"
--- @return {row: number, col: number}
function M.position(container_height, container_width, content_height, content_width, row_align, col_align)
  row_align = row_align or "center"
  col_align = col_align or "center"
  return {
    row = M.row(container_height, content_height, row_align),
    col = M.col(container_width, content_width, col_align),
  }
end

return M
