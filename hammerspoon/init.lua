hs.alert.show("hs init.lua loaded")

--Commmented these 2 out on 4-25-25 since not really using
-- hs.ipc.cliInstall()
-- hs.loadSpoon("EmmyLua")

require("submodules")
require("registerSpoons")

local TG = require("termGuard")

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

local terminal_app = "ghostty"
local terminal_app_id = "com.mitchellh.ghostty"
hs.hotkey.bind(goto_app_mod, "t", function()
	window_management.toggle_app_bundle_id(terminal_app_id)
	-- window_management.toggle_app(terminal_app)
end)

local function runCommand(command)
	hs.eventtap.keyStrokes(command)
	hs.eventtap.keyStroke({}, "return")
end

local function runCommandInItermAndHitEnter(command, delay)
	local app_running = hs.application.find(terminal_app)

	delay = app_running and 0.0 or (delay or 0.25)

	hs.application.launchOrFocus(terminal_app)
	hs.timer.doAfter(delay, function()
		if app_running then
			hs.eventtap.keyStroke({ "command" }, "n")
		end
		runCommand(command)
	end)
end
-- hs.hotkey.bind(goto_app_mod, "y", function()
-- 	runCommandInItermAndHitEnter("yazi")
-- end)

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
	window_management.toggle_app("Notes")
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

-- hs.hotkey.bind(goto_app_mod, "e", function()
-- 	window_management.goto_app("Emacs.app")
-- end)

-- function runCommandInITermAndHitEnter(command, delay)
-- 	delay = delay or 0.3
--
-- 	window_management.goto_app("iterm2")
--
-- 	-- Give it a moment to become active
-- 	hs.timer.doAfter(delay, function()
-- 		-- Send the keystrokes as if you were typing
-- 		if hs.application("iterm2") then
-- 			hs.eventtap.keyStroke({ "command" }, "t")
-- 		end
-- 		hs.eventtap.keyStrokes(command)
-- 		hs.eventtap.keyStroke({}, "return") -- Press Enter
-- 	end)
-- end

-- Run a command in iTerm2, hit Enter, and unfocus iTerm2
local function runCommandInItermAndUnfocus(command, delay)
	-- Store the currently focused application
	local original_app = hs.application.frontmostApplication()

	-- Check if iTerm2 is running
	local app_running = hs.application.find(terminal_app)
	delay = app_running and 0.0 or (delay or 0.25)

	-- Launch or focus iTerm2
	hs.application.launchOrFocus(terminal_app)

	-- Execute the command and hit Enter
	hs.timer.doAfter(delay, function()
		if app_running then
			hs.eventtap.keyStroke({ "command" }, "n") -- Open new tab if iTerm2 was already running
		end
		runCommand(command)

		-- Unfocus iTerm2 by restoring focus to the original application
		hs.timer.doAfter(0.1, function()
			if original_app and original_app:isFrontmost() == false then
				original_app:activate()
			end
			-- Optional: Minimize or hide iTerm2 to ensure it’s out of the way
			local iterm = hs.application.get(terminal_app)
			if iterm then
				iterm:hide() -- or iterm:minimize()
			end
		end)
	end)
end

-- -- Directory search hotkey

local function runCommandInBackground(command)
	-- Set PATH to include Homebrew binaries and source Zsh environment
	local shellCommand = string.format(
		'/bin/zsh -c "export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH; source /etc/zprofile 2>/dev/null; source ~/.zshenv 2>/dev/null; source ~/.zshrc 2>/dev/null && %s"',
		command
	)
	-- Execute and capture output/errors
	local output, status, type, rc = hs.execute(shellCommand)
	if not status then
		hs.notify
			.new({
				title = "Hammerspoon",
				informativeText = "Error running " .. command .. ": " .. (output or "Unknown error"),
			})
			:send()
	else
		hs.notify
			.new({
				title = "Hammerspoon",
				informativeText = "Successfully ran " .. command .. ". Text copied to clipboard.",
			})
			:send()
	end
	return output, status
end

local function captureAndOCR()
	-- Ensure screenshots directory exists
	local screenshotsDir = os.getenv("HOME") .. "/screenshots"
	os.execute("mkdir -p " .. screenshotsDir)

	-- Generate unique filename with timestamp
	local timestamp = os.date("%Y%m%d_%H%M%S")
	local screenshotPath = screenshotsDir .. "/screenshot_" .. timestamp .. ".png"

	-- Capture screenshot interactively
	local success = os.execute("screencapture -i " .. screenshotPath)
	if not success or not hs.fs.attributes(screenshotPath) then
		hs.notify.new({ title = "Hammerspoon", informativeText = "Failed to capture screenshot" }):send()
		return
	end

	-- Run get_ocr
	runCommandInBackground("get_ocr_old")
	-- runCommandInItermAndHitEnter("get_ocr")
end

function run_without_terminal(function_or_script_path)
	-- hs.execute("/bin/zsh -c 'source ~/.zshrc 2>/dev/null; LC_ALL=en_US.UTF-8 " .. function_or_script_path .. "'")
	hs.execute(
		string.format("/bin/zsh -c 'source ~/.zshrc 2>/dev/null; LC_ALL=en_US.UTF-8 %s'", function_or_script_path)
	)
end

hs.hotkey.bind({ "ctrl", "option" }, "x", function()
	-- run_without_terminal("~/bin/get_ocr.sh") --works nicely
	run_without_terminal("get_ocr") --works nicely

	-- hs.execute("/bin/zsh -c '$HOME/bin/get_ocr.sh'") -- garbles text

	-- runCommandInItermAndHitEnter("get_ocr") --works but opens terminal
	-- captureAndOCR() --works but requires local files (no pngpaste) and logic now lives within hammerspoon function rather tham bash or script file
end)

-- Run a command in iTerm2 without focusing it

local function runCommandInItermWithoutFocus(command)
	-- Modify command to exit after completion
	local wrappedCommand = command .. "; exit"

	local script = [[
        tell application "iterm2"
            -- Create a new terminal window without activating
            set newWindow to (create window with default profile without activating)
            
            -- Get the current session of the new window
            tell current session of newWindow
                -- Run the command with exit at the end
                write text "]] .. wrappedCommand .. [["
            end tell
        end tell
    ]]

	-- Run the AppleScript
	hs.osascript.applescript(script)
end

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

local function runCommandInGhostty(command)
	local wrappedCommand = command .. "; exit"
	-- Run Ghostty with the command
	hs.execute("/bin/zsh -c /opt/homebrew/bin/ghostty -e '" .. wrappedCommand .. "' &")
end

-- Run a command in iTerm2 without focusing the window and close when done
local function runCommandInItermWithoutFocus_broken(command)
	-- Modify command to signal completion
	local wrappedCommand = command .. "; echo 'HAMMERSPOON_COMMAND_COMPLETED'; exit"

	-- AppleScript to create a new terminal window, run command, and monitor for completion
	local script = [[
        tell application "iTerm2"
            -- Create a new terminal window without activating
            set newWindow to (create window with default profile without activating)
            
            -- Get the current session of the new window
            tell current session of newWindow
                -- Set up a handler to monitor the session output
                set isComplete to false
                set outputBuffer to ""
                
                -- Run the command
                write text "]] .. wrappedCommand .. [["
                
                -- Loop until we see our completion marker
                repeat until isComplete
                    delay 0.2
                    -- Get session contents
                    set outputBuffer to (get contents)
                    
                    -- Check if our marker is in the output
                    if outputBuffer contains "HAMMERSPOON_COMMAND_COMPLETED" then
                        set isComplete to true
                        close newWindow
                    end if
                end repeat
            end tell
        end tell
    ]]

	-- Run the AppleScript
	hs.osascript.applescript(script)
end

hs.hotkey.bind({ "ctrl", "option" }, "z", function()
	-- run_without_terminal("get_ocr_images")
	-- run_without_terminal("get_latex") --pix2tex seemingly needs actual terminal to work
	-- runCommandInItermAndUnfocus("get_latex")
	-- runCommandInItermWithoutFocus("get_latex")
	runCommandInTerminal("get_latex")
	-- runCommandInGhostty("get_latex")
end)

--NOTE: blocking version
--
-- hs.hotkey.bind(goto_app_mod, "d", function()
-- 	local function start_emacs_client()
-- 		os.execute([[/bin/zsh -l -c "/opt/homebrew/bin/emacsclient -c -n -a '' "]])
-- 	end
-- 	local serverRunning =
-- 		os.execute([[/bin/zsh -l -c "/opt/homebrew/bin/emacsclient -e '(server-running-p)' > /dev/null 2>&1"]])
--
-- 	local emacsApp = hs.application.get("org.gnu.Emacs")
--
-- 	if serverRunning then
-- 		if emacsApp and #emacsApp:allWindows() > 0 then
-- 			emacsApp:activate()
-- 		else
-- 			start_emacs_client()
-- 			emacsApp:activate()
-- 		end
-- 	else
-- 		hs.alert.show("Starting Emacs daemon and creating frame")
--
-- 		os.execute(string.format('/bin/zsh -l -c "/opt/homebrew/bin/emacs --daemon"'))
-- 		start_emacs_client()
-- 	end
-- end)

-- async/non-blocking version

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

-- NOTE: WIP below
-- hs.hotkey.bind({ "cmd", "option" }, "r", function()
-- 	prompt_with_callback("Enter comment character (e.g. #)", function(comment_char)
-- 		-- local script =
-- 		-- 	string.format("/bin/zsh -c 'source ~/.zshrc 2>/dev/null; pbpaste | rem %q | pbcopy &'", comment_char)
-- 		-- -- hs.execute(script .. " &") --  sub-shell truncates output!
-- 		-- hs.execute(script)
--
-- 		local script = string.format("source ~/.zshrc 2>/dev/null; pbpaste | rem %q | pbcopy", comment_char)
-- 		hs.task
-- 			.new("/bin/zsh", function(exitCode, stdOut, stdErr)
-- 				if exitCode == 0 then
-- 					hs.alert.show("Result copied to clipboard!")
-- 				else
-- 					hs.alert.show("Error: " .. (stdErr or "Unknown error"))
-- 				end
-- 			end, { "-c", script })
-- 			:start()
-- 		hs.alert.show("Result copied to clipboard!")
-- 	end)
-- end)

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
hs.hotkey.bind({ "ctrl", "option", "command" }, "t", function()
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

-- 1. Original “plain terminal” toggle -------------------------------------------------
local termBundle = "com.mitchellh.ghostty"

-- one helper that works for *any* terminal -------------------------------
local function launchTerminalTheRunCmd(opts)
	opts = opts or {} -- guard against nil
	local bundleID = opts.bundleID or "com.mitchellh.ghostty"
	local cmd = opts.cmd or error("opts.cmd required")
	local pollPeriod = opts.poll or 0.02 -- seconds
	local finalPause = opts.pause or 0.03 -- seconds
	local timeout = opts.timeout or 3 -- seconds

	-- 1. start the app if necessary
	local app = hs.application.get(bundleID)
	if not app then
		hs.application.launchOrFocusByBundleID(bundleID)
	end

	-- 2. poll until a window exists
	local poll
	poll = hs.timer.doEvery(pollPeriod, function()
		app = hs.application.get(bundleID)
		if app and #app:allWindows() > 0 then
			poll:stop()
			app:activate()
			hs.timer.doAfter(finalPause, function()
				hs.eventtap.keyStrokes(cmd)
				hs.eventtap.keyStroke({}, "return")
			end)
		end
	end)

	-- 3. safety kill-switch
	hs.timer.doAfter(timeout, function()
		if poll then
			poll:stop()
		end
	end)
end

local function launchTerminalWithCmd_og(opts)
	opts = opts or {}
	local cmd = opts.cmd or error("opts.cmd required")
	local bundleID = opts.bundleID or "com.mitchellh.ghostty"

	-- Explicitly source .zshrc before running command
	hs.execute(string.format("open -b %s --args -e zsh -c 'source ~/.zshrc && %s; exec zsh'", bundleID, cmd), true)
end

local function launchTerminalWithCmd_old(opts)
	opts = opts or {}
	local cmd = opts.cmd or error("opts.cmd required")
	local bundleID = opts.bundleID or "com.mitchellh.ghostty"

	local app = hs.application.get(bundleID)
	local newWindow = (app and app:isRunning()) and "" or "n"
	-- doesnt actually open a newWindow when app is running

	hs.execute(
		string.format("open -%sb %s --args -e zsh -c 'source ~/.zshrc && %s; exec zsh'", newWindow, bundleID, cmd),
		true
	)
end

local function launchTerminalWithCmd(opts)
	opts = opts or {}
	local cmd = opts.cmd or error("opts.cmd required")
	local bundleID = opts.bundleID or "com.mitchellh.ghostty"
	-- local bundleID = opts.bundleID or "com.googlecode.iterm2"

	local app = hs.application.get(bundleID)
	-- local app = hs.application.get(bundleID) or hs.application.launchOrFocusByBundleID(bundleID)
	local terminalApp = "Ghostty"

	-- local app = hs.application.find(terminalApp)
	local isRunning = app and app:isRunning()

	if not isRunning then
		-- #NOTE: 'open -n ..' creates a _new instance_ with the new window (not a problem here since app is not started)
		--  Previously this was an issue since i couldnt cycle through various windows with 'cmd + .' since that only works
		--  for many windows beloning to the _same_ instance
		--
		-- hs.execute(string.format("open -nb %s --args -e zsh -c 'source ~/.zshrc && %s; exec zsh'", bundleID, cmd), true)

		hs.execute(
			string.format("open -a %s --args -e zsh -c 'source ~/.zshrc && %s; exec zsh'", terminalApp, cmd),
			true
		)
	else
		local applescript = string.format(
			[[
			    tell application "%s"
				activate
			    end tell
			    delay 0.1
			    tell application "System Events"
				keystroke "n" using {command down}
			    end tell
			    delay 0.1
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
			hs.alert.show("Failed to open Ghostty window: " .. tostring(result))
		end
	end
end

local hotkey_ctrl_r = hs.hotkey.bind({ "ctrl" }, "r", function()
	-- hs.hotkey.bind({ "cmd", "alt" }, "r", function()
	-- launchTerminalWithCmd({ cmd = "send_key control r" })
	-- --NOTE: for some reason doesnt work .. feels like timing

	launchTerminalWithCmd({ cmd = "recent_pick" })
end)

local hotkey_ctrl_f = hs.hotkey.bind({ "ctrl" }, "f", function()
	launchTerminalWithCmd({ cmd = "send_key control f" }) -- find_file
end)

local hotkey_ctrl_d = hs.hotkey.bind({ "ctrl" }, "d", function()
	-- runCommandInItermAndHitEnter("find_dir_from_cache 'emacs'")
	launchTerminalWithCmd({ cmd = "send_key control d" }) -- find_dir_from_cache
end)

local hotkey_ctrl_option_d = hs.hotkey.bind({ "ctrl", "option" }, "d", function()
	launchTerminalWithCmd({ cmd = "send_key control option d" }) -- find_dir_then_cache
end)
--
local hotkey_ctrl_y = hs.hotkey.bind({ "ctrl" }, "y", function()
	launchTerminalWithCmd({ cmd = "send_key control y" }) -- yazi
end)

local hotkey_ctrl_h = hs.hotkey.bind({ "ctrl" }, "h", function()
	launchTerminalWithCmd({ cmd = "send_key control h" })
end)

TG.watch({ hotkey_ctrl_d, hotkey_ctrl_option_d, hotkey_ctrl_f, hotkey_ctrl_y, hotkey_ctrl_r, hotkey_ctrl_h })

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
