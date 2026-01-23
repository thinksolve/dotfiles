-- local function notify(msg: string)
--	hs.notify.new({ title = "Teal Test", informativeText = msg }):send()
-- end

-- notify("Teal is alive in Hammerspoon!")

-- print("Notification sent")

local type HelloOpts1 = { x: string }
-- local type HelloOpts2 = record x: string  end


local function hello(opts: HelloOpts1): string 
	return  opts.x or 'yo' 
end

hello({ x ="string" })
-- hello({ x =22 })






