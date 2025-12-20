local obj = {}
obj.__index = obj

obj.name = "KeystrokeShell"
obj.version = "1.0"

local log = hs.logger.new("KeystrokeShell", "info")

-- current capture state
local buf, tap, done = "", nil, nil

------------------------------------------------------------
-- internal key handler
-- local function handler(evt)
-- 	local key = evt:getKeyCode()
-- 	local mods = evt:getFlags()
--
-- 	if key == hs.keycodes.map["return"] and mods:containExactly({}) then
-- 		tap:stop()
-- 		tap = nil
-- 		done(true, buf) -- submit
-- 		return true
-- 	elseif key == hs.keycodes.map["escape"] then
-- 		tap:stop()
-- 		tap = nil
-- 		done(false) -- cancelled
-- 		hs.alert.show(" cancelled", 0.8)
-- 		return true
-- 	elseif key == hs.keycodes.map["delete"] then
-- 		buf = #buf > 0 and buf:sub(1, -2) or ""
-- 		return true
-- 	elseif evt:isAKeyPress() and not next(mods) then
-- 		buf = buf .. evt:getCharacters()
-- 		return true
-- 	end
-- 	return false
-- end

local function handler(evt)
	local key = evt:getKeyCode()
	local mods = evt:getFlags()

	-- if next(mods) then  --- short syntax to check if any mods was pressed
	if mods.alt or mods.ctrl or mods.shift or (mods.cmd and key ~= hs.keycodes.map["v"]) then
		return true
	end

	if mods.cmd and key == hs.keycodes.map["v"] then -- ⌘V
		local clip = hs.pasteboard.getContents() or ""
		buf = buf .. clip
		return true
	elseif key == hs.keycodes.map["return"] then
		tap:stop()
		tap = nil
		done(true, buf)
		return true
	elseif key == hs.keycodes.map["escape"] then
		tap:stop()
		tap = nil
		done(nil)
		hs.alert.show(" cancelled", 0.8)
		return true
	elseif key == hs.keycodes.map["delete"] then
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
end

------------------------------------------------------------
-- public: bind a hot-key
function obj:bind(mods, key, opts)
	opts = opts or {}
	local builder = opts.command_string or function(q)
		return "echo " .. q -- safest no-op default
	end
	-- hs.hotkey.bind(mods, key, function()
	-- 	buf = ""
	-- 	done = function(ok, text)
	-- 		if ok then
	-- 			local cmd = builder(hs.http.encodeForQuery(text))
	-- 			log.f("running: %s", cmd)
	-- 			hs.execute(cmd, true)
	-- 		end
	-- 	end
	-- 	tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, handler):start()
	-- end)
	hs.hotkey.bind(mods, key, function()
		print("HOT-KEY FIRED") -- should appear in console immediately
		buf = ""
		done = function(ok, text)
			if ok then
				local cmd = builder(hs.http.encodeForQuery(text))
				print("CMD:", cmd) -- you already have this
				-- local ok2, err = hs.execute(cmd, true)
				-- if not ok2 then
				-- 	print("EXEC FAIL:", err)
				-- end
				local ok2, err, code = hs.execute(cmd .. " 2>&1", true) -- redirect stderr → stdout
				print("exec ret:", ok2, "output:", err, "code:", code)
			end
		end
		tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, handler):start()
	end)
	return self
end

return obj
