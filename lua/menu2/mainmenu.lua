include( 'openurl2.lua' )
require("console")
local Gizeh = Gizeh or {}
local R=function(a,b,c,d,e) return function() return RunConsoleCommand(a,b,c,d,e) end end
local M=function(x) return function() return RunGameUICommand(x) end end
local NOT=function(f) return function(...) return not f(...) end end
local RM_GIZEH_CONSOLE=function() console.Initialize() console.Activate() end
local RM_GIZEH=function() 
	if file.Exists("bonus_menu_onoff.txt","DATA") then
		MsgC(Color(0, 255, 0), "This feature is disabled because it is not needed in the menu v2;)\n") 
		file.Delete("bonus_menu_onoff.txt")
	end
end

if Gizeh.bidouillage and Gizeh.bidouillage:IsValid() then Gizeh.bidouillage:Remove() end
Gizeh.bidouillage = vgui.Create('DPanelList',nil,'Gizeh.bidouillage')
Gizeh.bidouillage:EnableVerticalScrollbar(true)
Gizeh.bidouillage:Dock(TOP)
Gizeh.bidouillage:DockMargin(0,0,0,0)

local gameslist
function CreateGames()
	
	if gameslist and gameslist:IsValid() then gameslist:Remove() gameslist=nil end
	
	gameslist = vgui.Create('DForm',menulist_wrapper,'gameslist')
	gameslist:Dock(TOP)
	gameslist:SetName"#mounted_games"
	gameslist:SetExpanded(false)
	gameslist.Header:SetIcon 'icon16/joystick.png'
	gameslist:SetCookieName"gameslist"
	gameslist:LoadCookies()
	
	menulist_wrapper:AddItem(gameslist)
	menulist_wrapper:InvalidateLayout(true)
	gameslist:InvalidateLayout(true)
	
	local function AddButton(data,title,mounted,owned,installed,depot)
		
		local btn = vgui.Create("DCheckBoxLabel",gameslist,'gameslist_button')
			gameslist:AddItem(btn)
			btn:SetText(title)
			btn:SetChecked(mounted)
			btn:SetBright(true)
			btn:SetDisabled(not owned or not installed)
			btn:SizeToContents()
			function btn:OnChange(val)
				engine.SetMounted(depot,val)
				btn:SetChecked(IsMounted(depot))
			end
	
		btn:InvalidateLayout(true)
	end

	local t=engine.GetGames()
	table.sort(t,function(a,b)
		if a.mounted==b.mounted then
			if a.mounted then
				return a.depot<b.depot
			else
				return ((a.installed and a.owned) and 0 or 1)<((b.installed and b.owned) and 0 or 1)
			end
		else
			return  (a.mounted and 0 or 1)<(b.mounted and 0 or 1)
		end
	end)
	for _,data in next,t do
		AddButton(data,data.title,data.mounted,data.owned,data.installed,data.depot)
	end
	
end

function Gizeh.Open_Menu()
if IsValid(Gizeh.bonus_menu) then Gizeh.bonus_menu:Remove() end
Gizeh.bonus_menu = vgui.Create( "DFrame" )
Gizeh.bonus_menu:SetPos( 0, 0 )
Gizeh.bonus_menu:SetSize( ScrW(), 25 )
Gizeh.bonus_menu:SetTitle( "" )
Gizeh.bonus_menu:SetDraggable( false )
Gizeh.bonus_menu:ShowCloseButton( false )
Gizeh.bonus_menu.Paint = function()
	surface.SetDrawColor( 255, 0, 0, 255 )
	surface.DrawRect( 0, 0, Gizeh.bonus_menu:GetWide(), Gizeh.bonus_menu:GetTall() ) 
    surface.SetDrawColor( 0, 0, 0, 230 )
    surface.DrawRect( 0, 0, Gizeh.bonus_menu:GetWide(), Gizeh.bonus_menu:GetTall() ) 
end

local bonus_heure = vgui.Create( "DLabel", Gizeh.bonus_menu )
bonus_heure:SetPos( ScrW()-50, 3 )
bonus_heure:SetFont("TargetID")
bonus_heure:SetColor( Color( 180, 180, 180 ) )
bonus_heure:SetText( os.date( "%H:%M") )
timer.Create( "refresh_heure_menu2", 5, 0, function()
bonus_heure:SetText( os.date( "%H:%M") )
end)

local bonus_boutton = vgui.Create("DButton", Gizeh.bonus_menu)
bonus_boutton:SetText( "" )
bonus_boutton:SetPos( 5, 0 )
bonus_boutton.Paint = function( self, w, h )
  draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0) )
end
bonus_boutton.DoClick = function()
  M"engine gameui_hide"()
  bonus_boutton:SetSelected(false)
end
bonus_boutton:SetImage("icon16/joystick.png")
bonus_boutton:InvalidateLayout(true)
bonus_boutton:SetTextInset( 16+ 16, 0 )
bonus_boutton:SetContentAlignment(4) 
local tall = bonus_boutton:GetTall()+4
tall=tall<16 and 16 or tall
bonus_boutton:SetTall(tall)

local bonus_boutton = vgui.Create("DButton", Gizeh.bonus_menu)
bonus_boutton:SetText( "" )
bonus_boutton:SetPos( 35, -0.65 )
bonus_boutton.Paint = function( self, w, h )
  draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0) )
end
bonus_boutton.DoClick = function()
  M"engine disconnect"()
  bonus_boutton:SetSelected(false)
end
bonus_boutton:SetImage("icon16/disconnect.png")
bonus_boutton:InvalidateLayout(true)
bonus_boutton:SetTextInset( 16+ 16, 0 )
bonus_boutton:SetContentAlignment(4) 
local tall = bonus_boutton:GetTall()+4
tall=tall<16 and 16 or tall
bonus_boutton:SetTall(tall)

local bonus_boutton = vgui.Create("DButton", Gizeh.bonus_menu)
bonus_boutton:SetText( "" )
bonus_boutton:SetPos( 65, -0.65 )
bonus_boutton.Paint = function( self, w, h )
  draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0) )
end
bonus_boutton.DoClick = function()
  R"retry"()
  bonus_boutton:SetSelected(false)
end
bonus_boutton:SetImage("icon16/connect.png")
bonus_boutton:InvalidateLayout(true)
bonus_boutton:SetTextInset( 16+ 16, 0 )
bonus_boutton:SetContentAlignment(4) 
local tall = bonus_boutton:GetTall()+4
tall=tall<16 and 16 or tall
bonus_boutton:SetTall(tall)

local bonus_boutton = vgui.Create("DButton", Gizeh.bonus_menu)
bonus_boutton:SetText( "" )
bonus_boutton:SetPos( 95, -0.6 )
bonus_boutton.Paint = function( self, w, h )
  draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0) )
end
bonus_boutton.DoClick = function()
  M"opencreatemultiplayergamedialog"()
  bonus_boutton:SetSelected(false)
end
bonus_boutton:SetImage("icon16/server.png")
bonus_boutton:InvalidateLayout(true)
bonus_boutton:SetTextInset( 16+ 16, 0 )
bonus_boutton:SetContentAlignment(4) 
local tall = bonus_boutton:GetTall()+4
tall=tall<16 and 16 or tall
bonus_boutton:SetTall(tall)

local bonus_boutton = vgui.Create("DButton", Gizeh.bonus_menu)
bonus_boutton:SetText( "" )
bonus_boutton:SetPos( 125, -0.6 )
bonus_boutton.Paint = function( self, w, h )
  draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0) )
end
bonus_boutton.DoClick = function()
  M"openserverbrowser"()
  bonus_boutton:SetSelected(false)
end
bonus_boutton:SetImage("icon16/world_delete.png")
bonus_boutton:InvalidateLayout(true)
bonus_boutton:SetTextInset( 16+ 16, 0 )
bonus_boutton:SetContentAlignment(4) 
local tall = bonus_boutton:GetTall()+4
tall=tall<16 and 16 or tall
bonus_boutton:SetTall(tall)

local bonus_boutton = vgui.Create("DButton", Gizeh.bonus_menu)
bonus_boutton:SetText( "" )
bonus_boutton:SetPos( 155, -0.6 )
bonus_boutton.Paint = function( self, w, h )
  draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0) )
end
bonus_boutton.DoClick = function()
  R"lua_openserverbrowser"()
  bonus_boutton:SetSelected(false)
end
bonus_boutton:SetImage("icon16/world_add.png")
bonus_boutton:InvalidateLayout(true)
bonus_boutton:SetTextInset( 16+ 16, 0 )
bonus_boutton:SetContentAlignment(4) 
local tall = bonus_boutton:GetTall()+4
tall=tall<16 and 16 or tall
bonus_boutton:SetTall(tall)

local bonus_boutton = vgui.Create("DButton", Gizeh.bonus_menu)
bonus_boutton:SetText( "" )
bonus_boutton:SetPos( 185, -0.65 )
bonus_boutton.Paint = function( self, w, h )
  draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0) )
end
bonus_boutton.DoClick = function()
  M"openoptionsdialog"()
  bonus_boutton:SetSelected(false)
end
bonus_boutton:SetImage("icon16/wrench.png")
bonus_boutton:InvalidateLayout(true)
bonus_boutton:SetTextInset( 16+ 16, 0 )
bonus_boutton:SetContentAlignment(4) 
local tall = bonus_boutton:GetTall()+4
tall=tall<16 and 16 or tall
bonus_boutton:SetTall(tall)

local bonus_boutton = vgui.Create("DButton", Gizeh.bonus_menu)
bonus_boutton:SetText( "" )
bonus_boutton:SetPos( 215, -0.65 )
bonus_boutton.Paint = function( self, w, h )
  draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0) )
end
bonus_boutton.DoClick = function()
  M"quitnoconfirm"()
  bonus_boutton:SetSelected(false)
end
bonus_boutton:SetImage("icon16/door.png")
bonus_boutton:InvalidateLayout(true)
bonus_boutton:SetTextInset( 16+ 16, 0 )
bonus_boutton:SetContentAlignment(4) 
local tall = bonus_boutton:GetTall()+4
tall=tall<16 and 16 or tall
bonus_boutton:SetTall(tall)

local bonus_boutton = vgui.Create("DButton", Gizeh.bonus_menu)
bonus_boutton:SetText( "" )
bonus_boutton:SetPos( ScrW()-175, -0.6 )
bonus_boutton.Paint = function( self, w, h )
  draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0) )
end
bonus_boutton.DoClick = function()
  RM_GIZEH_CONSOLE()
  bonus_boutton:SetSelected(false)
end
bonus_boutton:SetImage("icon16/application_osx_terminal.png")
bonus_boutton:InvalidateLayout(true)
bonus_boutton:SetTextInset( 16+ 16, -0.6 )
bonus_boutton:SetContentAlignment(4) 
local tall = bonus_boutton:GetTall()+4
tall=tall<16 and 16 or tall
bonus_boutton:SetTall(tall)

local bonus_boutton = vgui.Create("DButton", Gizeh.bonus_menu)
bonus_boutton:SetText( "" )
bonus_boutton:SetPos( ScrW()-145, -0.6 )
bonus_boutton.Paint = function( self, w, h )
  draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0) )
end
bonus_boutton.DoClick = function()
  R"showconsole"()
  bonus_boutton:SetSelected(false)
end
bonus_boutton:SetImage("icon16/application_xp_terminal.png")
bonus_boutton:InvalidateLayout(true)
bonus_boutton:SetTextInset( 16+ 16, 0 )
bonus_boutton:SetContentAlignment(4) 
local tall = bonus_boutton:GetTall()+4
tall=tall<16 and 16 or tall
bonus_boutton:SetTall(tall)

local bonus_boutton = vgui.Create("DButton", Gizeh.bonus_menu)
bonus_boutton:SetText( "" )
bonus_boutton:SetPos( ScrW()-115, -0.6 )
bonus_boutton.Paint = function( self, w, h )
  draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0) )
end
bonus_boutton.DoClick = function()
  R"lua_view_cl"()
  bonus_boutton:SetSelected(false)
end
bonus_boutton:SetImage("icon16/server_key.png")
bonus_boutton:InvalidateLayout(true)
bonus_boutton:SetTextInset( 16+ 16, 0 )
bonus_boutton:SetContentAlignment(4) 
local tall = bonus_boutton:GetTall()+4
tall=tall<16 and 16 or tall
bonus_boutton:SetTall(tall)

local bonus_boutton = vgui.Create("DButton", Gizeh.bonus_menu)
bonus_boutton:SetText( "" )
bonus_boutton:SetPos( ScrW()-85, -0.5 )
bonus_boutton.Paint = function( self, w, h )
  draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0) )
end
bonus_boutton.DoClick = function()
  RM_GIZEH()
  bonus_boutton:SetSelected(false)
end
bonus_boutton:SetImage("icon16/bug.png")
bonus_boutton:InvalidateLayout(true)
bonus_boutton:SetTextInset( 16+ 16, 0 )
bonus_boutton:SetContentAlignment(4) 
local tall = bonus_boutton:GetTall()+4
tall=tall<16 and 16 or tall
bonus_boutton:SetTall(tall)
end

hook.Add( "InGame", "CreateMenu", function(is)
	Gizeh.Open_Menu()
end)

hook.Add( "ConsoleVisible", "CreateMenu", function(is)
	Gizeh.Open_Menu()
end)