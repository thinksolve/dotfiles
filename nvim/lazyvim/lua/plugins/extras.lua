return {
  -- useful for embedded code as strings in other files, such as in comment strings for nix writers scripts
  {
    "jmbuhr/otter.nvim",
    event = { "BufReadPre *.nix", "BufNewFile *.nix" },
    opts = {
      buffers = {
        set_filetype = true,
        write_to_disk = false,
      },
      handle_leading_whitespace = true,
      -- Try these extra settings
      lsp = {
        diagnostics_update_events = { "BufWritePost", "InsertLeave", "TextChanged", "TextChangedI" },
      },
      verbose = { no_code_found = true }, -- temporary, for debugging
    },
  },
  {
    "kylechui/nvim-surround",
    version = "^4.0.0",
    event = { "BufNewFile", "BufRead" }, --'VeryLazy',
  },
  {
    "mg979/vim-visual-multi",
    event = { "BufReadPre", "BufNewFile" },
  },
  { -- convenience ENTER key plugin
    "smoka7/hop.nvim",
    config = function()
      -- -- note: below return key (<CR>) both toggles and exists :HopWord
      require("hop").setup({ quit_key = "<CR>" })

      -- Keymap for normal mode: <CR> to start HopWord
      vim.keymap.set("n", "<CR>", function()
        require("hop").hint_words()
      end, { noremap = true, silent = true })
    end,
  },
  {
    "Ripple-TS/ripple",
    ft = "tsx",
    init = function()
      vim.filetype.add({
        extension = {
          tsrx = "tsx",
        },
      })
    end,
    config = function(plugin)
      vim.opt.rtp:append(plugin.dir .. "/packages/nvim-plugin")
      require("ripple").setup(plugin)

      -- -- this here otherwise have to add 'vim.filetype.add' below entire lazy plugins block
      -- vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
      --   pattern = "*.tsrx",
      --   callback = function()
      --     -- vim.bo.filetype = "typescriptreact"
      --     vim.bo.filetype = "tsx"
      --   end,
      -- })
    end,
  },
}
