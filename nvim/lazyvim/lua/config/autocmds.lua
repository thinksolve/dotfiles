-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--
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
    local function remap_from_to(from, to)
      return vim.keymap.set("n", to, from, { remap = true, buffer = true })
    end

    -- these are yazi-like
    remap_from_to("-", "<Left>") -- Up directory
    remap_from_to("<CR>", "<Right>") -- Enter file/dir
    remap_from_to("D", "d") -- Delete
    remap_from_to("R", "r") -- Rename

    -- remap_from_to("%", "a") -- Create file
    -- Create file in yazi manner (nested directories allowed!)
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
    end, { remap = true, buffer = true })
  end,
})
