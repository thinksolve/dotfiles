hs.ipc.cliInstall()
hs.loadSpoon("EmmyLua")
-- require("submodules")

-- close this space (using osascript for now)
hs.hotkey.bind({ "ctrl" }, "-", function()
	local success, output, descriptor = hs.osascript.applescript([[
        tell application "Mission Control" to launch
        delay 0.25
        tell application "System Events"
            tell list 1 of group 2 of group 1 of group 1 of process "Dock"
                set countSpaces to count of buttons
                if countSpaces is greater than 1 then
                    perform action "AXRemoveDesktop" of button countSpaces
                end if
            end tell
            keystroke (key code 53)
        end tell
    ]])
	if success then
		print("Successfully closed the current space")
	else
		print("Failed to close the current space: " .. descriptor)
	end
end)

-- Bind a hotkey to 'q' with the 'fn' key as a modifier

-- Close all spaces and leave 2
hs.hotkey.bind({ "ctrl" }, "q", function()
	local spaces = hs.spaces

	-- Get the current spaces for each screen
	for _, screen in pairs(hs.screen.allScreens()) do
		local spaceIDs = spaces.spacesForScreen(screen)
		if spaceIDs then
			-- Close spaces starting from the third space onwards
			for i = 2, #spaceIDs do
				spaces.removeSpace(spaceIDs[i], true)
			end
		end
	end
end)

hs.hotkey.bind({ "ctrl" }, "b", function()
	app_to_space_using_sleep("Brave")
end)

hs.hotkey.bind({ "cmd", "option" }, "t", function()
	hs.application.open("iterm2")
end)

hs.hotkey.bind({ "ctrl" }, "t", function()
	app_to_space_using_sleep("iterm2")("iterm2")
end)

hs.hotkey.bind({ "ctrl" }, "s", function()
	app_to_space_using_sleep("Spotify")
end)

-- hs.hotkey.bind({ "cmd", "alt" }, "d", function()
hs.hotkey.bind({ "ctrl" }, "d", function()
	app_to_space_using_sleep("Discord")
end)
hs.hotkey.bind({ "ctrl" }, "p", function()
	-- app_to_space_using_sleep("Perplexity")
	-- hs.timer.doAfter(0.25, function()
	-- 	hs.eventtap.keyStroke({ "ctrl", "fn" }, "f")
	-- end)

	openPerplexityAndPassArgument()
end)

function openPerplexityAndPassArgument(query)
	query = query or ""
	app_to_space_using_sleep("Perplexity")

	hs.timer.doAfter(0.25, function()
		-- Tells perplexity to go "fill" screen
		hs.eventtap.keyStroke({ "ctrl", "fn" }, "f")
	end)

	-- early return if no argument passed
	if not query or query == "" then
		return
	end

	-- Type the query into the app and hit enter
	hs.timer.doAfter(0.5, function()
		hs.eventtap.keyStrokes(query)
		-- hs.eventtap.keyStroke({}, "return")
	end)
	hs.timer.doAfter(1.5, function()
		hs.eventtap.keyStroke({}, "return")
	end)
end

function app_to_space_using_sleep(app_name)
	local app = hs.application.get(app_name)

	if app and app:isRunning() then
		local win = app:focusedWindow()
		return win and win:focus()
	end

	local screen = hs.screen.mainScreen()
	local spaces = require("hs.spaces")
	-- local current_space = spaces.activeSpaceOnScreen(screen)

	spaces.addSpaceToScreen(screen)

	local delay_interval = 150000 -- in microseconds, so 0.25 seconds
	hs.timer.usleep(delay_interval)

	local new_spaces = spaces.spacesForScreen(screen)
	local new_space = new_spaces and new_spaces[#new_spaces]
	if new_space then
		spaces.gotoSpace(new_space)
		hs.timer.usleep(delay_interval)

		hs.application.open(app_name)
		hs.timer.usleep(2 * delay_interval)

		local app_window = hs.window.focusedWindow()
		if app_window then
			spaces.moveWindowToSpace(app_window, new_space)
			-- spaces.gotoSpace(current_space)
		end
	else
		print("Failed to create or identify new space")
	end
end

function app_to_space_using_doAfter(app_name)
	local app = hs.application.get(app_name)

	if app and app:isRunning() then
		local win = app:focusedWindow()
		return win and win:focus()
	end

	local spaces = require("hs.spaces")
	local screen = hs.screen.mainScreen()

	spaces.addSpaceToScreen(screen)

	-- helper functions, forwarded here
	local createAndOpenAppSpace, openAppAndMoveWindow
	hs.timer.doAfter(0.25, function()
		gotoSpaceAndOpenApp(app_name, screen)
	end)

	gotoSpaceAndOpenApp = function(____app_name, __screen)
		local new_spaces = spaces.spacesForScreen(__screen)
		local new_space = new_spaces[#new_spaces]

		if new_space then
			spaces.gotoSpace(new_space)

			-- 250ms delay
			hs.timer.doAfter(0.25, function()
				openAppAndMoveWindow(____app_name, new_space)
			end)
		else
			print("Failed to create or identify new space")
		end
	end

	openAppAndMoveWindow = function(__app_name, __new_space)
		hs.application.open(__app_name)

		-- Ensure the app window is on the correct space
		hs.timer.doAfter(0.5, function()
			local app_window = hs.window.focusedWindow()
			if app_window then
				spaces.moveWindowToSpace(app_window, __new_space)
			end
		end)
	end
end

function app_to_space_coroutine_create(app_name)
	local app = hs.application.get(app_name)
	if app and app:isRunning() then
		local win = app:focusedWindow()
		return win and win:focus()
	end

	local spaces = require("hs.spaces")
	local screen = hs.screen.mainScreen()
	local current_space = spaces.activeSpaceOnScreen(screen)

	spaces.addSpaceToScreen(screen)
	local co = coroutine.create(function()
		coroutine.yield(0.25)

		local new_spaces = spaces.spacesForScreen(screen)
		local new_space = new_spaces[#new_spaces]

		if new_space then
			spaces.gotoSpace(new_space)
			coroutine.yield(0.25)

			hs.application.open(app_name)
			coroutine.yield(0.5)

			local new_app = hs.application.get(app_name)
			if new_app then
				local win = new_app:mainWindow()
				if win then
					spaces.moveWindowToSpace(win, new_space)
					spaces.gotoSpace(current_space) -- Return to original space
				end
			end
		else
			print("Failed to create or identify new space")
		end
	end)

	local function resume()
		local success, delay = coroutine.resume(co)
		if success and delay then
			hs.timer.doAfter(delay, resume)
		end
	end

	resume()
end

function app_to_space_coroutine_wrap(app_name)
	local app = hs.application.get(app_name)
	if app and app:isRunning() then
		local win = app:focusedWindow()
		return win and win:focus()
	end

	local spaces = require("hs.spaces")
	local screen = hs.screen.mainScreen()
	local current_space = spaces.activeSpaceOnScreen(screen)

	spaces.addSpaceToScreen(screen)
	local resume = coroutine.wrap(function()
		coroutine.yield(0.25)
		local new_spaces = spaces.spacesForScreen(screen)
		local new_space = new_spaces[#new_spaces]

		if new_space then
			spaces.gotoSpace(new_space)
			coroutine.yield(0.25)
			hs.application.open(app_name)
			coroutine.yield(0.5)
			local new_app = hs.application.get(app_name)
			if new_app then
				local win = new_app:mainWindow()
				-- spaces.gotoSpace(current_space) -- Return to original space; previously below moveWindowToSpace
				if win then
					spaces.moveWindowToSpace(win, new_space)
				end
			end
		else
			print("Failed to create or identify new space")
		end
	end)

	local function execute()
		local delay = resume()
		if delay then
			hs.timer.doAfter(delay, execute)
		end
	end
	execute()
end

-- NOTE: simplest but hs.sleep is blocking, so could be buggy
