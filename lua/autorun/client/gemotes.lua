-----------------------------------------------------------------------------------------------
gemotes = gemotes or {}
gemotes.emotions = {}


function gemotes.RegisterEmote(_material, _sound)
	table.insert(gemotes.emotions, {
		material = Material(_material), 
		sound = _sound
	})
end

-- Including config.
include("gemotes/config.lua")

local basisMaterial = Material("gemotes/base.png")
local basisSelectMaterial = Material("gemotes/base_select.png")

gemotes.Draw = function(id, x, y, w, h, selectBox)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(selectBox and basisSelectMaterial or basisMaterial)
    surface.DrawTexturedRect(x, y, w, selectBox and w or h)
    surface.SetMaterial(gemotes.emotions[id].material)
    surface.DrawTexturedRect(x+w*0.075, y+w*0.075, w*0.85, w*0.85)
end

-----------------------------------------------------------------------------------------------

local PANEL = {}

local blur = Material("pp/blurscreen")

function PANEL:Init() -- Init
    self:SetSize(ScrW(), ScrH())
	self:SetAlpha(0)
	self:Show()

    self.emotions = {}
    do
        local count = #gemotes.emotions
        local step = 2 * math.pi / count

        for i = 0, count - 1 do
            local rad = i * step
            table.insert(self.emotions, {
                cos = math.cos(rad),
                sin = math.sin(rad),
                scale = 1
            })
        end

        self.emotions.count = count
        self.emotions.step = step
    end
end

function PANEL:OnCursorMoved(x, y)
    local x, y = x - ScrW() / 2, y - ScrH() / 2
    local length = math.sqrt(x ^ 2 + y ^ 2)

    if length > 64 then
        local angle = y >= 0 and math.acos(x / length) or math.pi + math.acos(-x / length)
        self.emotions_selected = math.Round(angle / self.emotions.step) % self.emotions.count + 1
    else
        self.emotions_selected = nil
    end
end

function PANEL:Show() -- Show
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

    -- Draw Emotions
    for i, k in ipairs(self.emotions) do
        local cos, sin = k.cos, k.sin

        local scale = Lerp(RealFrameTime() * 12, k.scale,
            i == self.emotions_selected and 2 or 1)
        k.scale = scale

        local _w = 32 * scale
        local _h = 38 * scale
        local x = w / 2 + cos * 128 - _w / 2
        local y = h / 2 + sin * 128 - _h / 2

        gemotes.Draw(i, x, y, _w, _h, true)
    end
end

vgui.Register("gemotes", PANEL, "DPanel")

-----------------------------------------------------------------------------------------------

local Bind = CreateClientConVar("gemotes_open", tostring(KEY_J))

hook.Add("PlayerButtonDown", "gemotes", function(ply, key) -- Open
	if key == Bind:GetInt() then
		local panel = gemotes.panel
		if IsValid(panel) then
			panel:Show()
		else
			gemotes.panel = vgui.Create("gemotes")
		end
		gui.EnableScreenClicker(true)
	end
end)

hook.Add("PlayerButtonUp", "gemotes", function(ply, key) -- Close
	if key == Bind:GetInt() then
		local panel = gemotes.panel
		if IsValid(panel) then
			panel:Hide()
			CloseDermaMenus()
			gui.EnableScreenClicker(false)

            local selected = panel.emotions_selected
			if not selected then return end

			net.Start("gemotes") -- Net
			    net.WriteUInt(selected, 7)
			net.SendToServer()
		end
	end
end)

-----------------------------------------------------------------------------------------------

gemotes.draw = {}
gemotes.huddraw = false

net.Receive("gemotes", function() -- Receive
	local selected, ply = net.ReadUInt(7), net.ReadEntity()

	ply:EmitSound(gemotes.emotions[selected].sound, 75, 100, 1)

	if not gemotes.emotions[selected] then
        return
    end

    if ply == LocalPlayer() then
        gemotes.huddraw = true
    end

	gemotes.draw[ply] = {
        time = RealTime(),	
        scale = 0,
		selected = selected,
	}


end)

-----------------------------------------------------------------------------------------------

local m_vec, m_ang = Vector(0, 0, 0), Angle(0, 0, 0)
local vec_SetUnpacked = m_vec.SetUnpacked

hook.Add("PostPlayerDraw", "gemotes", function(ply, studio) -- PostPlayerDraw
	local data = gemotes.draw[ply]
	if not data then return end

	local time = RealTime() - data.time

	if time >= 5 then
		gemotes.draw[ply] = nil
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
            gemotes.Draw(data.selected, -16, -38, 32, 38)
		cam.End3D2D()

		if ply == LocalPlayer() then
			gemotes.huddraw = false
		end
	end
end)

hook.Add("HUDPaint", "gemotes", function() -- HUDPaint
    local ply = LocalPlayer()

	local data = gemotes.draw[ply]
	if not data then return end

	if not gemotes.huddraw then
		gemotes.huddraw = true
		return
	end

	local time = RealTime() - data.time

	if time >= 5 then
		gemotes.huddraw = false
		gemotes.draw[ply] = nil
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
            gemotes.Draw(data.selected, w / 2 - 160, 38, 320, 380)
		cam.PopModelMatrix()
	end
end)

-----------------------------------------------------------------------------------------------

local function BuildPanel(Panel) -- Utilites
	Panel.EmotionsText = vgui.Create("DLabel")
	Panel.EmotionsText:SetColor(Color(219, 65, 68, 255))
	Panel.EmotionsText:SetText("Emotions")
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
	spawnmenu.AddToolMenuOption("Utilities", "User", "GEmotes", "Binds", "", "", BuildPanel)
end)

-----------------------------------------------------------------------------------------------
