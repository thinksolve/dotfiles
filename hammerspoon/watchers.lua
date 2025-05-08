hs.alert.show("watchers.lua loaded!")

local M = {} -- Module table to hold watchers

local function reload_hs_if_a_file_changed(paths)
	for _, path in pairs(paths) do
		if path:match("%.lua$") then
			hs.reload()
			return
		end
	end
end

local function do_screen_sleep_wake(event)
	if event == hs.caffeinate.watcher.screensDidSleep then
		hs.wifi.setPower(false) -- Wi-Fi off
		hs.audiodevice.defaultOutputDevice():setMuted(true) -- Mute audio
		hs.execute("/run/current-system/sw/bin/blueutil --power 0") -- Bluetooth off
	elseif event == hs.caffeinate.watcher.systemDidWake then
		hs.wifi.setPower(true) -- Wi-Fi on
	end
end

-- Pathwatcher for Lua file changes; hs.configdir gives root dir for hs config
M.pathwatcher = hs.pathwatcher.new(hs.configdir, reload_hs_if_a_file_changed)

-- Caffeinate watcher for system sleep/wake
M.caff_watcher = hs.caffeinate.watcher.new(do_screen_sleep_wake)

M.pathwatcher:start()
M.caff_watcher:start()
return M
-- -- General watcher function to handle watchers separately
-- function Watcher()
-- 	local obj = {}
--
-- 	setmetatable(obj, {
-- 		__index = function(self, eventName)
-- 			local eventType = hs.caffeinate.watcher[eventName]
-- 			if not eventType then
-- 				error("Invalid event name: " .. eventName)
-- 			end
-- 			return function(callback)
-- 				local w = hs.caffeinate.watcher.new(function(event)
-- 					if event == eventType then
-- 						callback()
-- 					end
-- 				end)
-- 				w:start()
-- 				return w
-- 			end
-- 		end,
-- 	})
--
-- 	return obj
-- end
--
-- -- Screen sleep actions
-- Watcher().screensDidSleep(function()
-- 	hs.execute("/run/current-system/sw/bin/blueutil --power 0")
-- 	hs.execute("osascript -e 'set volume with output muted'")
-- 	hs.execute("networksetup -setairportpower en0 off")
-- end)
--

-- Watcher().systemDidWake(function()
-- 	hs.execute("networksetup -setairportpower en0 on")
-- end)
--
