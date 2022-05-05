local api = vim.api
local highlight = require('tabline.utils').highlight

local Tab = require('tabline.tab')

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

    noremap <c-t> :tabe<cr>
  ]])

  vim.opt.showtabline = 2
  vim.opt.tabline = "%!v:lua.require('tabline').render()"
end
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

function l.tabs(width)
  local tabs = {}
  local tab_objs = {}

  local current_tab_id = api.nvim_get_current_tabpage()

  local lastSel = false

  local total_width = 0
  local has_more = false

  local tabpages = api.nvim_list_tabpages()
  for i, tab_id in ipairs(tabpages) do
    local tab = Tab:new({
      index = i,
      tab_id = tab_id,
      current = tab_id == current_tab_id,
    })

    table.insert(tab_objs, tab)
  end

  -- TODO make sure current tab is visible
  for i, tab in ipairs(tab_objs) do
    local tab_width = tab:chars()
    local needed_width = i == #tab_objs and (total_width + tab_width) or (total_width + tab_width + 2)

    if needed_width > width then
      has_more = true
      break
    end

    table.insert(tabs, tab:render(lastSel))
    total_width = total_width + tab_width

    lastSel = tab.selected
  end

  local out = table.concat(tabs, '')

  if total_width < width then
    total_width = total_width + 1
    if lastSel then
      out = out .. highlight('TabLineFill', ' ')
    else
      out = out .. highlight('TabLineMeta', '⎸', 'Fill')
    end
  end

  if has_more then
    out = out .. (' '):rep(width - total_width - 2) .. ' ' -- 
  end

  return out
end

-- TODO move into utils
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

return M
