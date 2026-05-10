-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- consistent with netrw '-', i.e. travel to parent directory (but here from file buffer)
vim.keymap.set("n", "-", "<CMD>Ex<CR>", { desc = "Open parent directory" })

-- yank fullpath, parent, and filename
vim.keymap.set("n", "<leader>yp", function()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
end, { desc = "Copy path" })

vim.keymap.set("n", "<leader>yt", function()
  vim.fn.setreg("+", vim.fn.expand("%:t"))
end, { desc = "Copy path tail (i.e. basename)" })

vim.keymap.set("n", "<leader>yh", function()
  vim.fn.setreg("+", vim.fn.expand("%:p:h"))
end, { desc = "Copy path head (i.e. dirname)" })

vim.keymap.set("n", "<leader>`", function()
  --Snacks.dashboard.open()
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks.dashboard then
    Snacks.dashboard.open()
  end
end, { desc = "Open splash screen" })

vim.keymap.set("i", "jk", "<Esc>")
