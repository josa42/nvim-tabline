local M = {}

function M.highlight(hl, str, hl_end)
  str = '%#' .. hl .. '#' .. str
  if hl_end ~= nil then
    return str .. '%#' .. hl_end .. '#'
  end
  return str
end

return M
