local obj = {}
obj.__index = obj

obj._binds = obj._binds or {}

obj.name = "KeystrokeShell"
obj.version = "6.alpha"

local log = hs.logger.new("KeystrokeShell", "info")

local function alert(msg, duration)
	hs.alert(msg, duration or 0.6)
	print(msg)
end

local function createMenuIcon(home_rel_path)
	home_rel_path = home_rel_path or "/.hammerspoon/keyboard-xxl.png"
	-- or "/.hammerspoon/hs-icon.png"
	-- or "/.hammerspoon/small-mic.png"
	local path_from_home = os.getenv("HOME") .. home_rel_path
	local icon_dims = 20 --in px

	local mb = nil

	local function hideIcon() -- call on exit
		if mb then
			mb:delete()
			mb = nil
		end
	end

	local function showIcon()
		hideIcon() --cleanup is crucial, otherwise many icons will linger
		mb = hs.menubar.new()

		local icon = hs.image.imageFromPath(path_from_home):setSize({ w = icon_dims, h = icon_dims })

		mb:setIcon(icon, false) -- false allows any color icon to display
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
		timer = hs.timer.doAfter(delay or DO_AFTER_TIME or 2, fn)
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
	hideIcon()

	alert("exited modal mode", 0.2)

	modalMode = false
	buf = ""
end

local function modal_entered()
	showIcon()

	modalMode = true

	alert("entered modal mode", 0.2)

	setTimer(exit_modal, 3)
end

local function onDone(cb)
	-- if timer then
	-- 	timer:stop()
	-- 	timer = nil
	-- end

	-- stopTimer()

	-- previously wrapped this in delay-less setTimer without 'done==nil'; this is better
	if modalMode and done == nil then
		exit_modal()
	else
		hideIcon()
	end

	if tap then
		tap:stop()
		tap = nil
	end

	-- if not modalMode then
	-- 	buf = ""
	-- end

	buf = ""
	done = nil
	if cb then
		cb()
	end
end

-- local function armTimer()
-- 	setTimer(onDone)
--
-- 	-- hs.alert("timer armed")
-- 	--
-- 	-- setTimer(function()
-- 	-- 	onDone()
-- 	-- 	hs.alert("timer done")
-- 	-- end)
-- end

local function startCapture(opts, mode)
	alert("startcapture", 0.3)

	modalMode = (mode == "modal") or false

	-- if not (modalMode and modal) then
	-- 	buf = ""
	-- end

	buf = ""
	showIcon()

	-- note: this HAS to be defined inside startCapture, otherwise 'done=nil' destroys this spoons functionality in future instances
	done = function(ok, text)
		onDone()

		if ok then
			local cmd = (opts.command_string or function(q, _esc)
				return "echo " .. q
			end)(text, escape_quotes)

			log.f("running: %s", cmd)
			local out, st = hs.execute(cmd .. " 2>&1", true)
			if not st then
				hs.alert("❌ " .. (out or "unknown error"), 2)
			end
		else
			exit_modal()
			return
		end
	end

	setTimer(onDone)

	tap = hs.eventtap
		.new({ hs.eventtap.event.types.keyDown }, function(evt)
			setTimer(onDone)

			local key = evt:getKeyCode()
			local mods = evt:getFlags()

			-- if next(mods) then  --- short syntax to check if any mods was pressed

			-- NOTE: placing terminal keys upfront before any filtering
			if key == ESC or (modalMode and mods.alt and (key == SPACE)) then
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
					-- setTimer(exit_modal)
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
			startCapture(opts, "modal")
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
