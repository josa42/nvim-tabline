local api = vim.api

local M = {}
local l = {}

function M.setup()
  vim.cmd([[
    hi! TabLineSel       guibg=#282c34 guifg=#abb2bf
    hi! TabLineSelBold   guibg=#282c34 guifg=#abb2bf gui=bold
    hi! TabLineSelMarker guibg=#282c34 guifg=#61afef
    hi! TabLineSelMeta   guibg=#282c34 guifg=#4b5263
    hi! TabLine          guibg=#21252B guifg=#5c6370
    hi! TabLineBold      guibg=#21252B guifg=#5c6370 gui=bold
    hi! TabLineMarker    guibg=#21252B guifg=#4b5263
    hi! TabLineMeta      guibg=#21252B guifg=#4b5263
    hi! TabLineFill      guibg=#21252B
  ]])
  -- function! TablineSwitchTab(arg, clicks, btn, modifiers) abort
  --   call luaeval("require('tabline').switchTab(_A)", a:arg)
  -- endfunction

  vim.opt.showtabline = 2
  vim.opt.tabline = "%!v:lua.require('tabline').render()"
end

local function highlight(hl, str, hl_end)
  str = '%#' .. hl .. '#' .. str
  if hl_end ~= nil then
    return str .. '%#' .. hl_end .. '#'
  end
  return str
end

-- local function click_handler(handler, arg, str)
--   return '%' .. arg .. '@' .. handler .. '@' .. str .. '%X'
-- end
--
function M.switchTabIdx(idx)
  for i, tab_id in ipairs(api.nvim_list_tabpages()) do
    if idx == i then
      return api.nvim_set_current_tabpage(tab_id)
    end
  end
end

function M.render()
  local tree_width = l.file_tree_width()

  return (tree_width > 0 and highlight('TabLine', (' '):rep(tree_width + 1)) or '')
    .. l.tabs(vim.o.columns - (tree_width + 1))
end

-- function M.switchTab(tab_id)
--   api.nvim_set_current_tabpage(tab_id)
-- end

function l.tabs(width)
  local tabs = {}

  local current_tab_id = api.nvim_get_current_tabpage()

  local lastSel = false
  local hi = 'TabLine'
  local h = function(k, str, k2)
    if k2 ~= nil then
      return highlight(hi .. k, str, hi .. k2)
    end
    return highlight(hi .. k, str, nil)
  end

  local total_width = 0
  local has_more = false

  local tabpages = api.nvim_list_tabpages()
  for i, tab_id in ipairs(tabpages) do
    if tab_id == current_tab_id then
      hi = 'TabLineSel'
    else
      hi = 'TabLine'
    end

    local files = l.get_tab_files(tab_id)
    local tab = l.format_tab_files(files, h)

    if tab_id == current_tab_id or not lastSel then
      tab = h('Marker', '⎸') .. tab
    else
      tab = h('', ' ') .. tab
    end

    local chars = tab:gsub('%%#[^#]+#', ''):gsub('%%[0-9]*T', '')
    local tab_width = vim.fn.strchars(chars)
    local needed_width = i == #tabpages and (total_width + tab_width) or (total_width + tab_width + 2)

    if needed_width > width then
      has_more = true
      break
    end

    -- make tab clickable and draggable
    tab = '%' .. i .. 'T' .. tab .. '%T'
    -- tab = click_handler('TablineSwitchTab', tab_id, '%' .. i .. 'T' .. tab)

    table.insert(tabs, tab)
    total_width = total_width + tab_width

    lastSel = tab_id == current_tab_id
  end

  hi = 'TabLine'

  local out = table.concat(tabs, '')

  if total_width < width then
    total_width = total_width + 1
    if lastSel then
      out = out .. h('Fill', ' ')
    else
      out = out .. h('Meta', '⎸', 'Fill')
    end
  end

  if has_more then
    out = out .. (' '):rep(width - total_width - 2) .. ' ' -- 
  end

  return out
end

function l.file_tree_width()
  local tab_id = vim.api.nvim_get_current_tabpage()
  for _, win_id in ipairs(api.nvim_tabpage_list_wins(tab_id)) do
    local buf_id = api.nvim_win_get_buf(win_id)
    if vim.fn.getbufvar(buf_id, '__is-file-tree') == true then
      return vim.api.nvim_win_get_width(win_id)
    end
  end

  return 0
end

function l.get_tab_files(tab_id)
  local files = {}

  for _, win_id in ipairs(api.nvim_tabpage_list_wins(tab_id)) do
    local buf_id = api.nvim_win_get_buf(win_id)
    local buftype = vim.fn.getbufvar(buf_id, '&buftype')

    if buftype == 'nofile' or buftype == 'prompt' or buftype == 'quickfix' then
      goto continue
    end

    local filepath = vim.fn.expand('#' .. buf_id .. ':p:~')

    local root = vim.fn.fnamemodify(filepath, ':r')
    local ext = vim.fn.fnamemodify(filepath, ':e')
    if ext ~= '' then
      ext = '.' .. ext
    end

    local ext_pre = root:match('[-_.]test$')
    if ext_pre ~= nil then
      ext = ext_pre .. ext
      root = root:gsub('[-_.]test$', '')
    end

    if files[root] == nil then
      files[root] = {}
    end
    table.insert(files[root], ext)

    ::continue::
  end

  return files
end

function l.format_tab_files(files, h)
  local buf_names = {}
  for root, exts in pairs(files) do
    local name = vim.fn.fnamemodify(root, ':t')

    if not name or name == '' then
      table.insert(buf_names, h('', '[No Name]'))
    elseif #exts == 1 then
      table.insert(buf_names, h('Bold', name, '') .. exts[1])
    else
      table.insert(
        buf_names,
        table.concat({
          h('Bold', name),
          h('Meta', '[', ''),
          table.concat(exts, h('Meta', '⏐', '')),
          h('Meta', ']', ''),
        }, '')
      )
    end
  end

  return '   ' .. table.concat(buf_names, h('Meta', ' ⏐ ')) .. '   '
end

return M
