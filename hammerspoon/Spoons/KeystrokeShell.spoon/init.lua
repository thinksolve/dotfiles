local obj = {}
obj.__index = obj

obj.name = "KeystrokeShell"
obj.version = "1.0"

local log = hs.logger.new("KeystrokeShell", "info")

-- keys
local CAPS = 0x39 -- alternate escape key
local ESC = hs.keycodes.map["escape"]
local RET = hs.keycodes.map["return"]
local DEL = hs.keycodes.map["delete"]
local V = hs.keycodes.map["v"]

-- current capture state
local buf, tap, done = "", nil, nil

local timeoutTimer = nil

------------------------------------------------------------
-- public: bind a hot-key
function obj:bind(mods, key, opts)
	opts = opts or {}

	-- NOTE: need to supply a properly processed command string. i.e. escaped, quoted,
	-- hs.http.encodeForQuery(raw_string)), whatever else contextually
	local builder = opts.command_string or function(q)
		return "echo " .. q -- safest no-op default
	end
	hs.hotkey.bind(mods, key, function()
		buf = ""
		done = function(ok, text)
			if not ok then
				return false
			end

			local cmd = builder(text)
			log.f("running: %s", cmd)

			local output, status, _type, _rc = hs.execute(cmd .. " 2>&1", true)
			if not status then
				hs.alert("❌ " .. (output or "unknown error"), 5)
			end
		end

		-- local timeoutTimer = nil -- NOTE: should this be here or top level of module .. does it matter?
		resetTimeout = function(_TIMEOUT)
			if timeoutTimer then
				timeoutTimer:stop()
			end
			timeoutTimer = hs.timer.doAfter(_TIMEOUT or 5, function()
				tap:stop()
				tap = nil
				done(nil)
				hs.alert.show("cancelled", 0.8)
			end)
		end

		resetTimeout()
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
					tap:stop()
					tap = nil
					done(true, buf)
					return true
				elseif key == ESC or key == CAPS then
					tap:stop()
					tap = nil
					done(nil)
					hs.alert.show("cancelled", 0.8)
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

return obj
