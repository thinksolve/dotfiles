











local function hello(opts)
   return opts.x or 'yo'
end

hello({ x = "string" })
