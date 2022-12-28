vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    require('tabline').setup()
  end,
})
