local M = {}

function M.highlight(hl, str, hl_end)
  str = '%#' .. hl .. '#' .. str
  if hl_end ~= nil then
    return str .. '%#' .. hl_end .. '#'
  end
  return str
end

function M.render_spacer(hl, width)
  return M.highlight(hl, (' '):rep(width))
end

-- TODO move into utils
function M.file_tree_width()
  local tab_id = vim.api.nvim_get_current_tabpage()
  for _, win_id in ipairs(vim.api.nvim_tabpage_list_wins(tab_id)) do
    local buf_id = vim.api.nvim_win_get_buf(win_id)
    if vim.fn.getbufvar(buf_id, '__is-file-tree') == true then
      return vim.api.nvim_win_get_width(win_id)
    end
  end

  return 0
end

function M.map(list, fn)
  local ret = {}
  for i, value in ipairs(list) do
    table.insert(ret, fn(value, i))
  end

  return ret
end

function M.find_end(list, fn)
  local ret = {}
  for i, value in ipairs(list) do
    if not fn(value, i) then
      table.insert(ret, value)
    else
      break
    end
  end

  return ret
end

function M.find_start(list, fn)
  local ret = {}
  local found = false

  for i, value in ipairs(list) do
    found = found or fn(value, i)

    if found then
      table.insert(ret, value)
    end
  end

  return ret
end

return M
