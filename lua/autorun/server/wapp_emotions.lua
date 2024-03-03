local antispam = {}

util.AddNetworkString("wapp_emotions")
net.Receive("wapp_emotions", function(_, ply)
	antispam[ply] = antispam[ply] or RealTime()
	if antispam[ply] > RealTime() then return end
	antispam[ply] = RealTime() + 1

	net.Start("wapp_emotions")
		net.WriteInt(net.ReadInt(7), 7)
		net.WriteEntity(ply)
	net.Broadcast()
end)

-- Damdndndmadamdasnm