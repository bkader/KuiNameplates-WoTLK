--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
-- Backported by: Kader at https://github.com/bkader
]]
local addon = LibStub("AceAddon-3.0"):GetAddon("KuiNameplates")
local mod = addon:NewModule("CastWarnings", addon.Prototype, "AceEvent-3.0")
local kui = LibStub("Kui-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("KuiNameplates")

mod.uiName = L["Cast warnings"]

-- combat log events to listen to for cast warnings/healing
local warningEvents = {
	["SPELL_CAST_START"] = true,
	["SPELL_CAST_SUCCESS"] = true,
	["SPELL_INTERRUPT"] = true,
	["SPELL_HEAL"] = true,
	["SPELL_PERIODIC_HEAL"] = true
}

-- spell school colors
local schoolcolors = {
	[1] = {a = 1.00, r = 1.00, g = 1.00, b = 0.00}, -- Physical
	[2] = {a = 1.00, r = 1.00, g = 0.90, b = 0.50}, -- Holy
	[4] = {a = 1.00, r = 1.00, g = 0.50, b = 0.00}, -- Fire
	[8] = {a = 1.00, r = 0.30, g = 1.00, b = 0.30}, -- Nature
	[16] = {a = 1.00, r = 0.50, g = 1.00, b = 1.00}, -- Frost
	[20] = {a = 1.00, r = 0.50, g = 1.00, b = 1.00}, -- Frostfire
	[32] = {a = 1.00, r = 0.50, g = 0.50, b = 1.00}, -- Shadow
	[64] = {a = 1.00, r = 1.00, g = 0.50, b = 1.00} -- Arcane
}

-- wrapper for kui.framefade;
-- reimplementing previous behaviour from animation groups
local function FadeFrame(self, from, to, duration, end_delay, callback)
	kui.frameFadeRemoveFrame(self)

	self:Show()
	self:SetAlpha(from)

	kui.frameFade(self, {
		mode = "OUT",
		startAlpha = from,
		endAlpha = to,
		timeToFade = duration,
		fadeHoldTime = end_delay,
		finishedFunc = function(self)
			if to == 0 then
				self:Hide()
			else
				self:SetAlpha(to)
			end

			if callback then
				callback(self)
			end
		end
	})
end

------------------------------------------------------------- Frame functions --
local function SetCastWarning(self, spellName, spellSchool)
	self.castWarning:Stop()

	if spellName == nil then
		-- hide the warning instantly
		self.castWarning:SetText()
		self.castWarning:Hide()
	else
		local col = schoolcolors[spellSchool] or {r = 1, g = 1, b = 1}

		self.castWarning:SetText(spellName)
		self.castWarning:SetTextColor(col.r, col.g, col.b)
		self.castWarning:Fade()
	end
end

local function SetIncomingWarning(self, amount)
	if amount == 0 then
		return
	end
	self.incWarning:Stop()

	if amount > 0 then
		-- healing
		amount = "+" .. amount
		self.incWarning:SetTextColor(0, 1, 0)
	else
		-- damage (nyi)
		self.incWarning:SetTextColor(1, 0, 0)
	end

	self.incWarning:SetText(amount)
	self.incWarning:Fade()
end

-------------------------------------------------------------- Event handlers --
function mod:COMBAT_LOG_EVENT_UNFILTERED(_, castTime, event, guid, name, _, targetGUID, targetName, _, _, spellName, spellSchool, amount)
	if not (guid and targetGUID) then
		return
	end

	if warningEvents[event] then
		if event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
			-- fetch the spell's target's nameplate
			guid, name = targetGUID, targetName
		end

		if self.db.profile.useNames and name then
			name = name and name:gsub("%-.+$", "") -- remove realm names
		else
			name = nil
		end

		local f = addon:GetNameplate(guid, name)
		if f then
			if not f.castWarning or f.trivial then
				return
			end
			if event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
				-- display heal warning
				f:SetIncomingWarning(amount)
			elseif event == "SPELL_INTERRUPT" then
				-- hide the warning
				f:SetCastWarning(nil)
			else
				-- or display it for this spell
				f:SetCastWarning(spellName, spellSchool)
			end
		end
	end
end

---------------------------------------------------------------------- Create --
function mod:CreateCastWarnings(msg, frame)
	-- casting spell name
	frame.castWarning = frame:CreateFontString(frame.overlay, {size = "spellName", outline = "OUTLINE"})
	frame.castWarning:Hide()
	frame.castWarning:SetPoint("BOTTOM", frame.name, "TOP", 0, 1)

	frame.castWarning.Fade = function(self)
		FadeFrame(self, 1, 0, 3)
	end
	frame.castWarning.Stop = function(self)
		kui.frameFadeRemoveFrame(self)
	end

	-- incoming healing
	frame.incWarning = frame:CreateFontString(frame.overlay, {size = "small", outline = "OUTLINE"})
	frame.incWarning:Hide()
	frame.incWarning:SetPoint("TOP", frame.name, "BOTTOM", 0, -3)

	frame.incWarning.Fade = function(self, full)
		if full then
			FadeFrame(self, 0.5, 0, 0.5)
		else
			FadeFrame(self, 1, 0.5, 0.5, 0.5, function(self) self:Fade(true) end)
		end
	end
	frame.incWarning.Stop = function(self)
		kui.frameFadeRemoveFrame(self)
	end

	-- handlers
	frame.SetCastWarning = SetCastWarning
	frame.SetIncomingWarning = SetIncomingWarning
end

function mod:Hide(msg, frame)
	if frame.castWarning then
		frame.castWarning:Stop()
		frame.castWarning:SetText()
		frame.castWarning:Hide()

		frame.incWarning:Stop()
		frame.incWarning:SetText()
		frame.incWarning:Hide()
	end
end

---------------------------------------------------- Post db change functions --
mod:AddConfigChanged("warnings", function(v) mod:Toggle(v) end)
-------------------------------------------------------------------- Register --
function mod:GetOptions()
	return {
		warnings = {
			type = "toggle",
			name = L["Show cast warnings"],
			desc = L["Display cast and healing warnings on plates"],
			order = 1,
			disabled = false
		},
		useNames = {
			type = "toggle",
			name = L["Use names for warnings"],
			desc = L["Use character names to decide which frame to display warnings on. May increase memory usage and may cause warnings to be displayed on incorrect frames when there are many units with the same name. Reccommended on for PvP, off for PvE."],
			order = 2
		}
	}
end

function mod:OnInitialize()
	self.db = addon.db:RegisterNamespace(self.moduleName, {profile = {warnings = false, useNames = false}})

	addon:InitModuleOptions(self)
	mod:SetEnabledState(self.db.profile.warnings)
end

function mod:OnEnable()
	self:RegisterMessage("KuiNameplates_PostCreate", "CreateCastWarnings")
	self:RegisterMessage("KuiNameplates_PostHide", "Hide")

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	for _, frame in pairs(addon.frameList) do
		if not frame.castWarning then
			self:CreateCastWarnings(nil, frame.kui)
		end
	end
end

function mod:OnDisable()
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	for _, frame in pairs(addon.frameList) do
		self:Hide(nil, frame.kui)
	end
end