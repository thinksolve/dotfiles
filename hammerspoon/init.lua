hs.alert.show("hs init.lua loaded")

-- default terminal across hotkey binds below
local TERM = {
	ghostty = "com.mitchellh.ghostty",
	kitty = "net.kovidgoyal.kitty", -- kinda broken when using hotkey and app already running
	-- iterm2 = "com.googlecode.iterm2",
	terminal = "com.apple.Terminal",
}
local DEFAULT_TERM_ID = TERM.ghostty
local DEFAULT_TERM_NAME = DEFAULT_TERM_ID:match("[^.]+$") -- e.g. print(("com.mitchellh.ghostty"):match("[^.]+$")) --> ghostty

--Commmented these 2 out on 4-25-25 since not really using
-- hs.ipc.cliInstall()
-- hs.loadSpoon("EmmyLua")

require("submodules")
-- require("registerSpoons")

local watchers = require("watchers") -- set as variable in case want to stop a watcher
local window_management = require("window-management")
local space_management = require("space-management")

-- local function merge_modifiers_old(base_mods, ...)
-- 	return { table.unpack(base_mods), ... }
-- end

local function merge_modifiers(base_mods, ...)
	local new_mods = { table.unpack(base_mods) }

	--NOTE: deduplicating logic below for additional entries

	local exists = {}

	-- Mark existing modifiers
	for _, mod in ipairs(new_mods) do
		exists[mod] = true
	end

	-- Add new modifiers only if they don't exist
	for _, mod in ipairs({ ... }) do
		if not exists[mod] then
			table.insert(new_mods, mod)
			exists[mod] = true
		end
	end

	return new_mods
end

-- NOTE: not really useful to me anymore with cycling windows
-- local space_mod = { "ctrl" }
-- hs.hotkey.bind(space_mod, "q", space_management.close_all_spaces_but_two)
-- hs.hotkey.bind(space_mod, "-", space_management.close_this_space)
-- hs.hotkey.bind(merge_modifiers(space_mod, "shift"), "-", space_management.add_new_space)

local screen_position_mod = { "command", "option" }

hs.hotkey.bind(screen_position_mod, "Left", window_management.LeftHalf)
hs.hotkey.bind(screen_position_mod, "Right", window_management.RightHalf)
hs.hotkey.bind(screen_position_mod, "Up", window_management.TopHalf)
hs.hotkey.bind(screen_position_mod, "Down", window_management.BottomHalf)
hs.hotkey.bind(screen_position_mod, "Space", window_management.FullScreen)
-- hs.hotkey.bind(screen_position_mod, "Return", window_management.FullScreen)

local cycle_windows = { "command" }
hs.hotkey.bind(cycle_windows, ",", function()
	window_management.cycleWindows("right")
end)
hs.hotkey.bind(merge_modifiers(cycle_windows, "shift"), ",", function()
	window_management.cycleWindows("left")
end)

local goto_app_mod = { "command", "option" }
hs.hotkey.bind(goto_app_mod, "b", function()
	window_management.toggle_app("Brave Browser")
end)

hs.hotkey.bind(goto_app_mod, "t", function()
	window_management.toggle_app_bundle_id(DEFAULT_TERM_ID)
	-- window_management.toggle_app(terminal_app)
end)

hs.hotkey.bind(goto_app_mod, "s", function()
	-- window_management.toggle_app("Spotify")

	--NOTE: using bundle id is less buggy for PWAs
	local spotify_bundle_id = "com.brave.Browser.app.pjibgclleladliembfgfagdaldikeohf"
	window_management.toggle_app_bundle_id(spotify_bundle_id)
end)

hs.hotkey.bind(goto_app_mod, "m", function()
	-- window_management.goto_app("messages.app")
	window_management.toggle_open_close_by_bundle_id("com.apple.MobileSMS")
end)

hs.hotkey.bind(goto_app_mod, "n", function()
	-- window_management.toggle_app("Notes")
	window_management.toggle_open_close_by_bundle_id("com.apple.Notes")
end)

hs.hotkey.bind(goto_app_mod, "l", function()
	-- window_management.toggle_app("Mail")
	window_management.toggle_open_close_by_bundle_id("com.apple.mail")
end)

hs.hotkey.bind(goto_app_mod, "k", function()
	-- window_management.toggle_app("Calendar")
	window_management.toggle_open_close_by_bundle_id("com.apple.iCal")
end)

hs.hotkey.bind(goto_app_mod, "f", function()
	window_management.toggle_open_close_by_bundle_id("com.runningwithcrayons.Alfred")
end)

hs.hotkey.bind(goto_app_mod, "a", function()
	window_management.toggle_open_close_by_bundle_id("com.apple.ActivityMonitor")
end)

-- helper gives feedback when cmd string does not exist
local function runSilent(cmd)
	local _, status = hs.execute(cmd, true) -- bro why is the relevant data the SECOND one??
	if not status then
		hs.alert("That command doesnt work boss.", 3)
	end
end
hs.hotkey.bind({ "ctrl", "option" }, "x", function()
	-- local cmd = "get_ocr"
	-- hs.execute(string.format("/bin/zsh -i -c 'LC_ALL=en_US.UTF-8 %s'", cmd))
	runSilent("get_ocr")
end)
--

local function runCommandInTerminal(command)
	local wrappedCommand = command .. "; exit"
	local script = [[
        tell application "Terminal"
            set newWindow to do script "]] .. wrappedCommand .. [["
            -- Optionally close the window after execution
            -- delay 1
            -- tell newWindow to close
        end tell
    ]]
	hs.osascript.applescript(script)
end

hs.hotkey.bind({ "ctrl", "option" }, "z", function()
	runCommandInTerminal("get_latex")
end)

--TEST: tiny, fast, corner alert ---------------------------------------------------
-- NOTE: do end version of iife
-- local cornerAlert
-- do
-- 	local alertObj, timerObj
--
-- 	function cornerAlert(text, secs)
-- 		secs = secs or 2
-- 		if alertObj then
-- 			alertObj:delete()
-- 		end
-- 		if timerObj then
-- 			timerObj:stop()
-- 		end
--
-- 		local f = hs.screen.mainScreen():frame()
-- 		alertObj = hs.canvas.new({ x = f.w - 210, y = 25, w = 200, h = 30 })
-- 		alertObj[1] = { type = "rectangle", action = "fill", fillColor = { hex = "#000", alpha = 0.75 } }
-- 		alertObj[2] = { type = "text", text = text, textColor = { white = 1 }, textSize = 14 }
-- 		alertObj:behavior("canJoinAllSpaces"):level(hs.canvas.windowLevels.floating):show()
--
-- 		timerObj = hs.timer.doAfter(secs, function()
-- 			if alertObj then
-- 				alertObj:delete()
-- 				alertObj = nil
-- 			end
-- 		end)
-- 	end
-- end

-- NOTE: classic js-style iife version
local cornerAlert = (function()
	local alertObj, timerObj -- private up-values

	return function(text, secs)
		secs = secs or 2

		if alertObj then
			alertObj:delete()
		end
		if timerObj then
			timerObj:stop()
		end

		local f = hs.screen.mainScreen():frame()
		alertObj = hs.canvas.new({ x = f.w - 210, y = 25, w = 200, h = 30 })
		alertObj[1] = { type = "rectangle", action = "fill", fillColor = { hex = "#000", alpha = 0.75 } }
		alertObj[2] = { type = "text", text = text, textColor = { white = 1 }, textSize = 14 }
		alertObj:behavior("canJoinAllSpaces"):level(hs.canvas.windowLevels.floating):show()

		timerObj = hs.timer.doAfter(secs, function()
			if alertObj then
				alertObj:delete()
				alertObj = nil
			end
		end)
	end
end)()
--TEST: tiny, fast, corner alert ---------------------------------------------------

hs.hotkey.bind({ "cmd", "option" }, "d", function()
	--note:  async/non-blocking version
	local emacsclient = "/opt/homebrew/bin/emacsclient"
	local emacs = "/opt/homebrew/bin/emacs"

	--NOTE: this keybind uses async logic and hence we need to
	--handle stale references ... thats why we need 'getEmacsApp'
	local function getEmacsApp()
		return hs.application.get("org.gnu.Emacs")
	end

	local function startClient()
		hs.task
			.new(emacsclient, function()
				local _emacsApp = getEmacsApp()
				if _emacsApp then
					_emacsApp:activate()
				end
			end, { "-c", "-n", "-a", "" })
			:start()
	end

	local emacsApp = getEmacsApp()

	-- if emacsApp and #emacsApp:allWindows() > 0 then
	if emacsApp and #emacsApp:allWindows() > 0 then
		emacsApp:activate()
	else
		local daemon_running = os.execute(emacsclient .. " -e '(server-running-p)' > /dev/null 2>&1")
		if daemon_running then
			startClient()
		else
			-- hs.alert.show("Doom Emacs starting", 0.7)
			cornerAlert("Starting Doom Emacs daemon …")
			--
			hs.task.new(emacs, startClient, { "--daemon" }):start()
		end
	end
end)

-- NOTE: WIP below

function prompt_with_callback(place_holder_text, call_back)
	local chooser
	chooser = hs.chooser.new(function(choice)
		if not choice or not choice.text or choice.text == "" then
			return
		end
		call_back(choice.text)
	end)

	chooser:choices({ { ["text"] = "" } })
	chooser:queryChangedCallback(function(query)
		chooser:choices({ { ["text"] = query } })
	end)
	chooser:placeholderText(place_holder_text)
	chooser:width(30)
	chooser:rows(1)
	chooser:show()
end

-- -- Interactive translation with UI prompt (doesn't auto-copy)
-- hs.hotkey.bind({ "cmd", "option", "shift" }, "x", function()
-- 	prompt_with_callback("Enter text to translate", function(text)
-- 		local script = string.format(
-- 			[[
--             export LANG=en_US.UTF-8
--             export LC_ALL=en_US.UTF-8
--             cd ~
--             source .zshrc
--             translate_from_to %q en es
--         ]],
-- 			text
-- 		)
--
-- 		hs.task
-- 			.new("/bin/zsh", function(exitCode, stdOut, stdErr)
-- 				if exitCode == 0 and stdOut and stdOut ~= "" then
-- 					local translation = stdOut:gsub("%s+$", "")
-- 					-- Show translation in a dialog instead of auto-copying
-- 					show_translation_result(text, translation)
-- 				else
-- 					hs.alert.show("Translation error: " .. (stdErr or "Unknown error"))
-- 				end
-- 			end, { "-c", script })
-- 			:start()
-- 	end)
-- end)

-- -- Function to show translation result with copy option
-- function show_translation_result(original, translation)
-- 	local dialog = hs.dialog.blockAlert(
-- 		"Translation Result",
-- 		string.format("Original: %s\n\nTranslation: %s", original, translation),
-- 		"Copy to Clipboard",
-- 		"Close"
-- 	)

-- 	if dialog == "Copy to Clipboard" then
-- 		hs.pasteboard.setContents(translation)
-- 		hs.alert.show("Translation copied!")
-- 	end
-- end

-- Interactive translation with real-time results in chooser
hs.hotkey.bind({ "ctrl", "option", "shift" }, "t", function()
	translate_prompt_with_realtime()
end)

function translate_prompt_with_realtime()
	local chooser
	local debounceTimer = nil
	local lastTranslation = ""

	chooser = hs.chooser.new(function(choice)
		if not choice then
			return
		end

		-- If they selected the translation result, copy it
		if choice.translation then
			hs.pasteboard.setContents(choice.translation)
			hs.alert.show("Translation copied!")
			return
		end

		-- If they pressed enter on input, copy the translation if available
		if lastTranslation ~= "" then
			hs.pasteboard.setContents(lastTranslation)
			hs.alert.show("Translation copied!")
		end
	end)

	-- Function to perform translation
	-- NOTE: WIP: query edges cases like containing `" "` marks
	local function performTranslation(query)
		if query == "" then
			chooser:choices({ { ["text"] = query } })
			return
		end

		local script = string.format(
			[[
			export lang=en_us.utf-8
			export lc_all=en_us.utf-8
			cd ~
			source .zshrc
			translate=%q
			command -v $translate >/dev/null 2>&1 || { echo "error: $translate not found"; exit 1; }
			$translate %q
		    ]],
			"translate_from_to",
			query
		)

		hs.task
			.new("/bin/zsh", function(exitCode, stdOut, stdErr)
				if exitCode == 0 and stdOut and stdOut ~= "" then
					local translation = stdOut:gsub("%s+$", "")
					lastTranslation = translation

					-- Update chooser with input and translation
					chooser:choices({
						{
							["text"] = "→ " .. translation,
							["subText"] = "Translation (select to copy)",
							["translation"] = translation,
						},
					})
				else
					chooser:choices({
						{
							["text"] = query,
							["subText"] = "Input",
						},
						{
							["text"] = "❌ Translation failed",
							["subText"] = stdErr or "Unknown error",
						},
					})
				end
			end, { "-c", script })
			:start()
	end

	chooser:queryChangedCallback(function(query)
		-- Cancel previous timer
		if debounceTimer then
			debounceTimer:stop()
		end

		-- Set up debounced translation (500ms delay)
		debounceTimer = hs.timer.doAfter(0.5, function()
			performTranslation(query)
		end)

		-- Show input immediately
		chooser:choices({ { ["text"] = query, ["subText"] = "Translating..." } })
	end)

	chooser:placeholderText("Enter text to translate (EN→ES)")
	chooser:width(50)
	chooser:rows(2)
	chooser:show()
end

local clipboardActive = false
hs.hotkey.bind({ "option", "cmd", "shift" }, "v", function()
	if clipboardActive then
		-- spoon.ClipboardTool.stop()
		-- NOTE: LOL no stop() method so grok hack:
		spoon.ClipboardTool.shouldBeStored = function()
			return false
		end
		clipboardActive = false
		hs.alert.show("ClipboardTool Disabled")
	else
		spoon.ClipboardTool:start()
		clipboardActive = true
		hs.alert.show("ClipboardTool Enabled")
	end
end)

--NOTE: replaced with open_term_and_run
local function launchGhosttyWithCmd(opts)
	opts = opts or {}
	local cmd = opts.cmd or error("opts.cmd required")
	local bundleID = opts.bundleID or "com.mitchellh.ghostty"
	local terminalApp = "Ghostty"

	local app = hs.application.get(bundleID)
	-- local app = hs.application.find(terminalApp)

	if not (app and app:isRunning()) then
		-- #NOTE: 'open -n ..' creates a _new instance_ with the new window (not a problem here since app is not started)
		--  Previously this was an issue since i couldnt cycle through various windows with 'cmd + .' since that only works
		--  for many windows beloning to the _same_ instance

		hs.execute(string.format("open -a %s --args -e zsh -il -c '%s; exec zsh'", terminalApp, cmd), true)
	-- elseif app:isHidden() then  -- why didnt this work
	else
		local applescript = string.format(
			[[
			    tell application "%s"
				activate
			    end tell
			    -- delay 0.1
			    tell application "System Events"
				keystroke "n" using {command down}
			    end tell
			    -- delay 0.1
			    tell application "System Events"
				tell process "%s"
				    keystroke "%s"
				    keystroke return
				end tell
			    end tell
			]],
			terminalApp,
			terminalApp,
			cmd
		)

		local ok, result = hs.osascript.applescript(applescript)
		if not ok then
			hs.alert.show("Failed to open terminal window: " .. tostring(result))
		end
	end
end

local function open_term_and_run(opts)
	local cmd = opts.cmd or error("cmd required")

	local term_name = (opts.terminal or DEFAULT_TERM_NAME):lower():match("[^.]+$")
	local app = hs.application.get(DEFAULT_TERM_ID or error("unsupported terminal"))

	if term_name == "ghostty" or term_name == "kitty" then
		if not (app and app:isRunning()) then
			-- start + run command in first window
			cmd = cmd:gsub("'", "'\\''")

			hs.execute(string.format("open -a %s --args -e zsh -il -c '%s; exec zsh'", term_name, cmd), true)
		else
			-- NOTE: the delays below prevent weird race conditions (opens other apps, etc)
			-- there has to be a less janky way to do this

			local applescript = ([[
			    tell application "{term}"
				activate
			    end tell

			    delay 0.1  -- this prevents an alternate app (notes, alfred) opening bug

			    tell application "System Events"
				keystroke "n" using {command down}
			    end tell

			    delay 0.1 -- this allows other LSBs to fire their cmd properly

			    tell application "System Events"
				tell process "{term}"
				    keystroke "{cmd}"
				    keystroke return
				end tell
			    end tell
			]]):gsub("{(%w+)}", {
				term = term_name,
				cmd = cmd,
			})

			local ok, result = hs.osascript.applescript(applescript)
			if not ok then
				hs.alert.show("Failed to open terminal window: " .. tostring(result))
			end
		end

	-- ---------- AppleScript terminals ----------
	-- elseif isTerm("iterm2") then
	elseif term_name == "iterm2" then
		if not (app and app:isRunning()) then
			-- start + run command in first window
			local scpt = string.format(
				[[
				tell application "iTerm2"
				    launch
				    activate
				    set newWin to (create window with default profile)
				    tell current session of newWin
					write text "%s"
				    end tell
				end tell]],
				cmd
			)
			hs.osascript.applescript(scpt)
		else
			-- new tab/window + command
			local scpt = string.format(
				[[
				tell application "iTerm2"
				    activate
				    set newWin to (create window with default profile)
				    tell current session of newWin
					write text "%s"
				    end tell
				end tell]],
				cmd
			)
			hs.osascript.applescript(scpt)
		end
	else -- Terminal
		if not (app and app:isRunning()) then
			-- start + run command in first window
			local scpt = string.format(
				[[
				tell application "Terminal"
				    launch
				    activate
				    do script "%s"
				end tell]],
				cmd
			)
			hs.osascript.applescript(scpt)
		else
			-- new window + command
			local scpt = string.format(
				[[
				tell application "Terminal"
				    activate
				    do script "%s"
				end tell]],
				cmd
			)
			hs.osascript.applescript(scpt)
		end
	end
end

local LSB = require("loopSafeBind")

LSB.bind({ "option" }, "r", function()
	open_term_and_run({ cmd = "recent" })
	-- note: simulated control r, whether with osascript or hs.eventtap.keyStroke
	-- is somehow intercepted by macos, havent figured it out
end)

LSB.bind({ "option" }, "y", function()
	open_term_and_run({ cmd = "yazi" })
end)

LSB.bind({ "option" }, "f", function()
	open_term_and_run({ cmd = "fzd file" })
end)

LSB.bind({ "option" }, "d", function()
	open_term_and_run({ cmd = "fzd dir" })
end)

LSB.bind({ "ctrl", "option" }, "d", function()
	open_term_and_run({ cmd = "fzd" })
end)

LSB.bind({ "option" }, "h", function()
	open_term_and_run({ cmd = "send_key option h" })

	-- open_term_and_run({
	-- 	-- terminal = "terminal",
	-- 	cmd = "send_key option h",
	-- })
end)

--

-- local TG = require("termGuard")
-- TG.watch({
-- 	hotkey_ctrl_option_d,
-- 	hotkey_option_d,
-- 	hotkey_option_f,
-- 	hotkey_option_y,
-- 	hotkey_option_r,
-- 	hotkey_option_h,
-- })

--------------------------------------------------------------------------------
-- 100 % self-contained silent capture → clipboard
-- ⌘⌥C  : start
-- Enter: finish & copy
-- Esc  : cancel
--------------------------------------------------------------------------------
hs.hotkey.bind({ "cmd", "alt" }, "c", function()
	local seq = "" -- text being built
	local enterKeys = { [36] = true, [76] = true } -- Return / keypad Enter
	local stopper -- forward-declare

	local function handler(ev)
		local k = ev:getKeyCode()
		local f = ev:getFlags()

		if enterKeys[k] then -- finish
			hs.pasteboard.setContents(seq)
			stopper()
			hs.alert("Copied: " .. seq)
			return true
		end
		if k == 53 then -- Esc → cancel
			stopper()
			hs.alert("Capture cancelled")
			return true
		end
		if k == 51 then
			seq = seq:sub(1, -2)
			return true
		end -- Back-space
		if k == 49 then
			seq = seq .. " "
			return true
		end -- Space

		local name = hs.keycodes.map[k]
		if name and #name == 1 and not (f.ctrl or f.cmd or f.alt) then
			seq = seq .. (f.shift and name:upper() or name)
			return true
		end
		return true -- swallow rest
	end

	local tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, handler)
	stopper = function()
		tap:stop()
	end -- stop function
	tap:start()
	hs.alert("Type…  ⏎ copy  ⎋ cancel")
end)

hs.loadSpoon("KeystrokeShell")

local spoon_bind_mods = { "shift", "option" }
local ks = spoon.KeystrokeShell

ks:bind(spoon_bind_mods, "g", {
	command_string = function(q, esc)
		return string.format("s -p google '%s'", esc(q))
		-- return "open 'https://www.google.com/search?q=" .. hs.http.encodeForQuery(q) .. "'"
	end,
})
	:bind(spoon_bind_mods, "y", {
		command_string = function(q, esc)
			return string.format("s -p youtube '%s'", esc(q))
		end,
	})
	:bind(spoon_bind_mods, "p", {
		command_string = function(q, esc)
			return string.format("s -p perplexity '%s'", esc(q))
			-- return "open 'https://www.perplexity.ai/?q=" .. q .. "'"
		end,
	})
	:bind(spoon_bind_mods, "t", {
		command_string = function(q)
			return string.format("%s", q)
		end,
	})
	:bind(spoon_bind_mods, "o", {
		command_string = function(q)
			return string.format("open -a '%s'", q)
		end,
	})
	:bind(spoon_bind_mods, "w", {
		command_string = function(q, esc)
			return string.format("s -p wolfram '%s'", esc(q))
		end,
	})
	:bind(spoon_bind_mods, "s", {
		command_string = function(q, esc)
			return string.format("s -p grokipedia '%s'", esc(q))
		end,
	})

ks:bindModal({ "option" }, "space") -- uses all the key->action pairs from `:bind` instantiation
--
-- k = hs.hotkey.modal.new({ "option" }, "space")
--
-- function k:entered()
-- 	hs.alert("Entered mode")
-- end
-- function k:exited()
-- 	hs.alert("Exited mode")
-- end
-- k:bind({}, "escape", function()
-- 	k:exit()
-- end)
-- k:bind({}, "K", "Pressed K", function()
-- 	print("let the record show that K was pressed")
-- end)
