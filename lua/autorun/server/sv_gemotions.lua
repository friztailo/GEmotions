--------------------------------------------------------------------------------------
-- GEmotions
--------------------------------------------------------------------------------------

gemotions = gemotions or {}

--------------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------------

do
	local head = "[GEmotions] "
	local color = Color( 193, 118, 255)
	local color_text = Color( 210, 210, 210)

	gemotions.Msg = function(...)
		MsgC(color, head, color_text, ..., "\n")
	end
end

do
	gemotions.Register = function(title, tbldata)
		for k, v in ipairs(tbldata) do
			local mat, snd = v[1], v[2]
			if (mat) then
				resource.AddSingleFile(string.format("materials/%s", mat))
			end
			if (snd) then
				resource.AddSingleFile(string.format("sound/%s", snd))
			end
		end
	end
end

--------------------------------------------------------------------------------------
-- Loading Packages
--------------------------------------------------------------------------------------

do
	gemotions.Msg("Loading emotions packages...")

	gemotions.loadedPackages = 0
	for _,name in ipairs(file.Find("gemotions/*", "LUA")) do
		local path = string.format("gemotions/%s", name)
		AddCSLuaFile(path)
		include(path)

		gemotions.loadedPackages = gemotions.loadedPackages + 1
		gemotions.Msg(string.format("Registered emotions package '%s'", path))
	end

	gemotions.Msg(string.format("Registered %d packages!", gemotions.loadedPackages))
end

--------------------------------------------------------------------------------------
-- Adding Files
--------------------------------------------------------------------------------------

do
	gemotions.AddFiles = function(path)
		local path = string.format("%s/", path)
		for _,name in ipairs(file.Find(string.format("%s*", path), "GAME")) do
			resource.AddSingleFile(string.format("%s%s", path, name))
		end
	end

	gemotions.AddFiles("materials/gemotions")
	gemotions.AddFiles("sound/gemotions/ui")
end

--------------------------------------------------------------------------------------
-- Net Receive
--------------------------------------------------------------------------------------

do
	local temp = {}
	local cooldown = 0.8

	util.AddNetworkString("gemotions")
	net.Receive("gemotions", function(len, ply)
		local realtime = RealTime()
		local time = temp[ply] or realtime

		if time <= realtime then
			time = realtime + cooldown
			net.Start("gemotions")
				net.WriteUInt(net.ReadUInt(7), 7) -- PACKAGE ID
				net.WriteUInt(net.ReadUInt(7), 7) -- EMOTE ID
				net.WriteEntity(ply)
			net.Broadcast()
		end

		temp[ply] = time
	end)
end

--[[
		 _______             __        __        __    __           __        __ 
		|       \           |  \      |  \      |  \  /  \         |  \      |  \
		| $$$$$$$\ __    __ | $$   __  \$$      | $$ /  $$ ______  | $$   __  \$$
		| $$__/ $$|  \  |  \| $$  /  \|  \      | $$/  $$ |      \ | $$  /  \|  \
		| $$    $$| $$  | $$| $$_/  $$| $$      | $$  $$   \$$$$$$\| $$_/  $$| $$
		| $$$$$$$ | $$  | $$| $$   $$ | $$      | $$$$$\  /      $$| $$   $$ | $$
		| $$      | $$__/ $$| $$$$$$\ | $$      | $$ \$$\|  $$$$$$$| $$$$$$\ | $$
		| $$       \$$    $$| $$  \$$\| $$      | $$  \$$\\$$    $$| $$  \$$\| $$
		 \$$        \$$$$$$  \$$   \$$ \$$       \$$   \$$ \$$$$$$$ \$$   \$$ \$$

]]--