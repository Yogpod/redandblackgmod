do
    local developer = GetConVar("developer")
    _G.DEVELOPER = developer:GetBool()

    function IsDeveloper(n)
        return developer:GetInt() >= (n or 1)
    end
end

local function lom(path)
    local f = file.Open(path, 'rb', 'LuaMenu')

    if not f then
        ErrorNoHalt("Could not open: " .. path .. '\n')

        return
    end

    local str = f:Read(f:Size())
    f:Close()
    local func = CompileString(str, '@' .. path, false)

    if isstring(func) then
        error(func)
    else
        return func
    end
end

local function lrm(_, _, _, code)
    local func = CompileString(code, "", false)

    if isstring(func) then
        Msg"Invalid syntax> "
        print(func)

        return
    end

    MsgN("> ", code)

    xpcall(func, function(err)
        print(debug.traceback(err))
    end)
end

concommand.Add("lrm", lrm, nil, "Run lua on the menu state.", FCVAR_UNREGISTERED)
concommand.Add("lom", lom, nil, "Honestly no idea", FCVAR_UNREGISTERED)

function gamemenucommand(str)
    RunGameUICommand(str)
end

local function FindInTable(tab, find, parents, depth)
    depth = depth or 0
    parents = parents or ""
    if (not istable(tab)) then return end
    if (depth > 3) then return end
    depth = depth + 1

    for k, v in pairs(tab) do
        if (type(k) == "string") then
            if (k and k:lower():find(find:lower())) then
                Msg("\t", parents, k, " - (", type(v), " - ", v, ")\n")
            end

            if (istable(v) and k ~= "_R" and k ~= "_E" and k ~= "_G" and k ~= "_M" and k ~= "_LOADED" and k ~= "__index") then
                local NewParents = parents .. k .. "."
                FindInTable(v, find, NewParents, depth)
            end
        end
    end
end

local function Find(ply, command, arguments)
    if (IsValid(ply) and ply:IsPlayer() and not ply:IsAdmin()) then return end
    if (not arguments[1]) then return end
    Msg("Finding '", arguments[1], "':\n\n")
    FindInTable(_G, arguments[1])
    FindInTable(debug.getregistry(), arguments[1])
    Msg("\n\n")
end

concommand.Add("lua_find_menu", Find, nil, "", {FCVAR_DONTRECORD})

local iter

iter = function(t, cb)
    for k, v in next, t do
        if istable(v) then
            iter(v, cb)
        else
            cb(v, k)
        end
    end
end

hook.Add("MenuStart", "Menu2", function()
    print"MenuStart"
end)

hook.Add("ConsoleVisible", "Menu2", function(is)
    print(is and '\n<Console Activated>' or '\n<Console Deactivated>')
end)

hook.Add("InGame", "Menu2", function(is)
    print(is and "InGame" or "Out of game")
end)

hook.Add("LoadingStatus", "Menu2", function(status)
    print("LoadingStatus", status)
end)

local isingame = IsInGame()
local wasingame = false
local status = GetLoadStatus()
local console
local alt

hook.Add("Think", "Menu2", function()
    alt = not alt
    if alt then return end
    local is = IsInGame()

    if is ~= isingame then
        isingame = is
        wasingame = wasingame or isingame
        hook.Call("InGame", nil, isingame)
    end

    local s = GetLoadStatus()

    if s ~= status then
        status = s
        hook.Call("LoadingStatus", nil, status)
    end

    local s = gui.IsConsoleVisible()

    if s ~= console then
        console = s
        hook.Call("ConsoleVisible", nil, console)
    end
end)

function WasInGame()
    return wasingame
end

local games = engine.GetGames()
local addons = engine.GetAddons()

hook.Add("GameContentChanged", "Menu2", function()
    local games_new = engine.GetGames()
    local _ = games
    games = games_new
    local games = _
    local addons_new = engine.GetAddons()
    local _ = addons
    addons = addons_new
    local addons = _
    local wasmount = false
    local wasaddon = false

    for k, new in next, games_new do
        local old = games[k]
        assert(old.depot == new.depot)

        if old.mounted ~= new.mounted then
            print("MOUNT", new.title, new.mounted and "MOUNTED" or "UNMOUNTED")
            wasmount = true
        end
    end

    for k, new in next, addons_new do
        local old

        for k, v in next, addons do
            if v.file == new.file then
                old = v
                break
            end
        end

        if not old then
            print("ADDON LOADED:", new.mounted and "(M)" or "  ", new.title)
            wasaddon = true
            continue
        end

        assert(old.depot == new.depot)

        if old.mounted ~= new.mounted then
            print("MOUNT", new.title, "\t", new.mounted and "MOUNTED" or "UNMOUNTED")
            wasaddon = true
        end
    end

    for k, old in next, addons do
        local new

        for k, v in next, addons_new do
            if v.file == old.file then
                new = v
                break
            end
        end

        if not new then
            MsgN("Removed ", old.title)
            nothing = false
            continue
        end
    end

    if IsDeveloper(2) then
        print("MENU: Unhandled GameContentChanged")
    end

    hook.Call("GameContentsChanged", nil, wasmount, wasaddon)
end)

SelectGamemode = function(g)
    RunConsoleCommand("gamemode", g)
end

function SetMounted(game, yesno)
    engine.SetMounted(game.depot, yesno == nil or yesno)
end

function SearchWorkshop(str)
    str = string.JavascriptSafe(str)
    str = "http://steamcommunity.com/workshop/browse?searchtext=" .. str .. "&childpublishedfileid=0&section=items&appid=4000&browsesort=trend&requiredtags[]=-1"
    gui.OpenURL(str)
end

if outdated then
    R"showconsole"()
end

concommand.Add("whereis", function(_, _, _, path)
    local absolutePath = util.RelativePathToFull_Menu(path, "GAME")

    if (not absolutePath or not file.Exists(path, "GAME")) then
        MsgN"File not found."

        return
    end

    local relativePath = util.FullPathToRelative_Menu(absolutePath, "MOD")

    -- If the relative path is inside the workshop dir, it's part of a workshop addon
    if (relativePath and relativePath:match("^workshop[\\/].*")) then
        local addonInfo = util.RelativePathToGMA_Menu(path)

        -- Not here? Maybe somebody just put their own file in ./workshop
        if (addonInfo) then
            local addonRelativePath = util.RelativePathToFull_Menu(addonInfo.File)
            MsgN("'", addonInfo.Title, "' - ", addonRelativePath)

            return
        end
    end

    MsgN(absolutePath)
end, nil, "Searches for the highest priority instance of a file within the GAME mount path.")

local function ValidateIP(ip)
    if ip then
        local chunks = {ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+):*")}

        if (#chunks == 4) then
            for _, v in pairs(chunks) do
                if tonumber(v) > 255 then return false end
            end

            return true
        end
    end
end

function rejoinlast()
    ip = file.Read("lastserver.txt", "DATA")

    if not ValidateIP(ip) then
        MsgN("No previous server.")

        return
    end

    JoinServer(ip)
end

concommand.Add("rejoinlast", rejoinlast)
OriginalJoinServer = JoinServer

function JoinServer(ip)
    file.Write("lastserver.txt", ip)
    OriginalJoinServer(ip)
end