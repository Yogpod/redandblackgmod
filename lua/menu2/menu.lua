local Lime = Color(127, 255, 0, 255)
local Aquamarine = Color(127, 255, 212, 255)
local LightBlue  = Color(72,  209, 204, 255)
local Message = {
    "+-------------------oOo-------------------+",
    "|~ ~ ~ ~ ~                       ~ ~ ~ ~ ~|",
    "|~ ~   RNB Gmod Modification Loaded      ~|",
    "|~ ~                                   ~ ~|",
    "+-------------------oOo-------------------+",
}
local Modules = {
    "menu2/util.lua",
    "menu2/fuckloadingscreen.lua",
    "menu2/mainmenu.lua",
    "menu2/errors.lua",
    "menu2/openurl2.lua",
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


local version = "12"
http.Fetch( "https://pastebin.com/raw/KXGqugUc",
    function( body )
        versionr = body
        if versionr == version then
            MsgC(LightBlue,"Your menu version is up to date!\n")
        end
        if versionr > version then
            outdated = true
            for i = 1, 100 do
                MsgC(LightBlue,"Version Outdated, please go to https://github.com/Yogpod/redandblackgmod to update\n")
            end
        end
    end)

MENU2_LOADED = true
MsgC(LightBlue, "\nChecked for updates and all modules were loaded!\n")
