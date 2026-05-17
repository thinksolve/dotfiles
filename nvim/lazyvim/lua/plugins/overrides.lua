local function disable_default_plugins(...)
  return vim.tbl_map(function(name)
    return { name, enabled = false }
  end, { ... })
end

-- Read cache file at load time
local theme_file = os.getenv("HOME") .. "/.cache/theme.txt"
local handle = io.open(theme_file, "r")
local mode = handle and handle:read("*a"):gsub("[\n\r%s]+", "") or "dark"
if handle then
  handle:close()
end

return {
  disable_default_plugins("folke/flash.nvim", "folke/noice.nvim"), -- lazyvim flattens this .. dont need to "spread"
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = (mode == "light") and "catppuccin-latte" or "tokyonight-moon",
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        nix = { "nixfmt" },
        bash = { "shfmt" },
        sh = { "shfmt" },
      },
    },
  },
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
        "bash",
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
