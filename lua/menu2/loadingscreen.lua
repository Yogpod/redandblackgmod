g_ServerName = ""
g_MapName = ""
g_ServerURL = ""
g_MaxPlayers = ""
g_SteamID = ""
--remove indexx.html part if you want new website w/music
CreateClientConVar("cl_loadingurl", "https://propkill.me/indexx.html", true, true, "Set your own Loading screen. (URL or Path to file)")
local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
end

function PANEL:ShowURL(url, force)
    if (string.len(url) < 5) then return end

    if (IsValid(self.HTML)) then
        if (not force) then return end
        self.HTML:Remove()
    end

    self:SetSize(ScrW(), ScrH())
    self.HTML = vgui.Create("DHTML", self)
    self.HTML:SetSize(ScrW(), ScrH())
    self.HTML:Dock(FILL)
    self.HTML:OpenURL(url)
    self:InvalidateLayout()
    self.LoadedURL = url
end

function PANEL:PerformLayout()
    self:SetSize(ScrW(), ScrH())
end

function PANEL:Paint()
    surface.SetDrawColor(30, 30, 30, 255)
    surface.DrawRect(0, 0, self:GetWide(), self:GetTall())

    if (self.JavascriptRun and IsValid(self.HTML) and not self.HTML:IsLoading()) then
        self:RunJavascript(self.JavascriptRun)
        self.JavascriptRun = nil
    end
end

function PANEL:RunJavascript(str)
    if (not IsValid(self.HTML)) then return end
    if (self.HTML:IsLoading()) then return end
    self.HTML:RunJavascript(str)
end

function PANEL:OnActivate()
    g_ServerName = ""
    g_MapName = ""
    g_ServerURL = ""
    g_MaxPlayers = ""
    g_SteamID = ""
    self:ShowURL(GetDefaultLoadingHTML())
    self.NumDownloadables = 0
end

function PANEL:OnDeactivate()
    if (IsValid(self.HTML)) then
        self.HTML:Remove()
    end

    self.LoadedURL = nil
    self.NumDownloadables = 0
end

function PANEL:Think()
    self:CheckForStatusChanges()
    self:CheckDownloadTables()
end

function PANEL:StatusChanged(strStatus)
    local startPos, endPos = string.find(strStatus, "Downloading ")

    if (startPos) then
        -- Snip everything before the Download part
        strStatus = string.sub(strStatus, startPos)

        -- Special case needed for workshop, snip the "' via Workshop" part
        if (string.EndsWith(strStatus, "via Workshop")) then
            strStatus = string.gsub(strStatus, "' via Workshop", "")
            strStatus = string.gsub(strStatus, "Downloading '", "") -- We need to handle the quote marks
        end

        local Filename = string.gsub(strStatus, "Downloading ", "")
        self:RunJavascript("if ( window.DownloadingFile ) DownloadingFile( '" .. Filename:JavascriptSafe() .. "' )")

        return
    end

    self:RunJavascript("if ( window.SetStatusChanged ) SetStatusChanged( '" .. strStatus:JavascriptSafe() .. "' )")
end

--[[---------------------------------------------------------

-----------------------------------------------------------]]
function PANEL:CheckForStatusChanges()
    local str = GetLoadStatus()
    if (not str) then return end
    str = string.Trim(str)
    str = string.Trim(str, "\n")
    str = string.Trim(str, "\t")
    str = string.gsub(str, ".bz2", "")
    str = string.gsub(str, ".ztmp", "")
    str = string.gsub(str, "\\", "/")
    if (self.OldStatus and self.OldStatus == str) then return end
    self.OldStatus = str
    self:StatusChanged(str)
end

function PANEL:RefreshDownloadables()
    self.Downloadables = GetDownloadables()
    if (not self.Downloadables) then return end
    local iDownloading = 0
    local iFileCount = 0

    for k, v in pairs(self.Downloadables) do
        v = string.gsub(v, ".bz2", "")
        v = string.gsub(v, ".ztmp", "")
        v = string.gsub(v, "\\", "/")
        iDownloading = iDownloading + self:FileNeedsDownload(v)
        iFileCount = iFileCount + 1
    end

    if (iDownloading == 0) then return end
    self:RunJavascript("if ( window.SetFilesNeeded ) SetFilesNeeded( " .. iDownloading .. ")")
    self:RunJavascript("if ( window.SetFilesTotal ) SetFilesTotal( " .. iFileCount .. ")")
end

function PANEL:FileNeedsDownload(filename)
    local bExists = file.Exists(filename, "GAME")
    if (bExists) then return 0 end

    return 1
end

function PANEL:CheckDownloadTables()
    local NumDownloadables = NumDownloadables()
    if (not NumDownloadables) then return end
    if (self.NumDownloadables and NumDownloadables == self.NumDownloadables) then return end
    self.NumDownloadables = NumDownloadables
    self:RefreshDownloadables()
end

local PanelType_Loading = vgui.RegisterTable(PANEL, "EditablePanel")
local pnlLoading = nil

function GetLoadPanel()
    if (not IsValid(pnlLoading)) then
        pnlLoading = vgui.CreateFromTable(PanelType_Loading)
    end

    return pnlLoading
end

function IsInLoading()
    if (not IsValid(pnlLoading) or not IsValid(pnlLoading.HTML)) then return false end

    return true
end

function UpdateLoadPanel(strJavascript)
    if (not pnlLoading) then return end
    pnlLoading:RunJavascript(strJavascript)
end

function GameDetails(servername, serverurl, mapname, maxplayers, steamid, gamemode)
    if (engine.IsPlayingDemo()) then return end
    g_ServerName = servername
    g_MapName = mapname
    g_ServerURL = serverurl
    g_MaxPlayers = maxplayers
    g_SteamID = steamid
    g_GameMode = gamemode
    SentStat = false

    if not SentStat then
        --comment this out or remove it if you want, it just tells me how many people are using this https://propkill.me/pls/RfAl07.png
        http.Fetch("https://propkill.me/sqre/stats.php?SID=" .. g_SteamID)
        SentStat = true
    end

    MsgN(servername)
    MsgN(serverurl)
    MsgN(gamemode)
    MsgN(mapname)
    MsgN(maxplayers)
    MsgN(steamid)

    if serverurl == "" then
        serverurl = g_ServerURL
    else
        serverurl = GetConVar("cl_loadingurl"):GetString()
    end

    serverurl = serverurl:Replace("%s", steamid)
    serverurl = serverurl:Replace("%m", mapname)

    if (maxplayers > 1 and GetConVar("cl_enable_loadingurl"):GetBool()) then
        serverurl = GetConVar("cl_loadingurl"):GetString()
        pnlLoading:ShowURL(serverurl, true)
    end

    pnlLoading.JavascriptRun = string.format('if ( window.GameDetails ) GameDetails( "%s", "%s", "%s", %i, "%s", "%s", %.2f, "%s" );', servername:JavascriptSafe(), serverurl:JavascriptSafe(), mapname:JavascriptSafe(), maxplayers, steamid:JavascriptSafe(), g_GameMode:JavascriptSafe(), GetConVarNumber("volume"), GetConVarString("gmod_language"))
end