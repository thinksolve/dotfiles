-- lib/termGuard.lua  (or anywhere above your bindings)
local M = {}

-- default terminal list; caller can override
M.defaultIDs = {
	["com.mitchellh.ghostty"] = true,
	["com.googlecode.iterm2"] = true,
	["com.apple.Terminal"] = true,
}

-- enable/disable *one* hotkey object
M.toggle = function(hk, bundleSet)
	bundleSet = bundleSet or M.defaultIDs
	local app = hs.application.frontmostApplication()
	if app and bundleSet[app:bundleID()] then
		hk:disable()
	else
		hk:enable()
	end
end

-- wire up the watcher for a list of hotkeys
M.watch = function(hotkeys, bundleSet)
	bundleSet = bundleSet or M.defaultIDs
	local function check()
		for _, hk in ipairs(hotkeys) do
			M.toggle(hk, bundleSet)
		end
	end
	hs.application.watcher.new(check):start()
	check() -- initial state
end

return M
