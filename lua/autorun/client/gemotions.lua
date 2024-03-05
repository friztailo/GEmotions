gemotions = gemotions or {}

gemotions.emotions = {}
gemotions.packages = {}
gemotions.packagesCount = 0

do -- RegisterPackage
	local insert = table.insert

	function gemotions.RegisterPackage(name, title, data)
		if not gemotions.emotions[name] then
			gemotions.emotions[name] = {
				title = title
			}
			insert(gemotions.packages, name)
		end

		for i, k in ipairs(data) do
			local mat, snd = k[1], k[2]

			insert(gemotions.emotions[name], {
				material = Material(mat), 
				sound = snd
			})
		end
	end
end

gemotions.GetPackage = function(id) -- GetPackage
	return gemotions.emotions[gemotions.packages[id]]
end

do -- Draw
	local basis = Material("gemotions/base.png")
	local basisSelect = Material("gemotions/base_select.png")

	local mesh_Begin, mesh_Color, mesh_Position, mesh_TexCoord, mesh_AdvanceVertex, mesh_End, render_SetMaterial =
		mesh.Begin, mesh.Color, mesh.Position, mesh.TexCoord, mesh.AdvanceVertex, mesh.End, render.SetMaterial
	local vec_SetUnpacked = getmetatable(Vector(0, 0, 0)).SetUnpacked

	local quad_v1, quad_v2, quad_v3, quad_v4 = Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0)
	local makeQuad = function(x, y, w, h)
		local right, bot = x + w, y + h
		vec_SetUnpacked(quad_v1, x, y, 0)
		vec_SetUnpacked(quad_v2, right, y, 0)
		vec_SetUnpacked(quad_v3, right, bot, 0)
		vec_SetUnpacked(quad_v4, x, bot, 0)
	end

	local drawTexturedRect = function(x, y, w, h, mat)
		makeQuad(x, y, w, h)
		render_SetMaterial(mat)
		mesh_Begin(7, 1)
				mesh_Position(quad_v1)
				mesh_Color(255, 255, 255, 255)
				mesh_TexCoord(0, 0, 0)
			mesh_AdvanceVertex()
				mesh_Position(quad_v2)
				mesh_Color(255, 255, 255, 255)
				mesh_TexCoord(0, 1, 0)
			mesh_AdvanceVertex()
				mesh_Position(quad_v3)
				mesh_Color(255, 255, 255, 255)
				mesh_TexCoord(0, 1, 1)
			mesh_AdvanceVertex()
				mesh_Position(quad_v4)
				mesh_Color(255, 255, 255, 255)
				mesh_TexCoord(0, 0, 1)
			mesh_AdvanceVertex()
		mesh_End()
	end

	gemotions.Draw = function(package, id, x, y, w, h, selectBox)
		drawTexturedRect(x, y, w, selectBox and w or h, selectBox and basisSelect or basis)
		drawTexturedRect(x + w * 0.075, y + w * 0.075, w * 0.85, w * 0.85, package[id].material)
	end
end

do -- Loading Packages
	for k, v in ipairs(file.Find("gemotions/*", "LUA")) do
		include(string.format("gemotions/%s", v))
		gemotions.packagesCount = gemotions.packagesCount + 1
	end
end

-----------------------------------------------------------------------------------------------

local PANEL = {}

function PANEL:Init() -- Init
    self:SetSize(ScrW(), ScrH())
	self:SetAlpha(0)
	self:Show()

	self.selectedPackage = 1
	self.selectedEmote = nil
end

function PANEL:GetSelectedPackage()
	return gemotions.GetPackage(self.selectedPackage)
end

function PANEL:GetSelectedEmote()
	local package = self:GetSelectedPackage()
	return package and package[self.selectedEmote] or nil
end

do -- OnCursorMoved
	local pi = math.pi
	local ScrW, ScrH = ScrW, ScrH
	local sqrt = math.sqrt
	local acos = math.acos
	local round = math.Round

	function PANEL:OnCursorMoved(x, y)
		local package = self:GetSelectedPackage()
		if package == nil then return end

		local packageCount = #package
		local packageStep = 2 * pi / packageCount

		local x, y = x - ScrW() / 2, y - ScrH() / 2
		local length = sqrt(x ^ 2 + y ^ 2)

		if (length > 64) then
			local angle = acos(x / length)
			if (y < 0) then
				angle = 2 * pi - angle
			end

			local selected = round(angle / packageStep) % packageCount + 1

			if selected ~= self.selectedEmote then
				surface.PlaySound("gemotions/ui/switch.ogg")
			end
			
			self.selectedEmote = selected
		else
			self.selectedEmote = nil
		end
	end
end

function PANEL:OnMouseWheeled(delta) -- OnMouseWheeled
	if (gemotions.packagesCount < 2) then return end 

	self.selectedPackage = (self.selectedPackage - delta - 1) % gemotions.packagesCount + 1
	self.selectedEmote = nil

	surface.PlaySound("gemotions/ui/rollover.ogg")
end

do
	local animDuration = 0.12

	function PANEL:Show() -- Show
		local emote = self:GetSelectedEmote()
		if emote then
			emote.scale = 1
		end

		self.selectedEmote = nil
		self:SetVisible(true)
		self:Stop()
		self:AlphaTo(255, animDuration)
		self:SetMouseInputEnabled(true)
	end

	function PANEL:Hide() -- Hide
		self:Stop()
		self:AlphaTo(0, animDuration, nil, function()
			self:SetVisible(false)
			self:SetMouseInputEnabled(false)
		end)
	end
end

do -- Panel Paint
	local DrawBlur
	do -- DrawBlur
		local blur = Material("pp/blurscreen")
		local bFloat = "$blur"
		local bSetFloat = blur.SetFloat
		local bRecompute = blur.Recompute

		local render_UpdateScreenEffectTexture = render.UpdateScreenEffectTexture
		local surface_SetMaterial = surface.SetMaterial
		local surface_SetDrawColor = surface.SetDrawColor
		local surface_DrawTexturedRect = surface.DrawTexturedRect
		local surface_DrawRect = surface.DrawRect

		DrawBlur = function(self, w, h)
			bSetFloat(blur, bFloat, self:GetAlpha() / 64)
			bRecompute(blur)

			render_UpdateScreenEffectTexture()
			surface_SetMaterial(blur)
			surface_SetDrawColor(255, 255, 255, 255)
			surface_DrawTexturedRect(0, 0, w, h)

			surface_SetDrawColor(32, 32, 32, 240)
			surface_DrawRect(0, 0, w, h)
		end
	end

	local pi = math.pi
	local max = math.max
	local cos, sin = math.cos, math.sin

	surface.CreateFont("gemotions_small", {
		font = "Roboto",
		size = 16,
		extended = true,
	})

	surface.CreateFont("gemotions_medium", {
		font = "Roboto",
		size = 24,
		extended = true,
	})

	function PANEL:Paint(w, h)
		local w_half, h_half = w / 2, h / 2

		-- Background Blur
		DrawBlur(self, w, h)

		-- Package
		local package = self:GetSelectedPackage()
		local packageCount = #package
		local packageStep = 2 * pi / packageCount
		local packageRadius = max(112, (64 * packageCount) / (2 * pi))
		local packageTitle = package.title

		-- Draw Circle
		surface.DrawCircle(w_half, h_half, 64, 128, 128, 128, 32)

		-- Draw Emotions
		for id = 1, packageCount do
			local emote = package[id]

			local rad = (id - 1) * packageStep
			local emoteCos = cos(rad)
			local emoteSin = sin(rad)

			local emoteScale = Lerp(RealFrameTime() * 12, emote.scale or 1, (id == self.selectedEmote) and 2 or 1)
			emote.scale = emoteScale

			do
				local w = 32 * emoteScale
				local h = 32 * emoteScale
				local x = w_half + emoteCos * packageRadius - w / 2
				local y = h_half + emoteSin * packageRadius - h / 2

				gemotions.Draw(package, id, x, y, w, h, true)
			end
		end

		-- Draw Package
		if (gemotions.packagesCount > 1) then
			local _,sh =
			draw.SimpleText(string.format("%d/%d", self.selectedPackage, gemotions.packagesCount), "gemotions_small", w/2, h*0.98, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			draw.SimpleText(packageTitle, "gemotions_medium", w/2, h*0.98 - sh, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		else
			draw.SimpleText(packageTitle, "gemotions_medium", w/2, h*0.975, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end
	end
end

vgui.Register("gemotions", PANEL, "DPanel")

-----------------------------------------------------------------------------------------------

local Bind = CreateClientConVar("gemotions_open", tostring(KEY_T))

if IsValid(gemotions.panel) then
	gemotions.panel:Remove()
end

hook.Add("PlayerButtonDown", "gemotions", function(ply, key) -- Open
	if key == Bind:GetInt() then
		local panel = gemotions.panel
		if IsValid(panel) then
			panel:Show()
		else
			gemotions.panel = vgui.Create("gemotions")
		end
		gui.EnableScreenClicker(true)
	end
end)

hook.Add("PlayerButtonUp", "gemotions", function(ply, key) -- Close
	if key == Bind:GetInt() then
		local panel = gemotions.panel
		if IsValid(panel) then
			panel:Hide()
			CloseDermaMenus()
			gui.EnableScreenClicker(false)

            local selected = panel.selectedEmote
			if not selected then return end

			net.Start("gemotions") -- Net
			    net.WriteUInt(selected, 7) -- EMOTE ID
				net.WriteUInt(panel.selectedPackage, 7) -- PACKAGE ID
			net.SendToServer()
		end
	end
end)

-----------------------------------------------------------------------------------------------

local gemotionsDraw = {}

net.Receive("gemotions", function() -- Receive
	local selected, package, ply = net.ReadUInt(7), net.ReadUInt(7), net.ReadEntity()
	local packtbl = gemotions.GetPackage(package)

	if packtbl and packtbl[selected] then
        ply:EmitSound(packtbl[selected].sound
			or "gemotions/ui/bong.ogg", 75, 100, 1)

		gemotionsDraw[ply] = {
			selected = selected,
			package = packtbl,
			scale = 0,
			time = RealTime(),	
		}
    end
end)

-----------------------------------------------------------------------------------------------

hook.Add("PostDrawTranslucentRenderables", "gemotions", function() -- PostDrawTranslucentRenderables
	for i, ply in ipairs(player.GetAll()) do
		if ply == LocalPlayer() and not ply:ShouldDrawLocalPlayer() then return end

		local data = gemotionsDraw[ply]
		if not data then return end

		local time = RealTime() - data.time

		if time >= 5 then
			gemotionsDraw[ply] = nil
		else
			local pos = ply:GetShootPos()
			local head = ply:LookupBone("ValveBiped.Bip01_Head1")
			if head then
				local headpos = ply:GetBonePosition(head)
				pos = headpos == ply:GetPos() and pos or headpos
			end
			pos.z = pos.z + 10

			local angle = (pos - EyePos()):Angle()
			angle.yaw, angle.roll = angle.yaw - 90, 90

			local pingpong = math.abs((time * 2) % 2 - 1)
			angle.pitch = (math.ease.InOutBack(pingpong) - 0.5) * 15

			local scale = Lerp(RealFrameTime() * 8, data.scale, time < 2.5 and 0.44 or 0)
			data.scale = scale
			
			cam.Start3D2D(pos, angle, scale or data.scale)
				gemotions.Draw(data.package, data.selected, -16, -38, 32, 38)
			cam.End3D2D()
		end
	end
end)

do
	local m_vec, m_ang = Vector(0, 0, 0), Angle(0, 0, 0)
	local vec_SetUnpacked = m_vec.SetUnpacked

	local matrix = Matrix()
	local mat_Translate = matrix.Translate
	local mat_Rotate = matrix.Rotate
	local mat_Scale = matrix.Scale

	local Matrix = Matrix
	local ScrW, ScrH = ScrW, ScrH
	local abs, InOutBack = math.abs, math.ease.InOutBack

	hook.Add("HUDPaint", "gemotions", function() -- HUDPaint
		local ply = LocalPlayer()
		if ply:ShouldDrawLocalPlayer() then return end

		local data = gemotionsDraw[ply]
		if not data then return end

		local time = RealTime() - data.time

		if time >= 5 then
			gemotionsDraw[ply] = nil
		else
			local pingpong = abs((time * 2) % 2 - 1)
			local yaw = (InOutBack(pingpong) - 0.5) * 15

			local m = Matrix()
			local w, h = ScrW(), ScrH()

			vec_SetUnpacked(m_vec, w / 2, h / (w/h*1.125*2), 0)
			mat_Translate(m, m_vec)

			m_ang.yaw = yaw
			mat_Rotate(m, m_ang)

			local scale = Lerp(RealFrameTime() * 8, data.scale, time < 2.5 and 0.44 or 0)
			data.scale = scale

			vec_SetUnpacked(m_vec, scale, scale, scale)
			mat_Scale(m, m_vec)

			vec_SetUnpacked(m_vec, -w / 2, -h / (w/h*1.125), 0)
			mat_Translate(m, m_vec)

			cam.PushModelMatrix(m)
				gemotions.Draw(data.package, data.selected, w / 2 - 160, 38, 320, 380)
			cam.PopModelMatrix()
		end
	end)
end

-----------------------------------------------------------------------------------------------

local function BuildPanel(Panel) -- Utilites
	Panel.EmotionsText = vgui.Create("DLabel")
	Panel.EmotionsText:SetColor(Color(110, 110, 110))
	Panel.EmotionsText:SetText("Open")
	Panel.EmotionsText:SizeToContents()
	Panel:AddItem(Panel.EmotionsText)

	Panel.Emotionsbinder = vgui.Create("DBinder")
	Panel.Emotionsbinder:SetSelectedNumber(Bind:GetInt())
	function Panel.Emotionsbinder:OnChange(num)
		Bind:SetInt(num)
	end
	Panel:AddItem(Panel.Emotionsbinder)
end

hook.Add("PopulateToolMenu", "Emotions_PopulateToolMenu", function()
	spawnmenu.AddToolMenuOption("Utilities", "User", "GEmotions", "GEmotions", "", "", BuildPanel)
end)

-----------------------------------------------------------------------------------------------

--[[
		⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⢤⣚⣟⠿⠯⠿⠷⣖⣤⠤⣀⠀⠀⠀⠀⠀⠀⠀
		⠀⠀⠀⠀⠀⠀⠀⢀⡠⡲⠟⠛⠉⠉⠀⠀⠀⠀⠀⠀⠀⠉⠓⠽⣢⣀⠀⠀⠀⠀
		⠀⠀⠀⠀⠀⣠⣔⠝⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠤⣤⣤⡈⠹⣧⡄⠀⠀
		⠀⠀⠀⢀⣴⠝⠁⠀⠀⠀⣴⣖⣚⣛⠽⠆⢀⠀⠀⠀⠙⠉⠉⠛⠁⠀⠈⢞⢆⠀
		⠀⠀⢠⣻⠋⠀⠀⠀⠀⠀⠙⠋⠉⠀⠀⠀⠈⢣⠀⠈⡆⠀⠀⠀⠀⠀⠀⠀⢫⠆
		⠀⢰⣳⣣⠔⠉⢱⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢇⠘⠀⠀⢀⣤⣶⣶⣶⣶⣾⣗
		⢠⢯⠋⠀⠠⡴⠋⠙⠢⡄⠀⣠⡤⢔⣶⣶⣶⣶⣼⣤⣴⣾⡿⠋⢁⣤⣤⣽⣿⡏
		⢸⣸⠀⠒⢻⣧⣶⣤⣴⣗⡏⠁⠀⠀⠀⠀⠀⠈⢻⣿⣿⣿⣠⣿⣿⣿⣿⣿⣿⠁
		⣸⡏⠀⠘⠃⡿⢟⠇⢀⡿⣧⡄⠀⠀⠀⠀⠀⠀⣠⣿⠻⣿⣿⣿⣿⣿⣿⣿⠋⠀
		⣷⠃⠀⠀⡇⡇⠀⣱⠞⠁⠸⣿⣦⡀⠀⠀⠀⠀⣸⠏⠀⠙⠻⢿⢿⣿⡟⠋⠀⢀
		⢻⠀⠀⠀⣇⠴⠚⠁⠀⠀⠀⠈⠛⠿⢿⠤⠴⠚⠁⠀⣀⣠⠤⢔⡿⡟⠀⠀⠀⢸
		⣇⣘⡓⣺⡿⠀⠀⢠⠶⠒⢶⣲⡒⠒⠒⠒⠒⣛⣉⡩⠤⠖⠚⢁⡝⢠⡄⠀⢀⠦
		⠙⢶⢏⠁⠀⠀⠀⠀⠀⠀⠀⠈⠙⠿⣟⡛⠉⠀⠀⠀⠀⢀⡤⠊⢀⡜⢀⡼⡸⠏
		⠀⠀⢯⣦⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀⠀⠉⠉⠓⠒⠚⠉⠁⠀⣠⠎⢠⡾⡽⠁⠀
		⠀⠀⠈⠪⣵⠀⠀⠀⠀⠀⠀⠀⠀⠉⠳⠶⣤⣤⣤⣤⣤⡶⠟⣅⣴⣏⠏⠀⠀⠀
		⠀⠀⠀⠀⠉⢳⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣴⡯⠋⠁⠀⠀⠀⠀
		⠀⠀⠀⠀⠀⠀⠀⠉⠢⣤⣄⣀⠀⠀⠀⠀⠀⠀⢀⣀⠮⠓⠉⠀⠀⠀⠀⠀⠀⠀
		⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠈⠛⠓⠂⠀⠂⠁⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
		
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