-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- consistent with netrw '-', i.e. travel to parent directory (but here from file buffer)
vim.keymap.set("n", "-", "<CMD>Ex<CR>", { desc = "Open parent directory" })

-- yank fullpath, parent, and filename
vim.keymap.set("n", "<leader>yp", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("yanked path:\n" .. path)
end, { desc = "Copy path" })

vim.keymap.set("n", "<leader>yb", function()
  local path = vim.fn.expand("%:t")
  vim.fn.setreg("+", path)
  vim.notify("yanked basename:\n" .. path)
end, { desc = "Copy path basename (i.e. tail)" })

vim.keymap.set("n", "<leader>yd", function()
  local path = vim.fn.expand("%:p:h")
  vim.fn.setreg("+", path)
  vim.notify("yanked dirname:\n" .. path)
end, { desc = "Copy path dirname (i.e. head)" })

vim.keymap.set("n", "<leader>`", function()
  --Snacks.dashboard.open()
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks.dashboard then
    Snacks.dashboard.open()
  end
end, { desc = "Open splash screen" })

vim.keymap.set("i", "jk", "<Esc>")

vim.keymap.set("n", "<A-down>", "4j", { silent = true })
vim.keymap.set("n", "<A-up>", "4k", { silent = true })
vim.keymap.set("n", "<A-j>", "4j", { silent = true })
vim.keymap.set("n", "<A-k>", "4k", { silent = true })
