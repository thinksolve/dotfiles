--- NOTE: lazyvim merging (of plugins) is only useful for _dictionary_ fields since there is a stable key
--- that lazyvim can intelligently merge against.
--- When a field is an _array_ (see: whichkey opts.triggers) then merging will override the original field
--- with the specification supplied

local function disable_default_plugins(...)
  return vim.tbl_map(function(name)
    return { name, enabled = false }
  end, { ... })
end

local theme_file = os.getenv("HOME") .. "/.colorscheme"

local function is_dark()
  local handle = io.open(theme_file, "r")
  if not handle then
    return false
  end

  local mode = handle:read("*l") --file only contains single line
  -- local mode = handle:read("*a"):gsub("[\n\r%s]+", "")
  -- local mode = handle:read("*a"):gsub("[\r\n%s]", "")
  handle:close()

  return mode ~= "light" -- i.e. darkmode is default
end

local function get_colorscheme()
  return is_dark() and "tokyonight-moon" or "catppuccin-latte"
end

if not _G._colorscheme_watcher then
  local w = vim.uv.new_fs_poll()
  if not w then
    return
  end
  w:start(theme_file, 100, function(err, _, _)
    if err then
      return
    end
    -- apply colorscheme
    vim.schedule(function()
      local current = get_colorscheme()

      vim.o.background = is_dark() and "dark" or "light"
      vim.cmd.colorscheme(current)
      -- vim.cmd("redraw") -- force a full redraw; can help
      -- vim.cmd("redrawstatus") -- redraw status lines
    end)
  end)
  _G._colorscheme_watcher = w
end

return {
  disable_default_plugins("folke/flash.nvim", "folke/noice.nvim"), -- lazyvim flattens this .. dont need to "spread"
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = get_colorscheme(),
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      triggers = { ---  NOTE:  the spec here overrides the internal one since its an array (see top note)
        { "<leader>", mode = { "n", "v" } },
        { "[", mode = { "n", "v" } },
        { "]", mode = { "n", "v" } },
        { "z", mode = { "n", "v" } },
      },
      --- NOTE: this approach kinda works; disables popup for 'g' but doesnt fix combinations like 'gc'
      -- delay = function(ctx)
      --   -- if ctx.keys == "g" then
      --   if ctx.keys == "gc" or ctx.keys == "gcc" or ctx.keys:find("^gc") then
      --     -- if vim.startswith(ctx.keys, "gc") or vim.startswith(ctx.keys, "g") then
      --     return math.huge
      --   end
      --   return 0
      -- end,
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        c = { "clang-format" },
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
