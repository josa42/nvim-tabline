local api = vim.api
local highlight = require('tabline.utils').highlight
local file_tree_width = require('tabline.utils').file_tree_width

local map = require('tabline.utils').map
local find_end = require('tabline.utils').find_end

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

  -- TODO make sure current tab is visible
  local tabs_visible = find_end(tabs, function(tab, i)
    local tab_width = tab:chars()
    local needed_width = i == #tabs and (total_width + tab_width) or (total_width + tab_width + 3)

    if needed_width > width then
      return true
    end

    total_width = total_width + tab_width
    return false
  end)

  local has_more = #tabs_visible < #tabs
  local out = table.concat(
    map(tabs_visible, function(tab, i)
      return tab:render({
        previous = i == 1 and nil or tabs[i + 1],
        next = i == #tabs and nil or tabs[i + 1],
      })
    end),
    ''
  )

  if total_width < width then
    total_width = total_width + 1
    if #tabs > 0 and tabs[#tabs].selected then
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

return M
