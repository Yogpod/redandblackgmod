local G=_G
local MENU_DLL=MENU_DLL
local addcs=AddCSLuaFile
local vstruct={}
_G.vstruct=vstruct
local package={
    loaded = {ffi=ffi or {abi=function() return	false end},jit=jit},
    preload = {},
}

-- add all files
local added
local function requireallcs()

    if added then return end
    added=true
    local path = 'vstruct/vstruct/io/'
    for _,fn in next,(file.Find(path..'*.lua','LUA')) do
        AddCSLuaFile(path..fn)
    end
    local path = 'vstruct/vstruct/ast/'
    for _,fn in next,(file.Find(path..'*.lua','LUA')) do
        AddCSLuaFile(path..fn)
    end
    local path = 'vstruct/vstruct/'
    for _,fn in next,(file.Find(path..'*.lua','LUA')) do
        if fn~="test.lua" and fn~="compat1x.lua" then
            AddCSLuaFile(path..fn)
        end
    end
end

-- Minimal file wrapper for gmod files, like cursor.lua
local FILE={

        read=function(fd,len)
            fd=fd[1]
            local pos = fd:Tell()
            local sz = fd:Size()

            if pos>=sz then return nil,"eof" end

            return fd:Read(len)
        end,

        write=function(fd,dat)
            fd=fd[1]
            fd:Write(dat)
            return true
        end,

        close=function(fdd)
            local fd=fdd[1]
            fdd[1] = nil
            fd:Close()
            return true
        end,
        seek=function(fd,whence,pos)
            fd=fd[1]

            whence = whence or "cur"
            offset = offset or 0
            if whence == "set" then
            -- nop
            elseif whence == "cur" then
                pos = pos + fd:Tell()
            elseif whence == "end" then
                pos = pos + fd:Size()
            else
                error "bad argument #1 to seek"
            end
            if pos < 0 then
                return nil,"attempt to seek prior to start of file"
            end

            fd:Seek(pos)

            return fd:Tell()
        end,



        tell = function(fd)
            fd=fd[1]
            return fd:Tell()
        end,
}
local META={__index=FILE}
local function wrapfile(f)
    local t=setmetatable({f},META)
    return t
end
vstruct.wrapfile = wrapfile


local env = setmetatable({vstruct=vstruct,_G=vstruct,package=package},{__index=G})
env.require = function(what)


    if rawget(vstruct,what)~=nil then
        return vstruct[what]
    end

    local M = rawget(package.loaded,what)
    if M~=nil then	return M end

    if rawget(_G,what)~=nil then
        return _G[what]
    end



    local func

    if G.rawget(package.preload,what)~=nil then
        func = package.preload[what]
    else

        local path = "vstruct/"..what:gsub("%.","/")..'.lua'
        if not G.file.Exists(path,MENU_DLL and 'LuaMenu' or 'LUA') then
            path = "vstruct/"..what:gsub("%.","/")..'/init.lua'
        end

        func = G.CompileFile(path,false)

        if not func then G.error("vstruct module '"..G.tostring(what).."' not found") end

        if SERVER and G.vstruct_noaddcslua ~= true then
            addcs(path)
        end

    end



    setfenv(func,env)

    local ret = func(what)
    rawset(vstruct,what,ret)


    return ret

end



setfenv(env.require,env)
if SERVER and G.vstruct_noaddcslua ~= true then
    addcs()
end

setfenv(1,env)

require'vstruct'
G.vstruct=package.loaded.vstruct
G.package.loaded.vstruct=package.loaded.vstruct
G.vstruct.SendToClients = SERVER and function()
    local pf = 'vstruct/vstruct/'
    local fil,fold=file.Find('lua/'..pf.."*.*",'GAME')
    for _,fil in next,fil do
        if fil:find"%.lua$" then
            addcs(pf..fil)
        end
    end
    for _,fold in next,fold do
        if fold~="test" and not fold:find(".",1,true) then
            local fil=file.Find('lua/'..pf..fold..'/'.."*.lua",'GAME')
            for _,fil in next,fil do
                if fil:find"%.lua$" then
                    addcs(pf..fold..'/'..fil)
                end
            end
        end
    end
end

G.vstruct.wrapfile = wrapfile

if SERVER then
    G.vstruct.requireallcs = requireallcs
end

return package.loaded.vstruct
