gemotions = gemotions or {}

do -- Msg
	local head = "[GEmotions] "
	local color = Color( 193, 118, 255)
	local color_text = Color( 210, 210, 210)

	gemotions.Msg = function(...)
		MsgC(color, head, color_text, ..., "\n")
	end
end

do -- Loading Packages
	gemotions.RegisterPackage = function(package, title, data)
		for k, v in ipairs(data) do
			local mat, snd = v[1], v[2]
			if mat then
				resource.AddSingleFile(string.format("materials/%s", mat))
			end
			if snd then
				resource.AddSingleFile(string.format("sound/%s", snd))
			end
		end
	end
end

do -- Loading Packages
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

do -- Adding Files
	gemotions.AddFiles = function(path)
		local path = string.format("%s/", path)
		for _,name in ipairs(file.Find(string.format("%s*", path), "GAME")) do
			resource.AddSingleFile(string.format("%s%s", path, name))
		end
	end

	gemotions.AddFiles("materials/gemotions")
	gemotions.AddFiles("sound/gemotions/ui")
end

do -- Net Receive
	local temp = {}
	local cooldown = 0.6

	util.AddNetworkString("gemotions")
	net.Receive("gemotions", function(len, ply)
		local time = temp[ply]
		time = time or RealTime()

		if time < RealTime() then
			time = RealTime() + cooldown

			net.Start("gemotions")
				net.WriteUInt(net.ReadUInt(7), 7) -- EMOTE ID
				net.WriteUInt(net.ReadUInt(7), 7) -- PACKAGE ID
				net.WriteEntity(ply)
			net.Broadcast()
		end

		temp[ply] = time
	end)
end

-- This shitcoding :)





-- gemotions = gemotions or {}

-- function gemotions.RegisterPack(pack, title, data)
-- 	for i, k in ipairs(data) do
-- 		local mat, snd = k[1], k[2]

-- 		if mat then
-- 			resource.AddSingleFile(string.format("materials/%s", mat))
-- 		end

-- 		if snd then
-- 			resource.AddSingleFile(string.format("sound/%s", snd))
-- 		end
-- 	end
-- end

-- -- Looking for and loading packs
-- MsgC( Color( 193, 118, 255), "[GEmotions] ", Color(210, 210, 210), "Loading emotions packs...\n")

-- gemotions.loadedPacks = 0
-- for k, v in ipairs(file.Find( "gemotions/*", "LUA" )) do
-- 	local filePath = string.format("gemotions/%s", v)
-- 	AddCSLuaFile(filePath)
-- 	include(filePath)

-- 	MsgC( Color( 193, 118, 255), "[GEmotions] ", Color(210, 210, 210), string.format("Registered emotions pack %s\n", v ))
-- 	gemotions.loadedPacks = gemotions.loadedPacks + 1
-- end 

-- MsgC( Color( 193, 118, 255), "[GEmotions] ", Color(210, 210, 210), string.format("Registered %d packs!\n", gemotions.loadedPacks))

-- if (gemotions.loadedPacks == 0) then
-- 	MsgC( Color( 255, 110, 110), "[GEmotions] ", Color(210, 210, 210), "No packs loaded! Aborting...")	
-- 	return
-- end

-- -- Normal addon startup
-- AddCSLuaFile("autorun/client/gemotions.lua")

-- local function AddFiles(path)
-- 	local path = path .. "/"
-- 	for _,name in ipairs(file.Find(path .. "*", "GAME")) do
-- 		resource.AddSingleFile(string.format("%s%s",path,name))
-- 	end
-- end

-- -- load resources
-- AddFiles("materials/gemotions")
-- AddFiles("sound/gemotions/ui")

-- local antispam = {}

-- gemotions.EmoteCooldown = 0.5

-- util.AddNetworkString("gemotions")
-- net.Receive("gemotions", function(_, ply)
-- 	antispam[ply] = antispam[ply] or RealTime()
-- 	if antispam[ply] > RealTime() then return end
-- 	antispam[ply] = RealTime() + gemotions.EmoteCooldown

-- 	net.Start("gemotions")
-- 		net.WriteUInt(net.ReadUInt(7), 7)
-- 		net.WriteUInt(net.ReadUInt(7), 7) -- PACK ID
-- 		net.WriteEntity(ply)
-- 	net.Broadcast()
-- end)




-- -- Damdndndmadamdasnm