local obj = {}
obj.__index = obj

obj._binds = obj._binds or {}

obj.name = "KeystrokeShell"
obj.version = "4.0"

local log = hs.logger.new("KeystrokeShell", "info")

local function escape_quotes(q)
	return q:gsub('"', '\\"'):gsub("'", "'\\''")
end

-- keys
local CAPS = 0x39 -- alternate escape key
local ESC = hs.keycodes.map["escape"]
local RET = hs.keycodes.map["return"]
local DEL = hs.keycodes.map["delete"]
local V = hs.keycodes.map["v"]

local buf, tap, done = "", nil, nil

local DO_AFTER_TIME = 3
local timer = nil

-- useful for one common timer variable
local function timerDoAfter(fn, delay)
	if timer then
		timer:stop()
		timer = nil
	end

	timer = hs.timer.doAfter(delay or DO_AFTER_TIME, fn)
end

local modal = nil
local modalMode = false

local function exit_modal()
	if modal and modalMode then
		modal:exit()
	end
end

local function modal_exited()
	local msg = "exited modal mode"
	hs.alert(msg, 0.2)
	print(msg)

	modalMode = false
	buf = ""
end

local function modal_entered()
	modalMode = true

	local msg = "entered modal mode"
	hs.alert(msg, 0.2)
	print(msg)

	timerDoAfter(exit_modal, 3)
end

local function onDone()
	if timer then
		timer:stop()
		timer = nil
	end

	if tap then
		tap:stop()
		tap = nil
	end

	-- bug also cleared in 'modal_exited' hook logic
	if not modalMode then
		buf = ""
	end

	done = nil

	-- this alert needs better guard against first run of onDone
	hs.alert("startcapture ended", 0.3)
	print("startcapture ended")
end

local function armTimer()
	timerDoAfter(function()
		onDone()
		exit_modal()
	end)
end

local function startCapture(opts, mode)
	hs.alert("startcapture", 0.3)
	print("startcapture")

	modalMode = (mode == "modal") or false

	-- buf = ""
	if not (modalMode and modal) then
		buf = ""
	end

	-- onDone()

	-- note: this HAS to be defined inside startCapture, otherwise 'done=nil' destroys this spoons functionality in future instances
	done = function(ok, text)
		onDone()

		if not ok then
			return
		end
		local cmd = (opts.command_string or function(q, _esc)
			return "echo " .. q
		end)(text, escape_quotes)

		log.f("running: %s", cmd)
		local out, st = hs.execute(cmd .. " 2>&1", true)
		if not st then
			hs.alert("❌ " .. (out or "unknown error"), 2)
		end
	end

	armTimer()

	tap = hs.eventtap
		.new({ hs.eventtap.event.types.keyDown }, function(evt)
			armTimer()

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
				-- nothing typed → use clipboard
				if buf == "" then
					buf = hs.pasteboard.getContents() or ""
				end

				done(true, buf)

				if modalMode and (done == nil) then
					armTimer()
				end

				return true
			-- elseif key == ESC or key == CAPS then
			elseif key == ESC then
				done(nil)
				-- hs.alert("startcapture cancelled", 0.3)
				print("cancelled keystrokeshell")
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

	hs.hotkey.bind(mods, key, function()
		startCapture(opts)
	end)

	return self
end
--
function obj:bindModal(mod, key)
	modal = hs.hotkey.modal.new(mod, key)

	function modal:entered()
		modal_entered()
	end

	function modal:exited()
		modal_exited()
	end

	-- bind every registered letter
	for letter, opts in pairs(self._binds or {}) do
		modal:bind("", letter, function()
			print("letter pressed:", letter)
			startCapture(opts, "modal")
		end)
	end

	modal:bind("", "escape", exit_modal)

	return self
end

return obj
