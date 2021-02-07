--setfenv(1,_G)
local NATIVE = MENU_DLL == nil and SERVER == nil and CLIENT == nil
local coroutine = coroutine or require'coroutine'
local meta = {}
local co = setmetatable({}, meta)
local s, look = {}, {}
co.stack = s

local function push(thread)
    local n = #s + 1
    s[n] = thread
    look[thread] = n

    return n
end

local function pop()
    local n = #s
    local thread = s[n]
    look[thread] = nil
    s[n] = nil

    return thread, n
end

local function peek()
    local n = #s

    return s[n], n
end

local function has(thread)
    return look[thread]
end

if not NATIVE then
    _G.co = co
end

co._SimpleTimer = not NATIVE and timer.Simple or function()
    error"Please implement co._SimpleTimer"
end

-- todo
--	error handler wrapper?
--	select() polling support (epoll() please :c)
--	co.make steal parameters
--	?
local waitticks = {}
local SLEEP, CO_RET, SLEEP_TICK, CO_END, CALLBACK, CALL_OUTSIDE, CALL_OUTSIDE_NORET, ENDED, RETURN_RESULT, _ = {}, {}, {}, {}, {}, {}, {}, {}, {}, {} -- Unique identifiers

local extra_state = setmetatable({}, {
    __mode = 'k'
})

local function check_coroutine(thread)
    if thread == nil then
        thread = coroutine.running()
    end

    local curco = peek()

    if curco ~= thread then
        error("Not inside co-style coroutine", 2)
    end

    if not thread then
        error("Can not call outside coroutine", 2)
    end
end

local function in_co(thread)
    if thread == nil then
        thread = coroutine.running()
    end

    local curco = peek()

    return curco == thread and thread
end

co.running = in_co

local function __re(thread, ok, t, val, ...)
    pop()

    if not ok then
        ErrorNoHalt("[CO] " .. debug.traceback(thread, tostring(t)) .. '\n')

        return
    end

    if t == SLEEP then
        --Msg"[CO] Sleep "print(val)
        co._SimpleTimer(val, function()
            co._re(thread, SLEEP)
        end)

        return
    elseif t == SLEEP_TICK then
        table.insert(waitticks, thread)
    elseif t == CALLBACK then
    elseif t == CALL_OUTSIDE then
        -- wait for callback
        --elseif t==CB_ONE then -- wait for any one callback
        co._re(thread, CALL_OUTSIDE, val(...))
    elseif t == CALL_OUTSIDE_NORET then
        co._re(thread, CALL_OUTSIDE_NORET)
        val(...)
    elseif t == CO_END then
        --Msg"[CO] END "print("OK")
        extra_state[thread] = ENDED
    elseif t == CO_RET then
        -- return some stuff to the callback, continue coroutine
        --[[local discard,... = ]]
        co._re(thread, CO_RET)

        return val, ...
    else
        ErrorNoHalt("[CO] Unhandled " .. tostring(t) .. '\n')
    end
end

co._re = function(thread, ...)
    local status = coroutine.status(thread)

    if status == "running" then
        -- uhoh?
    elseif status == "dead" then
        -- we can do nothing
        return
    elseif status == "suspended" then
    else -- all ok
        error"Unknown coroutine status!?"
    end

    -- do we need this
    if extra_state[thread] == ENDED then return end
    push(thread)

    return __re(thread, coroutine.resume(thread, ...))
end

local function Think()
    local count = #waitticks

    for i = count, 1, -1 do
        local thread = table.remove(waitticks, i)
        co._re(thread, SLEEP_TICK)
    end
end

co._Think = Think

if not NATIVE then
    hook.Add(MENU_DLL and "Think" or "Tick", "colib", co._Think)
end

function meta:__call(func, ...)
    assert(type(func) == 'function', "invalid parameter supplied")

    local thread = coroutine.create(function(...)
        func(...)

        return CO_END
    end)

    return thread, co._re(thread, ...)
end

function co.wrap(func, ...)
    assert(type(func) == 'function', "invalid parameter supplied")

    local thread = coroutine.create(function(...)
        func(...)

        return CO_END
    end)

    return function(...) return co._re(thread, ...) end
end

--- make a thread out of this function
--- If we are already in a thread, reuse it. It has to be a co thread though!
function co.make(...)
    local thread = in_co()
    if thread then return false, thread end
    local func = debug.getinfo(2).func

    return true, co(func, ...)
end

local function wrap(ok, a, ...)
    if ok then return ... end
end

--[[ -- TODO
function co.cox(...)
	local t={...}
	local tc =#t
	local func = t[tc-1]
	local err = t[tc]
	t[tc]=nil
	t[tc-1]=nil

	assert(isfunction(func),"invalid parameter supplied")

	local thread = coroutine.create(function(unpack(t))
		xpcall(func,err,...)
	end)
	co._re(thread,...)

	return thread
end
--]]
function co.wait(delay)
    check_coroutine()
    local ret = coroutine.yield(SLEEP, tonumber(delay) or 0)

    if ret ~= SLEEP then
        error("Invalid return value from yield: " .. tostring(ret))
    end
    --Msg"[CO] End wait "print(ret)
end

function co.waittick()
    check_coroutine()
    local ret = coroutine.yield(SLEEP_TICK)

    if ret ~= SLEEP_TICK then
        error("Invalid return value from yield: " .. tostring(ret))
    end
    --Msg"[CO] End wait "print(ret)
end

co.sleep = co.wait

local function wrap(ret, ...)
    if ret ~= CALL_OUTSIDE then
        error("Invalid return value from yield: " .. tostring(ret))
    end

    return ...
end

function co.extern(func, ...)
    check_coroutine()

    return wrap(coroutine.yield(CALL_OUTSIDE, func, ...))
end

function co.expcall(...)
    return co.extern(xpcall, ...)
end

local function wrap(ret, ...)
    if ret ~= CALL_OUTSIDE_NORET then
        error("Invalid return value from yield: " .. tostring(ret))
    end

    assert(not (...), "noreturn returned?")

    return ...
end

function co.extern_noret(func, ...)
    check_coroutine()

    return wrap(coroutine.yield(CALL_OUTSIDE_NORET, func, ...))
end

function co.expcall_noret(...)
    return co.extern_noret(xpcall, ...)
end

-- LEGACY
function co.newcb2(res)
    local thread = peek()
    check_coroutine(thread)
    --TODO: infinite return value support?
    local called, _1, _2, _3, _4, _5, _6, _7
    local CB

    CB = function(a, ...)
        if a == RETURN_RESULT then return called, _1, _2, _3, _4, _5, _6, _7 end

        if in_co(thread) then
            called, _1, _2, _3, _4, _5, _6, _7 = true, ...

            return res
        end

        return co._re(thread, CALLBACK, CB, a, ...)
    end

    return CB
end

function co.newcb()
    local thread = peek()
    check_coroutine(thread)
    --Msg"[CO] Created cb for thread "print(thread)
    local CB
    CB = function(...) return co._re(thread, CALLBACK, CB, ...) end --Msg("[CO] Callback called for thread ",thread)print("OK")

    return CB
end

function co.extern_waitcb(func)
    local cb = co.newcb()
    co.extern_noret(func, cb)

    return co.waitcb(cb)
end

function co.extern_waitone(func, ...)
    co.extern_noret(func, ...)

    return co.waitone()
end

function co.ret(...)
    local ret = coroutine.yield(CO_RET, ...)

    if ret ~= CO_RET then
        error("Invalid return value from yield: " .. tostring(ret))
    end
end

local function _waitonewrap(caller, ...)
    return ...
end

function co.waitcb(cb)
    if cb == nil then return _waitonewrap(co.waitone()) end
    check_coroutine()

    local function wrap(ret, caller, ...)
        if ret ~= CALLBACK then
            error("Invalid return value from yield: " .. tostring(ret))
        end

        if caller ~= cb then
            error("Wrong callback returned")
        end

        return ...
    end

    return wrap(coroutine.yield(CALLBACK))
end

local function removeone(_, ...)
    return ...
end

function co.waitcb2(cb)
    check_coroutine()
    if (cb(RETURN_RESULT)) then return removeone(cb(RETURN_RESULT)) end

    local function wrap(ret, caller, ...)
        if ret ~= CALLBACK then
            error("Invalid return value from yield: " .. tostring(ret))
        end

        if caller ~= cb then
            error("Wrong callback returned")
        end

        return ...
    end

    return wrap(coroutine.yield(CALLBACK))
end

--same as above but returns the CB too
local function wrap(ret, caller, ...)
    if ret ~= CALLBACK then
        error("Invalid return value from yield: " .. tostring(ret))
    end

    return caller, ...
end

function co.waitone()
    check_coroutine()

    return wrap(coroutine.yield(CALLBACK))
end

local function error_propagator(ok, err, ...)
    if not ok then
        error(err)
    end

    return err, ...
end

function co.worker(worker, ...)
    local queue = {}
    local started
    local task

    local function work()
        while queue[1] do
            task = queue[1]
            table.remove(queue, 1)
            started = false --failsafe?
            task[1](true, worker(unpack(task, 2)))
            started = true
            task = nil
        end
    end

    local function thread()
        started = true
        co.waittick() -- detach thread to preserve order
        local ok, err

        while not ok do
            ok, err = xpcall(work, debug.traceback)

            if not ok and err then
                if task then
                    task[1](false, err)
                else
                    ErrorNoHalt('[Worker] ' .. err .. '\n')
                end
            end
        end

        started = false
    end

    local function resume()
        if started then return end
        started = true
        co(thread)
    end

    local function add_task(...)
        local cb = co.newcb()

        queue[#queue + 1] = {cb, ...}

        resume()

        return error_propagator(co.waitcb(cb))
    end

    return add_task, queue, ...
end

function co.work_cacher_filter(filter, worker, cache, ...)
    local function check_cache(key, ret1, ...)
        local cached = cache[key]

        if cached then
            local keep = filter(key, ret1, ...)

            if not keep then
                cache[key] = nil
            end
        end

        return ret1, ...
    end

    local function filter_processor(key, ...)
        return check_cache(key, worker(key, ...))
    end

    return filter_processor, cache, ...
end

local WEAK = {
    __index = 'v'
}

function co.work_cacher(worker, weak)
    local cache = weak and setmetatable({}, WEAK) or {}

    local function cache_this(key, ...)
        cache[key] = {...}

        return ...
    end

    local function cacher(key, ...)
        local cached = cache[key]
        if cached then return unpack(cached) end

        return cache_this(key, worker(key, ...))
    end

    return cacher, cache
end

if NATIVE then return co, co._Think end
-- testing --
--[[ -- Instantly returning callback handling
local function evil(cb)
	print("returned",cb("hello"))
end
local function good(cb)
	print("Good timer startin")
	timer.Simple(0.1,function()
		evil(cb)
	end)
end


local isevil  = true

co(function()
	local cb = co.newcb()
	local r = co.running()

	local good = isevil and evil or good

	local ret = co.extern_waitcb(function(cb)
		good(cb)
	end)

	co.ret("return value to callback")

	print("runcb returned",ret)
	print"end coro"
end)

--]]
--[[

co.wrap(function()

	local w = co.extern(function(...) return ... end,"extern")

	assert(w=="extern")

	local ct = os.clock()
	co.waittick()
	assert(ct~=os.clock())


	local ct = os.clock()
	co.sleep(0.2)
	assert(ct~=os.clock())

	local ok,dat,a,b,c,d = co.fetch("http://iriz.uk.to/404")

	assert(isstring(dat))

end)()

--]]
--