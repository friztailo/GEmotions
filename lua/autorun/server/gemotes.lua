gemotes = gemotes or {}

util.AddNetworkString("gemotes")

AddCSLuaFile("autorun/client/gemotes.lua")
AddCSLuaFile("gemotes/config.lua")

function gemotes.RegisterEmote(_material, _sound)
	resource.AddSingleFile(string.format("materials/%s", _material))
	resource.AddSingleFile(string.format("sound/%s", _sound))
end
-- load config
include("gemotes/config.lua")

-- load png
resource.AddSingleFile("materials/gemotes/base.png")
resource.AddSingleFile("materials/gemotes/base_select.png")

-- load sound
resource.AddSingleFile("sound/gemotes/ui/switch.ogg")

local antispam = {}

net.Receive("gemotes", function(_, ply)
	antispam[ply] = antispam[ply] or RealTime()
	if antispam[ply] > RealTime() then return end
	antispam[ply] = RealTime() + gemotes.EmoteCooldown

	net.Start("gemotes")
		net.WriteUInt(net.ReadUInt(7), 7)
		net.WriteEntity(ply)
	net.Broadcast()
end)

-- Damdndndmadamdasnm