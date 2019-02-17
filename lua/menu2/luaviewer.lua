require("stringtable")
require("luamio")
local Gizeh = Gizeh or {}
local javascript_escape_replacements = {
	["\\"] = "\\\\",
	["\0"] = "\\0" ,
	["\b"] = "\\b" ,
	["\t"] = "\\t" ,
	["\n"] = "\\n" ,
	["\v"] = "\\v" ,
	["\f"] = "\\f" ,
	["\r"] = "\\r" ,
	["\""] = "\\\"",
	["\'"] = "\\\'"
}
Gizeh.Nom_Serveur = math.random( 1, 999999 )
hook.Add( "InGame", "FixThisFuckingServerName", function(is)
	if is and g_ServerName ~= nil and g_ServerName ~= "" then
		Gizeh.Nom_Serveur = g_ServerName
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("|", "-") 
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("~", "-") 
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub(" ", "") 
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("✔", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("/", "-")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("\\", "-")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub(":", "-")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("ç", "c")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("©", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("™", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("®", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("℠", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("*", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("\"", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("<", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub(">", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("★", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("▌", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("à", "a")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("✦", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("►", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("◄", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub(",", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("È", "E")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("'", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("√", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("†", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("é", "e")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("è", "e")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("ê", "e")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("É", "E")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("â", "a")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("ä", "a")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("ë", "e")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("î", "i")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("ï", "i")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("♣", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("ツ", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("•", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("❖", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("♕", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("²", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("✪", "")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("ô", "o")
		Gizeh.Nom_Serveur = Gizeh.Nom_Serveur:gsub("ö", "o")
	end
end)
function string.JavascriptSafe( str )
	if str == nil then return end
	str = str:gsub( ".", javascript_escape_replacements )
	str = str:gsub( "\226\128\168", "\\\226\128\168" )
	str = str:gsub( "\226\128\169", "\\\226\128\169" )
	return str
end
local function GetLuaFiles(client_lua_files)
	if client_lua_files == nil then return end
	local count = client_lua_files:Count()
	local ret = {}
	for i = 1, count - 2 do
		local path = client_lua_files:GetString(i)
		ret[i] = {
			Path = path,
			CRC = client_lua_files:GetUserDataInt(i)
		}
	end
	return ret
end
local function GetLuaFileContents(crc)
	local fs = file.Open("cache/lua/" .. crc .. ".lua", "rb", "MOD")
	if fs ~= nil then
	fs:Seek(4)
	local contents = util.Decompress(fs:Read(fs:Size() - 4))
	return contents:sub(1, -2) -- Trim trailing null
	end
end
local function dumbFile(path, contents)
	if contents == nil then return end
	if not  path:match("%.lua$") then path = path..".lua" end
	local curdir = ""
	for t in path:gmatch("[^/\\*]+") do
		curdir = curdir..t
		if  curdir:match("%.lua$") then
			local f = io.open("garrysmod/data/"..curdir, "w+")
			if f == nil then continue end
			f:write(contents)
			f:close()
		else
			curdir = curdir.."/"
			file.CreateDir(curdir)
		end
	end
end
local dumbFolderCache = ""
local function dumbFolder(node)
	if node == nil then return end
	for _, subnode in ipairs(node.ChildNodes:GetChildren()) do
		if subnode:HasChildren() then
			dumbFolder(subnode)
		else
			dumbFile(dumbFolderCache..subnode.pathh, GetLuaFileContents(subnode.CRC))
		end
	end
end
local VIEWER = {}
function VIEWER:Init()
	if not IsInGame() then 
		MsgC(Color(255, 0, 0), "You must join a server before doing that !\n")
		self:Close()
		return
	end
	self:SetTitle("Lua Viewer Bonus - Clientside")
    self:SetSize(1200, 550)
    self:Center() 
    self:ShowCloseButton(false) 
    self.Paint = function(s,w,h)
        surface.SetDrawColor(Color(40,40,40))
        surface.DrawRect(0,0, w,h) 
        surface.SetDrawColor(Color(40,40,40)) 
        surface.DrawRect(1,1, w-2,h-2) 
        surface.SetDrawColor(Color(40,40,40))
        surface.DrawRect(2,2, w-4,h-4) 
        surface.SetDrawColor(Color(40,40,40)) 
        surface.DrawRect(7.5,27.5, w-14,h-34) 
    end 
    self.close = vgui.Create("DButton", self)
    self.close:SetSize(20, 20)
    self.close:SetPos(self:GetWide() - 25, -2)
    self.close:SetText("")
    self.close.Paint = function(s,w,h) 
        if self.close:IsDown() then
            draw.SimpleText("x", "Trebuchet24", (w / 2)-2, (h / 2)-10, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText("x", "Trebuchet24", (w / 2)-2, (h / 2)-11, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    self.close.DoClick = function(s,w,h)
        self:Close() 
    end
	self.left = vgui.Create("PANEL", self)
	self.left:SetWide(self:GetWide() * .2)
	self.left:Dock(LEFT)
	self.tree = vgui.Create("DTree", self.left)
	self.tree:Dock(FILL)
	self.tree.Directories = {}
    self.tree.Paint = function(s,w,h) 
        draw.RoundedBox( 4, 0, 0, w, h, Color( 33, 33, 33, 255  ) )
    end
	self.right = vgui.Create("PANEL", self)
	self.right:Dock(FILL)
	self.html = vgui.Create("DHTML", self.right)
	self.html:Dock(FILL)
	self.html:SetAllowLua(true)
	self.html:OpenURL("asset://garrysmod/lua/menu2/luaviewer/index.html")
	self.html:AddFunction("gmodinterface", "OnCode", function(code) end)
	client_lua_files = stringtable.Get "client_lua_files"
	local tree_data= {}
	for i, v in ipairs(GetLuaFiles(client_lua_files)) do
		if i == 1 then continue end
		local file_name = string.match(v.Path, ".*/([^/]+%.lua)")
		local dir_path = string.sub(v.Path, 1, -1 - file_name:len())
		local file_crc = v.CRC
		local cur_dir = tree_data
		for dir in string.gmatch(dir_path, "([^/]+)/") do
			if not cur_dir[dir] then
				cur_dir[dir] = {}
			end
			cur_dir = cur_dir[dir]
		end
		cur_dir[file_name] = {fileN = file_name, CRC = file_crc}
	end
	local file_queue = {}
	local function iterate(data, node, path)
		path = path or ""
		for k, v in SortedPairs(data) do
			if type(v) == "table" and not v.CRC then
				local new_node = node:AddNode(k)
				new_node.Label:SetTextColor(Color(230,230,230,255))
				new_node.DoRightClick = function()
					local dmenu = DermaMenu(new_node)
					dmenu:SetPos(gui.MouseX(), gui.MouseY())
					dmenu:AddOption("Save the file", function() 
						dumbFolderCache = "gizeh_filesteal/bonus/"..Gizeh.Nom_Serveur.."/".."/" 
						MsgC(Color(60,179,113), ("Folder to save in : data/gizeh_filesteal/bonus/"..Gizeh.Nom_Serveur.."/\n"))
						local start = CurTime() 
						dumbFolder(new_node) 
						MsgC(Color(60,179,113), ("Perform in "..CurTime() - start.." seconds\n"))
					end)
					dmenu:Open()
				end
				iterate(v, new_node, path .. k .. "/")
			else
				table.insert(file_queue, {node = node, fileN = v.fileN, path = path .. v.fileN, CRC = v.CRC})
			end
		end
	end
	iterate(tree_data, self.tree)
	for k, v in ipairs(file_queue) do
		local node = v.node:AddNode(v.fileN, "icon16/page.png")
		node.Label:SetTextColor(Color(200,250,200,255))
		node.DoClick = function()
			if string.JavascriptSafe(GetLuaFileContents(v.CRC)) == nil then return end
			self.html:QueueJavascript("SetContent('"..string.JavascriptSafe(GetLuaFileContents(v.CRC)).."'); GotoLine(1);")
			self.currentPath = v.path
		end
		node.DoRightClick = function()
			local dmenu = DermaMenu(node)
			dmenu:SetPos(gui.MouseX(), gui.MouseY())
			dmenu:AddOption("Save file", function() 
				dumbFile("gizeh_filesteal/bonus/"..Gizeh.Nom_Serveur.."/".." "..v.fileN, GetLuaFileContents(v.CRC)) 
				MsgC(Color(60,179,113), ("File save in : data/gizeh_filesteal/bonus/"..Gizeh.Nom_Serveur.."/"..v.fileN).."\n")
			end)
			dmenu:Open()
		end
		node.CRC = v.CRC
		node.pathh = v.path
	end
end
derma.DefineControl("luaviewer", "views clientside lua files", VIEWER, "DFrame")
concommand.Add("lua_view_cl", function()
	vgui.Create("luaviewer"):MakePopup()
end)