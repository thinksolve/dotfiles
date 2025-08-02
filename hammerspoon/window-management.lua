-- local screen_position_mod = { "option" }
--
-- hs.hotkey.bind(screen_position_mod, "Left", function()
-- 	LeftHalf()
-- end)
-- hs.hotkey.bind(screen_position_mod, "Right", function()
-- 	-- RightHalf()
-- 	RightHalfTest()
-- end)
-- hs.hotkey.bind(screen_position_mod, "Up", function()
-- 	TopHalf()
-- end)
-- hs.hotkey.bind(screen_position_mod, "Down", function()
-- 	BottomHalf()
-- end)
--
-- hs.hotkey.bind(screen_position_mod, "Return", function()
-- 	FullScreen()
-- end)
--
-- -- NOTE: may remove these ...
-- hs.hotkey.bind({ "option" }, ",", function()
-- 	cycleWindows("left")
-- end)
-- hs.hotkey.bind({ "option", "shift" }, ",", function()
-- 	cycleWindows("right")
-- end)

-- function dict_copy_hs_no_underscore_keys(t)
--
-- 	local t2 = {}
-- 	for k, v in pairs(t) do
-- 		-- for some reason underscore keys are retrieved, so have to remove underscores
-- 		t2[k:gsub("^_", "")] = v
-- 		print("Copying: " .. k .. "=" .. tostring(v))
-- 	end
-- 	return t2
-- end
-- function GetWinScreenData_()
-- 	local win = hs.window.focusedWindow()
-- 	local sf = win:screen():frame()
--
-- 	-- -- A:  f and sf are the same! Not copied, but share reference
-- 	-- local f = sf
-- 	-- local f = hs.geometry(sf)
--
-- 	-- -- B: f copied; not reference to sf
-- 	local f = dict_copy_hs_no_underscore_keys(sf) -- most elegant solution but requires custom function
-- 	-- local f = hs.geometry.rect(sf.x, sf.y, sf.w, sf.h)
-- 	-- local f = { x = sf.x, y = sf.y, w = sf.w, h = sf.h }
--
-- 	return win, sf, f
-- end
--

function GetWinScreenData()
	-- local win = hs.window.focusedWindow()
	-- local sf = win:screen():frame()
	-- return win, sf, hs.geometry.copy(sf)

	local win = hs.window.focusedWindow()
	local screen = win:screen()
	return win, screen:frame(), screen:frame()
end

function GetWinScreenData_old()
	local win = hs.window.focusedWindow()
	local win_frame = win:frame()
	local screen = win:screen()
	local screen_frame = screen:frame()

	return win, win_frame, screen_frame
end

function FullScreen()
	-- local win, wf, sf = GetWinScreenData_old()
	-- wf.x = sf.x
	-- wf.y = sf.y
	-- wf.w = sf.w
	-- wf.h = sf.h
	-- win:setFrame(wf)

	local win, f, _ = GetWinScreenData()
	win:setFrame(f)
end

function LeftHalf()
	-- local win, wf, sf = GetWinScreenData_old()
	-- wf.x = sf.x
	-- wf.y = sf.y
	-- wf.w = sf.w / 2
	-- wf.h = sf.h/2
	-- win:setFrame(wf)

	local win, f, sf = GetWinScreenData()
	f.w = sf.w / 2
	win:setFrame(f)
end

function RightHalf()
	-- local win, wf, sf = GetWinScreenData_old()
	-- wf.x = sf.x + (sf.w / 2)
	-- wf.y = sf.y
	-- wf.w = sf.w / 2
	-- wf.h = sf.h
	-- win:setFrame(wf)

	local win, f, sf = GetWinScreenData()
	local dx = sf.w / 2
	f.x = sf.x + sf.w - dx
	f.w = dx

	win:setFrame(f)
end

function TopHalf()
	-- local win, wf, sf = GetWinScreenData_old()
	-- wf.x = sf.x
	-- wf.y = sf.y
	-- wf.w = sf.w
	-- wf.h = sf.h / 2
	-- win:setFrame(wf)
	local win, f, sf = GetWinScreenData()
	f.h = sf.h / 2
	win:setFrame(f)
end

function BottomHalf()
	-- local win, wf, sf = GetWinScreenData_old()
	-- wf.h = sf.h / 2
	-- wf.y = sf.y + (sf.h / 2)
	-- wf.x = sf.x
	-- wf.w = sf.w
	-- win:setFrame(wf)

	local win, f, sf = GetWinScreenData()
	local dy = sf.h / 2
	f.h = dy
	f.y = sf.y + sf.h - dy
	win:setFrame(f)
end

function RightHalfTest()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()

	-- Get all windows on this screen
	local allWindows = hs.window.filter.new():setScreens(screen:id()):getWindows()

	local leftEdge = max.x -- Default to screen’s left edge
	local maxRight = max.x + max.w -- Screen’s right edge
	local hasOverlap = false -- Track if there’s a window to adjust to

	-- Find the rightmost edge of any window to the left
	for _, otherWin in pairs(allWindows) do
		if otherWin:id() ~= win:id() then -- Skip the focused window
			local otherFrame = otherWin:frame()
			local otherRight = otherFrame.x + otherFrame.w
			if otherRight > leftEdge and otherRight < maxRight then
				leftEdge = otherRight
				hasOverlap = true -- Found a window to align with
			end
		end
	end

	-- Set the frame: fill remaining space if overlap, else right half
	if hasOverlap then
		f.x = leftEdge
		f.w = maxRight - leftEdge
	else
		f.x = max.x + (max.w / 2) -- Right half start
		f.w = max.w / 2 -- Half width
	end
	f.y = max.y
	f.h = max.h
	win:setFrame(f)
end

-- placing the currentWindows
local currentWindows = {}
local currentIndex = 1

function update_windows()
	local wf = hs.window.filter.new():setCurrentSpace(true)

	-- old way but i wanted to instead collect by app, not by all windows
	-- currentWindows = wf:getWindows()

	-- Collect one window per application
	local appWindows = {}
	local seenApps = {}
	for _, win in ipairs(wf:getWindows()) do
		local appId = win:application():bundleID() or "unknown"
		if not seenApps[appId] then
			seenApps[appId] = true
			table.insert(appWindows, win)
		end
	end
	currentWindows = appWindows

	-- Sort by x-coordinate, then y-coordinate, then window ID for stability
	table.sort(currentWindows, function(a, b)
		-- -- Comprehensive filter but not needed
		-- local ax, ay = a:frame().x, a:frame().y
		-- local bx, by = b:frame().x, b:frame().y
		-- local a_id, b_id = a:id() or 0, b:id() or 0
		-- return ax < bx or (ax == bx and (ay < by or (ay == by and a_id < b_id)))

		return a:frame().x < b:frame().x or (a:id() < b:id())
		-- return a:frame().x < b:frame().x  ---- bug whenever there were ties
	end)

	-- Debug: Show window count and titles (handle nil/empty titles)
	-- local titles = ""
	-- for i, win in ipairs(currentWindows) do
	-- 	titles = titles .. i .. ": " .. (win:title() or "[No Title]") .. " (ID: " .. (win:id() or "nil") .. ")\n"
	-- end
	-- hs.alert.show("Windows: " .. #currentWindows .. "\n" .. titles)
end

function cycleWindows(direction)
	direction = direction or "right" -- Default to cycling right

	update_windows()

	if #currentWindows <= 1 then
		return
	end

	-- currentIndex = 1

	local focused = hs.window.focusedWindow()
	for i, win in ipairs(currentWindows) do
		if win:id() == focused:id() then
			currentIndex = i
			break
		end
	end

	if direction == "left" then
		currentIndex = (currentIndex - 2) % #currentWindows + 1 -- Move left, wrap
	else
		currentIndex = currentIndex % #currentWindows + 1 -- Move right, wrap
	end

	currentWindows[currentIndex]:focus()
end

function goto_app(app)
	return hs.application.launchOrFocus(app)

	-- return app_to_space_using_sleep(app)
end

function toggle_app(app_name)
	local app = hs.appfinder.appFromName(app_name)

	-- alt, for more flexibility
	if app then
		local frontmost = app:isFrontmost()
		if frontmost then
			app:hide()
		else
			app:activate()
		end
	else
		hs.application.launchOrFocus(app_name)
	end
end

function toggle_app_bundle_id(bundleID)
	local app = hs.application.get(bundleID)
	if app and app:isFrontmost() then
		app:hide()
	else
		hs.application.launchOrFocusByBundleID(bundleID) -- Launch if not running
	end
end

-- more robost to use bundle id when app is closed/open
function toggle_open_close_by_bundle_id(bundleID)
	local app = hs.application.get(bundleID)
	if app then
		app:kill9()
		-- used previously when had incorrect bundle id .. no longer needed
		-- hs.osascript.applescript(string.format([[ tell application "%s" to quit ]], app:name()))
	else
		hs.application.launchOrFocusByBundleID(bundleID) -- Launch if not running
	end
end

local window_management = {
	LeftHalf = LeftHalf,
	RightHalf = RightHalf,
	TopHalf = TopHalf,
	BottomHalf = BottomHalf,
	FullScreen = FullScreen,
	cycleWindows = cycleWindows,
	goto_app = goto_app,
	toggle_app = toggle_app,
	toggle_open_close_by_bundle_id = toggle_open_close_by_bundle_id,
	toggle_app_bundle_id = toggle_app_bundle_id,
}

return window_management
