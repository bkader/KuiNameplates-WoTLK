--[[
  Kui Nameplates
  Kesava-Auchindoun
]]
local addon, ns = ...
local kui = LibStub("Kui-1.0")
local uiscale, prevuiscale
local loadedGUIDs, loadedNames, targetExists, profile = {}, {}

-- our frame, whee
ns.f = CreateFrame("Frame")

-- Custom reaction colours
ns.r = {
    {.7, .2, .1}, -- hated
    {1, .8, 0}, -- neutral
    {.2, .6, .1} -- friendly
}

-- combat log events to listen to for cast warnings/healing
local warningEvents = {
    ["SPELL_CAST_START"] = true,
    ["SPELL_CAST_SUCCESS"] = true,
    ["SPELL_INTERRUPT"] = true,
    ["SPELL_HEAL"] = true,
    ["SPELL_PERIODIC_HEAL"] = true
}

--[[
  This attempts to fix issues with pixel-stretching, making frames look sharper
  as long as you are playing with a window height above a certain threshold
  and do not have UI scale enabled.

  Issues include:
  * Some graphical lag is introduced (plates will seem a bit loose),
    especially noticable at low frame rates.
  * If stacking nameplates is enabled in interface options, some plates will
    jitter when too many are visible at a time.
]]
--local fixaa = true
local origSizes, origFontSizes, sizes, fontSizes = {}, {}, {}, {}

-- support for some clients
local font = kui.m.f.yanone
local otherLocales = {koKR = true, zhCN = true, zhTW = true}
if otherLocales[GetLocale()] then font = NAMEPLATE_FONT end

--------------------------------------------------------------------- globals --
local strsplit, pairs, ipairs, unpack = strsplit, pairs, ipairs, unpack

------------------------------------------------------------- Frame functions --
-- set colour of health bar according to reaction/threat
local function SetHealthColour(self)
    if self.hasThreat then
        self.health.reset = true
        self.health:SetStatusBarColor(unpack(profile.tank.barcolour))
        return
    end

    local r, g, b = self.oldHealth:GetStatusBarColor()
    if self.health.reset or r ~= self.health.r or g ~= self.health.g or b ~= self.health.b then
        -- store the default colour
        self.health.r, self.health.g, self.health.b = r, g, b
        self.health.reset, self.friend = nil, nil

        if g > 0.9 and r == 0 and b == 0 then -- friendly NPC
            self.friend = true
            r, g, b = unpack(ns.r[3])
        elseif b > 0.9 and r == 0 and g == 0 then -- friendly player
            self.friend = true
            r, g, b = 0, 0.3, 0.6
        elseif r > 0.9 and g == 0 and b == 0 then -- enemy NPC
            r, g, b = unpack(ns.r[1])
        elseif (r + g) > 1.8 and b == 0 then -- neutral NPC
            r, g, b = unpack(ns.r[2])
        end
        -- enemy player, use default UI colour

        self.health:SetStatusBarColor(r, g, b)
    end
end

local function SetGlowColour(self, r, g, b, a)
    if not r then
        -- set default colour
        r, g, b = 0, 0, 0
    end

    if not a then
        a = .85
    end

    self.bg:SetVertexColor(r, g, b, a)
end

local function SetCastWarning(self, spellName, spellSchool)
    self.castWarning.ag:Stop()

    if spellName == nil then
        -- hide the warning instantly when interrupted
        self.castWarning:SetAlpha(0)
    else
        local col = COMBATLOG_DEFAULT_COLORS.schoolColoring[spellSchool] or {r = 1, g = 1, b = 1}

        self.castWarning:SetText(spellName)
        self.castWarning:SetTextColor(col.r, col.g, col.b)
        self.castWarning:SetAlpha(1)

        self.castWarning.ag:Play()
    end
end

local function SetIncomingWarning(self, amount)
    if amount == 0 then
        return
    end
    self.incWarning.ag:Stop()

    if amount > 0 then
        -- healing
        amount = "+" .. amount
        self.incWarning:SetTextColor(0, 1, 0)
    else
        -- damage (nyi)
        self.incWarning:SetTextColor(1, 0, 0)
    end

    self.incWarning:SetText(amount)

    self.incWarning:SetAlpha(1)
    self.incWarning.ag.fade:SetEndDelay(.5)

    self.incWarning.ag:Play()
end

-- Show the frame's castbar if it is casting
-- TODO update this for other units (party1target etc)
local function IsFrameCasting(self)
    if not self.castbar or not self.target then
        return
    end

    local name = UnitCastingInfo("target")
    local channel = false

    if not name then
        name = UnitChannelInfo("target")
        channel = true
    end

    if name then
        -- if they're casting or channeling, try to show a castbar
        ns.f:UNIT_SPELLCAST_START(self, "target", channel)
    end
end

local function StoreFrameGUID(self, guid)
    if not guid then
        return
    end
    if self.guid and loadedGUIDs[self.guid] then
        if self.guid ~= guid then
            -- the currently stored guid is incorrect
            loadedGUIDs[self.guid] = nil
        else
            return
        end
    end

    self.guid = guid
    loadedGUIDs[guid] = self

    if loadedNames[self.name.text] == self then
        loadedNames[self.name.text] = nil
    end
end

--------------------------------------------------------- Update combo points --
local function ComboPointsUpdate(self)
    if self.points and self.points > 0 then
        local size = (13 + ((18 - 13) / 5) * self.points)
        local blue = (1 - (1 / 5) * self.points)

        self:SetText(self.points)
        self:SetFont(font, size, "OUTLINE")
        self:SetTextColor(1, 1, blue)
    elseif self:GetText() then
        self:SetText("")
    end
end

----------------------------------------------------- Castbar script handlers --
local function OnCastbarUpdate(bar, elapsed)
    if bar.channel then
        bar.progress = bar.progress - elapsed
    else
        bar.progress = bar.progress + elapsed
    end

    if not bar.duration or ((not bar.channel and bar.progress >= bar.duration) or (bar.channel and bar.progress <= 0)) then
        -- hide the castbar bg
        bar:GetParent():Hide()
        bar.progress = 0
        return
    end

    -- display progress
    if bar.max then
        bar.curr:SetText(string.format("%.1f", bar.progress))

        if bar.delay == 0 or not bar.delay then
            bar.max:SetText(string.format("%.1f", bar.duration))
        else
            -- display delay
            if bar.channel then
                -- time is removed
                bar.max:SetText(
                    string.format("%.1f", bar.duration) .. "|cffff0000-" .. string.format("%.1f", bar.delay) .. "|r"
                )
            else
                -- time is added
                bar.max:SetText(
                    string.format("%.1f", bar.duration) .. "|cffff0000+" .. string.format("%.1f", bar.delay) .. "|r"
                )
            end
        end
    end

    bar:SetValue(bar.progress / bar.duration)
end

---------------------------------------------------- Update health bar & text --
local function OnHealthValueChanged(oldBar, curr)
    local frame = oldBar:GetParent()
    local min, max = oldBar:GetMinMaxValues()
    local deficit, big, sml, condition, display, pattern, rules = max - curr, "", ""

    frame.health:SetMinMaxValues(min, max)
    frame.health:SetValue(curr)

    -- select correct health display pattern
    if frame.friend then
        pattern = profile.hp.friendly
    else
        pattern = profile.hp.hostile
    end

    -- parse pattern into big/sml
    rules = {strsplit(";", pattern)}

    for k, rule in ipairs(rules) do
        condition, display = strsplit(":", rule)

        if condition == "<" then
            condition = curr < max
        elseif condition == "=" then
            condition = curr == max
        elseif condition == "<=" then
            condition = curr <= max
        end

        if condition then
            if display == "d" then
                big = "-" .. kui.num(deficit)
                sml = kui.num(curr)
            elseif display == "m" then
                big = kui.num(max)
            elseif display == "c" then
                big = kui.num(curr)
                sml = curr ~= max and kui.num(max)
            elseif display == "p" then
                big = floor(curr / max * 100)
                sml = kui.num(curr)
            end

            break
        end
    end

    frame.health.p:SetText(big)

    if frame.health.mo then
        frame.health.mo:SetText(sml)
    end
end

------------------------------------------------------- Frame script handlers --
local function OnFrameShow(self)
    if self.carrier then
        self.carrier:Show()
    end

    -- reset name
    self.name.text = self.oldName:GetText()
    self.name:SetText(self.name.text)

    if profile.hp.mouseover then
        -- force un-highlight
        self.highlighted = true
    end

    -- classifications
    if self.boss:IsVisible() then
        self.level:SetText("??b")
        self.level:SetTextColor(1, 0, 0)
        self.level:Show()
    elseif self.state:IsVisible() then
        if self.state:GetTexture() == "Interface\\Tooltips\\EliteNameplateIcon" then
            self.level:SetText(self.level:GetText() .. "+")
        else
            self.level:SetText(self.level:GetText() .. "r")
        end
    end

    if self.state:IsVisible() then
        -- hide the elite/rare dragon
        self.state:Hide()
    end

    if profile.castbar.usenames and not loadedNames[self.name.text] and not self.guid then
        -- store this frame's name
        loadedNames[self.name.text] = self
    end

    self:UpdateFrame()
    self:UpdateFrameCritical()

    -- force health update
    OnHealthValueChanged(self.oldHealth, self.oldHealth:GetValue())

    self:SetGlowColour()
    self:IsCasting()
end

local function OnFrameHide(self)
    if self.carrier then
        self.carrier:Hide()
    end

    if self.guid then
        -- remove guid from the store and unset it
        loadedGUIDs[self.guid] = nil
        self.guid = nil

        if self.cp then
            self.cp.points = nil
            self.cp:Update()
        end
    end

    if loadedNames[self.name.text] == self then
        -- remove name from store
        -- if there are name duplicates, this will be recreated in an onupdate
        loadedNames[self.name.text] = nil
    end

    self.lastAlpha = 0
    self.fadingTo = nil
    self.hasThreat = nil
    self.target = nil

    -- unset stored health bar colours
    self.health.r, self.health.g, self.health.b, self.health.reset = nil, nil, nil, nil

    if self.castbar then
        -- reset cast bar
        self.castbar.duration = nil
        self.castbar.id = nil
        self.castbarbg:Hide()
    end

    if self.castWarning then
        -- reset cast warning
        self.castWarning:SetText()
        self.castWarning.ag:Stop()

        self.incWarning:SetText()
    end
end

local function OnFrameEnter(self)
    if self.highlight then
        self.highlight:Show()
    end

    self:StoreGUID(UnitGUID("mouseover"))

    if profile.hp.mouseover then
        self.health.p:Show()
        if self.health.mo then
            self.health.mo:Show()
        end
    end
end

local function OnFrameLeave(self)
    if self.highlight then
        self.highlight:Hide()
    end

    if not self.target and profile.hp.mouseover then
        self.health.p:Hide()
        if self.health.mo then
            self.health.mo:Hide()
        end
    end
end

-- stuff that needs to be updated every frame
local function OnFrameUpdate(self, e)
    self.elapsed = self.elapsed + e
    self.critElap = self.critElap + e

    if profile.general.fixaa and uiscale then
        ------------------------------------------------------------ Position --
        local x, y = select(4, self:GetPoint())
        x = x / uiscale
        y = y / uiscale

        self.carrier:ClearAllPoints()
        self.carrier:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", floor(x - (self.carrier:GetWidth() / 2)), floor(y))
    end

    self.defaultAlpha = self:GetAlpha()
    ------------------------------------------------------------------- Alpha --

    if (self.defaultAlpha == 1 and targetExists) or (profile.fade.fademouse and self.highlighted) then
        self.currentAlpha = 1
    elseif targetExists or profile.fade.fadeall then
        self.currentAlpha = profile.fade.fadedalpha or .3
    else
        self.currentAlpha = 1
    end
    ------------------------------------------------------------------ Fading --
    if profile.fade.smooth then
        -- track changes in the alpha level and intercept them
        if self.currentAlpha ~= self.lastAlpha then
            if not self.fadingTo or self.fadingTo ~= self.currentAlpha then
                if kui.frameIsFading(self) then
                    kui.frameFadeRemoveFrame(self)
                end

                -- fade to the new value
                self.fadingTo = self.currentAlpha
                local alphaChange = (self.fadingTo - (self.lastAlpha or 0))

                kui.frameFade(self.carrier and self.carrier or self, {
                    mode = alphaChange < 0 and "OUT" or "IN",
                    timeToFade = abs(alphaChange) * (profile.fade.fadespeed or .5),
                    startAlpha = self.lastAlpha or 0,
                    endAlpha = self.fadingTo,
                    finishedFunc = function()
                        self.fadingTo = nil
                    end
                })
            end

            self.lastAlpha = self.currentAlpha
        end
    else
        (self.carrier and self.carrier or self):SetAlpha(self.currentAlpha)
    end

    -- call delayed updates
    if self.elapsed > 1 then
        self.elapsed = 0
        self:UpdateFrame()
    end

    if self.critElap > .1 then
        self.critElap = 0
        self:UpdateFrameCritical()
    end
end

-- stuff that can be updated less often
local function UpdateFrame(self)
    if profile.castbar.usenames and not loadedNames[self.name.text] and not self.guid then
        -- ensure a frame is still stored for this name, as name conflicts cause
        -- it to be erased when another might still exist
        -- also ensure that if this frame is targeted, this is the stored frame
        -- for its name
        loadedNames[self.name.text] = self
    end

    -- Health bar colour
    self:SetHealthColour()

    -- force health update (as self.friend is managed by SetHealthColour)
    --OnHealthValueChanged(self.oldHealth, self.oldHealth:GetValue())

    if self.cp then
        -- combo points
        self.cp:Update()
    end
end

-- stuff that needs to be updated often
local function UpdateFrameCritical(self)
    ------------------------------------------------------------------ Threat --
    if self.glow:IsVisible() then
        self.glow.wasVisible = true

        -- set glow to the current default ui's colour
        self.glow.r, self.glow.g, self.glow.b = self.glow:GetVertexColor()
        self:SetGlowColour(self.glow.r, self.glow.g, self.glow.b)

        if not self.friend and profile.tank.enabled then
            -- in tank mode; is the default glow red (are we tanking)?
            self.hasThreat = (self.glow.g + self.glow.b) < .1

            if self.hasThreat then
                -- tanking; recolour bar & glow
                local r, g, b, a = unpack(profile.tank.glowcolour)
                self:SetGlowColour(r, g, b, a)
                self:SetHealthColour()
            end
        end
    elseif self.glow.wasVisible then
        self.glow.wasVisible = nil

        -- restore shadow glow colour
        self:SetGlowColour()

        if self.hasThreat then
            -- lost threat
            self.hasThreat = nil
            self:SetHealthColour()
        end
    end
    ------------------------------------------------------------ Target stuff --
    if targetExists and self.defaultAlpha == 1 and self.name.text == UnitName("target") then
        -- this frame is targetted
        if not self.target then
            -- the frame just became targetted
            self.target = true
            self:StoreGUID(UnitGUID("target"))

            if self.carrier then
                -- move this frame above others
                -- default UI uses a level of 10 by default & 20 on the target
                self.carrier:SetFrameLevel(10)
            end

            if profile.hp.mouseover then
                self.health.p:Show()
                if self.health.mo then
                    self.health.mo:Show()
                end
            end

            -- check if the frame is casting
            self:IsCasting()
        end
    elseif self.target then
        self.target = nil

        if self.carrier then
            self.carrier:SetFrameLevel(1)
        end

        if not self.highlighted and profile.hp.mouseover then
            self.health.p:Hide()
            if self.health.mo then
                self.health.mo:Hide()
            end
        end
    end
    --------------------------------------------------------------- Mouseover --
    if self.oldHighlight:IsShown() then
        if not self.highlighted then
            self.highlighted = true
            OnFrameEnter(self)
        end
    elseif self.highlighted then
        self.highlighted = false
        OnFrameLeave(self)
    end
end

local function SetFontSize(fontstring, size)
    local font, _, flags = fontstring:GetFont()
    fontstring:SetFont(font, size, flags)
end

local function UpdateScales(self)
    -- all this for what is hopefully not a common occurrence
    self.carrier:SetScale(uiscale)
    self.carrier:SetSize(self:GetWidth() / uiscale, self:GetHeight() / uiscale)

    self.bg.fill:SetSize(sizes.width, sizes.height)
    self.health:SetSize(sizes.width - 2, sizes.height - 2)

    SetFontSize(self.health.p, fontSizes.large)

    if self.health.mo then
        SetFontSize(self.health.mo, fontSizes.small)
    end

    SetFontSize(self.level, fontSizes.name)
    SetFontSize(self.name, fontSizes.name)

    if self.cp then
        SetFontSize(self.cp, fontSizes.combopoints)
    end

    if self.castbarbg then
        self.castbarbg:SetHeight(sizes.cbheight)

        if self.castbar.name then
            SetFontSize(self.castbar.name, fontSizes.name)
        end

        if self.castbar.max then
            SetFontSize(self.castbar.max, fontSizes.name)
            SetFontSize(self.castbar.curr, fontSizes.small)
        end

        if self.spellbg then
            self.spellbg:SetSize(sizes.icon, sizes.icon)
            self.spell:SetSize(sizes.icon - 2, sizes.icon - 2)
        end
    end

    if self.castWarning then
        SetFontSize(self.castWarning, fontSizes.spellname)
        SetFontSize(self.incWarning, fontSizes.small)
    end

    self.bg:ClearAllPoints()
    self.bg:SetPoint("BOTTOMLEFT", 22 - 5, 16 - 5)
    self.bg:SetPoint("TOPRIGHT", self.carrier, "BOTTOMLEFT", 22 + sizes.width + 5, 16 + sizes.height + 5)
end

--------------------------------------------------------------- KNP functions --
function ns.f:GetNameplate(guid, name)
    local gf, nf = loadedGUIDs[guid], loadedNames[name]

    if gf then
        return gf
    elseif nf then
        return nf
    else
        return nil
    end
end

function ns.f:IsNameplate(frame)
    if frame:GetName() and not string.find(frame:GetName(), "^NamePlate") then
        return false
    end

    local overlayRegion = select(2, frame:GetRegions())
    return (overlayRegion and overlayRegion:GetObjectType() == "Texture" and
        overlayRegion:GetTexture() == "Interface\\Tooltips\\Nameplate-Border")
end

function ns.f:InitFrame(frame)
    -- TODO: this is just a tad long
    frame.init = true

    local healthBar, castBar = frame:GetChildren()
    local glowRegion, overlayRegion, castbarOverlay, shieldedRegion, spellIconRegion, highlightRegion, nameTextRegion, levelTextRegion, bossIconRegion, raidIconRegion, stateIconRegion = frame:GetRegions()

    highlightRegion:SetTexture(nil)
    bossIconRegion:SetTexture(nil)
    shieldedRegion:SetTexture(nil)
    castbarOverlay:SetTexture(nil)
    glowRegion:SetTexture(nil)

    -- disable default cast bar
    castBar:SetParent(nil)
    castbarOverlay.Show = function() return end
    castBar:SetScript("OnShow", function() castBar:Hide() end)

    frame.bg = overlayRegion
    frame.glow = glowRegion
    frame.boss = bossIconRegion
    frame.state = stateIconRegion
    frame.level = levelTextRegion
    frame.icon = raidIconRegion

    if profile.castbar.spellicon then
        frame.spell = spellIconRegion
    end

    frame.oldHealth = healthBar
    frame.oldHealth:Hide()

    frame.oldName = nameTextRegion
    frame.oldName:Hide()

    frame.oldHighlight = highlightRegion

    ---------------------------------------------------------- Frame functions--
    frame.UpdateFrame = UpdateFrame
    frame.UpdateFrameCritical = UpdateFrameCritical
    frame.SetHealthColour = SetHealthColour
    frame.SetGlowColour = SetGlowColour
    frame.IsCasting = IsFrameCasting
    frame.StoreGUID = StoreFrameGUID

    ------------------------------------------------------------------ Layout --
    local parent
    if profile.general.fixaa then
        frame.carrier = CreateFrame("Frame", nil, WorldFrame)
        frame.carrier:SetSize(frame:GetWidth() / uiscale, frame:GetHeight() / uiscale)
        frame.carrier:SetScale(uiscale)
        parent = frame.carrier
    else
        parent = frame
    end

    self.parent = parent

    do -- using CENTER breaks pixel-perfectness with oddly sized frames
        -- .. so we're doing it manually
        local w, h = parent:GetSize()
        x = floor((w / 2) - (sizes.width / 2))
        y = floor((h / 2) - (sizes.height / 2))
    end

    -- border ------------------------------------------------------------------
    --frame.bg = (frame.carrier and frame.carrier or frame):CreateTexture(nil, 'BACKGROUND')
    frame.bg:SetParent(parent)
    frame.bg:SetTexture("Interface\\AddOns\\Kui_Nameplates\\media\\t\\FrameGlow")
    frame.bg:SetTexCoord(0, .469, 0, .625)
    frame.bg:SetVertexColor(0, 0, 0, .9)

    -- background
    frame.bg.fill = parent:CreateTexture(nil, "BACKGROUND")
    frame.bg.fill:SetTexture(kui.m.t.solid)
    frame.bg.fill:SetVertexColor(0, 0, 0, .85)
    frame.bg.fill:SetDrawLayer("ARTWORK", 1) -- (1 sub-layer above .bg)

    frame.bg.fill:SetSize(sizes.width, sizes.height)
    frame.bg.fill:SetPoint("BOTTOMLEFT", x, y)

    frame.bg:ClearAllPoints()
    frame.bg:SetPoint("BOTTOMLEFT", x - 5, y - 5)
    frame.bg:SetPoint("TOPRIGHT", parent, "BOTTOMLEFT", x + sizes.width + 5, y + sizes.height + 5)

    -- health bar --------------------------------------------------------------
    frame.health = CreateFrame("StatusBar", nil, parent)
    frame.health:SetStatusBarTexture(kui.m.t.bar)

    frame.health:ClearAllPoints()
    frame.health:SetSize(sizes.width - 2, sizes.height - 2)
    frame.health:SetPoint("BOTTOMLEFT", x + 1, y + 1)

    if profile.hp.smooth then
        -- smooth bar
        frame.health.OrigSetValue = frame.health.SetValue
        frame.health.SetValue = ns.SetValueSmooth
    end

    -- raid icon ---------------------------------------------------------------
    frame.icon:SetParent(parent)
    --frame.icon:SetSize(24, 24)

    frame.icon:ClearAllPoints()
    frame.icon:SetPoint("BOTTOM", parent, "TOP", 0, -5)

    -- overlay (text is parented to this) --------------------------------------
    frame.overlay = CreateFrame("Frame", nil, parent)
    frame.overlay:SetAllPoints(frame.health)

    frame.overlay:SetFrameLevel(frame.health:GetFrameLevel() + 1)

    -- highlight ---------------------------------------------------------------
    if profile.general.highlight then
        frame.highlight = frame.overlay:CreateTexture(nil, "ARTWORK")
        frame.highlight:SetTexture(kui.m.t.bar)

        frame.highlight:SetAllPoints(frame.health)

        frame.highlight:SetVertexColor(1, 1, 1)
        frame.highlight:SetBlendMode("ADD")
        frame.highlight:SetAlpha(.4)
        frame.highlight:Hide()
    end

    -- health text -------------------------------------------------------------
    frame.health.p = kui.CreateFontString(frame.overlay, {
        font = font,
        size = fontSizes.large,
        outline = "OUTLINE"
    })
    frame.health.p:SetJustifyH("RIGHT")

    frame.health.p:SetPoint("BOTTOMRIGHT", frame.health, "TOPRIGHT", -2, uiscale and -(3 / uiscale) or -3)

    if profile.hp.showalt then
        frame.health.mo = kui.CreateFontString(frame.overlay, {
            font = font,
            size = fontSizes.small,
            outline = "OUTLINE"
        })
        frame.health.mo:SetJustifyH("RIGHT")

        frame.health.mo:SetPoint("BOTTOMRIGHT", frame.health, -2, uiscale and -(2 / uiscale) or -2)
        frame.health.mo:SetAlpha(.5)
    end

    -- level text --------------------------------------------------------------
    frame.level = kui.CreateFontString(frame.level, {
        reset = true,
        font = font,
        size = fontSizes.name,
        outline = "OUTLINE"
    })
    frame.level:SetParent(frame.overlay)

    frame.level:ClearAllPoints()
    frame.level:SetPoint("BOTTOMLEFT", frame.health, "TOPLEFT", 2, uiscale and -(2 / uiscale) or -2)

    -- name text ---------------------------------------------------------------
    frame.name = kui.CreateFontString(frame.overlay, {
        font = font,
        size = fontSizes.name,
        outline = "OUTLINE"
    })
    frame.name:SetJustifyH("LEFT")

    frame.name:SetHeight(8)

    frame.name:SetPoint("LEFT", frame.level, "RIGHT", -2, 0)
    frame.name:SetPoint("RIGHT", frame.health.p, "LEFT")

    -- combo point text --------------------------------------------------------
    if profile.general.combopoints then
        frame.cp = kui.CreateFontString(frame.health, {font = font, size = fontSizes.combopoints, outline = "OUTLINE", shadow = true})
        frame.cp:SetPoint("LEFT", frame.health, "RIGHT", 5, 1)

        frame.cp.Update = ComboPointsUpdate
    end

    if profile.castbar.enabled then
        -- TODO move this (and similar things) into functions
        -- cast bar background -------------------------------------------------
        frame.castbarbg = CreateFrame("Frame", nil, parent)
        frame.castbarbg:SetFrameStrata("BACKGROUND")
        frame.castbarbg:SetBackdrop({
            bgFile = kui.m.t.solid,
            edgeFile = kui.m.t.shadow,
            edgeSize = 5,
            insets = {top = 5, left = 5, bottom = 5, right = 5}
        })

        frame.castbarbg:SetBackdropColor(0, 0, 0, .85)
        frame.castbarbg:SetBackdropBorderColor(1, .2, .1, 0)
        frame.castbarbg:SetHeight(sizes.cbheight)

        frame.castbarbg:SetPoint("TOPLEFT", frame.bg.fill, "BOTTOMLEFT", -5, 4)
        frame.castbarbg:SetPoint("TOPRIGHT", frame.bg.fill, "BOTTOMRIGHT", 5, 0)

        frame.castbarbg:Hide()

        -- cast bar ------------------------------------------------------------
        frame.castbar = CreateFrame("StatusBar", nil, frame.castbarbg)
        frame.castbar:SetStatusBarTexture(kui.m.t.bar)

        frame.castbar:SetPoint("TOPLEFT", frame.castbarbg, "TOPLEFT", 6, -6)
        frame.castbar:SetPoint("BOTTOMLEFT", frame.castbarbg, "BOTTOMLEFT", 6, 6)
        frame.castbar:SetPoint("RIGHT", frame.castbarbg, "RIGHT", -6, 0)

        frame.castbar:SetMinMaxValues(0, 1)

        -- uninterruptible cast shield -----------------------------------------
        frame.castbar.shield = frame.castbar:CreateTexture(nil, "ARTWORK")
        frame.castbar.shield:SetTexture("Interface\\AddOns\\Kui_Nameplates\\media\\t\\Shield")
        frame.castbar.shield:SetTexCoord(0, .53125, 0, .6875)

        frame.castbar.shield:SetSize(12, 17)
        frame.castbar.shield:SetPoint("CENTER", frame.castbar, 0, 1)

        frame.castbar.shield:SetBlendMode("BLEND")
        frame.castbar.shield:SetDrawLayer("ARTWORK", 7)
        frame.castbar.shield:SetVertexColor(1, .1, .1)

        frame.castbar.shield:Hide()

        -- cast bar text -------------------------------------------------------
        if profile.castbar.spellname then
            frame.castbar.name = kui.CreateFontString(frame.castbar, {
                font = font,
                size = fontSizes.name,
                outline = "OUTLINE"
            })
            frame.castbar.name:SetPoint("TOPLEFT", frame.castbar, "BOTTOMLEFT", 2, -2)
        end

        if profile.castbar.casttime then
            frame.castbar.max = kui.CreateFontString(frame.castbar, {
                font = font,
                size = fontSizes.name,
                outline = "OUTLINE"
            })
            frame.castbar.max:SetPoint("TOPRIGHT", frame.castbar, "BOTTOMRIGHT", -2, -1)

            frame.castbar.curr = kui.CreateFontString(frame.castbar, {
                font = font,
                size = fontSizes.small,
                outline = "OUTLINE"
            })
            frame.castbar.curr:SetAlpha(.5)
            frame.castbar.curr:SetPoint("TOPRIGHT", frame.castbar.max, "TOPLEFT", -1, -1)
        end

        if frame.spell then
            -- cast bar icon background ----------------------------------------
            frame.spellbg = frame.castbarbg:CreateTexture(nil, "BACKGROUND")
            frame.spellbg:SetTexture(kui.m.t.solid)
            frame.spellbg:SetSize(sizes.icon, sizes.icon)

            frame.spellbg:SetVertexColor(0, 0, 0, .85)

            frame.spellbg:SetPoint("TOPRIGHT", frame.health, "TOPLEFT", -2, 1)

            -- cast bar icon ---------------------------------------------------
            frame.spell:ClearAllPoints()
            frame.spell:SetParent(frame.castbarbg)
            frame.spell:SetSize(sizes.icon - 2, sizes.icon - 2)

            frame.spell:SetPoint("TOPRIGHT", frame.spellbg, -1, -1)

            frame.spell:SetTexCoord(.1, .9, .1, .9)
        end

        -- scripts -------------------------------------------------------------
        frame.castbar:HookScript("OnShow", function(bar)
            if bar.interruptible then
                bar:SetStatusBarColor(unpack(profile.castbar.barcolour))
                bar:GetParent():SetBackdropBorderColor(0, 0, 0, .3)
                bar.shield:Hide()
            else
                bar:SetStatusBarColor(.8, .1, .1)
                bar:GetParent():SetBackdropBorderColor(1, .1, .2, .5)
                bar.shield:Show()
            end
        end)

        frame.castbar:SetScript("OnUpdate", OnCastbarUpdate)
    end

    -- cast warning ------------------------------------------------------------
    if profile.castbar.warnings then
        -- casting spell name
        frame.castWarning = kui.CreateFontString(frame.overlay, {
            font = font,
            size = fontSizes.spellname,
            outline = "OUTLINE"
        })
        frame.castWarning:SetPoint("BOTTOMLEFT", frame.level, "TOPLEFT", 0, 1)
        frame.castWarning:Hide()

        frame.castWarning.ag = frame.castWarning:CreateAnimationGroup()
        frame.castWarning.fade = frame.castWarning.ag:CreateAnimation("Alpha")
        frame.castWarning.fade:SetSmoothing("IN")
        frame.castWarning.fade:SetDuration(3)
        frame.castWarning.fade:SetChange(-1)

        frame.castWarning.ag:SetScript("OnPlay", function(self) self:GetParent():Show() end)

        frame.castWarning.ag:SetScript("OnFinished", function(self) self:GetParent():Hide() end)

        -- incoming healing
        frame.incWarning = kui.CreateFontString(frame.overlay, {
            font = font,
            size = fontSizes.small,
            outline = "OUTLINE"
        })
        frame.incWarning:SetPoint("BOTTOMRIGHT", frame.health.p, "TOPRIGHT", 1)
        frame.incWarning:Hide()

        frame.incWarning.ag = frame.incWarning:CreateAnimationGroup()
        frame.incWarning.ag.fade = frame.incWarning.ag:CreateAnimation("Alpha")
        frame.incWarning.ag.fade:SetSmoothing("IN")
        frame.incWarning.ag.fade:SetDuration(.5)
        frame.incWarning.ag.fade:SetChange(-.5)

        frame.incWarning.ag:SetScript("OnPlay", function(self) self:GetParent():Show() end)

        frame.incWarning.ag:SetScript("OnFinished", function(self)
            if self.fade:GetEndDelay() > 0 then
                -- fade out fully
                self:GetParent():SetAlpha(.5)
                self.fade:SetEndDelay(0)
                self:Play()
            else
                self:GetParent():Hide()
            end
        end)

        -- handlers
        frame.SetCastWarning = SetCastWarning
        frame.SetIncomingWarning = SetIncomingWarning
    end

    ----------------------------------------------------------------- Scripts --
    frame:SetScript("OnShow", OnFrameShow)
    frame:SetScript("OnHide", OnFrameHide)
    frame:SetScript("OnUpdate", OnFrameUpdate)

    frame.oldHealth:SetScript("OnValueChanged", OnHealthValueChanged)

    ------------------------------------------------------------ Finishing up --
    frame.UpdateScales = UpdateScales

    frame.elapsed = 0
    frame.critElap = 0

    -- force OnShow
    OnFrameShow(frame)
end

---------------------------------------------------------------------- Events --
function ns.f:UNIT_COMBO_POINTS()
    local target = UnitGUID("target")
    if not target or not loadedGUIDs[target] then
        return
    end
    target = loadedGUIDs[target]

    if target.cp then
        target.cp.points = GetComboPoints("player", "target")
        target.cp:Update()
    end

    -- clear points on other frames
    for guid, frame in pairs(loadedGUIDs) do
        if frame.cp and guid ~= target.guid then
            frame.cp.points = nil
            frame.cp:Update()
        end
    end
end

function ns.f:PLAYER_TARGET_CHANGED()
    targetExists = UnitExists("target")
end

-- automatic toggling of enemy frames
function ns.f:PLAYER_REGEN_ENABLED()
    SetCVar("nameplateShowEnemies", 0)
end
function ns.f:PLAYER_REGEN_DISABLED()
    SetCVar("nameplateShowEnemies", 1)
end

-- custom cast bar events ------------------------------------------------------
function ns.f:UNIT_SPELLCAST_START(frame, unit, channel)
    local cb = frame.castbar
    local name, _, _, texture, startTime, endTime, _, castID, notInterruptible

    if channel then
        name, _, _, texture, startTime, endTime, _, castID, notInterruptible = UnitChannelInfo(unit)
    else
        name, _, _, texture, startTime, endTime, _, castID, notInterruptible = UnitCastingInfo(unit)
    end

    if not name then
        frame.castbarbg:Hide()
        return
    end

    cb.id = castID
    cb.channel = channel
    cb.interruptible = not notInterruptible
    cb.duration = (endTime / 1000) - (startTime / 1000)
    cb.delay = 0

    if frame.spell then
        frame.spell:SetTexture(texture)
    end

    if cb.name then
        cb.name:SetText(name)
    end

    if cb.channel then
        cb.progress = (endTime / 1000) - GetTime()
    else
        cb.progress = GetTime() - (startTime / 1000)
    end

    frame.castbarbg:Show()
end

function ns.f:UNIT_SPELLCAST_DELAYED(frame, unit, channel)
    local cb = frame.castbar
    local _, name, startTime, endTime

    if channel then
        name, _, _, _, startTime, endTime = UnitChannelInfo(unit)
    else
        name, _, _, _, startTime, endTime = UnitCastingInfo(unit)
    end

    if not name then
        return
    end

    local newProgress
    if cb.channel then
        newProgress = (endTime / 1000) - GetTime()
    else
        newProgress = GetTime() - (startTime / 1000)
    end

    cb.delay = (cb.delay or 0) + cb.progress - newProgress
    cb.progress = newProgress
end

function ns.f:UNIT_SPELLCAST_CHANNEL_START(frame, unit)
    self:UNIT_SPELLCAST_START(frame, unit, true)
end
function ns.f:UNIT_SPELLCAST_CHANNEL_UPDATE(frame, unit)
    self:UNIT_SPELLCAST_DELAYED(frame, unit, true)
end

function ns.f:UNIT_SPELLCAST_STOP(frame, unit)
    frame.castbarbg:Hide()
end
function ns.f:UNIT_SPELLCAST_FAILED(frame, unit)
    frame.castbarbg:Hide()
end
function ns.f:UNIT_SPELLCAST_INTERRUPTED(frame, unit)
    frame.castbarbg:Hide()
end
function ns.f:UNIT_SPELLCAST_CHANNEL_STOP(frame, unit)
    frame.castbarbg:Hide()
end

-- custom cast bar event handler -----------------------------------------------
function ns.f:UnitCastEvent(e, unit, ...)
    if unit == "player" then
        return
    end
    local guid, name, f = UnitGUID(unit), GetUnitName(unit), nil

    -- fetch the unit's nameplate
    f = self:GetNameplate(guid, name)
    if f then
        if not f.castbar then
            return
        end
        if e == "UNIT_SPELLCAST_STOP" or e == "UNIT_SPELLCAST_FAILED" or e == "UNIT_SPELLCAST_INTERRUPTED" then
            -- these occasionally fire after a new _START
            local _, _, castID = ...
            if f.castbar.id ~= castID then
                return
            end
        end

        self[e](self, f, unit)
    end
end

-- cast warning handler --------------------------------------------------------
function ns.f:CastWarningEvent(...)
    -- _ = COMBAT_LOG_EVENT_UNFILTERED
    local castTime, event, _, guid, name, _, _, targetGUID, targetName = ...

    if warningEvents[event] then
        if event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
            -- fetch the spell's target's nameplate
            guid, name = targetGUID, targetName
        end

        local f = self:GetNameplate(guid, name)
        if f then
            if not f.SetIncomingWarning then
                return
            end
            local spName, spSch = select(13, ...)

            if event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
                -- display heal warning
                local amount = select(15, ...)
                f:SetIncomingWarning(amount)
            elseif event == "SPELL_INTERRUPT" then
                -- hide the warning
                f:SetCastWarning(nil)
            else
                -- or display it for this spell
                f:SetCastWarning(spName, spSch)
            end
        end
    end
end

------------------------------------------ Health bar smooth update functions --
-- (spoon-fed by oUF_Smooth)
do
    local f, smoothing, GetFramerate, min, max, abs = CreateFrame("Frame"), {}, GetFramerate, math.min, math.max, math.abs

    function ns.SetValueSmooth(self, value)
        local _, max = self:GetMinMaxValues()

        if value == self:GetValue() or (self.prevMax and self.prevMax ~= max) then
            -- finished smoothing/max health updated
            smoothing[self] = nil
            self:OrigSetValue(value)
        else
            smoothing[self] = value
        end

        self.prevMax = max
    end

    f:SetScript("OnUpdate", function()
        local limit = 30 / GetFramerate()

        for bar, value in pairs(smoothing) do
            local cur = bar:GetValue()
            local new = cur + min((value - cur) / 3, max(value - cur, limit))

            if new ~= new then
                new = value
            end

            bar:OrigSetValue(new)

            if cur == value or abs(new - value) < 2 then
                bar:OrigSetValue(value)
                smoothing[bar] = nil
            end
        end
    end)
end

------------------------------------------------------------- Script handlers --
ns.frames = 0
ns.frameList = {}

do
    local WorldFrame, lastUpdate = WorldFrame, 1

    function ns.OnUpdate(self, elapsed)
        lastUpdate = lastUpdate + elapsed

        if lastUpdate >= 0.1 then
            lastUpdate = 0

            local frames = select("#", WorldFrame:GetChildren())
            if frames ~= ns.frames then
                for i = 1, frames do
                    local f = select(i, WorldFrame:GetChildren())

                    if self:IsNameplate(f) and not f.init then
                        self:InitFrame(f)
                        if profile.general.fixaa then
                            tinsert(ns.frameList, f)
                        end
                    end
                end

                ns.frames = frames
            end
        end
    end
end

do -- events for custom cast bar
    local castEvents = {
        ["UNIT_SPELLCAST_START"] = true,
        ["UNIT_SPELLCAST_FAILED"] = true,
        ["UNIT_SPELLCAST_STOP"] = true,
        ["UNIT_SPELLCAST_INTERRUPTED"] = true,
        ["UNIT_SPELLCAST_DELAYED"] = true,
        ["UNIT_SPELLCAST_CHANNEL_START"] = true,
        ["UNIT_SPELLCAST_CHANNEL_UPDATE"] = true,
        ["UNIT_SPELLCAST_CHANNEL_STOP"] = true
    }

    function ns.OnEvent(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            -- send to cast warnings handler
            self:CastWarningEvent(...)
        elseif castEvents[event] then
            -- send to cast event handler
            self:UnitCastEvent(event, ...)
        else
            self[event](self, ...)
        end
    end

    ------------------------------------------------------- Event ... registerers --
    function ns.ToggleCastbar(io)
        if io then
            for event, _ in pairs(castEvents) do
                ns.f:RegisterEvent(event)
            end
        else
            for event, _ in pairs(castEvents) do
                ns.f:UnregisterEvent(event)
            end
        end
    end
end

function ns.ToggleWarnings(io)
    if io then
        ns.f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        ns.f:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

function ns.ToggleCombatEvents(io)
    if io then
        ns.f:RegisterEvent("PLAYER_REGEN_ENABLED")
        ns.f:RegisterEvent("PLAYER_REGEN_DISABLED")
    else
        ns.f:UnregisterEvent("PLAYER_REGEN_ENABLED")
        ns.f:UnregisterEvent("PLAYER_REGEN_DISABLED")
    end
end

function ns.ToggleComboPoints(io)
    if io then
        ns.f:RegisterEvent("UNIT_COMBO_POINTS")
    else
        ns.f:UnregisterEvent("UNIT_COMBO_POINTS")
    end
end

-------------------------------------------------------------------- Finalise --
function ns:OnEnable()
    profile = self.db.profile
    sizes = {
        -- frame
        width = 110,
        height = 11,
        -- cast bar stuff
        cbheight = 14,
        icon = 16
    }
    fontSizes = {
        combopoints = 13,
        large = 11,
        spellname = 10,
        name = 9,
        small = 8
    }

    if profile.general.fixaa then
        uiscale, origSizes, origFontSizes = UIParent:GetEffectiveScale(), sizes, fontSizes

        origSizes.cbheight = 12

        -- scale sizes up to "unscaled" values
        for k, size in pairs(origSizes) do
            sizes[k] = floor(size / uiscale)
        end

        -- fonts don't need to be pixel perfect, they just need to be scaled
        for k, size in pairs(origFontSizes) do
            fontSizes[k] = size / uiscale
        end
    end

    for k, size in pairs(fontSizes) do
        fontSizes[k] = size * profile.general.fontscale
    end

    ns.f:SetScript("OnUpdate", self.OnUpdate)
    ns.f:SetScript("OnEvent", self.OnEvent)

    ns.f:RegisterEvent("PLAYER_TARGET_CHANGED")

    self.ToggleCastbar(profile.castbar.enabled)
    self.ToggleWarnings(profile.castbar.warnings)
    self.ToggleCombatEvents(profile.general.combat)
    self.ToggleComboPoints(profile.general.combopoints)
end