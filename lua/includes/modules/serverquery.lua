--Dont touch, unfinished


local NATIVE = MENU_DLL ==nil and SERVER==nil and CLIENT==nil


local ErrorNoHalt=ErrorNoHalt
if MENU_DLL then ErrorNoHalt=function(...)
	MsgN(...)
end end

local vstruct = require 'vstruct' or vstruct
local co = require 'co' or co
local socket = NATIVE and require"socket" or require 'luasocket' or luasocket or socket

local Now = socket.gettime
local todata = string.char
local fromdata = string.byte

local A2S_INFO = '\xff\xff\xff\xff\x54Source Engine Query\0'

local function dbg(...)
	--Msg"[SI] " print(...)
end
module ('serverquery',package.seeall)

--thinkers=rawget(_M,'thinkers') or {}
--function Thinker(func)
--	thinkers[func]=true
--end
--function Think()
--	for func,_ in next,thinkers do
--		local ok,err = xpcall(func,debug.traceback)
--		if not ok or err==true then
--			thinkers[func]=nil
--		end
--		if not ok and err then
--			ErrorNoHalt("ServerQuery: "..err..'\n')
--		end
--	end
--end
--hook.Add("Think",'serverquery',Think)


function payload_masterquery(region, lastipport, filter)
	local payload = '\x31' .. todata(region or 0xFF) .. lastipport .. '\0' .. filter .. '\0'
	return payload
end



local masterservers = {{ "208.64.200.39", 27011 }, { "208.64.200.52", 27011 }, { "208.64.200.65", 27015 } }

if not NATIVE then
	math.randomseed( os.time() )
end

local function shuffleTable( t )
	local rand = math.random
	local iterations = #t
	local j

	for i = iterations, 2, -1 do
		j = rand(i)
		t[i], t[j] = t[j], t[i]
	end
end

shuffleTable(masterservers)


local function query_master(master_retries_remaining,cb,filter,region,host,port,nomore)
	local udp = assert(socket.udp())
	assert(udp:settimeout(0))
	assert(udp:setpeername(host, port))

	local timeout = Now() + 3.4567

	local query_ipport = "0.0.0.0:0"
	local queried_ipport
	local finished
	local should_retry
	while true do -- get a reply from master server


		-- if no reply for this long, bail out
		if Now()>timeout then
			dbg("server ",host,port," did not reply.",should_retry and "retrying" or "abort")
			if should_retry then
				query_ipport = queried_ipport
				queried_ipport = nil
				should_retry = false
			else
				break
			end
		end

		-- should we send a packet?
		if query_ipport then
			timeout = Now() + 6

			queried_ipport = query_ipport
			query_ipport = nil
			udp:send(payload_masterquery(region,queried_ipport,filter))
		end

		local dat,err = udp:receive()
		if dat==nil then
			if err == 'timeout' then
				co.waittick()
				goto cont -- goto tryagain
			else
				error(tostring(err))
			end
		else
			assert(dat:sub(1,6)=='\xFF\xFF\xFF\xFF\x66\x0A',"invalid server reply: "..tostring(dat))
			queried_ipport = nil

			should_retry = true -- we got something, retry next request

			-- strip common reply
			dat = dat:sub(7,-1)
		end

		-- parse server list
		for offset=0, 6*8192, 6 do
			local ip1,ip2,ip3,ip4,port1,port2=string.byte(dat,offset+1,offset+6)
			if port2==nil then
				assert(ip1==nil,"invalid packet size!?")
				break
			end
			local port = port1*256 + port2
			local ip = ip1..'.'..ip2..'.'..ip3..'.'..ip4
			local ipport= ip..':'..port
			if port==0 and port==ip1 and ip1==ip2 then
				-- finished
				cb(true)
				return true
			else
				-- next packet for next loop
				query_ipport = ipport
				local ret = cb(true,ip,port,ipport)
				if ret then return true end
			end
		end

		if not query_ipport then
			cb(nil,"master server timeout",host,port)
			return true
		end

		::cont::

	end
end

function getServerList(cb, filter, region)
	if co.make(cb, filter, region) then return end

	local idx = 0
	local function GetMasterServer()
		idx = idx + 1
		local srv = masterservers[idx]
		if srv == nil then
			idx = 1
			srv = masterservers[1]
		end

		return srv[1], srv[2], masterservers[idx + 1] == nil
	end

	for master_retries_remaining = 1,20 do
		local ok,ret = xpcall( query_master,debug.traceback,master_retries_remaining,cb,filter,region,GetMasterServer())
		if not ok then
			cb(nil,ret)
			ErrorNoHalt("[ServerQuery] "..tostring(ret)..'\n')
			return
		end
		if ret then return end
	end
	ErrorNoHalt("[ServerQuery] loop fart?\n")

end

------------------------------------------------






local function rebuild_format(fmt)
	local vstruct_format={}
	for k,v in next,fmt do vstruct_format[k]=v[1] end
	vstruct_format=table.concat(vstruct_format, " " )
	return vstruct_format
end


local A2S_INFO_FORMAT
A2S_INFO_FORMAT={
	{ "s4" , "hdr1" },
	{ "s1" , "hdr2"},
	{ "u1" , "proto"},
	{ "z"  , "name"},
	{ "z"  , "map"},
	{ "z"  , "dir"},
	{ "z"  , "desc"},
	{ "i2" , "appid"},
	{ "u1" , "players"},
	{ "u1" , "maxplayers"},
	{ "u1" , "bots"},
	{ "s1" , "dedicated"},
	{ "s1" , "os"},
	{ "b1" , "passworded"},
	{ "b1" , "secure"},
	{ "z"  , "gamever"},
	{ "u1" , "edf"}
}
local function hasflag(flag,what)
	return bit.band(flag,what)>0
end
local function add(t,...)
	t[#t+1]={...}
end

local ecache = {}
local function parse_EDF(EDF,data)

	local cached = ecache[EDF]
	if cached then return unpack(cached) end

	local t = {}
	local start
	if hasflag( EDF  , 0x80 ) then add(t,"i2","gameport")  end
	if hasflag( EDF , 0x10 )  then
		add(t,"u4","steamid1")
		add(t,"u4","steamid2")
	end
	if hasflag( EDF , 0x40 )  then
		add(t,"u2","specport")
		add(t,"z","specname")
	end
	if hasflag( EDF , 0x20 )  then add(t,"z","tags") end
	if hasflag( EDF , 0x01 )  then
									add(t,"u4","gameid1")
									add(t,"u4","gameid2")
								end

	local u = { t,rebuild_format(t) }
	ecache[EDF] = u

	return unpack(u)
end

local vstruct_A2S_INFO = rebuild_format(A2S_INFO_FORMAT)

local function add_data(entry,struct,fmt)
	for k,v in next,struct do
		local name = fmt[k][2]
		entry[name] = v
	end
end

local function parseA2Sreply(entry)

	-- parse before edf

	local data = vstruct.cursor(entry[3])

	local struct = vstruct.read(vstruct_A2S_INFO,data)

	add_data(entry,struct,A2S_INFO_FORMAT)

	assert(entry.hdr1=='\xFF\xFF\xFF\xFF')
	assert(entry.hdr2=='\x49')

	-- parse edf

	local edf = entry.edf
	assert(edf)
	if edf==0 then return end

	local fmt,vstruct_fmt = parse_EDF(edf)
	if not next(fmt) then return end

	local struct = vstruct.read(vstruct_fmt,data)

	add_data(entry,struct,fmt)

end

function getServerInfoWorker(cb,max_parallel,max_wait,max_tries)
	max_parallel = max_parallel or 10
	max_wait = max_wait or 4
	max_tries = max_tries or 2
	assert(max_parallel>=1 and max_parallel<10000)
	assert(max_wait>=0.1 and max_wait<60)
	assert(max_tries>=1 and max_tries<10000)
	assert(type(cb)=='function')

	local udp = assert(socket.udp())
	assert(udp:setsockname('*',0))
	assert(udp:setpeername('*'))
	udp:settimeout(0)

	local function send_req(entry)
		local ok, err = udp:sendto(A2S_INFO,entry[1],entry[2])
		if ok == nil then
			dbg("sendto error",err,entry[1],entry[2])
			return false,err
		end
		return true
	end

	local queue = {}

	local function process_entry(entry,now)

		-- callback this thing
		local processed = entry[3]
		if processed~=nil then
			if processed then
				local ok , err = xpcall(parseA2Sreply,debug.traceback,entry)
				if not ok then
					--dbg("parse fail",entry[1],entry[2],err)
					cb(false,entry,err)
					return true
				end
				cb(true,entry)
			end
			return true
		end

		-- check if we have timed out, retry if need
		local timeout = entry[4]
		local retries_remaining = entry[5]
		if timeout then
			if now > timeout then
				if retries_remaining <= 0 then
					entry[4] = nil
					cb(false,entry)
				else
					entry[4] = false -- timeout
					entry[5] = retries_remaining - 1
					table.insert(queue,entry) -- add to the end of the queue to not break stuff
				end
				return true
			end
		end

		-- no timeout yet, set one and send request
		if not timeout then
			timeout = Now() + max_wait
			entry[4] = timeout
			if not send_req(entry) then
				assert(false,"sendfail!?")
			end
		end

	end

	local function got_reply(entry,data,now)
		entry[3] = data -- processed -> data
		local started = entry[4] - max_wait
		local len = now - started
		if len<0 then len=-1 end
		entry[4] = len -- timeout -> timespent
		entry[5] = nil -- retrys remaining
		--dbg('reply',entry[1],#data)
	end

	local maxerrs = 1024
	local function work()
		-- process entries (timeout, finished)
		local i = 0
		local now = Now()
		while i<max_parallel do
			i=i+1
			local entry = queue[i]
			if entry == nil then break end
			local ret = process_entry(entry,now)
			if ret == true then
				table.remove(queue,i)
				i=i-1
			end
		end

		-- receive data
		local now = Now()
		for received_in_a_tick=0,1024 do
			local data,ip,port=udp:receivefrom()
			if data == nil then
				if ip == 'timeout' then
					break
				else
					print("recvfrom: "..tostring(ip))
					maxerrs = maxerrs - 1
					if maxerrs==0 then error"something is really broken" end
					break
				end
			end

			-- find the server
			for i=1,max_parallel do
				local entry = queue[i]

				-- too bad
				if entry == nil then
					dbg("Timed out/unknown reply from ",ip,':',port,' ',#data)
					break
				end

				if ip==entry[1] and port==entry[2] then

					if entry[3] then
						dbg("Duplicate!? reply from ",ip,':',port,' ',#data)
						break
					end

					got_reply(entry,data,now)
					break
				end
			end

		end

		return queue[1]

	end

	-- worker coroutine
	local working
	local function worker()
		working = true
		--dbg("worker started")

		cb(false,true,"worker started")

		co.waittick()
		while working do
			working = work()
			co.waittick()
		end

		--dbg("worker ended")
		cb(false,false,"worker ended")
	end

	-- start coroutine
	local function start_worker()
		if working then return end
		co(worker)

		return true
	end

	-- servers to query
	local function add_queue(ip,port)
		local entry = {
			ip, -- 1
			port,
			nil, -- 3 -- processed
			false, -- 4 -- timeout
			max_tries, -- 5 - retry count
		}
		table.insert( queue, entry )
		start_worker()
		return entry
	end
	return {
		add_queue=add_queue,
		stop = function()
			working=false
			queue={}
		end
	}

end


-- challenge helper --

local function getchallenge(dat)
	if dat:sub(1,5)=='\xFF\xFF\xFF\xFFA' then
		local chall = dat:sub(6,-1)
		if chall:len()~=4 then return end
		return chall
	end
end

--- MULTIPART HELPER ---

local function collapse_multipart(entry)
	--assert part count ?

	local mp = entry.multipartdata

	local dat = table.concat(mp,"")
	entry[3] = dat
	entry.multipartdata = true
end

local multipart_parse_hdr = vstruct.compile"[4| b1 u31 ] u1 u1 u2"

local parse_multipart_vstr={}
-- https://developer.valvesoftware.com/wiki/Server_Queries#Source_Server
local function parse_multipart(entry,dat)
	local ismultipart,hasallparts = entry.ismultipart,entry.hasallparts

	if ismultipart and hasallparts then PrintTable(entry) assert(false,"!?") end

	-- check if multipart at all?
	if dat:sub(1,4)~='\xFE\xFF\xFF\xFF' then
		assert(not ismultipart,"non multiparts in stream!?")
		return false,false
	end

	ismultipart = true
	entry.ismultipart = ismultipart

	local data = vstruct.cursor(dat)

	data:seek(nil,4)

	-- multipart header

	local dat = parse_multipart_vstr
	for i=#dat,1,-1 do
		dat[i]=nil
	end
	multipart_parse_hdr:read(data,dat)

	local bz2 = dat[1]
	local id = dat[2]
	local packets = dat[3]
	local pnum = dat[4]+1
	local wtf = dat[5]
	--dbg(">",unpack(dat))
	if wtf~=1248 then
		dbg("packetsize","1248!="..wtf)
	end

	--assert(not bz2,"DATA COMPRESSED!?!?")
	if bz2 then
		dbg("multipart","DATA COMPRESSED?!")
	end

	local _id = entry.multipart_id
	if _id == nil then
		_id = id
		entry.multipart_id = _id
	else
		assert(id==_id,"multiple multipart messages in transit not supported")
	end


	local _packets = entry.multipart_packets
	if _packets == nil then
		_packets = packets
		entry.multipart_packets = _packets
	else
		assert(packets==_packets,"packet amount changed!?")
	end


	local payload = data:read'*a'

	local mp = entry.multipartdata
	if mp == nil then
		mp = {}
		for i=1,packets do
			mp[i]=false
		end
		entry.multipartdata = mp
	end

	assert(pnum<=packets,"multipart with too big packet number")

	local prev = mp[pnum]
	if prev then
		dbg("multipart","received packet number",pnum,"multiple times!?")
	end
	mp[pnum] = payload

	local nump = 0
	for k,v in next,mp do
		if v~=false then
			nump = nump + 1
		end
	end

	hasallparts = nump == packets

	if hasallparts then
		entry.hasallparts = true
		--dbg("hasallparts!")
	end



	return ismultipart,hasallparts

end

------------- the meat ------------

local function GENERATE(__payload__,__parse__) return function(cb,max_parallel,max_wait,max_tries)

	max_parallel = max_parallel or 5
	max_wait = max_wait or 4
	max_tries = max_tries or 1
	assert(max_parallel>=1 and max_parallel<10000)
	assert(max_wait>=0.1 and max_wait<60)
	assert(max_tries>=1 and max_tries<10000)
	assert(type(cb)=='function')

	local udp = assert(socket.udp())
	assert(udp:setsockname('*',0))
	assert(udp:setpeername('*'))
	udp:settimeout(0)

	local function send_req(entry)
		local data = __payload__(entry.challenge)
		--dbg("sendto",entry[1],entry[2],entry.challenge and "with challenge" or "no challenge")
		local ok, err = udp:sendto(data,entry[1],entry[2])
		if ok == nil then
			dbg("sendto error",err,entry[1],entry[2])
			return false,err
		end
		return true
	end

	local queue = {}

	local function process_entry(entry,now)

		-- callback this thing
		local processed = entry[3]
		if processed then
			entry[3] = false

			local datas = entry[6]
			assert(datas[1])

			for i,data in next,datas do
				datas[i] = nil -- we go through everything, erase here

				-- challenge/response

				local challenge = getchallenge(data)
				--dbg("REPLY LEN",processed:len(),processed and "challenge" or "not challenge")
				if challenge then
					entry.challenge = challenge
					entry[3] = false -- not processed
					entry[4] = nil -- no timeout yet, send challenge
					table.Empty(datas)
					break
				end

				-- multipart processing

				local ok,multipart,allparts = xpcall(parse_multipart,debug.traceback,entry,data)

				if not ok then
					cb(nil,entry,multipart)
					return true
				end

				-- multipart assembling

				if multipart then
					if allparts then
						--dbg"allparts"
						collapse_multipart(entry)
					else
						--dbg"notallparts"
						goto cont
					end
				else -- collapse single message
					dbg"notmultipart"
					assert(not next(datas),"too many messages for non multipart!?")
					entry[3] = data
				end

				--dbg"parse..."
				-- parsing

				local ok , err = xpcall(__parse__,debug.traceback,entry)

				if ok then
					cb(true,entry)
				else
					cb(nil,entry,err)
				end

				do return true end

				::cont::

			end
		end

		-- check if we have timed out, retry if need
		local timeout = entry[4]
		local retries_remaining = entry[5]
		if timeout then
			if now > timeout then
				if retries_remaining <= 0 then
					entry[4] = nil
					cb(nil,entry,'timeout')
				else

					-- this is UGLY
					entry[4] = false -- timeout
					entry[6] = {}
					entry.multipart_id=nil
					entry.multipart_packets=nil
					entry.ismultipart=nil
					entry.hasallparts=nil
					entry.multipartdata=nil
					entry[5] = retries_remaining - 1
					table.insert(queue,entry) -- add to the end of the queue to not break stuff
				end
				return true
			end
		end

		-- no timeout yet, set one and send request
		if not timeout then
			timeout = Now() + max_wait
			entry[4] = timeout
			if not send_req(entry) then
				assert(false,"sendfail!?")
			end
		end

	end

	local function got_reply(entry,data,now)

		local t = entry[6]
		local pos = #t+1
		t[pos] = data

		entry[3] = entry[3] or pos

		if pos>1 then
			dbg("multidata",pos)
		end

		--should not let sender decide like this.
		--sender can send as much as they want now
		local timeout = now + max_wait
		entry[4] = timeout

	end

	local maxerrs = 1024
	local function work()
		-- receive data
		local now = Now()
		for received_in_a_tick=0,1024 do
			local data,ip,port=udp:receivefrom()
			if data == nil then
				if ip == 'timeout' then
					break
				else
					print("recvfrom: "..tostring(ip))
					maxerrs = maxerrs - 1
					if maxerrs==0 then error"something is really broken" end
					break
				end
			end

			-- find the server
			for i=1,max_parallel do
				local entry = queue[i]

				-- too bad
				if entry == nil then
					dbg("Timed out/unknown reply from ",ip,':',port,' len:',#data)
					break
				end

				if ip==entry[1] and port==entry[2] then

					got_reply(entry,data,now)

					break

				end
			end

		end

		-- process entries (timeout, finished)
		local i = 0
		local now = Now()
		while i<max_parallel do
			i=i+1
			local entry = queue[i]
			if entry == nil then break end
			local ret = process_entry(entry,now)
			if ret == true then
				table.remove(queue,i)
				i=i-1
			end
		end


		return queue[1]

	end

	-- worker coroutine
	local working
	local function worker()
		working = true
		--dbg("worker started")

		cb(false,true,"worker started")

		co.waittick()
		while working do
			working = work()
			co.waittick()
		end

		--dbg("worker ended")
		cb(false,false,"worker ended")
	end

	-- start coroutine
	local function start_worker()
		if working then return end
		co(worker)

		return true
	end

	-- servers to query
	local function add_queue(ip,port)
		local entry = {
			ip, -- 1
			port,
			false, -- 3 -- processed
			false, -- 4 -- timeout
			max_tries, -- 5 - retry count
			{}
		}
		table.insert( queue, entry )
		start_worker()
		return entry
	end
	return {
		add_queue=add_queue,
		stop = function()
			error"unimplemented"
		end
	}


end end -- GENERATE



----------------------------

local A2S_PLAYER = '\xFF\xFF\xFF\xFF\x55'
local function payload_a2splayer(response)
	return A2S_PLAYER..(response or '\xFF\xFF\xFF\xFF')
end


local vstruct_A2S_PLAYERS = "u1 z u4 f4"

local function parseA2SPlayers(entry)

	-- parse before edf

	local data = entry[3]
	local a,b,c,d=data:byte(1,4)


	assert(a==b and b==c and c==d and d==0xff,"TODO: UNIMPLEMENTED: SPLITPACKET")

	--Msg"UGH " PrintTable(data)

	local responsetype,numplayers = data:byte(5,7)
	assert(responsetype==0x44,"Invalid response type: "..responsetype)

	data = vstruct.cursor(data)

	data:seek(nil,4+2)

	local t = {}
	entry[3] = t

	for i=1,numplayers do
		local dat = vstruct.read(vstruct_A2S_PLAYERS,data)
		t[#t+1]=dat
	end
end


----------------------------


local A2S_RULES = '\xFF\xFF\xFF\xFFV'
local function payload_a2srules(response)
	return A2S_RULES..(response or '\xFF\xFF\xFF\xFF')
end


local a2s_rules_tmp={}
local function parseA2SRules(entry)

	-- parse before edf

	local data = entry[3]

	local a,b,c,d=data:byte(1,4)

	if not a==b and b==c and c==d and d==0xff then
		dbg("EEK",a..'.'..b..'.'..c..'.'..d)
	end

	--Msg"UGH " PrintTable(data)
	data = vstruct.cursor(data)
	data:seek(nil,4)

	vstruct.read('responsetype:u1 numrules:u2',data,a2s_rules_tmp)
	local responsetype,numrules = a2s_rules_tmp.responsetype,a2s_rules_tmp.numrules

	assert(responsetype==0x45,"Invalid response type: "..responsetype)

	dbg("num rules",numrules)

	local t = {}
	entry[3] = t

	entry.parsing_rules = true

	for i=1,numrules do
		vstruct.read('key:z val:z',data,a2s_rules_tmp)
		local key,val = a2s_rules_tmp.key,a2s_rules_tmp.val

		t[key] = val

	end

	entry.parsing_rules = false
end

local function GENERATE_FETCHERS()
	playerListFetcher=GENERATE(payload_a2splayer,parseA2SPlayers)
	serverRulesFetcher=GENERATE(payload_a2srules,parseA2SRules)
end
GENERATE_FETCHERS()

return _M

--[=[


local function server_reply(what,entry,x)
	if what and entry then print(entry[1],entry[2],entry.name) return end
	--Msg"2"
end

local serverinfo = serverquery.getServerInfoWorker(server_reply)

local rules = serverRulesFetcher(function(...)
	local a,b=...

	if a then
		for k,v in next,b[3] do
			if k:lower():find"epoe" then
				print(k,b[1],b[2])
				serverinfo.add_queue(b[1],b[2])
				break
			end
		end
		Msg"."
	else
		--Msg"1"
	end
end,20)


local function cb(info,ip,port,ipport)
	if info == true and ip then
		rules.add_queue(ip,port)
	else
		--Msg"0"
	end
end

serverquery.getServerList(cb, [[\gamedir\garrysmod\empty\1]])


--fetcher.add_queue('1.1.1.1',27015)
--]=]