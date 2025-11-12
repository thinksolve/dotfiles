--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||                    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================

What is Kickstart?

  Kickstart.nvim is *not* a distribution.

  Kickstart.nvim is a starting point for your own configuration.
    The goal is that you can read every line of code, top-to-bottom, understand
    what your configuration is doing, and modify it to suit your needs.

    Once you've done that, you can start exploring, configuring and tinkering to
    make Neovim your own! That might mean leaving Kickstart just the way it is for a while
    or immediately breaking it into modular pieces. It's up to you!

    If you don't know anything about Lua, I recommend taking some time to read through
    a guide. One possible example which will only take 10-15 minutes:
      - https://learnxinyminutes.com/docs/lua/

    After understanding a bit more about Lua, you can use `:help lua-guide` as a
    reference for how Neovim integrates Lua.
    - :help lua-guide
    - (or HTML version): https://neovim.io/doc/user/lua-guide.html

Kickstart Guide:

  TODO: The very first thing you should do is to run the command `:Tutor` in Neovim.

    If you don't know what this means, type the following:
      - <escape key>
      - :
      - Tutor
      - <enter key>

    (If you already know the Neovim basics, you can skip this step.)

  Once you've completed that, you can continue working through **AND READING** the rest
  of the kickstart init.lua.

  Next, run AND READ `:help`.
    This will open up a help window with some basic information
    about reading, navigating and searching the builtin help documentation.

    This should be the first place you go to look when you're stuck or confused
    with something. It's one of my favorite Neovim features.

    MOST IMPORTANTLY, we provide a keymap "<space>sh" to [s]earch the [h]elp documentation,
    which is very useful when you're not exactly sure of what you're looking for.

  I have left several `:help X` comments throughout the init.lua
    These are hints about where to find more information about the relevant settings,
    plugins or Neovim features used in Kickstart.

   NOTE: Look for lines like this

    Throughout the file. These are for you, the reader, to help you understand what is happening.
    Feel free to delete them once you know what you're doing, but they should serve as a guide
    for when you are first encountering a few different constructs in your Neovim config.

If you experience any errors while trying to install kickstart, run `:checkhealth` for more info.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now! :)
--]]

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = false

-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`
--
-- vim.o.termguicolors = true

-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

vim.opt.clipboard:append("unnamedplus") -- needed to add after enabling vi-mode in zshrc

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
-- vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" } -- NOTE: custom:changed
-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`
--
-- Clear echo area
vim.keymap.set("n", "<leader>ce", function()
	vim.api.nvim_echo({}, false, {})
	vim.cmd("redraw")
end, { desc = "Clear echo area" })

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--

-- custom function to toggle themes, lazily
local function lazy_themes(themes)
	local theme_index_file = vim.fn.stdpath("config") .. "/theme_index"

	local theme_index = (function()
		local theme_index = 1
		local file = io.open(theme_index_file, "r")
		if file then
			theme_index = math.floor(tonumber(file:read("*a")) or theme_index)
			file:close()
		end
		return theme_index
	end)()

	for i, theme in ipairs(themes) do
		theme.lazy = i ~= theme_index
	end

	local function save_theme_index(__theme_index)
		local file = io.open(theme_index_file, "w")
		if file then
			file:write(__theme_index) -- automatically written as string
			file:close()
		end
	end

	-- Function to save the theme index to file
	vim.keymap.set("n", "<leader>t<leader>t", function()
		theme_index = (theme_index % #themes) + 1
		themes[theme_index].config()
		save_theme_index(theme_index)
	end, { desc = "Theme Switcher" })

	return themes
end

-- NOTE: load lazy plugin on custom cmd
local function set_up_cmd(plugin, callback)
	vim.api.nvim_create_user_command(plugin.cmd, function()
		require("lazy").load({ plugins = { plugin.name } })
		vim.schedule(callback)
	end, {})
end

local function set_marko_commentstring()
	if vim.bo.filetype ~= "marko" then
		return
	end

	local cursor_row = vim.fn.line(".") - 1
	local anchor_row = vim.fn.mode():match("^[vV]") and vim.fn.line("v") - 1 or cursor_row

	local start_row = math.min(cursor_row, anchor_row)
	local end_row = math.max(cursor_row, anchor_row)

	-- Get all selected lines
	local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)

	-- Strip leading blank lines from the selection
	local first_nonblank_index = nil
	for i, line in ipairs(lines) do
		if line:match("%S") then
			first_nonblank_index = i
			break
		end
	end

	-- If leading blank line(s), adjust start_row and lines accordingly
	if first_nonblank_index and first_nonblank_index > 1 then
		-- Shift start_row down to first nonblank line's actual buffer line
		start_row = start_row + first_nonblank_index - 1
		lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
	end

	-- Now run your existing logic on 'lines' and 'start_row'/'end_row' as needed
	-- For example, detect style tags, html tags, etc using 'lines'

	-- (Your existing style/js/html detection here, but working on trimmed lines)

	-- Example: quick <style> detection
	local is_style_tag = false
	for _, line in ipairs(lines) do
		if line:match("^%s*</?style") then
			is_style_tag = true
			break
		end
	end

	-- etc... rest of your logic...

	-- Finally set commentstring accordingly
	if is_style_tag then
		vim.bo.commentstring = "/* %s */"
	elseif #lines > 0 and lines[1]:match("^%s*<") then
		vim.bo.commentstring = "<!-- %s -->"
	else
		vim.bo.commentstring = "// %s"
	end
end

---- NOTE: manually handle comment string logic for marko files
local function set_marko_commentstring_og()
	-- extra safety in case function call not guarded with 'in marko file' logic
	if vim.bo.filetype ~= "marko" then
		return
	end

	local end_row = vim.fn.line(".") - 1 -- current cursor row (0-based)
	local start_row = vim.fn.mode():match("^[vV]") and vim.fn.line("v") - 1 or end_row
	if start_row > end_row then
		start_row, end_row = end_row, start_row
	end
	local lines = vim.api.nvim_buf_get_lines(0, 0, end_row + 1, false)

	-- 1. quick reject if selection itself contains <style> or </style>
	local is_style_tag = false
	for i = start_row + 1, end_row + 1 do
		local l = lines[i] or vim.api.nvim_get_current_line()
		if l:match("^%s*</?style") then
			is_style_tag = true
			break
		end
	end

	-- 2. nearest style boundary *above* selection (only if we aren't a tag)
	local in_style = false
	if not is_style_tag then
		for i = start_row, 0, -1 do -- backwards from line above selection
			local l = lines[i] or ""
			if l:match("^%s*</style") then
				in_style = false
				break
			end
			if l:match("^%s*<style") then
				in_style = true
				break
			end
		end
	end

	-- 3. JS detection: if *any* selected line has a Marko prefix → entire block is JS
	local is_js = false
	for i = start_row + 1, end_row + 1 do
		local raw = lines[i] or vim.api.nvim_get_current_line()
		local txt = raw:match("^%s*(.-)%s*$") -- drop indent
		local stripped = txt:gsub("^(static%s+|export%s+|server%s+|client%s+)", "") -- drop prefix

		-- fast path: had a Marko prefix → whole block is JS
		if txt ~= stripped then
			is_js = true
			break
		end

		-- otherwise run the original parse test on the stripped remainder
		if stripped ~= "" and not stripped:match("^%s*<") and not stripped:match("${.*}") then
			local ok, p = pcall(vim.treesitter.get_string_parser, stripped, "javascript")
			if ok then
				local root = p:parse()[1]:root()
				if root:type() == "program" and not root:has_error() then
					is_js = true
					p:destroy()
					break
				end
				p:destroy()
			end
		end
	end

	-- -- NOTE: BROKEN: 3. JS detection (skip lines inside tags / ${} )
	-- local is_js = false
	-- if not in_style and not is_style_tag then
	-- 	for i = start_row + 1, end_row + 1 do
	-- 		local raw = lines[i] or vim.api.nvim_get_current_line()
	-- 		-- NOTE: previously problematic
	-- 		-- local txt = raw:gsub("^%s*(static%s+|export%s+|server%s+|client%s+)", ""):match("(.-)%s*$")
	--
	-- 		local txt = raw:match("^%s*(.-)%s*$") -- trim indent
	-- 		txt = txt:gsub("^(static%s+|export%s+|server%s+|client%s+)", "") -- drop prefix
	--
	-- 		if txt ~= "" and not txt:match("^%s*<") and not txt:match("${.*}") then
	-- 			local ok, p = pcall(vim.treesitter.get_string_parser, txt, "javascript")
	-- 			if ok then
	-- 				local root = p:parse()[1]:root()
	-- 				is_js = root:type() == "program" and not root:has_error()
	-- 				p:destroy()
	-- 				if is_js then
	-- 					break
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end

	vim.bo.filetype = "marko"
	vim.bo.commentstring = (in_style and not is_style_tag) and "/* %s */"
		or (is_style_tag or lines[end_row + 1]:match("^%s*<")) and "<!-- %s -->"
		or is_js and "// %s"
		or "<!-- %s -->"
end

local function set_marko_commentstring_test()
	if vim.bo.filetype ~= "marko" then
		return
	end

	local cursor_row = vim.fn.line(".") - 1
	local anchor_row = vim.fn.mode():match("^[vV]") and vim.fn.line("v") - 1 or cursor_row

	local start_row = math.min(cursor_row, anchor_row)
	local end_row = math.max(cursor_row, anchor_row)

	-- Get full selection
	local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)

	-- Strip leading and trailing blank lines
	local first, last = 1, #lines
	while first <= #lines and lines[first]:match("^%s*$") do
		first = first + 1
	end
	while last >= 1 and lines[last]:match("^%s*$") do
		last = last - 1
	end

	local trimmed_lines = {}
	for i = first, last do
		table.insert(trimmed_lines, lines[i])
	end

	-- Exit early if empty after trimming
	if #trimmed_lines == 0 then
		vim.bo.commentstring = "// %s"
		return
	end

	-- Check if inside <style> block (simplified)
	local in_style = false
	local style_lines = vim.api.nvim_buf_get_lines(0, 0, start_row, false)
	for i = #style_lines, 1, -1 do
		local l = style_lines[i]
		if l:match("^%s*</style") then
			break
		end
		if l:match("^%s*<style") then
			in_style = true
			break
		end
	end

	-- Check if all lines look like HTML
	local all_html = true
	for _, line in ipairs(trimmed_lines) do
		if not line:match("^%s*</?[%w][^>]*>") and not line:match("^%s*<[%w]+") then
			all_html = false
			break
		end
	end

	-- Decide commentstring
	if in_style then
		vim.bo.commentstring = "/* %s */"
	elseif all_html then
		vim.bo.commentstring = "<!-- %s -->"
	else
		vim.bo.commentstring = "// %s"
	end
end

require("lazy").setup({

	{
		"phaazon/hop.nvim",
		branch = "v2",
		config = function()
			-- -- note: below return key (<CR>) both toggles and exists :HopWord

			require("hop").setup({ quit_key = "<CR>" })

			-- Keymap for normal mode: <CR> to start HopWord
			vim.keymap.set("n", "<CR>", function()
				require("hop").hint_words()
			end, { noremap = true, silent = true })

			-- alternate:
			-- vim.api.nvim_set_keymap("n", "<CR>", ":HopWord<CR>", { noremap = true, silent = true })
		end,
	},
	-- NOTE: broke in the latest `:Lazy sync` on nov-2-2025
	-- { -- simple regex-based Marko colours (treesitter has no marko support!)
	-- 	"Epitrochoid/marko-vim-syntax.git",
	-- 	name = "marko-vim-syntax", -- optional, just keeps the short name
	-- 	ft = "marko",
	-- },
	{
		"brianhuster/live-preview.nvim",
		cmd = "LP", -- load plugin on this command; init function below also starts live preview server
		-- ft = { "html", "markdown" },
		opts = {
			cmd = "LivePreview",
			port = 5400,
			autokill = false,
			browser = "default",
			dynamic_root = false,
			sync_scroll = false,
			picker = nil,
		},
		dependencies = {
			-- Not required, but recomended for autosaving and sync scrolling
			"brianhuster/autosave.nvim",
			-- You can choose one of the following pickers
			"nvim-telescope/telescope.nvim",
			"ibhagwan/fzf-lua",
			"echasnovski/mini.pick",
		},

		init = function(plugin)
			vim.api.nvim_create_user_command(plugin.cmd, function()
				require("lazy").load({ plugins = { plugin.name } })
				vim.schedule(function()
					vim.cmd("LivePreview start")
				end)
			end, {})

			vim.api.nvim_create_user_command("LPx", function()
				vim.cmd("LivePreview close")
			end, {})
		end,
	},
	{
		"sindrets/diffview.nvim",
		cmd = "InitDiffviewOpen",

		init = function(plugin)
			vim.api.nvim_create_user_command(plugin.cmd, function()
				require("lazy").load({ plugins = { plugin.name } })

				vim.schedule(function()
					vim.cmd("DiffviewOpen")
				end)
			end, {})
		end,
	},
	lazy_themes({
		{
			"neanias/everforest-nvim",
			config = function()
				vim.cmd.colorscheme("everforest")
			end,
		},

		{
			"samharju/serene.nvim",
			config = function()
				vim.cmd.colorscheme("serene")
			end,
		},
		-- {
		-- 	"jesseleite/nvim-noirbuddy",
		--
		--  	dependencies = {
		-- 		{ "tjdevries/colorbuddy.nvim" },
		-- 	},
		-- 	config = function()
		-- 		vim.cmd.colorscheme("noirbuddy")
		-- 	end,
		-- },
		{
			"mellow-theme/mellow.nvim",
			config = function()
				vim.cmd.colorscheme("mellow")
			end,
		},
		{
			"Yazeed1s/oh-lucy.nvim",
			config = function()
				vim.cmd.colorscheme("oh-lucy-evening")
				-- vim.cmd.colorscheme("oh-lucy")
			end,
		},
		{
			"rose-pine/neovim",
			config = function()
				vim.cmd.colorscheme("rose-pine-moon")
			end,
		},
		{
			"folke/tokyonight.nvim",
			config = function()
				vim.cmd.colorscheme("tokyonight-night")
			end,
		},
		{
			"joshdick/onedark.vim",
			config = function()
				vim.cmd.colorscheme("onedark")
			end,
		},

		{
			"tiagovla/tokyodark.nvim",
			config = function(_, opts)
				require("tokyodark").setup(opts)
				vim.cmd([[colorscheme tokyodark]])
			end,
		},
		{
			"catppuccin/nvim",
			config = function()
				vim.cmd.colorscheme("catppuccin-mocha")
			end,
		},
	}),
	-- NOTE: https://codeberg.org/sheykail/my-lazyvim/src/branch/master/lua/plugins/fold.lua
	-- (nvim 0.11 will replace this?)
	{
		"kevinhwang91/nvim-ufo",
		dependencies = { "kevinhwang91/promise-async" },
		event = "VeryLazy",
		-- opts = {},
		config = function()
			-- Fold options
			vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
			vim.o.foldcolumn = "1" -- '0' is not bad
			vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
			vim.o.foldlevelstart = 99
			vim.o.foldenable = true
			require("ufo").setup()
		end,
	},
	{
		"JoosepAlviste/nvim-ts-context-commentstring",
		event = "VeryLazy",
		build = ":TSUpdate",

		-- config = function()
		--
		-- 		require("nvim-treesitter.configs").setup({
		-- 			ensure_installed = {
		-- 				"vim",
		-- 				"lua",
		-- 				"svelte",
		-- 				"css",
		-- 				"javascript",
		-- 				"typescript",
		-- 			},
		-- 			highlight = {
		-- 				enable = true,
		-- 			},
		-- 		})
		-- end,
	},
	-- NOTE: ncessary to get commenting out in jsx/tsx
	{
		"numToStr/Comment.nvim",
		ft = { "javascriptreact", "typescriptreact" },
		dependencies = "JoosepAlviste/nvim-ts-context-commentstring",
		config = function()
			local prehook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook()
			require("Comment").setup({ pre_hook = prehook })
		end,
	},
	{
		"axelvc/template-string.nvim",
		ft = { "astro", "svelte", "javascript", "typescript", "javascriptreact", "typescriptreact" },
		config = function(plugin)
			require("template-string").setup({
				filetypes = plugin.ft,
				jsx_brackets = true,
				remove_template_string = false,
				restore_quotes = {
					normal = [[']']],
					jsx = [[']']],
				},
			})
		end,
	},
	{
		"mg979/vim-visual-multi",
		event = { "BufReadPre", "BufNewFile" },
		-- config = function()
		-- end,
	},
	{
		"kylechui/nvim-surround",
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		-- event = 'VeryLazy',
		event = { "BufNewFile", "BufRead" },
		config = function()
			require("nvim-surround").setup({})
		end,
	},
	{
		"iamcco/markdown-preview.nvim",
		event = "BufNewFile",
		-- event = { 'BufReadPre', 'BufNewFile' },
		ft = { "markdown" },
		config = function()
			-- vim.g.mkdp_filetypes = { 'markdown' }
			vim.fn["mkdp#util#install"]()
			vim.api.nvim_set_keymap("n", "<leader>mp", ":MarkdownPreviewToggle<CR>", { noremap = true, silent = true })
		end,
	},
	"tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically

	{ -- Adds git related signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
		},
	},

	{ -- Useful plugin to show you pending keybinds.
		"folke/which-key.nvim",
		event = "VimEnter", -- Sets the loading event to 'VimEnter'
		opts = {
			icons = {
				-- set icon mappings to true if you have a Nerd Font
				mappings = vim.g.have_nerd_font,
				-- If you are using a Nerd Font: set icons.keys to an empty table which will use the
				-- default whick-key.nvim defined Nerd Font icons, otherwise define a string table
				keys = vim.g.have_nerd_font and {} or {
					Up = "<Up> ",
					Down = "<Down> ",
					Left = "<Left> ",
					Right = "<Right> ",
					C = "<C-…> ",
					M = "<M-…> ",
					D = "<D-…> ",
					S = "<S-…> ",
					CR = "<CR> ",
					Esc = "<Esc> ",
					ScrollWheelDown = "<ScrollWheelDown> ",
					ScrollWheelUp = "<ScrollWheelUp> ",
					NL = "<NL> ",
					BS = "<BS> ",
					Space = "<Space> ",
					Tab = "<Tab> ",
					F1 = "<F1>",
					F2 = "<F2>",
					F3 = "<F3>",
					F4 = "<F4>",
					F5 = "<F5>",
					F6 = "<F6>",
					F7 = "<F7>",
					F8 = "<F8>",
					F9 = "<F9>",
					F10 = "<F10>",
					F11 = "<F11>",
					F12 = "<F12>",
				},
			},

			-- Document existing key chains
			spec = {
				{ "<leader>c", group = "[C]ode", mode = { "n", "x" } },
				{ "<leader>d", group = "[D]ocument" },
				{ "<leader>r", group = "[R]ename" },
				{ "<leader>s", group = "[S]earch" },
				{ "<leader>w", group = "[W]orkspace" },
				{ "<leader>t", group = "[T]oggle" },
				{ "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
			},
		},
	},

	{ -- Fuzzy Finder (files, lsp, etc)
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ -- If encountering errors, see telescope-fzf-native README for installation instructions
				"nvim-telescope/telescope-fzf-native.nvim",

				-- `build` is used to run some command when the plugin is installed/updated.
				-- This is only run then, not every time Neovim starts up.
				build = "make",

				-- `cond` is a condition used to determine whether this plugin should be
				-- installed and loaded.
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },

			-- Useful for getting pretty icons, but requires a Nerd Font.
			{ "nvim-tree/nvim-web-devicons", enabled = true or vim.g.have_nerd_font },
		},
		config = function()
			local builtin = require("telescope.builtin") -- NOTE: moved
			local util = require("lspconfig.util")
			local actions_state = require("telescope.actions.state")
			local default_search = true

			local function get_project_root()
				local project_root = util.root_pattern(".git", "package.json", ".project_root")(vim.fn.getcwd())
				return project_root
			end

			local function toggle_search_behaviour(prompt_bufnr)
				local current_picker = actions_state.get_current_picker(prompt_bufnr)
				local picker_name = current_picker.prompt_title:lower():gsub("%s+", "_") --add? :gsub('[^%w_]', '')
				local builtin_func = builtin[picker_name]

				-- filter out builtins that dont make sense to toggle
				if not builtin_func then
					vim.notify("Toggle not supported for this picker", vim.log.levels.WARN)
					return
				end

				builtin_func({
					default_text = current_picker:_get_prompt(),
					cwd = not default_search and get_project_root() or nil,
					no_ignore = not default_search,
				})

				vim.notify(default_search and "Default search" or "Custom search (root and ignore gitignore)")

				default_search = not default_search
			end

			-- [[ Configure Telescope ]]
			-- See `:help telescope` and `:help telescope.setup()`
			require("telescope").setup({
				-- You can put your default mappings / updates / etc. in here
				--  All the info you're looking for is in `:help telescope.setup()`
				--
				defaults = {

					mappings = {
						i = {
							-- ['<c-enter>'] = 'to_fuzzy_refine',

							-- NOTE: this allows toggling search files to root dir and ignore gitignore
							["<C-f>"] = function(prompt_bufnr)
								toggle_search_behaviour(prompt_bufnr)
							end,
						},
					},
				},
				-- pickers = {
				--   no_ignore = true,
				-- },
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})

			-- Enable Telescope extensions if they are installed
			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")

			-- See `:help telescope.builtin`
			-- local builtin = require 'telescope.builtin'
			vim.keymap.set("n", "<leader>sc", builtin.colorscheme, { desc = "[S]earch [C]olorscheme" })
			vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
			vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
			vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
			vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
			vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
			vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
			vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
			vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
			vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

			-- Slightly advanced example of overriding default behavior and theme
			vim.keymap.set("n", "<leader>/", function()
				-- You can pass additional configuration to Telescope to change the theme, layout, etc.
				builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[/] Fuzzily search in current buffer" })

			-- It's also possible to pass additional configuration options.
			--  See `:help telescope.builtin.live_grep()` for information about particular keys
			vim.keymap.set("n", "<leader>s/", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "[S]earch [/] in Open Files" })

			-- Shortcut for searching your Neovim configuration files
			vim.keymap.set("n", "<leader>sn", function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "[S]earch [N]eovim files" })
		end,
	},

	-- LSP Plugins
	{
		-- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
		-- used for completion, annotations and signatures of Neovim apis
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luvit types when the `vim.uv` word is found
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
			},
		},
	},
	{ "Bilal2453/luvit-meta", lazy = true },
	{
		-- Main LSP Configuration
		"neovim/nvim-lspconfig",
		dependencies = {
			-- Automatically install LSPs and related tools to stdpath for Neovim
			{ "williamboman/mason.nvim", config = true }, -- NOTE: Must be loaded before dependants
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",

			-- Useful status updates for LSP.
			-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
			{ "j-hui/fidget.nvim", opts = {} },

			-- Allows extra capabilities provided by nvim-cmp
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					-- NOTE: Remember that Lua is a real programming language, and as such it is possible
					-- to define small helper and utility functions so you don't have to repeat yourself.
					--
					-- In this case, we create a function that lets us more easily define mappings specific
					-- for LSP related items. It sets the mode, buffer and description for us each time.
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					-- Jump to the definition of the word under your cursor.
					--  This is where a variable was first declared, or where a function is defined, etc.
					--  To jump back, press <C-t>.
					map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

					-- Find references for the word under your cursor.
					map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

					-- Jump to the implementation of the word under your cursor.
					--  Useful when your language has ways of declaring types without an actual implementation.
					map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

					-- Jump to the type of the word under your cursor.
					--  Useful when you're not sure what type a variable is and you want to see
					--  the definition of its *type*, not where it was *defined*.
					map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

					-- Fuzzy find all the symbols in your current document.
					--  Symbols are things like variables, functions, types, etc.
					map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

					-- Fuzzy find all the symbols in your current workspace.
					--  Similar to document symbols, except searches over your entire project.
					map(
						"<leader>ws",
						require("telescope.builtin").lsp_dynamic_workspace_symbols,
						"[W]orkspace [S]ymbols"
					)

					-- Rename the variable under your cursor.
					--  Most Language Servers support renaming across files, etc.
					map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

					-- Execute a code action, usually your cursor needs to be on top of an error
					-- or a suggestion from your LSP for this to activate.
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })

					-- WARN: This is not Goto Definition, this is Goto Declaration.
					--  For example, in C this would take you to the header.
					map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

					-- The following two autocommands are used to highlight references of the
					-- word under your cursor when your cursor rests there for a little while.
					--    See `:help CursorHold` for information about when this is executed
					--
					-- When you move your cursor, the highlights will be cleared (the second autocommand).
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
						local highlight_augroup =
							vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})

						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})

						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({
									group = "kickstart-lsp-highlight",
									buffer = event2.buf,
								})
							end,
						})
					end

					-- The following code creates a keymap to toggle inlay hints in your
					-- code, if the language server you are using supports them
					--
					-- This may be unwanted, since they displace some of your code
					if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "[T]oggle Inlay [H]ints")
					end
				end,
			})

			-- LSP servers and clients are able to communicate to each other what features they support.
			--  By default, Neovim doesn't support everything that is in the LSP specification.
			--  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
			--  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			local servers = {
				-- clangd = {},
				-- gopls = {},
				-- pyright = {},
				-- rust_analyzer = {},
				-- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
				--
				-- Some languages (like typescript) have entire language plugins that can be useful:
				--    https://github.com/pmizio/typescript-tools.nvim
				--
				-- But for many setups, the LSP (`ts_ls`) will work just fine
				ts_ls = {},
				astro = {},
				svelte = {},
				lua_ls = {
					-- cmd = {...},
					-- filetypes = { ...},
					-- capabilities = {},
					settings = {
						Lua = {
							completion = {
								callSnippet = "Replace",
							},
							-- moved ALL hammersppon config to ~/.hammerspoon/.luarc.json
						},
					},
				},
			}

			-- Ensure the servers and tools above are installed
			--  To check the current status of installed tools and/or manually install
			--  other tools, you can run
			--    :Mason
			--
			--  You can press `g?` for help in this menu.
			require("mason").setup()

			-- You can add other tools here that you want Mason to install
			-- for you, so that they are available from within Neovim.
			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, {
				"stylua", -- Used to format Lua codestyl
			})
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						-- This handles overriding only values explicitly passed
						-- by the server configuration above. Useful when disabling
						-- certain features of an LSP (for example, turning off formatting for ts_ls)
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
		end,
	},

	{ -- Autoformat
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				-- Disable "format_on_save lsp_fallback" for languages that don't
				-- have a well standardized coding style. You can add additional
				-- languages here or re-enable it for the disabled ones.
				local disable_filetypes = { c = true, cpp = true }
				local lsp_format_opt
				if disable_filetypes[vim.bo[bufnr].filetype] then
					lsp_format_opt = "never"
				else
					lsp_format_opt = "fallback"
				end
				return {
					-- timeout_ms = 500,
					timeout_ms = 5000, -- NOTE: custom:changed
					lsp_format = lsp_format_opt,
				}
			end,
			formatters_by_ft = {
				sh = { "shfmt" },
				bash = { "shfmt" },
				haskell = { "fourmolu" },
				nix = { "nixfmt" }, -- pkgs.nixfmt-rfc-style in flake.nix (nix-darwin)
				json = { "prettier" },
				lua = { "stylua" },
				html = { "prettierd", "prettier", stop_after_first = true }, -- NOTE: custom:added
				-- Conform can also run multiple formatters sequentially
				-- python = { "isort", "black" },
				--
				-- You can use 'stop_after_first' to run the first available formatter from the list
				javascript = { "prettierd", "prettier", stop_after_first = true },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				css = { "prettier" }, -- Add this line for CSS formatting
			},
		},
	},

	{ -- Autocompletion
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			-- Snippet Engine & its associated nvim-cmp source
			{
				"L3MON4D3/LuaSnip",
				build = (function()
					-- Build Step is needed for regex support in snippets.
					-- This step is not supported in many windows environments.
					-- Remove the below condition to re-enable on windows.
					if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
						return
					end
					return "make install_jsregexp"
				end)(),
				dependencies = {
					-- `friendly-snippets` contains a variety of premade snippets.
					--    See the README about individual language/framework/plugin snippets:
					--    https://github.com/rafamadriz/friendly-snippets
					{
						"rafamadriz/friendly-snippets",
						config = function()
							require("luasnip.loaders.from_vscode").lazy_load()
						end,
					},
				},
				config = function()
					require("luasnip").setup({})

					local luasnip = require("luasnip")
					local s = luasnip.snippet
					local t = luasnip.text_node
					local i = luasnip.insert_node

					local jsx_function_snippet = {
						s("cmp", {
							-- s("function", {
							t("function "),
							i(1, "name"),
							t("("),
							i(2, "props"),
							t(") {"),
							t({ "", "  " }),
							t({ "", "  return (" }),
							t({ "", "    <div>" }),
							t({ "", "      " }),
							i(3, ""),
							t({ "", "    </div>" }),
							t({ "", "  )" }),
							t({ "", "}" }),
						}),
					}
					luasnip.add_snippets("javascriptreact", jsx_function_snippet)
					luasnip.add_snippets("typescriptreact", jsx_function_snippet)

					luasnip.filetype_extend("javascriptreact", { "html" })
					luasnip.filetype_extend("typescriptreact", { "html" }) -- If you also use TypeScript React
				end,
			},
			"saadparwaiz1/cmp_luasnip",

			-- Adds other completion capabilities.
			--  nvim-cmp does not ship with all sources by default. They are split
			--  into multiple repos for maintenance purposes.
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
		},
		config = function()
			-- See `:help cmp`
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			luasnip.config.setup({})

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				completion = { completeopt = "menu,menuone,noinsert" },

				-- For an understanding of why these mappings were
				-- chosen, you will need to read `:help ins-completion`
				--
				-- No, but seriously. Please read `:help ins-completion`, it is really good!
				mapping = cmp.mapping.preset.insert({
					-- Select the [n]ext item
					["<C-n>"] = cmp.mapping.select_next_item(),
					-- Select the [p]revious item
					["<C-p>"] = cmp.mapping.select_prev_item(),

					-- Scroll the documentation window [b]ack / [f]orward
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),

					-- Accept ([y]es) the completion.
					--  This will auto-import if your LSP supports it.
					--  This will expand snippets if the LSP sent a snippet.
					["<Tab>"] = cmp.mapping.confirm({ select = true }), -- NOTE: custom:changed
					-- ['<C-y>'] = cmp.mapping.confirm { select = true },

					-- If you prefer more traditional completion keymaps,
					-- you can uncomment the following lines
					--['<CR>'] = cmp.mapping.confirm { select = true },
					--['<Tab>'] = cmp.mapping.select_next_item(),
					--['<S-Tab>'] = cmp.mapping.select_prev_item(),

					-- Manually trigger a completion from nvim-cmp.
					--  Generally you don't need this, because nvim-cmp will display
					--  completions whenever it has completion options available.
					["<C-Space>"] = cmp.mapping.complete({}),

					-- Think of <c-l> as moving to the right of your snippet expansion.
					--  So if you have a snippet that's like:
					--  function $name($args)
					--    $body
					--  end
					--
					-- <c-l> will move you to the right of each of the expansion locations.
					-- <c-h> is similar, except moving you backwards.
					["<C-l>"] = cmp.mapping(function()
						if luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						end
					end, { "i", "s" }),
					["<C-h>"] = cmp.mapping(function()
						if luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						end
					end, { "i", "s" }),

					-- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
					--    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
				}),
				sources = {
					{
						name = "lazydev",
						-- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
						group_index = 0,
					},
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
				},
			})

			-- NEW: LSP Configuration Section (add this after cmp.setup)
			-- Migrate nil_ls to new vim.lsp.config API (replaces old require("lspconfig").nil_ls.setup)
			require("lspconfig").nil_ls.setup({
				settings = {
					nixd = {
						flake = { autoEvalInputs = true },
					},
				},
			})
		end,
	},
	--
	-- Highlight todo, notes, etc in comments
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},

	{ -- Collection of various small independent plugins/modules
		"echasnovski/mini.nvim",
		config = function()
			require("mini.comment").setup({
				hooks = {
					pre = function()
						if vim.bo.filetype == "marko" then
							set_marko_commentstring_test()
							return
						end
					end,
				},
			})

			-- Better Around/Inside textobjects
			--
			-- Examples:
			--  - va)  - [V]isually select [A]round [)]paren
			--  - yinq - [Y]ank [I]nside [N]ext [Q]uote
			--  - ci'  - [C]hange [I]nside [']quote
			require("mini.ai").setup({ n_lines = 500 })

			-- Add/delete/replace surroundings (brackets, quotes, etc.)
			--
			-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
			-- - sd'   - [S]urround [D]elete [']quotes
			-- - sr)'  - [S]urround [R]eplace [)] [']
			require("mini.surround").setup()

			-- Simple and easy statusline.
			--  You could remove this setup call if you don't like it,
			--  and try some other statusline plugin
			local statusline = require("mini.statusline")
			-- set use_icons to true if you have a Nerd Font
			statusline.setup({ use_icons = vim.g.have_nerd_font })

			-- You can configure sections in the statusline by overriding their
			-- default behavior. For example, here we set the section for
			-- cursor location to LINE:COLUMN
			---@diagnostic disable-next-line: duplicate-set-field
			statusline.section_location = function()
				return "%2l:%-2v"
			end

			-- ... and there is more!
			--  Check out: https://github.com/echasnovski/mini.nvim
		end,
	},
	{ -- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter.configs", -- Sets main module to use for opts
		-- [[ Configure Treesitter ]] See `:help nvim-treesitter`

		opts = {
			ensure_installed = {
				-- "marko" == doesnt work,
				"astro", -- NOTE: custom: added
				"svelte", -- NOTE: custom: added
				"css", -- NOTE: custom: added
				"javascript", -- NOTE: custom: added
				"typescript", -- NOTE: custom: added
				"tsx",
				"bash",
				"c",
				"diff",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"query",
				"vim",
				"vimdoc",
			},

			-- Autoinstall languages that are not installed
			auto_install = true,
			highlight = {
				enable = true,
				-- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
				--  If you are experiencing weird indenting issues, add the language to
				--  the list of additional_vim_regex_highlighting and disabled languages for indent.
				additional_vim_regex_highlighting = { "ruby" },
			},
			indent = { enable = true, disable = { "ruby" } },
			fold = { enable = false },
		},
		-- There are additional nvim-treesitter modules that you can use to interact
		-- with nvim-treesitter. You should go explore a few and see what interests you:
		--
		--    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
		--    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
		--    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
	},

	-- The following two comments only work if you have downloaded the kickstart repo, not just copy pasted the
	-- init.lua. If you want these files, they are in the repository, so you can just download them and
	-- place them in the correct locations.

	-- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
	--
	--  Here are some example plugins that I've included in the Kickstart repository.
	--  Uncomment any of the lines below to enable them (you will need to restart nvim).
	--
	-- require 'kickstart.plugins.debug',
	-- require 'kickstart.plugins.indent_line',
	-- require 'kickstart.plugins.lint',
	-- require 'kickstart.plugins.autopairs',
	-- require 'kickstart.plugins.neo-tree',
	-- require 'kickstart.plugins.gitsigns', -- adds gitsigns recommend keymaps

	-- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
	--    This is the easiest way to modularize your config.
	--
	--  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
	--    For additional information, see `:help lazy.nvim-lazy.nvim-structuring-your-plugins`
	-- { import = 'custom.plugins' },
}, {
	ui = {
		-- If you are using a Nerd Font: set icons to an empty table which will use the
		-- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
		icons = vim.g.have_nerd_font and {} or {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
})
--NOTE: transparent code ...
local is_transparent_file = vim.fn.stdpath("config") .. "/is_transparent"

local function save_is_transparent(__is_transparent)
	local file = io.open(is_transparent_file, "w")
	if not file then
		vim.cmd('echo "Error: Could not open file for writing"')
		return
	end
	file:write(tostring(__is_transparent):lower())
	file:close()
end

local function get_is_transparent()
	local is_transparent = true
	local file = io.open(is_transparent_file, "r")
	if file then
		local value = file:read("*a")
		if value and value:lower() == "false" then
			is_transparent = false
		else
			is_transparent = true
		end
		-- vim.cmd('echo "Current is_transparent value: ' .. value .. '"')
		file:close()
	end
	return is_transparent
end

local is_transparent = get_is_transparent()

local normal_colour = "#11121f"

local function set_background_transparent(boolean)
	vim.cmd("highlight Normal guibg=" .. (boolean and "none" or normal_colour))
	vim.cmd("highlight NonText guibg=" .. (boolean and "none" or normal_colour))
	vim.cmd("highlight Comment guifg=" .. (boolean and "#8f98ba" or "#565f89"))

	is_transparent = boolean
	save_is_transparent(boolean)
end

-- Initialize transparency
set_background_transparent(is_transparent)

-- Toggle transparency
vim.keymap.set("n", "<leader>tt", function()
	set_background_transparent(not is_transparent)
end, { desc = "Toggle transparency" })

--NOTE: this didnt work:
-- NOTE:custom:added transparency toggler (not theme related yet)
--
--
-- local is_transparent_file = vim.fn.stdpath 'config' .. '/is_transparent'
--
-- local is_transparent = (function()
--   local is_transparent = true
--   local file = io.open(is_transparent_file, 'r')
--   if file then
--     local value = file:read '*a'
--     if value and value:lower() == 'false' then
--       is_transparent = false
--     else
--       is_transparent = true
--     end
--     vim.cmd('echo "Current is_transparent value: ' .. value .. '"')
--     file:close()
--   end
--   return is_transparent
-- end)()
--
-- local function save_is_transparent(__is_transparent)
--   local file = io.open(is_transparent_file, 'w')
--   if file then
--     file:write(tostring(__is_transparent):lower())
--     file:close()
--   end
-- end

-- local toggle_transparency = function()
--   -- local is_transparent = true
--   local normal_colour = '#11121f'
--
--   local function set_background_transparent(boolean)
--     if type(boolean) ~= 'boolean' then
--       error 'Expected a boolean value'
--     end
--     vim.cmd('highlight Normal guibg=' .. (boolean and 'none' or normal_colour))
--     vim.cmd('highlight NonText guibg=' .. (boolean and 'none' or normal_colour))
--     vim.cmd('highlight Comment guifg=' .. (boolean and '#8f98ba' or '#565f89'))
--
--     is_transparent = boolean
--
--     save_is_transparent(is_transparent)
--   end
--
--   -- Initialize transparency
--   set_background_transparent(true)
--
--   return function()
--     set_background_transparent(not is_transparent)
--   end
-- end
--
-- vim.keymap.set('n', '<leader>tt', toggle_transparency())

-- NOTE:custom:added keymaps
vim.keymap.set("n", "<A-down>", "6j", { silent = true })
vim.keymap.set("n", "<A-up>", "6k", { silent = true })
vim.keymap.set("n", "<A-j>", "4j", { silent = true })
vim.keymap.set("n", "<A-k>", "4k", { silent = true })
--- Move single line or selected block up

vim.keymap.set("n", "<S-A-k>", ":m .-2<CR>==", { noremap = true, silent = true })
vim.keymap.set("v", "<S-A-k>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("n", "<S-A-j>", ":m .+1<CR>==", { noremap = true, silent = true })
vim.keymap.set("v", "<S-A-j>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("n", "-", ":Ex<CR>", { desc = ":Explore" })
vim.g.netrw_keepdir = 0
--
--
-- NOTE: Old ideas:
--
---- Goated plugin wrapper to set up custom events. E.g. in terminal `nvim -c ":doautocmd User InitDiffview" -c "DiffviewOpen"`
--
--local function load_plugin_on_user_event(pluginTable)
-- if event is a string make it table anyways to handle both cases
--   local events = type(pluginTable.event) == 'table' and pluginTable.event or { pluginTable.event }
--
--   for _, event in ipairs(events) do
--     if type(event) == 'string' and event:match '^User ' then
--       vim.api.nvim_create_autocmd('User', {
--         -- otherwise calling this event would be `:doautocmd User User EventName`
--         pattern = event:gsub('^User ', ''),
--         callback = function()
--           -- vim.notify('Plugin loaded: ' .. pluginTable[1])
--         end,
--       })
--     end
--   end
--
--   return pluginTable
-- end
--
-- require('lazy').setup({
-- load_plugin_on_user_event {
--   'sindrets/diffview.nvim',
--   event = 'User InitDiffview',
-- },
-- {
--   'sindrets/diffview.nvim',
--   cmd = 'DiffviewOpenLazy',
--   init = function()
--     vim.api.nvim_create_user_command('DiffviewOpenLazy', function()
--       require('lazy').load { plugins = { 'diffview.nvim' } }
--       vim.schedule(function()
--         vim.cmd 'DiffviewOpen'
--       end)
--     end, {})
--   end,
-- },
--
----NOTE: old way to encapsulate themes + theme_switcher. Previously had to add this entry
-- to lazy setup section: { theme_plugins, theme_plugins:theme_switcher() }
--
-- local theme_plugins = {
--   {
--     'folke/tokyonight.nvim',
--     config = function()
--       vim.cmd.colorscheme 'tokyonight-night'
--     end,
--     -- lazy = true,
--   },
--   {
--     'catppuccin/nvim',
--     config = function()
--       vim.cmd.colorscheme 'catppuccin-mocha'
--     end,
--     -- lazy = true,
--   },
--   theme_switcher = function(self)
--     local theme_index = 2
--
--     -- initializes which single theme to have 'lazy = false' (i.e. default)
--     for i, theme in ipairs(self) do
--       theme.lazy = i ~= theme_index
--     end
--
--     -- sets up keymap for toggling logic
--     vim.keymap.set('n', '<leader>t<leader>t', function()
--       theme_index = (theme_index % #self) + 1
--       self[theme_index].config()
--     end, { desc = 'Theme Switcher' })
--   end,
-- }
-- NOTE: Old ideas.
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*.js",
	callback = function()
		print("Attempting to format JavaScript file...")
		require("conform").format({ async = false })
	end,
})

vim.api.nvim_create_user_command("Replace", function(opts)
	local old_str, new_str = opts.args:match("^(.-)/(.-)$")
	if old_str and new_str then
		vim.cmd(string.format("%%s/%s/%s/gc", old_str, new_str))
	else
		print("Invalid arguments! Usage: :replace oldstring/newstring")
	end
end, { nargs = 1 })

--NOTE: banger! mimics yazi defaults in netrw view
vim.api.nvim_create_autocmd("FileType", {
	pattern = "netrw",
	callback = function()
		local function netrw_bind(from, to)
			return vim.keymap.set("n", to, from, { remap = true, buffer = true })
		end

		-- netrw_bind("%", "a") -- Create file
		netrw_bind("D", "d") -- Delete
		netrw_bind("R", "r") -- Rename
		-- netrw_bind( "-", "h") -- Up directory
		-- netrw_bind("<CR>", "l") -- Enter file/dir
		netrw_bind("<C-w>v<CR>", "p") -- Open in vertical split
		netrw_bind("<C-w>s<CR>", "P") -- Open in horizontal split

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

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et

-- NOTE: testing
-- vim.keymap.set("n", "<leader>bc", [["_c]])
-- vim.keymap.set("n", "<leader>bd", [["_d]])
vim.keymap.set("n", "<leader>p", [["_viwP]])
--o
-- opening urls
vim.keymap.set({ "n", "x" }, "gx", function()
	-- grab the whole WORD, then cut out the http(s) part
	local word = vim.fn.expand("<cWORD>")
	local url = word:match("(https?://%S+)") or word:match("(ftp://%S+)")
	if url then
		vim.ui.open(url)
	else
		vim.notify("No URL found under cursor", vim.log.levels.WARN)
	end
end, { desc = "open URL under cursor" })
