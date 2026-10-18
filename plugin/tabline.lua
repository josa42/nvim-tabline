if vim.v.vim_did_enter == 1 then
  require('tabline').setup()
else
  vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function()
      require('tabline').setup()
    end,
  })
end
