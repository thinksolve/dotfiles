-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Otter for embedded languages in Nix NOTE: testing ,,,might dlete
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "nix",
--   callback = function()
--     -- Languages you commonly embed in Nix (add/remove as needed)
--     require("otter").activate({
--       "python",
--       "bash", -- or "sh"
--       "lua",
--       "javascript",
--       -- "rust", etc.
--     }, true, true) -- completion = true, diagnostics = true
--   end,
-- })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local arg = vim.fn.argv(0)

    if arg ~= "" and vim.fn.isdirectory(arg) == 1 then
      vim.cmd("cd " .. vim.fn.fnameescape(arg))
    end
  end,
})

-- mimics some yazi defaults in netrw view
vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  --pattern = { "netrw", "snacks_picker_list" },
  callback = function()
    local opts = { remap = true, buffer = true }

    vim.keymap.set("n", "<Right>", "<CR>", opts) -- Enter file/dir
    vim.keymap.set("n", "<Left>", "-", opts) -- Up directory
    vim.keymap.set("n", "d", "D", opts) --Delete
    vim.keymap.set("n", "r", "R", opts) --Rename
    vim.keymap.set("n", "a", function()
      local path = vim.fn.input("Create file (with path): ", "", "file")
      if path == "" then
        return
      end

      local dir = vim.fn.fnamemodify(path, ":h")
      if dir ~= "." then
        vim.fn.mkdir(dir, "p") -- 'p' creates intermediate dirs
      end
      vim.cmd("e " .. path)
      vim.cmd("w") -- Save immediately to disk
    end, opts)
  end,
})
