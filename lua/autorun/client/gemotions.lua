--[[
	░▒▓████████▓▒░▒▓███████▓▒░░▒▓█▓▒░       ░▒▓██████▓▒░░▒▓███████▓▒░  
	░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
	░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
	░▒▓██████▓▒░ ░▒▓███████▓▒░░▒▓█▓▒░      ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░ 
	░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
	░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
	░▒▓████████▓▒░▒▓███████▓▒░░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
]]--

gemotions = gemotions or {}

gemotions.emotions = {}
gemotions.packages = {}

do
	function gemotions.RegisterPackage(package, title, data)
		if not gemotions.emotions[package] then
			gemotions.emotions[package] = {
				title = title
			}
			table.insert(gemotions.packages, package)
		end

		for i, k in ipairs(data) do
			local mat, snd = k[1], k[2]

			table.insert(gemotions.emotions[package], {
				material = Material(mat), 
				sound = snd
			})
		end
	end
end

do 
	gemotions.GetPack = function(id)
		return gemotions.emotions[gemotions.packages[id]]
	end
end

do
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
	end
end

-----------------------------------------------------------------------------------------------

local PANEL = {}

local blur = Material("pp/blurscreen")

function PANEL:GetSelectedPackage()
	return gemotions.GetPack(self.selectedPack)
end

function PANEL:Init() -- Init
    self:SetSize(ScrW(), ScrH())
	self:SetAlpha(0)
	self:Show()

	self.selectedPack = 1
end

function PANEL:OnCursorMoved(x, y)
    local x, y = x - ScrW() / 2, y - ScrH() / 2
    local length = math.sqrt(x ^ 2 + y ^ 2)

	local emotions = self:GetSelectedPackage()
	local step = 2 * math.pi / #emotions

	if length > 64 then
		local angle = y >= 0 and math.acos(x / length) or math.pi + math.acos(-x / length)

		local selected = math.Round(angle / step) % #emotions + 1
	
		if selected ~= self.emotionSelected then
			surface.PlaySound("gemotions/ui/switch.ogg")
		end
		
		self.emotionSelected = selected

	else
		self.emotionSelected = nil
	end
end

function PANEL:OnMouseWheeled(delta)
	if (#gemotions.packages < 2) then return end 

	self.selectedPack = (self.selectedPack - delta - 1) % #gemotions.packages + 1
	self.emotionSelected = nil

	surface.PlaySound("gemotions/ui/rollover.ogg")
end

function PANEL:Show() -- Show
	if self.emotionSelected then
		self:GetSelectedPackage()[self.emotionSelected].scale = 1
		self.emotionSelected = nil
	end

	self:SetVisible(true)
	self:Stop()
	self:AlphaTo(255, 0.1)
	self:SetMouseInputEnabled(true)
end

function PANEL:Hide() -- Hide
	self:Stop()
	self:AlphaTo(0, 0.1, nil, function()
		self:SetVisible(false)
		self:SetMouseInputEnabled(false)
	end)
end

function PANEL:Paint(w, h)
    -- Blur
    blur:SetFloat("$blur", self:GetAlpha() / 64)
	blur:Recompute()

	render.UpdateScreenEffectTexture()
	surface.SetMaterial(blur)
	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawTexturedRect(0, 0, w, h)

	surface.SetDrawColor(32, 32, 32, 240)
	surface.DrawRect(0, 0, w, h)

	-- Cifri snizu
	local package = self:GetSelectedPackage()

	-- if (#gemotions.packages > 1) then
		local _, sh = draw.SimpleText( string.format("%d/%d", self.selectedPack, #gemotions.packages), "HudDefault", w/2, h*0.975, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		draw.SimpleText( package.title, "HudDefault", w/2, h*0.975 - sh, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	-- end

	-- Draw Circle
	surface.DrawCircle(w / 2, h / 2, 64, 128, 128, 128, 32)

    -- Draw Emotions
	local count = #package
	local radius = math.max(112, (64 * count) / (2 * math.pi))

    for i = 1, count do
		local k = package[i]
		local step = 2 * math.pi / count
		local rad = (i - 1) * step

        local cos, sin = math.cos(rad), math.sin(rad)	

        local scale = Lerp(RealFrameTime() * 12, k.scale or 1, i == self.emotionSelected and 2 or 1)
		k.scale = scale

        local _w = 32 * scale
        local _h = 32 * scale
        local x = w / 2 + cos * radius - _w / 2
        local y = h / 2 + sin * radius - _h / 2

        gemotions.Draw(package, i, x, y, _w, _h, true)
    end
	
end

vgui.Register("gemotions", PANEL, "DPanel")

--[[

 /$$       /$$$$$$ /$$    /$$ /$$$$$$ /$$        /$$$$$$  /$$   /$$ /$$$$$$$$ /$$$$$$$   
| $$      |_  $$_/| $$   | $$|_  $$_/| $$       /$$__  $$| $$$ | $$|__  $$__/| $$__  $$  
| $$        | $$  | $$   | $$  | $$  | $$      | $$  \ $$| $$$$| $$   | $$   | $$  \ $$  
| $$        | $$  |  $$ / $$/  | $$  | $$      | $$$$$$$$| $$ $$ $$   | $$   | $$$$$$$/  
| $$        | $$   \  $$ $$/   | $$  | $$      | $$__  $$| $$  $$$$   | $$   | $$__  $$  
| $$        | $$    \  $$$/    | $$  | $$      | $$  | $$| $$\  $$$   | $$   | $$  \ $$  
| $$$$$$$$ /$$$$$$   \  $/    /$$$$$$| $$$$$$$$| $$  | $$| $$ \  $$   | $$   | $$  | $$  
|________/|______/    \_/    |______/|________/|__/  |__/|__/  \__/   |__/   |__/  |__/  
                                                                                         
                                                                                         
                                                                                         
                                                                                         
										    /$$                                                                                  
										   | $$                                                                                  
										 /$$$$$$$$                                                                               
										|__  $$__/                                                                               
										   | $$                                                                                  
										   |__/                                                                                  
                                                                                         
                                                                                         
                                                                                         
                                                                                         
 /$$$$$$$  /$$$$$$$  /$$$$$$  /$$$$$$  /$$$$$$$$ /$$$$$$  /$$     /$$ /$$        /$$$$$$ 
| $$__  $$| $$__  $$|_  $$_/ /$$__  $$|__  $$__//$$__  $$|  $$   /$$/| $$       /$$__  $$
| $$  \ $$| $$  \ $$  | $$  | $$  \__/   | $$  | $$  \ $$ \  $$ /$$/ | $$      | $$  \ $$
| $$  | $$| $$$$$$$/  | $$  |  $$$$$$    | $$  | $$$$$$$$  \  $$$$/  | $$      | $$  | $$
| $$  | $$| $$__  $$  | $$   \____  $$   | $$  | $$__  $$   \  $$/   | $$      | $$  | $$
| $$  | $$| $$  \ $$  | $$   /$$  \ $$   | $$  | $$  | $$    | $$    | $$      | $$  | $$
| $$$$$$$/| $$  | $$ /$$$$$$|  $$$$$$/   | $$  | $$  | $$    | $$    | $$$$$$$$|  $$$$$$/
|_______/ |__/  |__/|______/ \______/    |__/  |__/  |__/    |__/    |________/ \______/ 
                                                                                         
                                                                                                                           
]]--

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

            local selected = panel.emotionSelected
			if not selected then return end

			net.Start("gemotions") -- Net
			    net.WriteUInt(selected, 7)
				net.WriteUInt(panel.selectedPack,7)
			net.SendToServer()
		end
	end
end)

-----------------------------------------------------------------------------------------------

gemotions.draw = {}
gemotions.huddraw = false

net.Receive("gemotions", function() -- Receive
	local selected, package, ply = net.ReadUInt(7), net.ReadUInt(7), net.ReadEntity()

	local packtbl = gemotions.GetPack(package)

	if not packtbl then
		return
	end

	if not packtbl[selected] then
        return
    end

	ply:EmitSound(packtbl[selected].sound
		or "gemotions/ui/bong.ogg", 75, 100, 1)

    if ply == LocalPlayer() then
        gemotions.huddraw = true
    end

	gemotions.draw[ply] = {
        time = RealTime(),	
        scale = 0,
		selected = selected,
		package = packtbl
	}
end)

-----------------------------------------------------------------------------------------------

local m_vec, m_ang = Vector(0, 0, 0), Angle(0, 0, 0)
local vec_SetUnpacked = m_vec.SetUnpacked

hook.Add("PostPlayerDraw", "gemotions", function(ply, studio) -- PostPlayerDraw
	local data = gemotions.draw[ply]
	if not data then return end

	local time = RealTime() - data.time

	if time >= 5 then
		gemotions.draw[ply] = nil
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

		if ply == LocalPlayer() then
			gemotions.huddraw = false
		end
	end
end)

hook.Add("HUDPaint", "gemotions", function() -- HUDPaint
    local ply = LocalPlayer()

	local data = gemotions.draw[ply]
	if not data then return end

	if not gemotions.huddraw then
		gemotions.huddraw = true
		return
	end

	local time = RealTime() - data.time

	if time >= 5 then
		gemotions.huddraw = false
		gemotions.draw[ply] = nil
	else
		local pingpong = math.abs((time * 2) % 2 - 1)
		local yaw = (math.ease.InOutBack(pingpong) - 0.5) * 15

		local m = Matrix()
		local w, h = ScrW(), ScrH()

		vec_SetUnpacked(m_vec, w / 2, h / (w/h*1.125*2), 0)
		m:Translate(m_vec)

		m_ang.yaw = yaw
		m:Rotate(m_ang)

		local scale = Lerp(RealFrameTime() * 8, data.scale, time < 2.5 and 0.44 or 0)
		data.scale = scale

		vec_SetUnpacked(m_vec, scale, scale, scale)
		m:Scale(m_vec)

		vec_SetUnpacked(m_vec, -w / 2, -h / (w/h*1.125), 0)
		m:Translate(m_vec)

		cam.PushModelMatrix(m)
            gemotions.Draw(data.package, data.selected, w / 2 - 160, 38, 320, 380)
		cam.PopModelMatrix()
	end
end)

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