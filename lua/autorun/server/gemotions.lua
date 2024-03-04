gemotions = gemotions or {}

util.AddNetworkString("gemotions")

AddCSLuaFile("autorun/client/gemotions.lua")
AddCSLuaFile("gemotions/config.lua")

function gemotions.RegisterEmote(_material, _sound)
	resource.AddSingleFile(string.format("materials/%s", _material))
	resource.AddSingleFile(string.format("sound/%s", _sound))
end

local function AddFiles(path)
	local path = path .. "/"
	for _,name in ipairs(file.Find(path .. "*", "GAME")) do
		resource.AddSingleFile(path .. name)
	end
end

-- load config
include("gemotions/config.lua")

-- load resources
AddFiles("materials/gemotions")
AddFiles("sound/gemotions/ui")

local antispam = {}

net.Receive("gemotions", function(_, ply)
	antispam[ply] = antispam[ply] or RealTime()
	if antispam[ply] > RealTime() then return end
	antispam[ply] = RealTime() + gemotions.EmoteCooldown

	net.Start("gemotions")
		net.WriteUInt(net.ReadUInt(7), 7)
		net.WriteEntity(ply)
	net.Broadcast()
end)

-- Damdndndmadamdasnm