-- WIP KeystrokeShell-spoon.lua ---------------------------------------------------
local obj = {}
obj.__index = obj
obj._binds = {} -- letter → opts
obj.name = "KeystrokeShell"
obj.version = "4.0"

local log = hs.logger.new("KeystrokeShell", "info")
----------------------------------------------------------------------------- helpers

-- keys
local CAPS = 0x39 -- alternate escape key
local ESC = hs.keycodes.map["escape"]
local RET = hs.keycodes.map["return"]
local DEL = hs.keycodes.map["delete"]
local V = hs.keycodes.map["v"]

local DO_AFTER_TIME = 2

local function esc(q)
	return q:gsub('"', '\\"'):gsub("'", "'\\''")
end
----------------------------------------------------------------------------- state
local buf, onDone -- captured text and callback
local tap, timer -- single tap + single timer
local modal -- persistent modal object (nil until startModal; never nil otherwise)
local inModal = false -- flag so we know how to clean up
local finish -- forward declare terminal function defined below

----------------------------------------------------------------------------- timers / cleanup
local function killTimer()
	if timer then
		timer:stop()
		timer = nil
	end
end

local function armTimer()
	killTimer()
	timer = hs.timer.doAfter(DO_AFTER_TIME, function()
		finish(false, "timed out")
	end)
end

local function finish(ok, text)
	-- single exit point
	if tap then
		tap:stop()
		tap = nil
	end
	killTimer()

	if inModal and modal then
		modal:exit()
	end
	inModal = false

	buf, onDone = "", nil

	if not ok then
		hs.alert("cancelled", 0.8)
		return
	end

	-- local cmd = (text and onDone) and onDone(text, esc) or "echo " .. esc(text or "")

	local cmd = (text and onDone) and onDone(text, esc) or ("echo " .. esc(text or ""))
	log.f("running: %s", cmd)
	local out, st = hs.execute(cmd .. " 2>&1", true)
	if not st then
		hs.alert("❌ " .. (out or "unknown error"), 2)
	end
end
----------------------------------------------------------------------------- capture
local function startCapture(opts, isModal)
	-- public entry point used by both hot-key and modal
	inModal = isModal or false
	buf = ""
	onDone = opts.command_string or function(q)
		return "echo " .. q
	end

	hs.alert.show(inModal and "modal capture" or "hotkey capture")

	armTimer() -- start (or restart) the single timer

	if tap then
		tap:stop()
	end
	tap = hs.eventtap
		.new({ hs.eventtap.event.types.keyDown }, function(evt)
			armTimer() -- any key restarts the same timer

			local key = evt:getKeyCode()
			local mods = evt:getFlags()

			-- ignore if real modifier held (except ⌘V)
			if mods.alt or mods.ctrl or mods.shift or (mods.cmd and key ~= V) then
				return true
			end

			if mods.cmd and key == V then -- ⌘V paste
				buf = buf .. (hs.pasteboard.getContents() or "")
				return true
			end

			if key == RET then
				if buf == "" then
					buf = hs.pasteboard.getContents() or ""
				end
				finish(true, buf)
				return true
			end

			if key == ESC or key == CAPS then
				finish(false)
				return true
			end

			if key == DEL then
				buf = buf:sub(1, -2)
				return true
			end

			local chars = evt:getCharacters()
			if chars and #chars > 0 then
				buf = buf .. chars
				return true
			end

			return false
		end)
		:start()
end
----------------------------------------------------------------------------- public API
function obj:bind(mods, key, opts)
	opts = opts or {}
	self._binds[key] = opts
	hs.hotkey.bind(mods, key, function()
		startCapture(opts, false)
	end)
	return self
end

function obj:startModal(mod, key)
	modal = hs.hotkey.modal.new(mod, key)

	function modal:entered()
		hs.alert("entered modal mode", 0.5)
	end
	function modal:exited()
		hs.alert("exited modal mode", 0.5)
	end

	for letter, opts in pairs(self._binds or {}) do
		modal:bind("", letter, function()
			startCapture(opts, true)
		end)
	end
	modal:bind("", "escape", function()
		modal:exit()
	end)
	return self
end

return obj
