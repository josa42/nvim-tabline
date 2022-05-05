local highlight = require('tabline.utils').highlight

local Tab = {}
local l = {}

function Tab:new(t)
  setmetatable(t, self)
  self.__index = self

  self.files = l.get_tab_files(t.tab_id)

  return t
end

function Tab:hi(key, str, key_end)
  local hi = self.current and 'TabLineSel' or 'TabLine'

  if key_end ~= nil then
    return highlight(hi .. key, str, hi .. key_end)
  end
  return highlight(hi .. key, str, nil)
end

function Tab:render(lastSel)
  local out = ''

  if self.current or not lastSel then
    out = self:hi('Marker', '⎸')
  else
    out = self:hi('', ' ')
  end

  out = out .. l.format_tab_files(self.files, function(key, str, key_end)
    return self:hi(key, str, key_end)
  end)

  out = '%' .. self.index .. 'T' .. out .. '%T'

  return out
end

-- TODO amke this smarter
function Tab:chars()
  return vim.fn.strchars(self:render(false):gsub('%%#[^#]+#', ''):gsub('%%[0-9]*T', ''):gsub('%%[0-9]*T', ''))
end

function l.get_tab_files(tab_id)
  local files = {}

  for _, win_id in ipairs(vim.api.nvim_tabpage_list_wins(tab_id)) do
    local buf_id = vim.api.nvim_win_get_buf(win_id)
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

return Tab
