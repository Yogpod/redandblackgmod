local PANEL_Browser = {}
PANEL_Browser.Base = "DFrame"

function PANEL_Browser:Init()
    self.HTML = vgui.Create("HTML", self)

    if (not self.HTML) then
        print("SteamOverlayReplace: Failed to create HTML element")
        self:Remove()

        return
    end

    self.HTML:Dock(FILL)
    self.HTML:SetOpenLinksExternally(true)
    self:SetTitle("Steam overlay replacement")
    self:SetSize(ScrW() * 0.75, ScrH() * 0.75)
    self:SetSizable(true)
    self:Center()
    self:MakePopup()
end

function PANEL_Browser:SetURL(url)
    self.HTML:OpenURL(url)
end

-- Called from the engine
function GMOD_OpenURLNoOverlay(url)
    local BrowserInst = vgui.CreateFromTable(PANEL_Browser)
    BrowserInst:SetURL(url)

    timer.Simple(0, function()
        if (not gui.IsGameUIVisible()) then
            gui.ActivateGameUI()
        end
    end)
end

----------------------------------------------
local PANEL = {}
PANEL.Base = "DFrame"

function PANEL:Init()
    self.Type = "openurl"
    self:SetTitle("#openurl.title")
    self.Garble = vgui.Create("DLabel", self)
    self.Garble:SetText("#openurl.text")
    self.Garble:SetContentAlignment(5)
    self.Garble:Dock(TOP)
    self.URL = vgui.Create("DTextEntry", self)
    self.URL:SetDisabled(true)
    self.URL:Dock(TOP)
    self.CustomPanel = vgui.Create("DLabel", self)
    self.CustomPanel:Dock(TOP)
    self.CustomPanel:SetContentAlignment(5)
    self.CustomPanel:DockMargin(0, 5, 0, 0)
    self.CustomPanel:SetVisible(false)
    self.CustomPanel.Color = Color(0, 0, 0, 0)

    self.CustomPanel.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, s.Color)
    end

    self.Buttons = vgui.Create("Panel", self)
    self.Buttons:Dock(TOP)
    self.Buttons:DockMargin(0, 5, 0, 0)
    self.Disconnect = vgui.Create("DButton", self.Buttons)
    self.Disconnect:SetText("#openurl.disconnect")

    self.Disconnect.DoClick = function()
        self:DoNope()
        RunConsoleCommand("disconnect")
    end

    self.Disconnect:Dock(LEFT)
    self.Disconnect:SizeToContents()
    self.Disconnect:SetWide(self.Disconnect:GetWide() + 10)
    self.Nope = vgui.Create("DButton", self.Buttons)
    self.Nope:SetText("#openurl.nope")

    self.Nope.DoClick = function()
        self:DoNope()
    end

    self.Nope:DockMargin(0, 0, 5, 0)
    self.Nope:Dock(RIGHT)
    self.Yes = vgui.Create("DButton", self.Buttons)
    self.Yes:SetText("#openurl.yes")

    self.Yes.DoClick = function()
        self:DoYes()
    end

    self.Yes:DockMargin(0, 0, 5, 0)
    self.Yes:Dock(RIGHT)
    self:SetSize(680, 104)
    self:Center()
    self:MakePopup()
    self:DoModal()
    hook.Add("Think", self, self.AlwaysThink)

    if (not IsInGame()) then
        self.Disconnect:SetVisible(false)
    end
end

function PANEL:LoadServerInfo()
    self.CustomPanel:SetVisible(true)
    self.CustomPanel:SetText("Loading server info...")
    self.CustomPanel:SizeToContents()

    serverlist.PingServer(self:GetURL(), function(ping, name, desc, map, players, maxplayers, bot, pass, lp, ip, gamemode)
        if (not IsValid(self)) then return end

        if (not ping) then
            self.CustomPanel.Color = Color(200, 50, 50)
            self.CustomPanel:SetText("#askconnect.no_response")
        else
            self.CustomPanel:SetText(string.format("%s\n%i/%i players | %s | %s | %ims", name, players, maxplayers, map, desc, ping))
        end

        self.CustomPanel:SizeToContents()
    end)
end

function PANEL:AlwaysThink()
    -- Ping the server for details
    if (SysTime() - self.StartTime > 0.1 and self.Type == "askconnect" and not self.CustomPanel:IsVisible()) then
        self:LoadServerInfo()
    end

    if (self.StartTime + 1 > SysTime()) then return end

    if (not self.Yes:IsEnabled()) then
        self.Yes:SetEnabled(true)
    end

    if (not gui.IsGameUIVisible()) then
        self:Remove()
    end
end

function PANEL:PerformLayout(w, h)
    DFrame.PerformLayout(self, w, h)
    self:SizeToChildren(false, true)
end

function PANEL:SetURL(url)
    self.URL:SetText(url)
    self.StartTime = SysTime()
    self.Yes:SetEnabled(false)
    self.CustomPanel:SetVisible(false)
    self.CustomPanel.Color = Color(0, 0, 0, 0)
    self:InvalidateLayout()
end

function PANEL:GetURL()
    return self.URL:GetText()
end

function PANEL:DoNope()
    self:Remove()
    gui.HideGameUI()
end

function PANEL:DoYes()
    if (self.StartTime + 1 > SysTime()) then return end
    self:DoYesAction()
    self:Remove()
    gui.HideGameUI()
end

function PANEL:DoYesAction()
    if (self.Type == "openurl") then
        gui.OpenURL(self.URL:GetText())
    elseif (self.Type == "askconnect") then
        JoinServer(self.URL:GetText())
    end
end

function PANEL:SetType(t)
    self.Type = t
    self:SetTitle("#" .. t .. ".title")
    self.Garble:SetText("#" .. t .. ".text")
end

local PanelInst = nil

local function OpenConfirmationDialog(address, confirm_type)
    if (IsValid(PanelInst) and PanelInst:GetURL() == address) then return end

    if (not IsValid(PanelInst)) then
        PanelInst = vgui.CreateFromTable(PANEL)
    end

    PanelInst:SetType(confirm_type)
    PanelInst:SetURL(address)

    timer.Simple(0, function()
        if (not gui.IsGameUIVisible()) then
            gui.ActivateGameUI()
        end
    end)
end

local OpenURLCalls = 0

-- Called from the engine
function RequestOpenURL(url)
    OpenURLCalls = OpenURLCalls + 1

    if OpenURLCalls > 10 then
        print("Blocking RequestOpenURL due to spam.")

        return
    end

    OpenConfirmationDialog(url, "openurl")
end

local ConnectCalls = 0

-- Called from the engine
function RequestConnectToServer(serverip)
    ConnectCalls = ConnectCalls + 1

    if ConnectCalls >= 10 then
        print("Blocking RequestConnectToServer due to spam.")

        return
    end

    OpenConfirmationDialog(serverip, "askconnect")
end

timer.Create("RNBDCT", 2, 0, function()
    if ConnectCalls > 0 or OpenURLCalls > 0 then
        if not IsInGame() then
            ConnectCalls = 0
            OpenURLCalls = 0
        else
            ConnectCalls = ConnectCalls - 1
            OpenURLCalls = OpenURLCalls - 1
        end
    end
end)