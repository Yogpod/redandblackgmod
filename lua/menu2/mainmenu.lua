RNB = RNB or {}
local R = function(a, b, c, d, e) return function() return RunConsoleCommand(a, b, c, d, e) end end
local M = function(x) return function() return RunGameUICommand(x) end end
function RNB.Open_Menu()
	if IsValid(RNB.bonus_menu) then RNB.bonus_menu:Remove() end
	RNB.bonus_menu = vgui.Create("DFrame", pnlMainMenu)
	RNB.bonus_menu:SetPos(0, 0)
	RNB.bonus_menu:SetSize(ScrW(), 25)
	RNB.bonus_menu:SetTitle("")
	RNB.bonus_menu:SetDraggable(false)
	RNB.bonus_menu:ShowCloseButton(false)
	RNB.bonus_menu.Paint = function(self, w, h)
		surface.SetDrawColor(255, 0, 0, 255)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(0, 0, 0, 230)
		surface.DrawRect(0, 0, w, h)
	end

	-- Function to create the buttons on the menu
	local function CreateButton(pos, command, icon, tip)
		local bonus_button = vgui.Create("DButton", RNB.bonus_menu)
		bonus_button:SetText("")
		bonus_button:SetPos(unpack(pos))
		bonus_button.Paint = function(self, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0)) end
		bonus_button.DoClick = function()
			if isfunction(command) then
				command()
			else
				M(command)()
			end

			bonus_button:SetSelected(false)
		end

		bonus_button:SetImage(icon)
		bonus_button:InvalidateLayout(true)
		bonus_button:SetTextInset(32, 0)
		bonus_button:SetContentAlignment(4)
		local tall = bonus_button:GetTall() + 4
		tall = tall < 16 and 16 or tall
		bonus_button:SetTall(tall)
		bonus_button:SetTooltip(tip)
	end

	-- Left side buttons
	CreateButton({5, 0}, "engine gameui_hide", "icon16/joystick.png", "Hide the menu")
	CreateButton({35, 0}, "engine disconnect", "icon16/disconnect.png", "Disconnect")
	CreateButton({65, 0}, "retry", "icon16/connect.png", "Retry")
	CreateButton({95, 0}, "opencreatemultiplayergamedialog", "icon16/server.png", "Start a new game")
	CreateButton({125, 0}, "openserverbrowser", "icon16/world_delete.png", "Server Browser")
	CreateButton({155, 0}, "openoptionsdialog", "icon16/wrench.png", "Settings")
	CreateButton({185, 0}, "quitnoconfirm", "icon16/door.png", "Quit")
	-- Right side buttons and clock
	-- Clock display (refresh every 5 seconds)
	local TimeStamp = os.time()
	local bonus_hour = vgui.Create("DLabel", RNB.bonus_menu)
	bonus_hour:SetPos(ScrW() - 75, 3)
	bonus_hour:SetFont("TargetID")
	bonus_hour:SetColor(Color(180, 180, 180))
	bonus_hour:SetText(os.date("%H:%M", TimeStamp))
	timer.Create("refresh_hour_menu2", 5, 0, function() bonus_hour:SetText(os.date("%H:%M", os.time())) end)
	-- Console button
	CreateButton({ScrW() - 115, 0}, function()
		if gui.IsConsoleVisible() then
			M("hideconsole")() -- This doesn't work
		else
			gui.ShowConsole()
		end
	end, "icon16/application_osx_terminal.png", "Toggle Console")
end

hook.Add("ConsoleVisible", "CreateMenu", function(is) RNB.Open_Menu() end)
hook.Add("MenuStart", "CreateMenu", function(is) timer.Simple(1, function() RNB.Open_Menu() end) end)
R"showconsole"()