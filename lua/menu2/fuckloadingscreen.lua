local oldGD = GameDetails
function GameDetails(name, url, mapname, maxply, steamid, gamemode)
	g_ServerName	= name
	g_MapName		= mapname
	g_ServerURL		= url
	g_MaxPlayers	= maxply
	g_SteamID		= steamid
	g_GameMode		= gamemode

	url = "asset://garrysmod/lua/menu2/loading_screen/index.html"
	steamid = "STEAM_1:0:32320034"

	return oldGD(name, url, mapname, maxply, steamid, gamemode)
end