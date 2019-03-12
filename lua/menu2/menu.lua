local Lime = Color(127, 255, 0, 255)
local Aquamarine = Color(127, 255, 212, 255)
local LightBlue  = Color(72,  209, 204, 255)
local Message = {
	"+-------------------oOo-------------------+",
	"|~ ~ ~ ~ ~ 					  ~ ~ ~ ~ ~|",
	"|~ ~your weird red gui was loaded retard ~|",
	"|~ ~                                   ~ ~|",
	"+-------------------oOo-------------------+",
}
local Modules = {
	"menu2/util.lua",
	"menu2/fuckloadingscreen.lua",
	"menu2/mainmenu.lua",
	"menu2/errors.lua",
	"menu2/luaviewer.lua",
	"menu2/openurl2.lua",
	"menu2/serverquery.lua",
}
local longest = 0
for _, v in pairs(Message) do
	if v:len() > longest then longest = v:len() end
end
MsgN()
for _, line in pairs(Message) do
	for i=1, line:len() do
		local hue = ((i-1) / longest) * 360
		MsgC(HSVToColor(hue, 0.375, 1), line:sub(i, i))
	end
	MsgN()
end
MsgN()
for _, v in pairs(Modules) do
	MsgC(Aquamarine, "Loading the modules ")
	MsgC(Lime, v)
	MsgC(Aquamarine, " ...\n")
	include(v)
end
MsgC(LightBlue, "\nAll modules were loaded!\n\n")

MENU2_LOADED = true
