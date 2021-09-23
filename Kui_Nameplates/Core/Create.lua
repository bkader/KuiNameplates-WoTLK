--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
-- Frame element creation/update functions
-- Backported by: Kader at https://github.com/bkader
]]
local addon = LibStub("AceAddon-3.0"):GetAddon("KuiNameplates")
local kui = LibStub("Kui-1.0")

local side_coords = {
	left = {0, .04, 0, 1},
	right = {.96, 1, 0, 1},
	top = {.05, .95, 0, .24},
	bottom = {.05, .95, .76, 1}
}

------------------------------------------------------------------ Background --
function addon:CreateBackground(frame, f)
	-- frame glow
	f.bg = {sides = {}}

	-- solid background
	f.bg.fill = f:CreateTexture(nil, "ARTWORK", nil, 1)
	f.bg.fill:SetTexture(kui.m.t.solid)
	f.bg.fill:SetVertexColor(0, 0, 0, .8)

	-- create frame glow sides
	-- not using frame backdrop as it seems to cause a lot of lag on frames
	-- which update very often (such as nameplates)
	for side, coords in pairs(side_coords) do
		f.bg.sides[side] = f:CreateTexture(nil, "ARTWORK", nil, 0)
		side = f.bg.sides[side]

		side:SetTexture("Interface\\AddOns\\Kui_Nameplates\\Media\\FrameGlow")
		side:SetTexCoord(unpack(coords))
	end

	local of = self.sizes.frame.bgOffset + 1

	f.bg.sides.top:SetPoint("BOTTOMLEFT", f.bg.fill, "TOPLEFT", 1, -1)
	f.bg.sides.top:SetPoint("BOTTOMRIGHT", f.bg.fill, "TOPRIGHT", -1, -1)
	f.bg.sides.top:SetHeight(of)

	f.bg.sides.bottom:SetPoint("TOPLEFT", f.bg.fill, "BOTTOMLEFT", 1, 1)
	f.bg.sides.bottom:SetPoint("TOPRIGHT", f.bg.fill, "BOTTOMRIGHT", -1, 1)
	f.bg.sides.bottom:SetHeight(of)

	f.bg.sides.left:SetPoint("TOPRIGHT", f.bg.sides.top, "TOPLEFT")
	f.bg.sides.left:SetPoint("BOTTOMRIGHT", f.bg.sides.bottom, "BOTTOMLEFT")
	f.bg.sides.left:SetWidth(of)

	f.bg.sides.right:SetPoint("TOPLEFT", f.bg.sides.top, "TOPRIGHT")
	f.bg.sides.right:SetPoint("BOTTOMLEFT", f.bg.sides.bottom, "BOTTOMRIGHT")
	f.bg.sides.right:SetWidth(of)

	function f.bg:SetVertexColor(r, g, b, a)
		for _, side in pairs(self.sides) do
			side:SetVertexColor(r, g, b, a)
		end
	end
	function f.bg:Hide()
		self.fill:Hide()
		for _, side in pairs(self.sides) do
			side:Hide()
		end
	end
	function f.bg:Show()
		self.fill:Show()
		for _, side in pairs(self.sides) do
			side:Show()
		end
	end
end
function addon:UpdateBackground(f, trivial)
	f.bg.fill:ClearAllPoints()

	if trivial then
		-- switch to trivial sizes
		f.bg.fill:SetSize(self.sizes.frame.twidth, self.sizes.frame.theight)
		f.bg.fill:SetPoint("BOTTOMLEFT", f.x, f.y)
	elseif not trivial then
		-- switch back to normal sizes
		f.bg.fill:SetSize(self.sizes.frame.width, self.sizes.frame.height)
		f.bg.fill:SetPoint("BOTTOMLEFT", f.x, f.y)
	end
end
------------------------------------------------------------------ Health bar --
function addon:CreateHealthBar(frame, f)
	f.health = CreateFrame("StatusBar", nil, f)
	f.health:SetFrameLevel(1)
	f.health:SetStatusBarTexture(addon.bartexture)
	f.health.percent = 100

	f.health:GetStatusBarTexture():SetDrawLayer("ARTWORK", -8)

	if self.SetValueSmooth then
		f.health.OrigSetValue = f.health.SetValue
		f.health.SetValue = self.SetValueSmooth
	elseif self.CutawayBar then
		self.CutawayBar(f.health)
	end
end
function addon:UpdateHealthBar(f, trivial)
	f.health:ClearAllPoints()

	if trivial then
		f.health:SetSize(self.sizes.frame.twidth - 2, self.sizes.frame.theight - 2)
	elseif not trivial then
		f.health:SetSize(self.sizes.frame.width - 2, self.sizes.frame.height - 2)
	end

	f.health:SetPoint("BOTTOMLEFT", f.x + 1, f.y + 1)
end
------------------------------------------------------------------- Highlight --
function addon:CreateHighlight(frame, f)
	if not self.db.profile.general.highlight then
		return
	end

	f.highlight = f.overlay:CreateTexture(nil, "ARTWORK")
	f.highlight:SetTexture(addon.bartexture)
	f.highlight:SetAllPoints(f.health)

	f.highlight:SetVertexColor(1, 1, 1)
	f.highlight:SetBlendMode("ADD")
	f.highlight:SetAlpha(.4)
	f.highlight:Hide()
end
----------------------------------------------------------------- Health text --
function addon:CreateHealthText(frame, f)
	f.health.p = f:CreateFontString(f.overlay, {
		font = self.font,
		size = "health",
		alpha = 1,
		outline = "OUTLINE"
	})

	f.health.p:SetHeight(10)
	f.health.p:SetJustifyH("RIGHT")
	f.health.p:SetJustifyV("MIDDLE")
	f.health.p.osize = "health" -- original font size used to update/restore

	if self.db.profile.hp.text.mouseover then
		f.health.p:Hide()
	end
end
function addon:UpdateHealthText(f, trivial)
	if trivial then
		f.health.p:Hide()
	else
		if not self.db.profile.hp.text.mouseover then
			f.health.p:Show()
		end

		local anch2, anch1 = self.db.profile.text.healthanchorpoint or "BOTTOMRIGHT", ""

		if anch2:find("BOTTOM") then
			anch1 = "TOP"
			f.health.p:SetJustifyV("BOTTOM")
		elseif anch2:find("TOP") then
			anch1 = "BOTTOM"
			f.health.p:SetJustifyV("TOP")
		else
			f.health.p:SetJustifyV("MIDDLE")
		end

		if anch2:find("LEFT") then
			anch1 = anch1 .. "LEFT"
			f.health.p:SetJustifyH("LEFT")
		elseif anch2:find("RIGHT") then
			anch1 = anch1 .. "RIGHT"
			f.health.p:SetJustifyH("RIGHT")
		end

		f.health.p:ClearAllPoints()
		f.health.p:SetPoint(anch1, f.health, anch2, self.db.profile.text.healthoffsetx or 0, self.db.profile.text.healthoffsety or 0)
	end
end
------------------------------------------------------------------ Level text --
function addon:CreateLevel(frame, f)
	if not f.level then
		return
	end

	f.level = f:CreateFontString(f.level, {
		reset = true,
		font = self.font,
		size = "level",
		alpha = 1,
		outline = "OUTLINE"
	})

	f.level:SetParent(f.overlay)
	f.level:SetJustifyH("LEFT")
	f.level:SetJustifyV("MIDDLE")
	f.level:SetHeight(10)
	f.level:ClearAllPoints()
	f.level.osize = "level" -- original font size used to update/restore

	if self.db.profile.text.level then
		f.level.enabled = true
	end
end
function addon:UpdateLevel(f, trivial)
	if trivial then
		f.level:Hide()
	else
		local anch2, anch1 = self.db.profile.text.levelanchorpoint or "BOTTOMLEFT", ""

		if anch2:find("BOTTOM") then
			f.level:SetJustifyV("BOTTOM")
			anch1 = "TOP"
		elseif anch2:find("TOP") then
			f.level:SetJustifyV("TOP")
			anch1 = "BOTTOM"
		else
			f.level:SetJustifyV("MIDDLE")
		end

		if anch2:find("LEFT") then
			anch1 = anch1 .. "LEFT"
			f.level:SetJustifyH("LEFT")
		elseif anch2:find("RIGHT") then
			anch1 = anch1 .. "RIGHT"
			f.level:SetJustifyH("RIGHT")
		end

		f.level:ClearAllPoints()
		f.level:SetPoint(anch1, f.health, anch2, self.db.profile.text.leveloffsetx or 2.5, self.db.profile.text.leveloffsety or 0)
	end
end
------------------------------------------------------------------- Name text --
function addon:CreateName(frame, f)
	f.name = f:CreateFontString(f.overlay, {
		font = self.font,
		size = "name",
		outline = "OUTLINE"
	})

	f.name.osize = "name" -- original font size used to update/restore
	f.name:SetHeight(10)
end
function addon:UpdateName(f, trivial)
	f.name:ClearAllPoints()
	f.name:SetWidth(0)

	local anch2, anch1 = self.db.profile.text.nameanchorpoint or "TOP", ""
	if anch2 == "BOTTOM" then
		anch1 = "TOP"
		f.name:SetJustifyV("TOP")
		f.name:SetJustifyH("CENTER")
	elseif anch2 == "TOP" then
		anch1 = "BOTTOM"
		f.name:SetJustifyV("BOTTOM")
		f.name:SetJustifyH("CENTER")
	elseif anch2 == "LEFT" then
		anch1 = "RIGHT"
		f.name:SetJustifyV("MIDDLE")
		f.name:SetJustifyH("RIGHT")
	elseif anch2 == "RIGHT" then
		anch1 = "LEFT"
		f.name:SetJustifyV("MIDDLE")
		f.name:SetJustifyH("LEFT")
	end

	f.name:SetPoint(anch1, f.health, anch2, self.db.profile.text.nameoffsetx or 2.5, self.db.profile.text.nameoffsety or 0)
	if trivial then
		f.name:SetWidth(addon.sizes.frame.twidth * 2)
	else
		f.name:SetWidth(addon.sizes.frame.width * 2)
	end
end
----------------------------------------------------------------- Target glow --
function addon:CreateTargetGlow(f)
	f.targetGlow = f.overlay:CreateTexture(nil, "ARTWORK")
	f.targetGlow:SetTexture("Interface\\AddOns\\Kui_Nameplates\\Media\\target-glow")
	f.targetGlow:SetTexCoord(0, .593, 0, .875)
	f.targetGlow:SetPoint("TOP", f.overlay, "BOTTOM", 0, 1)
	f.targetGlow:SetVertexColor(unpack(self.db.profile.general.targetglowcolour))
	f.targetGlow:Hide()
end
function addon:UpdateTargetGlow(f, trivial)
	if not f.targetGlow then
		return
	end
	if trivial then
		f.targetGlow:SetSize(self.sizes.tex.ttargetGlowW, self.sizes.tex.targetGlowH)
	else
		f.targetGlow:SetSize(self.sizes.tex.targetGlowW, self.sizes.tex.targetGlowH)
	end
end
-- raid icon ###################################################################
local PositionRaidIcon = {
	function(f) return f.icon:SetPoint("RIGHT", f.overlay, "LEFT", -8, 0) end,
	function(f) return f.icon:SetPoint("BOTTOM", f.overlay, "TOP", 0, 12) end,
	function(f) return f.icon:SetPoint("LEFT", f.overlay, "RIGHT", 8, 0) end,
	function(f) return f.icon:SetPoint("TOP", f.overlay, "BOTTOM", 0, -8) end
}

function addon:UpdateRaidIcon(f)
	f.icon:SetParent(f.overlay)
	f.icon:SetSize(addon.sizes.tex.raidicon, addon.sizes.tex.raidicon)

	f.icon:ClearAllPoints()
	if PositionRaidIcon[addon.db.profile.general.raidicon_side] then
		PositionRaidIcon[addon.db.profile.general.raidicon_side](f)
	else
		PositionRaidIcon[3](f)
	end
end