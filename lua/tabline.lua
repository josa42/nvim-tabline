local api = vim.api

local M = {}

function M.setup()
  vim.cmd([[
    hi! TabLineSel        guibg=#282c34 guifg=#abb2bf
    hi! TabLineSelBold    guibg=#282c34 guifg=#abb2bf gui=bold
    hi! TabLineSelMarker  guibg=#282c34 guifg=#61afef
    hi! TabLineSelMeta    guibg=#282c34 guifg=#4b5263
    hi! TabLine              guibg=#21252B guifg=#5c6370
    hi! TabLineBold          guibg=#21252B guifg=#5c6370 gui=bold
    hi! TabLineMarker        guibg=#21252B guifg=#4b5263
    hi! TabLineMeta          guibg=#21252B guifg=#4b5263
    hi! TabLineFill guibg=#21252B
  ]])
  -- function! TablineSwitchTab(arg, clicks, btn, modifiers) abort
  --   call luaeval("require('tabline').switchTab(_A)", a:arg)
  -- endfunction

  function _G.__tabline()
    return M.tabs()
  end

  vim.opt.showtabline = 2
  vim.opt.tabline = '%!v:lua.__tabline()'
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

-- function M.switchTab(tab_id)
--   api.nvim_set_current_tabpage(tab_id)
-- end

function M.tabs()
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

  for i, tab_id in ipairs(api.nvim_list_tabpages()) do
    local buf_names = {}
    local bufs = {}

    if tab_id == current_tab_id then
      hi = 'TabLineSel'
    end

    for _, win_id in ipairs(api.nvim_tabpage_list_wins(tab_id)) do
      local buf_id = api.nvim_win_get_buf(win_id)
      local buftype = vim.fn.getbufvar(buf_id, '&buftype')

      if buftype == 'nofile' or buftype == 'prompt' or buftype == 'quickfix' then
        goto continue
      end

      local filepath = vim.fn.expand('#' .. buf_id .. ':p:~')
      -- local name = vim.fn.fnamemodify(filepath, ":p:t")
      -- local filetype = vim.fn.getbufvar(buf_id, "&filetype")

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

      if bufs[root] == nil then
        bufs[root] = { ext }
      else
        table.insert(bufs[root], ext)
      end

      -- table.insert(buf_names, name)
      ::continue::
    end

    for root, exts in pairs(bufs) do
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

    local tab = table.concat(buf_names, h('Meta', ' ⏐ '))
    tab = '   ' .. tab .. '   '
    if lastSel then
      tab = h('', ' ') .. tab
    else
      tab = h('Marker', '⎸') .. tab
    end

    -- make tab clickable and draggable
    tab = '%' .. i .. 'T' .. tab .. '%T'

    -- tab = click_handler('TablineSwitchTab', tab_id, '%' .. i .. 'T' .. tab)

    table.insert(tabs, tab)

    hi = 'TabLine'
    lastSel = tab_id == current_tab_id
  end

  local out = table.concat(tabs, '')
  if lastSel then
    out = out .. h('Fill', ' ')
  else
    out = out .. h('Meta', '⎸', 'Fill')
  end

  return out
end

return M
