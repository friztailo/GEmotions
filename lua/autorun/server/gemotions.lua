gemotions = gemotions or {}

util.AddNetworkString("gemotions")

AddCSLuaFile("autorun/client/gemotions.lua")
AddCSLuaFile("gemotions/config.lua")

function gemotions.RegisterEmote(_material, _sound)
	resource.AddSingleFile(string.format("materials/%s", _material))
	resource.AddSingleFile(string.format("sound/%s", _sound))
end
-- load config
include("gemotions/config.lua")

-- load png
resource.AddSingleFile("materials/gemotions/base.png")
resource.AddSingleFile("materials/gemotions/base_select.png")

-- load sound
resource.AddSingleFile("sound/gemotions/ui/switch.ogg")

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