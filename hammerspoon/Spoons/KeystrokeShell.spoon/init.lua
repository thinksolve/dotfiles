local obj = {}
obj.__index = obj

obj._binds = obj._binds or {}

obj.name = "KeystrokeShell"
obj.version = "6.0"

local log = hs.logger.new("KeystrokeShell", "info")

local function alert(msg, duration)
	hs.alert(msg, duration or 0.6)
	print(msg)
end

local function createMenuIcon(opt)
	opt = opt or {}

	local size = opt.size or 20 --in px
	local fallback_rel_path = "/.hammerspoon/" .. ({ "keyboard-xxl.png", "hs-icon.png", "small-mic.png" })[1]

	local path = os.getenv("HOME") .. (opt.home_rel_path or fallback_rel_path)

	local mbar = nil

	local function hideIcon() -- call on exit
		if mbar then
			mbar:delete()
			mbar = nil
		end
	end

	local function showIcon()
		hideIcon() --cleanup is crucial, otherwise many icons will linger
		mbar = hs.menubar.new()

		local icon = hs.image.imageFromPath(path):setSize({ w = size, h = size })

		mbar:setIcon(icon, false) -- false allows any color icon to display
	end
	return showIcon, hideIcon
end

local showIcon, hideIcon = createMenuIcon()

local function escape_quotes(q)
	return q:gsub('"', '\\"'):gsub("'", "'\\''")
end

-- keys
local CAPS = 0x39 -- alternate escape key
local ESC = hs.keycodes.map["escape"]
local RET = hs.keycodes.map["return"]
local DEL = hs.keycodes.map["delete"]
local V = hs.keycodes.map["v"]
local SPACE = hs.keycodes.map["space"]

local buf, tap, done = "", nil, nil

local function stopCapture()
	if tap then
		tap:stop()
		tap = nil
	end

	buf = ""
end

local DO_AFTER_TIME = 3

-----@return fun(fn: function, delay: number?):nil, fun():nil
local function createTimer()
	local timer = nil

	---@type fun():nil
	local _stopTimer = function()
		if timer then
			timer:stop()
			timer = nil
		end
	end

	---@type fun(fn: function, delay: number?):nil
	local _setTimer = function(fn, delay)
		_stopTimer()
		-- hs.alert("may fire many times 1")

		timer = hs.timer.doAfter(delay or DO_AFTER_TIME or 2, function()
			fn()
			-- hs.alert("may fire many times 2")
		end)
	end

	return _setTimer, _stopTimer
end

local setTimer, stopTimer = createTimer()

local modal = nil
local modalMode = false

local function exit_modal()
	if modal and modalMode then
		modal:exit()
	end
end

local function modal_exited()
	alert("exited modal mode", 0.2)

	modalMode = false
	hideIcon()
	stopCapture()
end

local function modal_entered()
	alert("entered modal mode", 0.2)

	modalMode = true
	showIcon()
	setTimer(exit_modal, 3)
end

local function onDone(ok)
	-- stopTimer()

	stopCapture()

	if not modalMode then
		hideIcon()
	elseif modalMode and (done == nil or ok == nil) then
		exit_modal() -- this also hide's icon
	end

	done = nil
end

local function startCapture(opts)
	alert("startcapture", 0.3)

	stopCapture()
	showIcon()

	-- note: this HAS to be defined inside startCapture, otherwise 'done=nil' destroys this spoons functionality in future instances
	done = function(ok, text)
		onDone(ok)

		if ok then
			local cmd = (opts.command_string or function(q, _esc)
				return "echo " .. q
			end)(text, escape_quotes)

			log.f("running: %s", cmd)
			local out, st = hs.execute(cmd .. " 2>&1", true)
			if not st then
				hs.alert("❌ " .. (out or "unknown error"), 2)
			end
		end
	end

	setTimer(onDone)

	tap = hs.eventtap
		.new({ hs.eventtap.event.types.keyDown }, function(evt)
			setTimer(onDone)

			local key = evt:getKeyCode()
			local mods = evt:getFlags()

			-- NOTE: placing terminal keys upfront before any filtering
			if key == ESC or (mods.alt and (key == SPACE)) then -- could do `modalMode to second case .. but nah
				done(nil)
				alert("ESC keystrokeshell", 0.3)
				return true
			elseif key == RET then
				-- nothing typed → use clipboard
				if buf == "" then
					buf = hs.pasteboard.getContents() or ""
				end

				done(true, buf)

				if modalMode and (done == nil) then
					setTimer(onDone)
				end

				return true
			end

			-- NOTE: not sure i need this
			-- if mods.alt or mods.ctrl or mods.shift or (mods.cmd and key ~= V) then
			-- 	return true
			-- end

			if mods.cmd and key == V then -- ⌘V
				local clip = hs.pasteboard.getContents() or ""
				buf = buf .. clip
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
			startCapture(opts)
			-- NOTE: idea pass letter in startCapture like startCapture(opts, letter, "modal") so can handle double tap like 'gg
			-- abnd defined the following either module level or startCapture level?:
			-- local lastLetter = nil
			-- local lastLetterTime = 0
			-- local DOUBLE_TAP_THRESHOLD = 1.0
		end)
	end

	modal:bind("", "escape", exit_modal)
	modal:bind(mod, key, exit_modal) -- easier

	return self
end

return obj
