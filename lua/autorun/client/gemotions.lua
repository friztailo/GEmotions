--[[
	Страницы сделаны
	Я бы код чучуть перебрал, а то у меня переменные ваще по уебски называтся (стрк 55)
]]--
-----------------------------------------------------------------------------------------------
gemotions = gemotions or {}

gemotions.emotions = {}
gemotions.emotionsPages = {}

function gemotions.RegisterEmote(page, _material, _sound)
	table.insert(gemotions.emotions, {
		material = Material(_material), 
		sound = _sound
	})

	if not gemotions.emotionsPages[page] then
		gemotions.emotionsPages[page] = {}
	end

	table.insert(gemotions.emotionsPages[page], #gemotions.emotions)
end

-- Including config.
include("gemotions/config.lua")

do
	local basis = Material("gemotions/base.png")
	local basisSelect = Material("gemotions/base_select.png")	

	local surface_SetDrawColor = surface.SetDrawColor
	local surface_SetMaterial = surface.SetMaterial
	local surface_DrawTexturedRect = surface.DrawTexturedRect

	gemotions.Draw = function(id, x, y, w, h, selectBox)
		surface_SetDrawColor(255, 255, 255, 255)
		surface_SetMaterial(selectBox and basisSelect or basis)
		surface_DrawTexturedRect(x, y, w, selectBox and w or h)
		surface_SetMaterial(gemotions.emotions[id].material)
		surface_DrawTexturedRect(x + w * 0.075, y + w * 0.075, w * 0.85, w * 0.85)
	end
end

-----------------------------------------------------------------------------------------------

local PANEL = {}

local blur = Material("pp/blurscreen")

function PANEL:Init() -- Init
    self:SetSize(ScrW(), ScrH())
	self:SetAlpha(0)
	self:Show()

    do
		self.emotions = {}
		self.emotionsPage = 1
		self.emotionsPages = #gemotions.emotionsPages

		for p = 1, self.emotionsPages do
			self.emotions[p] = {}

			local page = gemotions.emotionsPages[p]
			local count = #page
			local step = 2 * math.pi / count

			for i, k in ipairs(page) do
				local rad = (i - 1) * step
				table.insert(self.emotions[p], {
					cos = math.cos(rad),
					sin = math.sin(rad),
					scale = 1
				})
			end

			self.emotions[p].radius = math.max(112, (64 * count) / (2 * math.pi))
			self.emotions[p].count = count
			self.emotions[p].step = step
		end
	end
end

function PANEL:OnCursorMoved(x, y)
    local x, y = x - ScrW() / 2, y - ScrH() / 2
    local length = math.sqrt(x ^ 2 + y ^ 2)

    if length > 64 then
        local angle = y >= 0 and math.acos(x / length) or math.pi + math.acos(-x / length)

		local emotions = self.emotions[self.emotionsPage]
        local selected = math.Round(angle / emotions.step) % emotions.count + 1

		if selected ~= self.emotionsSelected then
			surface.PlaySound("gemotions/ui/switch.ogg")
		end
		
		self.emotionsSelected = selected
    else
        self.emotionsSelected = nil
    end
end

function PANEL:OnMouseWheeled(delta)
	local emotions = self.emotions
	self.emotionsPage = (self.emotionsPage - delta - 1) % self.emotionsPages + 1
	self.emotionsSelected = nil
end

function PANEL:Show() -- Show
	if self.emotionsSelected then
		local k = self.emotions[self.emotionsPage][self.emotionsSelected]
		k.scale = 1
		self.emotionsSelected = nil
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

	-- Draw Circle
	surface.DrawCircle(w / 2, h / 2, 64, 128, 128, 128, 32)

    -- Draw Emotions
	local emotions = self.emotions[self.emotionsPage]
	local radius = emotions.radius

    for i = 1, emotions.count do
		local k = emotions[i]
        local cos, sin = k.cos, k.sin

        local scale = Lerp(RealFrameTime() * 12, k.scale,
            i == self.emotionsSelected and 2 or 1)
        k.scale = scale

        local _w = 32 * scale
        local _h = 32 * scale
        local x = w / 2 + cos * radius - _w / 2
        local y = h / 2 + sin * radius - _h / 2

        gemotions.Draw(gemotions.emotionsPages[self.emotionsPage][i], x, y, _w, _h, true)
    end
end

vgui.Register("gemotions", PANEL, "DPanel")

-----------------------------------------------------------------------------------------------

local Bind = CreateClientConVar("gemotions_open", tostring(KEY_J))

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

            local selected = panel.emotionsSelected
			if not selected then return end

			net.Start("gemotions") -- Net
			PrintTable(gemotions.emotionsPages)
			    net.WriteUInt(gemotions.emotionsPages[panel.emotionsPage][selected], 7)
			net.SendToServer()
		end
	end
end)

-----------------------------------------------------------------------------------------------

gemotions.draw = {}
gemotions.huddraw = false

net.Receive("gemotions", function() -- Receive
	local selected, ply = net.ReadUInt(7), net.ReadEntity()

	ply:EmitSound(gemotions.emotions[selected].sound
		or "gemotions/ui/bong.ogg", 75, 100, 1)

	if not gemotions.emotions[selected] then
        return
    end

    if ply == LocalPlayer() then
        gemotions.huddraw = true
    end

	gemotions.draw[ply] = {
        time = RealTime(),	
        scale = 0,
		selected = selected,
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
            gemotions.Draw(data.selected, -16, -38, 32, 38)
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

		vec_SetUnpacked(m_vec, w / 2, h / 4, 0)
		m:Translate(m_vec)

		m_ang.yaw = yaw
		m:Rotate(m_ang)

		local scale = Lerp(RealFrameTime() * 8, data.scale, time < 2.5 and 0.44 or 0)
		data.scale = scale

		vec_SetUnpacked(m_vec, scale, scale, scale)
		m:Scale(m_vec)

		vec_SetUnpacked(m_vec, -w / 2, -h / 2, 0)
		m:Translate(m_vec)

		cam.PushModelMatrix(m)
            gemotions.Draw(data.selected, w / 2 - 160, 38, 320, 380)
		cam.PopModelMatrix()
	end
end)

-----------------------------------------------------------------------------------------------

local function BuildPanel(Panel) -- Utilites
	Panel.EmotionsText = vgui.Create("DLabel")
	Panel.EmotionsText:SetColor(Color(219, 65, 68, 255))
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
