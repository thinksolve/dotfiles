------ TYPES SECTION
---@alias SetTimer fun(fn: function, delay: number?):nil
---@alias StopTimer fun():nil
---@alias Tap hs.eventtap|nil
---@alias Modal hs.hotkey.modal
---@alias StopCapture fun(opt?: {hide_icon: boolean}): nil
---@alias EscapeQuotes fun(q:string):string?
---@alias CommandString  fun(q:string, esc?:EscapeQuotes):string
---@alias OptsStartCapture {command_string: CommandString}
---

---@alias Done (fun(ok?:true, text?:string):nil)|nil

---`ok == true`  → success, use `text`
---`ok == nil` → abort/cancelled (equivalent to supplying no arguments)
---@alias OnDone (fun(ok?:true, text?:string, command_str?:CommandString):nil)
---

--- TESTING
-- ---@class StrictOpts
-- ---@field ok true | 'abort'
-- ---@field text? string
--
-- ---@type fun(opts:StrictOpts):nil
-- local function done(opts) end
--
-- done({ ok = true, text = "string" })
-- done({ ok = "abort" })
--- TESTING

------ TYPES SECTION

local obj = {}
obj.__index = obj

obj._binds = obj._binds or {}

obj.name = "KeystrokeShell"
obj.version = "9.0.alpha"

local log = hs.logger.new("KeystrokeShell", "info")

-- keys
local CAPS = 0x39 -- alternate escape key
local ESC = hs.keycodes.map["escape"]
local RET = hs.keycodes.map["return"]
local DEL = hs.keycodes.map["delete"]
local V = hs.keycodes.map["v"]
local SPACE = hs.keycodes.map["space"]

-- Useful for debugging
local function alert(msg, duration)
	-- hs.alert(msg, duration or 2)
	print(msg)
end

-- Useful for toggling custom spoon .. might move to hs/init.lua
local function createMenuIcon(opt)
	opt = opt or {}

	local size = opt.size or 20 --in px
	local fallback_rel_path = "/.hammerspoon/" .. ({ "keyboard-xxl.png", "hs-icon.png", "small-mic.png" })[1]

	local path = os.getenv("HOME") .. (opt.home_rel_path or fallback_rel_path)

	---@type hs.menubar|nil
	local mbar = nil

	local function hideIcon() -- call on exit
		if mbar then
			mbar:delete()
			mbar = nil
		end
	end

	local function showIcon()
		hideIcon() --cleanup is crucial, otherwise many icons will linger

		---@type hs.menubar|nil
		mbar = hs.menubar.new()

		---@type hs.image|nil
		local icon = hs.image.imageFromPath(path)

		if mbar and icon then
			mbar:setIcon(icon:setSize({ w = size, h = size }), false) -- false allows any color icon to display
		end
	end
	return showIcon, hideIcon
end

local showIcon, hideIcon = createMenuIcon()

-- Useful for handling/disposing of 'doAfter' timers; in this spoon just need a single timer instance
local DO_AFTER_TIME = 3

---@type SetTimer, StopTimer
local setTimer, stopTimer = nil, nil

local function createTimer()
	local timer = nil

	---@type StopTimer
	local function _stopTimer()
		-- local _stopTimer = function()
		if timer then
			timer:stop()
			timer = nil
		end
	end

	---@type SetTimer
	local _setTimer = function(fn, delay)
		_stopTimer()

		timer = hs.timer.doAfter(delay or DO_AFTER_TIME or 2, fn)
	end

	return _setTimer, _stopTimer
end

setTimer, stopTimer = createTimer()

local buf = ""

---@type Tap
local tap = nil

---@type Modal
local modal
local modalMode = false

---@type Done
local done = nil

-- When startCapture runs buf is the text input formed from keyboard 'tap's

---@type StopCapture
local function stopCapture(opt)
	stopTimer()

	buf = ""

	if tap then
		tap:stop()
		tap = nil
	end

	if (opt and opt.hide_icon) or not modalMode then
		hideIcon()
	end
end

local function exit_modal()
	if modal and modalMode then
		modal:exit()
	end
end

local function modal_exited()
	alert("exited modal mode", 0.2)

	-- stopCapture({ hide_icon = true })
	modalMode = false
	stopCapture()
end

local function modal_entered()
	alert("entered modal mode", 0.2)

	modalMode = true
	showIcon()
	setTimer(exit_modal, 4)
end

---@type OnDone
local onDone

onDone = function(ok, text, command_str)
	ok = ok or nil
	text = text or ""

	command_str = command_str
		or function(q, _esc)
			alert("❌ supply command_string in ~/.hammerspoon/init.lua", 5)
			return "echo " .. q
		end

	stopCapture()

	-- NOTE: trying to place this in stopCapture caused infinite recursion previously since
	-- stopCapture was called in modal:exit. I.e. exit_modal (via stopCapture) called in modal_exit ... which
	-- would call exit_modal (via stopCapture) ...
	if modalMode and (ok == nil or done == nil) then
		exit_modal()
	end

	--WIP: calling onDone without parameters effectively aborts modal mode
	-- ... desirable after idle timeout
	--  'modalMode and ok' here translates to the (modal mode) RET branch below
	if modalMode and ok then
		setTimer(onDone)
	end

	-- run command logic
	if ok and text then
		---@type EscapeQuotes
		local function escape_quotes(q)
			local qq = q:gsub('"', '\\"'):gsub("'", "'\\''")
			return qq
		end

		local cmd = command_str(text, escape_quotes)

		log.f("running: %s", cmd)
		local out, st = hs.execute(cmd .. " 2>&1", true)
		if not st then
			hs.alert("❌ " .. (out or "unknown error"), 2)
		end
	end
end

---@param opts OptsStartCapture
local function startCapture(opts)
	alert("startcapture", 0.3)

	stopCapture()

	showIcon()

	setTimer(onDone)

	-- note: this HAS to be defined inside startCapture, otherwise 'done=nil' destroys this spoons functionality in future instances
	done = function(ok, text)
		onDone(ok, text, opts.command_string)

		done = nil
	end

	tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(evt)
		setTimer(onDone) --resets timer on each keypress

		local key = evt:getKeyCode()
		local mods = evt:getFlags()

		local ACCEPT = key == RET
		local ABORT = key == ESC or (mods.alt and (key == SPACE))

		if ABORT then
			done(nil)

			alert("ESC keystrokeshell", 0.3)
			return true
		elseif ACCEPT then
			-- nothing typed → use clipboard
			if buf == "" then
				buf = hs.pasteboard.getContents() or ""
			end

			done(true, buf)

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

	tap:start()
end

---NOTE: wip
function create_capture()
	local _buf, _tap, _done = "", nil, nil

	---@type StopCapture
	local function stop_capture(opt)
		-- stopTimer()

		_buf = ""

		if _tap then
			_tap:stop()
			_tap = nil
		end

		if (opt and opt.hide_icon) or not modalMode then
			hideIcon()
		end
	end

	local function start_capture(opts)
		alert("start_capture", 0.3)

		stop_capture()

		showIcon()

		setTimer(onDone)

		-- note: this HAS to be defined inside startCapture, otherwise 'done=nil' destroys this spoons functionality in future instances
		_done = function(ok, text)
			onDone(ok, text, opts.command_string)

			_done = nil -- makes more sense here than in onDone
		end

		_tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(evt)
			setTimer(onDone) --resets timer on each keypress

			local key = evt:getKeyCode()
			local mods = evt:getFlags()

			local ACCEPT = key == RET
			local ABORT = key == ESC or (mods.alt and (key == SPACE))

			if ABORT then
				_done(nil)

				alert("_ESC keystrokeshell", 0.3)
				return true
			elseif ACCEPT then
				-- nothing typed → use clipboard
				if _buf == "" then
					_buf = hs.pasteboard.getContents() or ""
				end

				_done(true, _buf)

				return true
			end

			if mods.cmd and key == V then -- ⌘V
				local clip = hs.pasteboard.getContents() or ""
				_buf = _buf .. clip
				return true
			elseif key == DEL then
				_buf = #_buf > 0 and _buf:sub(1, -2) or ""
				return true
			end

			-- ordinary printable key
			local chars = evt:getCharacters()
			if chars and #chars > 0 then -- printable key
				_buf = _buf .. chars
				return true
			end

			return false
		end)

		_tap:start()
	end

	return start_capture, stop_capture
end

---NOTE: wip

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

--NOTE: rec guards are very useful for debugging recursion in hooks
-- e.g., f called in modal:exited() hook, but f contains modal:exit()
-- lifecycle function ... this would cause infinite recursion
-- NOTE2: this works for `re-entrance` i.e. same stack recursive calls (RCs)
-- like:
--    `f() if true then f() end end`
-- not `re-scheduling` i.e. cross-stack RCs like:
--    `f() doAfter(3,f) end`

local function create_recursion_guard()
	local in_hook = false
	return function(fn, fn_name)
		if in_hook then
			log.e(string.format("⚠️  Recursion prevented in %s - check your logic!", fn_name or "hook"))
			return
		end

		in_hook = true
		fn()
		in_hook = false
	end
end

local function create_limiter_per_fn(max_calls)
	local count = 0

	return function(fn, name)
		name = name or "anonymous"

		count = count + 1
		if count > max_calls then
			log.e(string.format("⚠️ %s exceeded %d calls, resetting", name, max_calls))
			count = 0
			return
		end

		fn()
		count = 0
	end
end

function obj:bindModal(mod, key)
	modal = hs.hotkey.modal.new(mod, key)

	-- local modal_exited_guard = create_recursion_guard()
	-- local modal_entered_guard = create_recursion_guard()
	--

	local limit_exited = create_limiter_per_fn(1)
	local limit_entered = create_limiter_per_fn(1)

	function modal:exited()
		-- modal_exited_guard(modal_exited, "modal_exited")
		limit_exited(modal_exited, "modal_exited")
	end

	function modal:entered()
		-- modal_entered_guard(modal_entered, "modal_entered")

		limit_entered(modal_entered, "modal_entered")
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
