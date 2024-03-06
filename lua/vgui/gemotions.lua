--------------------------------------------------------------------------------------
-- GEmotions
--------------------------------------------------------------------------------------

gemotions = gemotions or {}

local emotions = gemotions.emotions
local packages = gemotions.packages

local ge_GetPackage = gemotions.GetPackage
local ge_GetEmote = gemotions.GetEmote
local ge_DrawEmoteQuad = gemotions.DrawEmoteQuad

if IsValid(gemotions.base) then
    gemotions.base:Remove()
end

--------------------------------------------------------------------------------------
-- Panel
--------------------------------------------------------------------------------------

local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:SetAlpha(0)

    self.selectedPackage = 1
    self.selectedEmote = nil 
end

function PANEL:GetSelectedPackage()
    return ge_GetPackage(self.selectedPackage)
end

function PANEL:GetSelectedEmote()
    return ge_GetEmote(self.selectedPackage, self.selectedEmote)
end

do
    local ScrW, ScrH = ScrW, ScrH
    local pi, sqrt, acos, Round = math.pi, math.sqrt, math.acos, math.Round

    function PANEL:OnCursorMoved(x, y)
        local package = self:GetSelectedPackage()
        if (package == nil) then 
            return
        end

        local packageCount = package.count
        local packageStep = package.step

        local x, y = x - ScrW() / 2, y - ScrH() / 2
        local length = sqrt(x * x + y * y)

        if (length < 64) then
            self.selectedEmote = nil
            return
        end

        local angle = acos(x / length)
        if (y < 0) then
            angle = 2 * pi - angle
        end

        local selectedEmote = Round(angle / packageStep) % packageCount + 1

        if (selectedEmote ~= self.selectedEmote) then
            surface.PlaySound("gemotions/ui/switch.ogg")
        end

        self.selectedEmote = selectedEmote
    end
end

function PANEL:OnMouseWheeled(delta)
    local packagesCount = gemotions.packagesCount

    if (gemotions.packagesCount < 2) then
        return
    end

    self.selectedPackage = (self.selectedPackage - delta - 1) % packagesCount + 1
    self.selectedEmote = nil

    surface.PlaySound("gemotions/ui/rollover.ogg")
end

do
    local blur = Material("pp/blurscreen")
    local bSetFloat = blur.SetFloat
    local bRecompute = blur.Recompute

    local m_panel = FindMetaTable("Panel")
    local pGetAlpha = m_panel.GetAlpha

    local render_UpdateScreenEffectTexture, surface_SetMaterial, surface_SetDrawColor, surface_DrawTexturedRect, surface_DrawRect, surface_DrawCircle, draw_SimpleText =
        render.UpdateScreenEffectTexture, surface.SetMaterial, surface.SetDrawColor, surface.DrawTexturedRect, surface.DrawRect, surface.DrawCircle, draw.SimpleText

    local Lerp, RealFrameTime = Lerp, RealFrameTime

    local pi, cos, sin = math.pi, math.cos, math.sin

    surface.CreateFont("gemotions_small", {font = "Roboto", size = 16, extended = true})
    surface.CreateFont("gemotions_medium", {font = "Roboto", size = 24, extended = true})

    local gemotions_small = "gemotions_small"
    local gemotions_medium = "gemotions_medium"

    function PANEL:Paint(w, h)
        local w_half, h_half = w / 2, h / 2
        local alpha = pGetAlpha(self)

        -- Blur
        bSetFloat(blur, "$blur", alpha / 64)
        bRecompute(blur)

        render_UpdateScreenEffectTexture()
        surface_SetMaterial(blur)
        surface_SetDrawColor(255, 255, 255, 255)
        surface_DrawTexturedRect(0, 0, w, h)

        surface_SetDrawColor(32, 32, 32, 240)
        surface_DrawRect(0, 0, w, h)

        -- Package
        local package = self:GetSelectedPackage()
        if (package == nil) then
            return
        end

        local packageTitle = package.title
        local packageCount = package.count
        local packageStep = package.step
        local packageRadius = package.radius

        -- Circle
        surface_DrawCircle(w_half, h_half, 64, 128, 128, 128, 32)

        -- Draw Package
		if (gemotions.packagesCount > 1) then
			local _,sh =
			draw_SimpleText(string.format("%d/%d", self.selectedPackage, gemotions.packagesCount), gemotions_small, w_half, h * 0.98, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			draw_SimpleText(packageTitle, gemotions_medium, w_half, h * 0.98 - sh, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		else
			draw_SimpleText(packageTitle, gemotions_medium, w_half, h * 0.975, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end

        -- Emotions
        local realtime = RealFrameTime()

        for id, emote in ipairs(package) do
            local rad = id * packageStep - packageStep
            local emoteCos = cos(rad)
            local emoteSin = sin(rad)

            local emoteScale = Lerp(realtime * 12, emote.scale or 1, (id == self.selectedEmote) and 2 or 1)
            emote.scale = emoteScale

            local size = 36 * emoteScale
            local x = w_half + emoteCos * packageRadius - size / 2
            local y = h_half + emoteSin * packageRadius - size / 2
            
            ge_DrawEmoteQuad(emote, x, y, size, size, alpha)
        end
    end
end

do
    local animDuration = 0.16
    local animHide = function(_,self)
        self:SetVisible(false)
        self:IsMouseInputEnabled(true)
    end

    function PANEL:Show()
        local emote = self:GetSelectedEmote()
        if (emote ~= nil) then
            emote.scale = 1
        end
        self.selectedEmote = nil

        self:Stop()
        self:SetVisible(true)
        self:AlphaTo(255, animDuration)
        self:IsMouseInputEnabled(true)
        gui.EnableScreenClicker(true)
    end

    function PANEL:Hide()
        self:Stop()
        self:AlphaTo(0, animDuration, _, animHide)
        gui.EnableScreenClicker(false)
        CloseDermaMenus()

        if (self.selectedEmote ~= nil) then
            net.Start("gemotions")
                net.WriteUInt(self.selectedPackage, 7) -- PACKAGE ID
			    net.WriteUInt(self.selectedEmote, 7) -- EMOTE ID
			net.SendToServer()
        end
    end
end

vgui.Register("gemotions", PANEL, "DPanel")

--------------------------------------------------------------------------------------
-- Utilites Menu
--------------------------------------------------------------------------------------

do
    hook.Add("PopulateToolMenu", "Emotions_PopulateToolMenu", function()
        spawnmenu.AddToolMenuOption("Utilities", "User", "GEmotions", "GEmotions", "", "", function(panel)
            panel.EmotionsText = vgui.Create("DLabel")
            panel.EmotionsText:SetColor(Color(110, 110, 110))
            panel.EmotionsText:SetText("Open")
            panel.EmotionsText:SizeToContents()
            panel:AddItem(panel.EmotionsText)

            panel.Emotionsbinder = vgui.Create("DBinder")
            panel.Emotionsbinder:SetSelectedNumber(gemotions.bind:GetInt())
            function panel.Emotionsbinder:OnChange(num)
                gemotions.bind:SetInt(num)
            end
            panel:AddItem(panel.Emotionsbinder)
        end)
    end)
end

-- https://youtu.be/dQw4w9WgXcQ