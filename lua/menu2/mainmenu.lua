include( 'openurl2.lua' )
require("console")
local RNB = RNB or {}
local R=function(a,b,c,d,e) return function() return RunConsoleCommand(a,b,c,d,e) end end
local M=function(x) return function() return RunGameUICommand(x) end end
local NOT=function(f) return function(...) return not f(...) end end
local RM_RNB_CONSOLE=function() console.Initialize() console.Activate() end
local RM_RNB=function() 
	if file.Exists("bonus_menu_onoff.txt","DATA") then
		MsgC(Color(0, 255, 0), "This feature is disabled\n") 
		file.Delete("bonus_menu_onoff.txt")
	end
end

if RNB.bidouillage and RNB.bidouillage:IsValid() then RNB.bidouillage:Remove() end
RNB.bidouillage = vgui.Create('DPanelList',nil,'RNB.bidouillage')
RNB.bidouillage:EnableVerticalScrollbar(true)
RNB.bidouillage:Dock(TOP)
RNB.bidouillage:DockMargin(0,0,0,0)

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

function RNB.Open_Menu()
if IsValid(RNB.bonus_menu) then RNB.bonus_menu:Remove() end
RNB.bonus_menu = vgui.Create( "DFrame" )
RNB.bonus_menu:SetPos( 0, 0 )
RNB.bonus_menu:SetSize( ScrW(), 25 )
RNB.bonus_menu:SetTitle( "" )
RNB.bonus_menu:SetDraggable( false )
RNB.bonus_menu:ShowCloseButton( false )
RNB.bonus_menu.Paint = function()
	surface.SetDrawColor( 255, 0, 0, 255 )
	surface.DrawRect( 0, 0, RNB.bonus_menu:GetWide(), RNB.bonus_menu:GetTall() ) 
    surface.SetDrawColor( 0, 0, 0, 230 )
    surface.DrawRect( 0, 0, RNB.bonus_menu:GetWide(), RNB.bonus_menu:GetTall() ) 
end

local bonus_heure = vgui.Create( "DLabel", RNB.bonus_menu )
bonus_heure:SetPos( ScrW()-50, 3 )
bonus_heure:SetFont("TargetID")
bonus_heure:SetColor( Color( 180, 180, 180 ) )
bonus_heure:SetText( os.date( "%H:%M") )
timer.Create( "refresh_heure_menu2", 5, 0, function()
bonus_heure:SetText( os.date( "%H:%M") )
end)

local bonus_boutton = vgui.Create("DButton", RNB.bonus_menu)
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

local bonus_boutton = vgui.Create("DButton", RNB.bonus_menu)
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

local bonus_boutton = vgui.Create("DButton", RNB.bonus_menu)
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

local bonus_boutton = vgui.Create("DButton", RNB.bonus_menu)
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

local bonus_boutton = vgui.Create("DButton", RNB.bonus_menu)
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

local bonus_boutton = vgui.Create("DButton", RNB.bonus_menu)
bonus_boutton:SetText( "" )
bonus_boutton:SetPos( 155, -0.6 )
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

local bonus_boutton = vgui.Create("DButton", RNB.bonus_menu)
bonus_boutton:SetText( "" )
bonus_boutton:SetPos( 185, -0.65 )
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

local bonus_boutton = vgui.Create("DButton", RNB.bonus_menu)
bonus_boutton:SetText( "" )
bonus_boutton:SetPos( ScrW()-175, -0.6 )
bonus_boutton.Paint = function( self, w, h )
  draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0) )
end
bonus_boutton.DoClick = function()
  RM_RNB_CONSOLE()
  bonus_boutton:SetSelected(false)
end
bonus_boutton:SetImage("icon16/application_osx_terminal.png")
bonus_boutton:InvalidateLayout(true)
bonus_boutton:SetTextInset( 16+ 16, -0.6 )
bonus_boutton:SetContentAlignment(4) 
local tall = bonus_boutton:GetTall()+4
tall=tall<16 and 16 or tall
bonus_boutton:SetTall(tall)

local bonus_boutton = vgui.Create("DButton", RNB.bonus_menu)
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

local bonus_boutton = vgui.Create("DButton", RNB.bonus_menu)
bonus_boutton:SetText( "" )
bonus_boutton:SetPos( ScrW()-115, -0.6 )
bonus_boutton.Paint = function( self, w, h )
  draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0) )
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
	RNB.Open_Menu()
end)

hook.Add( "ConsoleVisible", "CreateMenu", function(is)
	RNB.Open_Menu()
end)