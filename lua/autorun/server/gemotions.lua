gemotions = gemotions or {}

function gemotions.RegisterEmote(_material, _sound)
	resource.AddSingleFile(string.format("materials/%s", _material))
	resource.AddSingleFile(string.format("sound/%s", _sound))
end

-- Looking for and loading packs
MsgC( Color( 193, 118, 255), "[GEmotions] ", Color(210, 210, 210), "Loading emotions packs...\n")

gemotions.loadedPacks = 0
for k, v in ipairs(file.Find( "gemotions/*", "LUA" )) do
	local filePath = string.format("gemotions/%s", v)
	AddCSLuaFile(filePath)
	include(filePath)

	MsgC( Color( 193, 118, 255), "[GEmotions] ", Color(210, 210, 210), string.format("Registered emotions pack %s\n", v ))
	gemotions.loadedPacks = gemotions.loadedPacks + 1
end 

MsgC( Color( 193, 118, 255), "[GEmotions] ", Color(210, 210, 210), string.format("Registered %d packs!\n", gemotions.loadedPacks))

if (gemotions.loadedPacks == 0) then
	MsgC( Color( 255, 110, 110), "[GEmotions] ", Color(210, 210, 210), "No packs loaded! Aborting...")	
	return
end

-- Normal addon startup
AddCSLuaFile("autorun/client/gemotions.lua")

local function AddFiles(path)
	local path = path .. "/"
	for _,name in ipairs(file.Find(path .. "*", "GAME")) do
		resource.AddSingleFile(string.format("%s%s",path,name))
	end
end

-- load resources
AddFiles("materials/gemotions")
AddFiles("sound/gemotions/ui")

local antispam = {}

gemotions.EmoteCooldown = 0.5

util.AddNetworkString("gemotions")
net.Receive("gemotions", function(_, ply)
	antispam[ply] = antispam[ply] or RealTime()
	if antispam[ply] > RealTime() then return end
	antispam[ply] = RealTime() + gemotions.EmoteCooldown

	net.Start("gemotions")
		net.WriteUInt(net.ReadUInt(7), 7)
		net.WriteUInt(net.ReadUInt(7), 7) -- PACK ID
		net.WriteEntity(ply)
	net.Broadcast()
end)




-- Damdndndmadamdasnm