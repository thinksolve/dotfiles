local obj = {}
obj.__index = obj

obj._binds = obj._binds or {} --useful to collect all bind key and opts into a table

obj.name = "KeystrokeShell"
obj.version = "3.alpha"

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

local m = nil --modal
local modalMode = false

local timer = nil
local aborted = false

local function doneTimer(ok)
	print("doneTimer called")
	-- hs.alert("doneTimer called")

	local function doAfterCallback()
		print("doneTimer doAfter called")

		-- cleanup current timer
		if timer then
			timer:stop()
			timer = nil
		end

		if m and modalMode then
			-- if modalMode and m then
			m:exit()
		end

		if tap then
			tap:stop()
			tap = nil
		end

		buf = ""
	end

	if ok then
		-- if true then
		if timer then
			timer:stop()
			timer = nil
		end
		timer = hs.timer.doAfter(DO_AFTER_TIME or 2, doAfterCallback)
	else
		doAfterCallback()
	end

	-- if timer then
	-- 	timer:stop()
	-- 	timer = nil
	-- end
	-- timer = hs.timer.doAfter(DO_AFTER_TIME or 2, doAfterCallback)
end

done = function(ok, text)
	doneTimer(ok)

	if not ok then
		return
	end

	local cmd = (text and onDone) and onDone(text, escape_quotes) or ("echo " .. escape_quotes(text or ""))

	log.f("running: %s", cmd)
	local out, st = hs.execute(cmd .. " 2>&1", true)
	if not st then
		hs.alert("❌ " .. (out or "unknown error"), 2)
	end
end

local function startCapture(opts, isModal)
	modalMode = (isModal == "modal") or false

	-- hs.alert.show("isModal: ", tostring(isModal))

	onDone = opts.command_string or function(q)
		return "echo " .. q
	end

	buf = ""

	-- resetTimeout()
	doneTimer()

	tap = hs.eventtap
		.new({ hs.eventtap.event.types.keyDown }, function(evt)
			-- WIP: this jank guard until i figure out how to separate modal from non-modal modes better
			-- if modalMode then
			-- 	resetModalTimer()
			-- else
			-- 	resetTimeout()
			-- end
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
			-- elseif key == ESC or key == CAPS then
			elseif key == ESC then
				done(nil)
				if modalMode and m then
					m:exit()
				end
				hs.alert("cancelled", 0.8)
				return true
			elseif key == DEL then
				buf = #buf > 0 and buf:sub(1, -2) or ""
				return true
			end

			doneTimer(true)
			print("tap after if-else block reached")

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
			startCapture(opts, "modal")
		end)
	end

	m:bind("", "escape", function()
		hs.alert("cancelado")
		m:exit()
	end)

	return self
end

return obj
