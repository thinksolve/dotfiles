local obj = {}
obj.__index = obj

obj._binds = obj._binds or {} --useful to collect all bind key and opts into a table

obj.name = "KeystrokeShell"
obj.version = "3.0"

local log = hs.logger.new("KeystrokeShell", "info")

local function escape_quotes(q)
	return q:gsub('"', '\\"'):gsub("'", "'\\''")
end

local DO_AFTER_TIME = 2

-- keys
local CAPS = 0x39 -- alternate escape key
local ESC = hs.keycodes.map["escape"]
local RET = hs.keycodes.map["return"]
local DEL = hs.keycodes.map["delete"]
local V = hs.keycodes.map["v"]

local buf, tap, done = "", nil, nil

local timeoutTimer, modalTimer = nil, nil
local m = nil --modal
local modalMode = false

local function cancelTimeout()
	if timeoutTimer then
		timeoutTimer:stop()
		timeoutTimer = nil
	end
end

local function cancelModalTimeout()
	if modalTimer then
		modalTimer:stop()
		modalTimer = nil
	end
end

local function resetModalTimer()
	cancelModalTimeout()
	modalTimer = hs.timer.doAfter(DO_AFTER_TIME or 2, function()
		-- hs.alert("cancel model", 0.8)
		print("modalTimer doAfter")
		if m then
			m:exit()
		end
	end)
end

local function cancelAll()
	cancelTimeout()
	-- cancelModalTimeout()

	-- cancel tap
	if tap then
		tap:stop()
		tap = nil
	end

	-- NOTE: dont uncomment this .. it cancels modalMode before delays ..
	-- if modalMode and m then
	-- 	m:exit()
	-- 	-- m = nil -- i think nilling this is really problematic
	-- end

	buf = ""
	done = nil
end

local function resetTimeout()
	cancelTimeout()
	timeoutTimer = hs.timer.doAfter(DO_AFTER_TIME or 2, function()
		print("timeoutTimer doAfter")

		hs.alert("cancelled regular mode", 0.5)

		cancelAll()
	end)
end

local function startCapture(opts, isModal)
	modalMode = isModal or false

	-- hs.alert.show(tostring(modalMode))
	-- hs.alert.show("isModal: ", tostring(isModal))

	buf = ""

	-- note: this HAS to be defined inside startCapture, otherwise 'done=nil' destroys this spoons functionality in future instances
	done = function(ok, text)
		cancelAll()
		if not ok then
			return
		end
		local cmd = (opts.command_string or function(q)
			return "echo " .. q
		end)(text, escape_quotes)

		log.f("running: %s", cmd)
		local out, st = hs.execute(cmd .. " 2>&1", true)
		if not st then
			hs.alert("❌ " .. (out or "unknown error"), 2)
		end
	end

	resetTimeout()
	-- if modalMode then
	-- 	resetModalTimer()
	-- else
	-- 	resetTimeout()
	-- end

	-- identical eventtap you already had
	tap = hs.eventtap
		.new({ hs.eventtap.event.types.keyDown }, function(evt)
			-- WIP: this jank guard until i figure out how to separate modal from non-modal modes better
			if modalMode then
				resetModalTimer()
			else
				resetTimeout()
			end

			local key = evt:getKeyCode()
			local mods = evt:getFlags()

			-- if next(mods) then  --- short syntax to check if any mods was pressed
			if mods.alt or mods.ctrl or mods.shift or (mods.cmd and key ~= V) then
				return true
			end

			if mods.cmd and key == V then -- ⌘V
				local clip = hs.pasteboard.getContents() or ""
				buf = buf .. clip
				return true
			elseif key == RET then
				-- nothing typed → use clipboard (better than  ⌘V logic above!
				if buf == "" then
					buf = hs.pasteboard.getContents() or ""
				end

				done(true, buf)
				return true
			elseif key == ESC or key == CAPS then
				done(nil)
				hs.alert("cancelled", 0.8)
				return true
			elseif key == DEL then
				buf = #buf > 0 and buf:sub(1, -2) or ""
				return true
			end

			-- ordinary printable key
			local chars = evt:getCharacters()
			if chars and #chars > 0 then -- printable key
				buf = buf .. chars
				return true
			end

			return false
		end)
		:start()
end

------------------------------------------------------------
-- public: bind a hot-key
function obj:bind(mods, key, opts)
	opts = opts or {}

	self._binds[key] = opts -- remember key → opts

	-- local builder = opts.command_string or function(q)
	-- 	return "echo " .. q -- safest no-op default
	-- end
	hs.hotkey.bind(mods, key, function()
		startCapture(opts)
	end)

	return self
end
--
function obj:startModal(mod, key)
	-- create and enter the modal exactly like the demo
	m = hs.hotkey.modal.new(mod, key)

	function m:entered()
		hs.alert("entered modal mode", 0.5)
	end
	function m:exited()
		hs.alert("exited modal mode", 0.5)
	end

	-- bind every registered letter
	for letter, opts in pairs(self._binds or {}) do
		m:bind("", letter, function()
			print("letter pressed:", letter)
			startCapture(opts, true)
		end)
	end

	m:bind("", "escape", function()
		m:exit()
	end)

	return self
end

return obj
