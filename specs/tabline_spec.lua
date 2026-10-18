local tabline = require('tabline')

local function eval()
  return vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true }).str
end

local function strip(str)
  return (str:gsub('%%#[^#]*#', ''):gsub('%%%d*T', ''))
end

describe('tabline', function()
  before_each(function()
    vim.o.columns = 80
    tabline.setup()
  end)

  after_each(function()
    vim.cmd('silent! tabonly!')
    vim.cmd('silent! only!')
    vim.cmd('enew!')
  end)

  it('sets the tabline', function()
    assert.equals(2, vim.o.showtabline)
    assert.equals("%!v:lua.require('tabline').render_safely()", vim.o.tabline)
  end)

  it('renders the file names of all tabs', function()
    vim.cmd('edit a.lua')
    vim.cmd('tabnew b.lua')

    local out = eval()
    assert.truthy(out:find('1  a.lua', 1, true))
    assert.truthy(out:find('2  b.lua', 1, true))
    assert.equals(80, vim.api.nvim_strwidth(out))
  end)

  it('groups files by name in window order', function()
    vim.cmd('edit c.lua | vsplit b.lua | vsplit a.lua | vsplit a.js')

    assert.truthy(eval():find('a[.js⏐.lua] ⏐ b.lua ⏐ c.lua', 1, true))
  end)

  it('escapes % in file names', function()
    vim.cmd('edit 100\\%done.txt')

    assert.truthy(eval():find('100%done.txt', 1, true))
  end)

  it('keeps the current tab visible in a narrow window', function()
    for i = 1, 6 do
      vim.cmd('tabnew file-' .. i .. '.lua')
    end
    vim.o.columns = 12

    vim.cmd('tabfirst')
    assert.truthy(strip(tabline.render()):find('1  [No Name]', 1, true))

    vim.cmd('tablast')
    assert.truthy(strip(tabline.render()):find('7  file-6.lua', 1, true))
  end)

  it('restores the highlights after a colorscheme change', function()
    vim.cmd('colorscheme default')

    assert.equals(0x61afef, vim.api.nvim_get_hl(0, { name = 'TabLineSelMarker' }).fg)
  end)

  it('does not register duplicate autocmds when setup is called again', function()
    tabline.setup()

    assert.equals(1, #vim.api.nvim_get_autocmds({ group = 'tabline' }))
  end)

  it('switches to the tab by index', function()
    vim.cmd('tabnew | tabnew | tabfirst')
    tabline.switch_tab_idx(3)

    assert.equals(3, vim.fn.tabpagenr())
  end)
end)
