--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
-- Backported by: Kader at github.com/bkader
]]
local kui = LibStub("Kui-1.0")
local addon = LibStub("AceAddon-3.0"):GetAddon("KuiNameplates")
local mod = addon:NewModule("Castbar", addon.Prototype, "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("KuiNameplates")

mod.uiName = L["Cast bars"]

local format = format
local function ResetFade(f)
	if not f or not f.castbar then
		return
	end

	kui.frameFadeRemoveFrame(f.castbar)
	f.castbar.shield:Hide()
	f.castbar:Hide()
	f.castbar:SetAlpha(1)
end

local sizes = {}

local function SetCVars()
	-- force these to true as the module hides them anyway
	SetCVar("showVKeyCastbar", 1)
end
------------------------------------------------------------- Script handlers --
local function OnDefaultCastbarShow(self)
	if not mod.enabledState then
		return
	end

	local f = self:GetParent().kui
	ResetFade(f)

	if mod:FrameIsIgnored(f) then
		return
	end

	if f.castbar.name and f.castbar.spellName then
		f.castbar.name:SetText(f.castbar.spellName)
	end

	-- is cast uninterruptible?
	if f.shield:IsShown() then
		f.castbar.bar:SetStatusBarColor(unpack(mod.db.profile.display.shieldbarcolour))
		f.castbar.shield:Show()
	else
		f.castbar.bar:SetStatusBarColor(unpack(mod.db.profile.display.barcolour))
		f.castbar.shield:Hide()
	end

	if f.trivial then
		-- hide text & icon
		if f.castbar.icon or f.castbar.curr then
			f.castbar.curr:Hide()
		end
	else
		if f.castbar.icon then
			f.castbar.icon.tex:SetTexture(f.spell:GetTexture())
			f.castbar.icon:Show()
		end

		if f.castbar.curr then
			f.castbar.curr:Show()
		end
	end
	-- castbar is shown on first update
end
local function OnDefaultCastbarHide(self)
	local f = self:GetParent().kui
	if f.castbar:IsShown() then
		kui.frameFade(
			f.castbar,
			{
				mode = "OUT",
				timeToFade = .5,
				startAlpha = 1,
				endAlpha = 0,
				finishedFunc = function()
					ResetFade(f)
				end
			}
		)

		if f.castbar.name then
			f.castbar.spellName = nil
			f.castbar.name:SetText("")
		end

		if f.castbar.icon then
			f.castbar.icon.tex:SetTexture(nil)
		end
	end
end
local function OnDefaultCastbarUpdate(self, elapsed)
	if not mod.enabledState then
		return
	end

	local f = self:GetParent().kui

	if mod:FrameIsIgnored(f) then
		return
	end

	local min, max = self:GetMinMaxValues()

	if f.castbar.curr then
		f.castbar.curr:SetText(format("%.1f", self:GetValue()))
	end

	if f.castbar.name and f.castbar.spellName then
		f.castbar.name:SetText(f.castbar.spellName)
	end

	f.castbar.bar:SetMinMaxValues(min, max)
	f.castbar.bar:SetValue(self:GetValue())

	if f.shield:IsShown() then
		f.castbar.bar:SetStatusBarColor(unpack(mod.db.profile.display.shieldbarcolour))
		f.castbar.shield:Show()
	else
		f.castbar.bar:SetStatusBarColor(unpack(mod.db.profile.display.barcolour))
		f.castbar.shield:Hide()
	end

	if f.trivial then
		-- hide text & icon
		if f.castbar.icon or f.castbar.curr then
			f.castbar.curr:Hide()
		end
	else
		if f.castbar.icon then
			f.castbar.icon.tex:SetTexture(f.spell:GetTexture())
			f.castbar.icon:Show()
		end

		if f.castbar.curr then
			f.castbar.curr:Show()
		end
	end

	f.castbar:Show()
end
local function OnDefaultCastbarEvent(self, event, unit, spellName, spellRank)
	if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
		local frame = addon:GetUnitPlate(unit)
		if frame and frame.castbar then
			frame.castbar.spellName = spellName
		end
	end
end
---------------------------------------------------------------------- create --
-- update castbar height and icon size
local function UpdateCastbar(frame)
	if not frame.castbar then
		return
	end

	if frame.castbar.bg then
		frame.castbar.bg:SetHeight(sizes.cbheight)
	end

	if frame.castbar.icon then
		frame.castbar.icon.bg:SetSize(sizes.icon, sizes.icon)
	end
end
function mod:CreateCastbar(frame)
	if frame.castbar then
		return
	end
	-- container ---------------------------------------------------------------
	frame.castbar = CreateFrame("Frame", nil, frame)
	frame.castbar:SetFrameLevel(1)
	frame.castbar:Hide()

	-- background --------------------------------------------------------------
	frame.castbar.bg = frame.castbar:CreateTexture(nil, "ARTWORK", nil, 1)
	frame.castbar.bg:SetTexture(kui.m.t.solid)
	frame.castbar.bg:SetVertexColor(0, 0, 0, 0.8)

	frame.castbar.bg:SetPoint("TOPLEFT", frame.bg.fill, "BOTTOMLEFT", 0, -1)
	frame.castbar.bg:SetPoint("TOPRIGHT", frame.bg.fill, "BOTTOMRIGHT", 0, 0)

	-- cast bar ------------------------------------------------------------
	frame.castbar.bar = CreateFrame("StatusBar", nil, frame.castbar)
	frame.castbar.bar:SetStatusBarTexture(addon.bartexture)
	frame.castbar.bar:GetStatusBarTexture():SetDrawLayer("ARTWORK", 2)

	frame.castbar.bar:SetPoint("TOPLEFT", frame.castbar.bg, "TOPLEFT", 1, -1)
	frame.castbar.bar:SetPoint("BOTTOMLEFT", frame.castbar.bg, "BOTTOMLEFT", 1, 1)
	frame.castbar.bar:SetPoint("RIGHT", frame.castbar.bg, "RIGHT", -1, 0)

	frame.castbar.bar:SetMinMaxValues(0, 1)

	-- spark
	frame.castbar.spark = frame.castbar.bar:CreateTexture(nil, "ARTWORK")
	frame.castbar.spark:SetDrawLayer("ARTWORK", 6)
	frame.castbar.spark:SetVertexColor(1, 1, 0.8)
	frame.castbar.spark:SetTexture("Interface\\AddOns\\Kui_Nameplates\\Media\\t\\spark")
	frame.castbar.spark:SetPoint("TOP", frame.castbar.bar:GetRegions(), "TOPRIGHT", 0, 3)
	frame.castbar.spark:SetPoint("BOTTOM", frame.castbar.bar:GetRegions(), "BOTTOMRIGHT", 0, -3)
	frame.castbar.spark:SetWidth(6)

	-- uninterruptible cast shield -----------------------------------------
	frame.castbar.shield = frame.castbar.bar:CreateTexture(nil, "ARTWORK")
	frame.castbar.shield:SetTexture("Interface\\AddOns\\Kui_Nameplates\\Media\\Shield")
	frame.castbar.shield:SetTexCoord(0, 0.84375, 0, 1)
	frame.castbar.shield:SetVertexColor(0.5, 0.5, 0.7)

	frame.castbar.shield:SetSize(sizes.shield * .84375, sizes.shield)
	frame.castbar.shield:SetPoint("LEFT", frame.castbar.bg, -7, 0)

	frame.castbar.shield:SetBlendMode("BLEND")
	frame.castbar.shield:SetDrawLayer("ARTWORK", 7)

	frame.castbar.shield:Hide()

	-- cast bar text -------------------------------------------------------
	if self.db.profile.display.spellname then
		frame.castbar.name = frame:CreateFontString(frame.castbar.bar, {size = "small"})
		frame.castbar.name:SetPoint("TOP", frame.castbar.bar, "BOTTOM", 0, -3)
	end

	if self.db.profile.display.casttime then
		frame.castbar.curr = frame:CreateFontString(frame.castbar.bar, {size = "small"})
		frame.castbar.curr:SetPoint("LEFT", frame.castbar.bg, "RIGHT", 2, 0)
	end

	if self.db.profile.display.spellicon then
		frame.castbar.icon = CreateFrame("Frame", nil, frame.castbar)

		frame.castbar.icon.bg = frame.castbar:CreateTexture(nil, "BACKGROUND")
		frame.castbar.icon.bg:SetTexture(kui.m.t.solid)
		frame.castbar.icon.bg:SetVertexColor(0, 0, 0, 0)
		frame.castbar.icon.bg:SetPoint("TOPRIGHT", frame.health, "TOPLEFT", -2, 1)

		frame.castbar.icon.tex = frame.castbar:CreateTexture(nil, "ARTWORK")
		frame.castbar.icon.tex:SetPoint("TOPLEFT", frame.castbar.icon.bg, "TOPLEFT", 1, -1)
		frame.castbar.icon.tex:SetPoint("BOTTOMRIGHT", frame.castbar.icon.bg, "BOTTOMRIGHT", -1, 1)
	end

	UpdateCastbar(frame)

	-- scripts -------------------------------------------------------------
	frame.oldCastbar:HookScript("OnShow", OnDefaultCastbarShow)
	frame.oldCastbar:HookScript("OnHide", OnDefaultCastbarHide)
	frame.oldCastbar:HookScript("OnUpdate", OnDefaultCastbarUpdate)
	frame.castbar:RegisterEvent("UNIT_SPELLCAST_START")
	frame.castbar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	frame.castbar:SetScript("OnEvent", OnDefaultCastbarEvent)

	if frame.oldCastbar:IsVisible() then
		OnDefaultCastbarShow(frame.oldCastbar)
	end
end
------------------------------------------------------------------------ Hide --
function mod:HideCastbar(frame)
	ResetFade(frame)
end
------------------------------------------------------------------- Functions --
function mod:FrameIsIgnored(frame)
	return frame.castbar_ignore_frame or (frame.friend and not self.db.profile.onfriendly)
end
function mod:IgnoreFrame(frame)
	frame.castbar_ignore_frame = (frame.castbar_ignore_frame and frame.castbar_ignore_frame + 1 or 1)

	if frame.castbar and frame.castbar:IsShown() then
		ResetFade(frame)
	end
end
function mod:UnignoreFrame(frame)
	frame.castbar_ignore_frame = (frame.castbar_ignore_frame and frame.castbar_ignore_frame - 1 or nil)
	if frame.castbar_ignore_frame and frame.castbar_ignore_frame <= 0 then
		frame.castbar_ignore_frame = nil
	end
end
---------------------------------------------------- Post db change functions --
mod:AddConfigChanged(
	"enabled",
	function(v)
		mod:Toggle(v)
	end
)
mod:AddConfigChanged(
	{"display", "shieldbarcolour"},
	nil,
	function(f, v)
		f.castbar.shield:SetVertexColor(unpack(v))
	end
)
mod:AddConfigChanged(
	{"display", "cbheight"},
	function()
		sizes.cbheight = mod.db.profile.display.cbheight
		sizes.icon = addon.db.profile.general.hheight + sizes.cbheight + 1
	end,
	UpdateCastbar
)
mod:AddGlobalConfigChanged("addon", {"general", "hheight"}, mod.configChangedFuncs.display.cbheight.ro, UpdateCastbar)
-------------------------------------------------------------------- Register --
function mod:GetOptions()
	return {
		enabled = {
			type = "toggle",
			name = L["Enable cast bar"],
			desc = L["Show cast bars (at all)"],
			order = 0,
			disabled = false
		},
		onfriendly = {
			type = "toggle",
			name = L["Show friendly cast bars"],
			desc = L["Show cast bars on friendly nameplates"],
			order = 10,
			disabled = function()
				return not self.db.profile.enabled
			end
		},
		display = {
			type = "group",
			name = L["Display"],
			inline = true,
			order = 20,
			disabled = function()
				return not self.db.profile.enabled
			end,
			args = {
				casttime = {
					type = "toggle",
					name = L["Show cast time"],
					desc = L["Show cast time and time remaining"],
					order = 20
				},
				spellname = {
					type = "toggle",
					name = L["Show spell name"],
					order = 15
				},
				spellicon = {
					type = "toggle",
					name = L["Show spell icon"],
					order = 10
				},
				barcolour = {
					type = "color",
					name = L["Bar colour"],
					desc = L["The colour of the cast bar during interruptible casts"],
					order = 0
				},
				shieldbarcolour = {
					type = "color",
					name = L["Uninterruptible colour"],
					desc = L["The colour of the cast bar and shield during UNinterruptible casts."],
					order = 5
				},
				cbheight = {
					type = "range",
					name = L["Height"],
					desc = L["The height of castbars on nameplates. Also affects the size of the spell icon."],
					order = 25,
					step = 1,
					min = 3,
					softMax = 20,
					max = 100
				}
			}
		}
	}
end
function mod:OnInitialize()
	self.db =
		addon.db:RegisterNamespace(
		self.moduleName,
		{
			profile = {
				enabled = true,
				onfriendly = true,
				display = {
					casttime = false,
					spellname = true,
					spellicon = true,
					cbheight = 5,
					barcolour = {.43, 0.47, 0.55, 1},
					shieldbarcolour = {.8, 0.1, 0.1, 1}
				}
			}
		}
	)

	addon:InitModuleOptions(self)
	self:SetEnabledState(self.db.profile.enabled)

	sizes = {cbheight = self.db.profile.display.cbheight, shield = 16}

	self.configChangedFuncs.display.cbheight.ro(sizes.cbheight)

	-- handle default interface cvars & checkboxes
	InterfaceOptionsCombatPanel:HookScript(
		"OnShow",
		function()
			InterfaceOptionsCombatPanelEnemyCastBarsOnNameplates:SetChecked(true)
			InterfaceOptionsCombatPanelEnemyCastBarsOnNameplates:Disable()
		end
	)
	InterfaceOptionsFrame:HookScript(
		"OnHide",
		function()
			SetCVars()
		end
	)

	SetCVars()
end
function mod:OnEnable()
	for _, frame in pairs(addon.frameList) do
		if not frame.kui or not frame.kui.castbar then
			self:CreateCastbar(frame.kui)
		end
	end
end
function mod:OnDisable()
	for _, frame in pairs(addon.frameList) do
		self:HideCastbar(frame.kui)
	end
end