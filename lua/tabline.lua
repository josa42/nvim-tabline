local api = vim.api
local highlight = require('tabline.utils').highlight
local render_spacer = require('tabline.utils').render_spacer
local file_tree_width = require('tabline.utils').file_tree_width

local map = require('tabline.utils').map
local find_end = require('tabline.utils').find_end
local find_start = require('tabline.utils').find_start

local Tab = require('tabline.tab')

local M = {}
local l = {}

function M.setup()
  vim.cmd([[
    hi! TabLineSel        guibg=#282c34 guifg=#abb2bf
    hi! TabLineSelBold    guibg=#282c34 guifg=#abb2bf gui=bold
    hi! TabLineSelMarker  guibg=#282c34 guifg=#61afef
    hi! TabLineSelMeta    guibg=#282c34 guifg=#4b5263

    hi! TabLine           guibg=#252830 guifg=#5c6370
    hi! TabLineBold       guibg=#252830 guifg=#5c6370 gui=bold
    hi! TabLineMarker     guibg=#252830 guifg=#4b5263
    hi! TabLineMeta       guibg=#252830 guifg=#4b5263

    hi! TabLineFill       guibg=#21252B
    hi! TabLineFillMarker guibg=#21252B guifg=#4b5263

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
  local out = { prefix = '', start_more = '', tabs = '', end_more = '', spacer = '' }
  local render = function(key, str)
    out[key] = out[key] .. str
  end

  local width = vim.o.columns
  local width_rendered = 0

  local tree_width = file_tree_width()
  width = width - (tree_width + 1)

  render('prefix', (tree_width > 0 and render_spacer('TabLineFill', tree_width + 1) or ''))

  local tabs = Tab.list()

  local current_not_found = false

  local tabs_visible = find_end(tabs, function(tab, i)
    local tab_width = tab:chars()
    local needed_width = i == #tabs and (width_rendered + tab_width) or (width_rendered + tab_width + 3)

    if current_not_found and needed_width > width then
      return true
    end

    current_not_found = current_not_found or tab.current
    width_rendered = width_rendered + tab_width

    return false
  end)

  local has_more_end = tabs_visible[#tabs_visible].tab_id ~= tabs[#tabs].tab_id

  tabs_visible = find_start(tabs_visible, function(tab, i)
    local more_end = has_more_end and 3 or 0
    local more_start = i > 1 and 3 or 0

    if width_rendered + more_start + more_end > width then
      width_rendered = width_rendered - tab:chars()
      return false
    end

    return true
  end)

  local has_more_start = tabs_visible[1].tab_id ~= tabs[1].tab_id

  -- has more at start indicator
  if has_more_start then
    render('start_more', ' ')
    width_rendered = width_rendered + 2
  elseif #tabs_visible < #tabs then
    render('start_more', '  ')
    width_rendered = width_rendered + 2
  end

  -- tabs
  render(
    'tabs',
    table.concat(
      map(tabs_visible, function(tab, i)
        return tab:render({
          previous = i == 1 and nil or tabs[i - 1],
          next = i == #tabs and nil or tabs[i + 1],
        })
      end),
      ''
    )
  )

  -- last tab end
  -- TODO refactor
  if width_rendered < width then
    width_rendered = width_rendered + 1
    if #tabs > 0 and tabs[#tabs].selected then
      render('tabs', highlight('TabLineFill', ' '))
    else
      render('tabs', highlight('TabLineFillMarker', '⎸', 'Fill'))
    end
  end

  -- has more at end indicator
  if has_more_end then
    width_rendered = width_rendered + 2
    render('end_more', ' ')
  end

  render('spacer', render_spacer('TabLineFill', width - width_rendered))

  return out.prefix .. out.start_more .. out.tabs .. out.spacer .. out.end_more
end

return M
