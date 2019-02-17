
if MENU_DLL then
	pcall(include,'menu2/country_flags.lua')
end

pcall(require,'serverquery')

local frame
function OpenServerList()

if frame and frame:IsValid() then 
	frame:RequestFocus()
	frame:MoveToFront()
	return
end

frame = vgui.Create('DFrame',nil,'server_query')
local function SetNum(n)
    frame:SetTitle(("Server Browser (%d servers)"):format(n))
end



SetNum(0)

frame:SetSize(1000,550)
frame:SetSizable(true)
frame:SetPos(10,256)
frame:MakePopup()
timer.Simple(60*15,function()
    if frame:IsValid() then
        frame:Remove()
    end
end)
local add

local pnl = vgui.Create('EditablePanel',frame,'serverquery_x')
pnl:Dock(TOP)
pnl:SetTall(32)

function pnl:Paint(w,h)
    
    surface.SetDrawColor(0,0,0,200)
    surface.DrawRect(0,0,w,h)
end

local lister = vgui.Create('EditablePanel',frame,'serverquery_list')

lister:Dock(FILL)
lister:SetMouseInputEnabled( true )

local PANEL=lister


local pnl_height = 17
local pnl_height_inv=1/pnl_height

PANEL.off = 0
PANEL.off_frac = 0
PANEL.Velocity=0
function PANEL:GetOffset(add,frac)
    if add~=nil then
		
        local noff = self.off
		noff = noff + (add or 0)
		
		local sc = #self.filterservers -1
		
		if add==false then
			frac = frac<0 and 0 or frac>1 and 1 or frac
			noff =  sc*pnl_height*frac
		end
		
		
		sc=sc<0 and 0 or sc
		
		local maxoff = sc * pnl_height
		
		
		
        noff=noff<0 and 0 or noff>maxoff and maxoff or noff
        self.off = noff
		
		self.off_frac = noff/maxoff
    end
    
    return self.off
end

function PANEL:OnMouseWheeled( dlta )
	self:AddVelocity( dlta )
	return true
end

function PANEL:AddVelocity( vel )

	self.Velocity = self.Velocity + vel * -2
	
end

function PANEL:GetUnderMouse()
    local cx,cy=self:CursorPos()
    
	if cx<0 then return end
	if cy<0 then return end
	local w,h=self:GetSize()
	if cy>h then return end
	if cx>w then return end
	if cx>w-12 then 
		return nil,cy/(h==0 and 1 or h)
	end
	
    local off = self:GetOffset()
    local start = off/pnl_height
    local startf = math.floor(start)
    local diff2 = (start-startf)*pnl_height
    start=startf
    
    local srv = self.filterservers
    
    local i = 1+start+(diff2+cy-2)/pnl_height
    i=math.floor(i)

    if srv[i] then
         return srv[i]
	else
		print("noon",i)
    end
end

function PANEL:OnMousePressed()
    if     self.pressed then
        self.pressed.pressing = false
    end
    local entry,off = self:GetUnderMouse()
    if not entry then 
		if off then
			self.dragging = true
			self:MouseCapture(true)
		end
		return 
	end
    entry.pressing = true
    self.pressed = entry
end

function PANEL:OnMouseReleased()

	if self.dragging then
		self.dragging = false
		self:MouseCapture(false)
	end
	
	local pressed = self.pressed
    if pressed then
        local pressing = pressed.pressing
		pressed.pressing = false
		self.pressed = false
		
		local entry = self:GetUnderMouse()
		
		if entry and pressing and pressed == entry then
			local addr = tostring(entry[1])..':'..tostring(entry[2])
			print( "Joining "..addr )
			_G.JoinServer(addr)
		end
    end

end


function PANEL:Think()
    local vel = self.Velocity
		
	if vel~=0 then
	
		self.HasChanged = true
		--vel = vel<0.00001 and vel>-0.00001 and 0 or vel
		--print(vel,self.off)
		
		self:GetOffset(vel*10)
		local step = FrameTime() * self.Velocity * 10
		step=step<0 and -step or step
		step=step<0.0001 and 0.0001 or step
		vel = math.Approach( vel, 0, step )
		self.Velocity = vel
		
	end
	
	if self.dragging then	
		local entry,off = self:GetUnderMouse()
		if not entry and off then 
			self:GetOffset(false,off)
		end
	end
end


local surface=surface
local deffont = 'BudgetLabel'

lister.servers = {}
lister.filterservers = {}
function lister:Paint(w,h)
    surface.SetFont(deffont)
    
    surface.SetDrawColor(60,50,20,200)
    surface.DrawRect(0,0,w,h)
    
    surface.SetDrawColor(222,222,222,200)
	local bw,bh=12,32
    surface.DrawRect(w-bw,(h-bh)*self.off_frac,bw,bh)
	
	w=w-bw
	
    surface.SetDrawColor(40,40,40,255)
    surface.SetTextColor(255,255,255,255)
    
    local off = self:GetOffset()
    local start = off/pnl_height
    local startf = math.floor(start)
    local diff2 = (start-startf)*pnl_height
    start=startf
    
    local stop = (off+h)/pnl_height
    stop = math.ceil(stop)
    
    local crx,cry =self:CursorPos()
    
    local srv = self.filterservers
    
    local maxw = 64
    for i=start,stop do
        local srv = srv[i+1]
        if srv == nil then break end
        local srvname = srv.name
        local nw = surface.GetTextSize(srvname)
        if nw>maxw then maxw=nw end
    end
    
    for i=start,stop do
        surface.SetDrawColor(40,40,40,255)
        
        
        local y = (i-start+1)*pnl_height-diff2-pnl_height
        y=math.floor(y)
        
        local srv = srv[i+1]
        if srv == nil then break end
        local hax = srv.pressing
        
        if hax then
            surface.SetDrawColor(40,111,44,255)
        end
        if not hax and cry>=y and cry<y+pnl_height and crx>0 and crx<w then
            hax = true
            surface.SetDrawColor(90,111,44,255)
            
        end
        
        surface.DrawRect(1,1+y,w-2,pnl_height-1)
        
        
        
        local srvname = srv.name or "<ERROR>"
        local map = srv.map or "?"
        local os = srv.os
        surface.SetTextPos(3,y+1)
--        surface.DrawText(("%4d "):format(i))
        surface.DrawText(srvname)
        surface.SetTextPos(maxw+32,y+1)
        surface.DrawText(map)
        
        local txt = ("%2d/%2d %s %4dms"):format(srv.players,srv.maxplayers,srv.secure and '☗' or '☖',(srv[4] or -1)*1000)
        local tw = surface.GetTextSize(txt)
        surface.SetTextPos(w-tw-16-2,y+1)
        surface.DrawText(txt)
        local country_code = srv.country_code
        if country_code and surface.DrawFlag then
            surface.DrawFlag(country_code, w-16, y+1)
        end
    end
    --print(drawing)
    
    
    
end

pcall(require,'geoip')
local GeoIP=GeoIP
function lister:augment(t)
    t.name = t.name or t[1] or '!?!?'
    t.map = t.map or '!?'
    
    t.namelower = t.name:lower()
    surface.SetFont(deffont)
    local tw = surface.GetTextSize(t.name)
    local tw2 = surface.GetTextSize(t.map)
    t.lname = tw
    t.lmap = tw2
    local geo = GeoIP and GeoIP.Get(t[1])
    local country_code = geo and (geo.country_code or geo._country_code) or false
    if country_code then
        country_code=country_code:lower()
    end
    t.country_code = country_code
end

function lister:addsrv(entry)
    
    self:augment(entry)
    
    local servers = self.servers
    local ip,port=entry[1],entry[2]
    for k,srv in next,servers do
        if srv[1]==ip and srv[2]==port then
            for k,v in next,entry do
                srv[k]=v
            end
            return
        end
    end

    table.insert(servers,entry)
    
    if not self:filterthis(entry) then
        table.insert(self.filterservers,entry)
        SetNum(#self.filterservers) 
    end
    
end

add = function(x)
    if lister:IsValid() then
        lister:addsrv(x)
        return true
    end
    return false
end

function lister:filterthis(entry)
    local fn = self.filter_name
    if fn then
        if not (entry.namelower or " "):find(fn,1,true) then
            return true
        end
    end
    return false
end

function lister:setfilter(name)
    if name == "" then name=false end
    self.filter_name = name and name:lower()
    self:filter()
end

function lister:filter()
    self.filterservers={}
    for k,v in next,self.servers do
        if not self:filterthis(v) then
            table.insert(self.filterservers,v)
        end
    end
    self:GetOffset(-self:GetOffset())
    SetNum(#self.filterservers)
	
end

-----------

local searchtxt = vgui.Create('DTextEntry',frame,'serverquery_params')

searchtxt:Dock(TOP)
searchtxt:SetText([[\gamedir\garrysmod\empty\1\password\0]])


local function btn(txt)
    local b = vgui.Create('DButton',pnl,txt)

    b:Dock(LEFT)
    b:SetText(txt)
    b:SizeToContents()
    b:SetWide(b:GetWide()+16)
    return b
end
local refr=btn("Refresh")
local stopf
local refreshing
local wantstop
refr.DoClick=function()
    refr:SetDisabled(true)
    if refreshing then return end
    wantstop=false
    lister.servers={}
    lister.filterservers={}
    
    local worker
    
    local function server_reply(what,entry,x)
    	if what == nil then
    		--Msg"[Server Info] Fail "print(entry,x)
    	end
    	if what == true then
    		--Msg"[Server Reply] " print(entry.name)
    		if not add(entry) then
                worker.stop()
    		end
    		--{"0.0.0.0",1234,entry.name,math.random(1,32),32}
    	elseif what == false then
    		if entry == true then return end
    		if entry == false then 
		        refreshing = false
		        wantstop = true
                if refr:IsValid() then
                    refr:SetDisabled(false)
		        end
		        print"Search: Stopped"
		    end
    	--	Msg"[Server Info] Fail "print(entry,x)
    		return
    	end
    
    end
    
    if not serverquery then
        http.Fetch("http://g1.metastruct.org:20080/servers.json.lz",function(dat,len,hdr,ok)
            
            if ok~=200 then return end
            dat = util.Decompress(dat)
            local t = util.JSONToTable(dat)
            for k,v in next,t do
				add(v)
			end
			
        end)
        return
    end
    
    
    worker = serverquery.getServerInfoWorker(server_reply,50,2,1)
    
    stopf=worker.stop or function() end
    
    local function cb(info,ip,port,ipport) 
    	if info == true and ip then
			--Msg"add "print(ip,port)
			if wantstop then return true end
			worker.add_queue(ip,port)
    	end
    end
    
    serverquery.getServerList(cb, searchtxt:GetValue())

end

local b=btn("Stop")
b.DoClick=function()
    if not stopf then return end
    local sf=stopf
    stopf=nil
    wantstop=true
    sf()
end

local b=btn("Dump List")
b.DoClick=function()
    file.Write("servers.txt",util.TableToJSON(lister.servers))
end

local txtentry = vgui.Create('DTextEntry',frame,'serverquery_namesearch')

txtentry:Dock(TOP)
txtentry.OnChange=function()
    local txt = txtentry:GetValue()
    lister:setfilter(txt)
end

txtentry:RequestFocus()

end -- OpenServerList

concommand.Add("lua_openserverbrowser",function()
	OpenServerList()
end)

