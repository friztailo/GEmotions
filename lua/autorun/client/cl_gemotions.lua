--------------------------------------------------------------------------------------
-- GEmotions
--------------------------------------------------------------------------------------

gemotions = gemotions or {}

gemotions.emotions = {}

gemotions.packages = {}
gemotions.packagesCount = 0

local emotions = gemotions.emotions
local packages = gemotions.packages

--------------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------------

do
	local insert = table.insert

	gemotions.Register = function(title, tbldata)
		if (not emotions[title]) then
			emotions[title] = {}
			emotions[title].title = title
			insert(packages, emotions[title])

			gemotions.packagesCount = gemotions.packagesCount + 1
		end
		
		for k, v in ipairs(tbldata) do
			insert(emotions[title], {
				material = Material(v[1], "smooth ignorez"),
				sound = v[2]
			})
		end
		
		emotions[title].count = #emotions[title]
		emotions[title].step = 2 * math.pi / #emotions[title]
		emotions[title].radius = math.max(112, (72 * #emotions[title]) / (2 * math.pi))
	end

	gemotions.GetPackage = function(package)
		return packages[package]
	end
end

do
	local ge_GetPackage = gemotions.GetPackage

	gemotions.GetEmote = function(package, id)
		local package = ge_GetPackage(package)
		return package and package[id] or nil
	end
end

do
	local vec_SetUnpacked = getmetatable(Vector(0, 0, 0)).SetUnpacked
	local mesh_v1, mesh_v2, mesh_v3, mesh_v4 = Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0)
	local mesh_Begin, mesh_Color, mesh_Position, mesh_TexCoord, mesh_AdvanceVertex, mesh_End, render_SetMaterial =
		mesh.Begin, mesh.Color, mesh.Position, mesh.TexCoord, mesh.AdvanceVertex, mesh.End, render.SetMaterial

	local DrawTexturedRect = function(x, y, w, h, mat, a)
		local right, bot = x + w, y + h
		vec_SetUnpacked(mesh_v1, x, y, 0)
		vec_SetUnpacked(mesh_v2, right, y, 0)
		vec_SetUnpacked(mesh_v3, right, bot, 0)
		vec_SetUnpacked(mesh_v4, x, bot, 0)

		if (a == nil) then
			a = 255
		end

		render_SetMaterial(mat)
		mesh_Begin(7, 1)
			mesh_Position(mesh_v1); mesh_Color(255, 255, 255, a); mesh_TexCoord(0, 0, 0); mesh_AdvanceVertex();
			mesh_Position(mesh_v2); mesh_Color(255, 255, 255, a); mesh_TexCoord(0, 1, 0); mesh_AdvanceVertex();
			mesh_Position(mesh_v3); mesh_Color(255, 255, 255, a); mesh_TexCoord(0, 1, 1); mesh_AdvanceVertex();
			mesh_Position(mesh_v4); mesh_Color(255, 255, 255, a); mesh_TexCoord(0, 0, 1); mesh_AdvanceVertex();
		mesh_End()
	end

	local basis = Material("gemotions/base.png", "ignorez")

	gemotions.DrawEmote = function(emote, x, y, w, h, a)
		DrawTexturedRect(x, y, w, h, basis, a)
		DrawTexturedRect(x + w * 0.075, y + w * 0.075, w * 0.85, w * 0.85, emote.material, a)
	end

	local basis = Material("gemotions/base_select.png", "ignorez")

	gemotions.DrawEmoteQuad = function(emote, x, y, w, h, a)
		DrawTexturedRect(x, y, w, h, basis, a)
		DrawTexturedRect(x + w * 0.075, y + h * 0.075, w * 0.85, h * 0.85, emote.material, a)
	end
end

local ge_GetPackage = gemotions.GetPackage
local ge_GetEmote = gemotions.GetEmote
local ge_DrawEmote = gemotions.DrawEmote
local ge_DrawEmoteQuad = gemotions.DrawEmoteQuad

--------------------------------------------------------------------------------------
-- Panel Open/Close
--------------------------------------------------------------------------------------

do
	local keyDefault = KEY_T

	local bind = CreateClientConVar("gemotions_open", tostring(keyDefault))
	gemotions.bind = bind

	if IsValid(gemotions.base) then
		gemotions.base:Remove()
	end

	hook.Add("PlayerButtonDown", "gemotions", function(ply, key)
		if (key == bind:GetInt()) then
			if not IsValid(gemotions.base) then
				gemotions.base = vgui.Create("gemotions")
			end	
			gemotions.base:Show()
		end
	end)

	hook.Add("PlayerButtonUp", "gemotions", function(ply, key)
		if (key == bind:GetInt()) then
			if not IsValid(gemotions.base) then
				gemotions.base = vgui.Create("gemotions")
			end
			gemotions.base:Hide()
		end
	end)
end

--------------------------------------------------------------------------------------
-- Net Receive
--------------------------------------------------------------------------------------

do
	gemotions.drawQueue = {}

	local soundDefault = "gemotions/ui/bong.ogg"

	net.Receive("gemotions", function()
		local selectedPackage = net.ReadUInt(7)
		local selectedEmote = net.ReadUInt(7)
		local ply = net.ReadEntity()

		local package = ge_GetPackage(selectedPackage)
		if (package == nil) then
			return
		end

		local emote = ge_GetEmote(selectedPackage, selectedEmote)
		if (emote == nil) then
			return
		end

		ply:EmitSound(emote.sound or soundDefault, 75, 100, 1)

		gemotions.drawQueue[ply] = {
			emote = emote,
			time = RealTime()
		}
	end)
end

--------------------------------------------------------------------------------------
-- PostDrawTranslucentRenderables
--------------------------------------------------------------------------------------

do
	local ipairs, player_GetAll = ipairs, player.GetAll
	local drawQueue = gemotions.drawQueue

	local abs, InOutBack = math.abs, math.ease.InOutBack
	local Lerp, RealFrameTime = Lerp, RealFrameTime

	local cam_Start3D2D, cam_End3D2D = cam.Start3D2D, cam.End3D2D

	hook.Add("PostDrawTranslucentRenderables", "gemotions", function()
		for i, ply in ipairs(player_GetAll()) do
			if (ply == LocalPlayer() and not ply:ShouldDrawLocalPlayer()) then
				continue
			end

			local data = drawQueue[ply]
			if (data == nil) then 
				continue
			end

			local time = RealTime() - data.time

			if (time >= 5) then
				drawQueue[ply] = nil
				continue
			end

			local pos, head = ply:GetShootPos(), ply:LookupBone("ValveBiped.Bip01_Head1")
			if (head ~= nil) then
				local headpos = ply:GetBonePosition(head)
				pos = headpos == ply:GetPos() and pos or headpos
			end
			pos.z = pos.z + 10

			local angle = (pos - EyePos()):Angle()
			angle.yaw, angle.roll = angle.yaw - 90, 90

			local pingpong = abs((time * 2) % 2 - 1)
			angle.pitch = (InOutBack(pingpong) - 0.5) * 15

			local emoteScale = Lerp(RealFrameTime() * 8, data.scale or 0, time < 2.5 and 0.44 or 0)
			data.scale = emoteScale
			
			cam_Start3D2D(pos, angle, emoteScale)
				ge_DrawEmote(data.emote, -16, -38, 32, 38)
			cam_End3D2D()
		end
	end)
end

--------------------------------------------------------------------------------------
-- HUDPaint
--------------------------------------------------------------------------------------

do
	local drawQueue = gemotions.drawQueue

	local abs, InOutBack = math.abs, math.ease.InOutBack
	local Lerp, RealFrameTime = Lerp, RealFrameTime

	local matrix = Matrix()
	local mat_Translate, mat_Rotate, mat_Scale = matrix.Translate, matrix.Rotate, matrix.Scale

	local m_vec, m_ang = Vector(0, 0, 0), Angle(0, 0, 0)
	local vec_SetUnpacked = m_vec.SetUnpacked
	local ang_SetUnpacked = m_ang.SetUnpacked
	
	local cam_PushModelMatrix, cam_PopModelMatrix = cam.PushModelMatrix, cam.PopModelMatrix

	hook.Add("HUDPaint", "gemotions", function()
		local ply = LocalPlayer()
		if ply:ShouldDrawLocalPlayer() then 
			return 
		end

		local data = drawQueue[ply]
		if (data == nil) then 
			return 
		end

		local time = RealTime() - data.time

		if (time >= 5) then
			drawQueue[ply] = nil
			return
		end

		local pingpong = abs((time * 2) % 2 - 1)
		local yaw = (InOutBack(pingpong) - 0.5) * 15

		local m = Matrix()
		local w_half, h = ScrW() / 2, ScrH()

		local scale = Lerp(RealFrameTime() * 8, data.scale or 0, time < 2.5 and 0.44 or 0)
		data.scale = scale

		vec_SetUnpacked(m_vec, w_half, 222, 0); mat_Translate(m, m_vec);
		ang_SetUnpacked(m_ang, 0, yaw, 0); mat_Rotate(m, m_ang)
		vec_SetUnpacked(m_vec, scale, scale, 0); mat_Scale(m, m_vec)
		vec_SetUnpacked(m_vec, -w_half, 0, 0); mat_Translate(m, m_vec)

		cam_PushModelMatrix(m)
			ge_DrawEmote(data.emote, w_half - 160, -380, 320, 380)
		cam_PopModelMatrix()
	end)
end

--------------------------------------------------------------------------------------
-- Include Packages
--------------------------------------------------------------------------------------

do
	for k, v in ipairs(file.Find("gemotions/*", "LUA")) do
		include(string.format("gemotions/%s", v))
	end
end

--[[
			           __                                                __       
			          |  \                                              |  \      
			  ______  | $$____    _______   ______    _______   ______  | $$   __ 
			 |      \ | $$    \  /       \ /      \  /       \ |      \ | $$  /  \
			  \$$$$$$\| $$$$$$$\|  $$$$$$$|  $$$$$$\|  $$$$$$$  \$$$$$$\| $$_/  $$
			 /      $$| $$  | $$ \$$    \ | $$  | $$ \$$    \  /      $$| $$   $$ 
			|  $$$$$$$| $$__/ $$ _\$$$$$$\| $$__/ $$ _\$$$$$$\|  $$$$$$$| $$$$$$\ 
			 \$$    $$| $$    $$|       $$ \$$    $$|       $$ \$$    $$| $$  \$$\
			  \$$$$$$$ \$$$$$$$  \$$$$$$$   \$$$$$$  \$$$$$$$   \$$$$$$$ \$$   \$$            

]]--