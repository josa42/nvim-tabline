local api = vim.api
local highlight = require('tabline.utils').highlight
local file_tree_width = require('tabline.utils').file_tree_width

local map = require('tabline.utils').map
local find_end = require('tabline.utils').find_end
local find_start = require('tabline.utils').find_start

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
  local tree_width = file_tree_width()

  return (tree_width > 0 and highlight('TabLine', (' '):rep(tree_width + 1)) or '')
    .. l.tabs(vim.o.columns - (tree_width + 1))
end

function l.tabs(width)
  local tabs = Tab.list()

  local total_width = 0
  local current_not_found = false

  local tabs_visible = find_end(tabs, function(tab, i)
    local tab_width = tab:chars()
    local needed_width = i == #tabs and (total_width + tab_width) or (total_width + tab_width + 3)

    if current_not_found and needed_width > width then
      return true
    end

    current_not_found = current_not_found or tab.current
    total_width = total_width + tab_width
    return false
  end)

  local has_more_end = tabs_visible[#tabs_visible].tab_id ~= tabs[#tabs].tab_id

  tabs_visible = find_start(tabs_visible, function(tab, i)
    local more_end = has_more_end and 3 or 0
    local more_start = i > 1 and 3 or 0

    if total_width + more_start + more_end > width then
      total_width = total_width - tab:chars()
      return false
    end

    return true
  end)

  local has_more_start = tabs_visible[1].tab_id ~= tabs[1].tab_id

  local out = ''
  local render = function(str)
    out = out .. str
  end

  -- has more at start indicator
  if has_more_start then
    render(' ')
    total_width = total_width + 2

    if not has_more_end then
      local spacer_width = width - total_width

      total_width = total_width + spacer_width
      render((' '):rep(spacer_width))
    end
  end

  -- tabs
  render(table.concat(
    map(tabs_visible, function(tab, i)
      return tab:render({
        previous = i == 1 and nil or tabs[i + 1],
        next = i == #tabs and nil or tabs[i + 1],
      })
    end),
    ''
  ))

  -- last tab end
  -- TODO refactor
  if total_width < width then
    total_width = total_width + 1
    if #tabs > 0 and tabs[#tabs].selected then
      render(highlight('TabLineFill', ' '))
    else
      render(highlight('TabLineMeta', '⎸', 'Fill'))
    end
  end

  -- has more at end indicator
  if has_more_end then
    render((' '):rep(width - total_width - 2) .. ' ')
  end

  return out
end

return M
