local obj = {}
obj.__index = obj

obj._binds = obj._binds or {} --useful to collect all bind key and opts into a table

obj.name = "KeystrokeShell"
obj.version = "2.0"

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
-- current capture state
local buf, tap, done, modal = "", nil, nil, nil
local cancel_tap = function()
	if tap then
		tap:stop()
		tap = nil
	end
end

local timeoutTimer = nil
local cancel_timeout = function()
	if timeoutTimer then
		timeoutTimer:stop()
		timeoutTimer = nil
	end
end

-- shared helpers

-- tier-1: stop only the timer
function cancelTimeout()
	if timeoutTimer then
		timeoutTimer:stop()
		timeoutTimer = nil
	end
end

-- tier-2: stop everything (timer + tap + modal)
function cancelAll()
	cancelTimeout() -- this made into its own function because used directly in resetTimeout

	if tap then
		tap:stop()
		tap = nil
	end

	if modal then
		modal:exit()
		modal = nil
	end

	if obj.modal then
		obj.modal:exit()
		obj.modal = nil
	end
	buf, done = "", nil
end

function resetTimeout()
	cancelTimeout()
	timeoutTimer = hs.timer.doAfter(4, function()
		hs.alert("cancelled", 0.8)
		cancelAll()
	end)
end

function startCapture(opts)
	buf = ""
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
	-- identical eventtap you already had
	tap = hs.eventtap
		.new({ hs.eventtap.event.types.keyDown }, function(evt)
			resetTimeout()

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

	-- NOTE: need to supply a properly processed command string. i.e. escaped, quoted,
	-- hs.http.encodeForQuery(raw_string)), whatever else contextually
	local builder = opts.command_string or function(q)
		return "echo " .. q -- safest no-op default
	end
	hs.hotkey.bind(mods, key, function()
		buf = ""
		done = function(ok, text)
			-- irrespective of 'ok', when done is called cancel tap and timeout
			cancel_tap()
			cancel_timeout()

			if not ok then
				return false
			end

			local cmd = builder(text, escape_quotes) --NOTE: works but maybe needs better type definition for builder
			log.f("running: %s", cmd)

			local output, status, _type, _rc = hs.execute(cmd .. " 2>&1", true)
			if not status then
				hs.alert("❌ " .. (output or "unknown error"), 2)
			end
		end

		_resetTimeout = function(_TIMEOUT)
			cancel_timeout()

			timeoutTimer = hs.timer.doAfter(_TIMEOUT or 4, function()
				done(nil)
				hs.alert("cancelled", 0.8)
			end)
		end

		_resetTimeout()
		tap = hs.eventtap
			.new({ hs.eventtap.event.types.keyDown }, function(evt)
				_resetTimeout()

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
	end)

	return self
end

-- function obj:startModal(mod, key)
-- 	-- create and enter the modal exactly like the demo
-- 	local m = hs.hotkey.modal.new(mod, key)
-- 	function m:entered()
-- 		hs.alert("Entered mode")
-- 	end
-- 	function m:exited()
-- 		hs.alert("Exited mode")
-- 	end
--
-- 	-- bind every registered letter
-- 	for letter, opts in pairs(self._binds or {}) do
-- 		m:bind("", letter, function()
-- 			-- toying with this (WIP
-- 			-- hs.timer.doAfter(3.5, function()
-- 			-- 	m:exit()
-- 			-- end)
-- 			--
-- 			print("letter pressed:", letter)
-- 			startCapture(opts)
-- 		end)
-- 	end
--
-- 	m:bind("", "escape", function()
-- 		m:exit()
-- 	end)
-- 	self.modal = m --need this?
-- 	return self
-- end
--

function obj:startModal(mod, key)
	obj.modal = hs.hotkey.modal.new(mod, key) -- no ‘local m’
	function obj.modal:entered()
		hs.alert("Entered mode")
	end
	function obj.modal:exited()
		hs.alert("Exited mode")
	end

	for letter, opts in pairs(self._binds or {}) do
		obj.modal:bind("", letter, function()
			print("letter pressed:", letter)
			startCapture(opts)
		end)
	end

	obj.modal:bind("", "escape", function()
		obj.modal:exit()
	end)
	return self
end

return obj
