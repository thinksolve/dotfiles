local function disable_default_plugins(...)
  return vim.tbl_map(function(name)
    return { name, enabled = false }
  end, { ... })
end

return {
  disable_default_plugins("folke/flash.nvim", "folke/noice.nvim"), -- lazyvim flattens this .. dont need to "spread"
  {
    "folke/snacks.nvim",

    opts = {
      picker = {
        win = {
          list = {
            keys = {
              ["<Left>"] = "explorer_up",
              ["<Right>"] = "confirm",
            },
          },
        },
      },
    },

    keys = {
      {
        "<leader><leader>",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>/",
        function()
          Snacks.picker.lines()
        end,
        desc = "Fuzzy search in buffer",
      },
      {
        "<leader>,",
        function()
          Snacks.picker.files()
        end,
        desc = "Find files root dir",
      },
      {
        "<leader>fC",
        function()
          Snacks.picker.files({ cwd = vim.fn.stdpath("data") .. "/lazy/LazyVim" })
        end,
        desc = "Find LazyVim source files",
      },
    },
  },
  {
    -- extending treesitter languages
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "zsh",
        "nix",
      },
      auto_install = true,
    },
  },
  -- {
  --   "nvim-telescope/telescope.nvim",
  --   keys = {
  --     {
  --       "<leader><leader>",
  --       function()
  --         require("telescope.builtin").buffers()
  --       end,
  --       desc = "Buffers",
  --     },
  --   },
  -- },
  -- {
  --   "neovim/nvim-lspconfig",
  --   config = function()
  --     local lspconfig = require("lspconfig")
  --     local configs = require("lspconfig.configs")
  --
  --     if not configs.ripple then
  --       configs.ripple = {
  --         default_config = {
  --           cmd = { "ripple-language-server", "--stdio" },
  --           filetypes = { "tsx", "tsrx" },
  --           root_dir = lspconfig.util.root_pattern("package.json", ".git"),
  --         },
  --       }
  --     end
  --
  --     lspconfig.ripple.setup({})
  --   end,
  -- },
  -- {
  --   "neovim/nvim-lspconfig",
  --   opts = {
  --     servers = {
  --       ripple = {
  --         cmd = { "ripple-language-server", "--stdio" },
  --         filetypes = { "tsx", "tsrx" },
  --         root_dir = require("lspconfig").util.root_pattern("package.json", ".git"),
  --       },
  --     },
  --   },
  -- },
}
