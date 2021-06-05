--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- Backported by: Kader at https://github.com/bkader
--
-- changes colour of health bars based on health percentage
]]
local addon = LibStub("AceAddon-3.0"):GetAddon("KuiNameplates")
local mod = addon:NewModule("LowHealthColours", addon.Prototype, "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("KuiNameplates")

mod.uiName = L["Low health colour"]

local LOW_HEALTH_COLOR, PRIORITY, OVER_CLASSCOLOUR

local function OnHealthValueChanged(oldHealth, current)
	local frame = oldHealth:GetParent().kui

	if (frame.tapped) or (not OVER_CLASSCOLOUR and frame.player and not frame.friend) then
		-- don't show on enemy players or tapped units
		return
	end

	local percent = frame.health.percent

	if percent <= addon.db.profile.general.lowhealthval then
		frame:SetHealthColour(PRIORITY, unpack(LOW_HEALTH_COLOR))
		frame.stuckLowHealth = true
	elseif frame.stuckLowHealth then
		frame:SetHealthColour(false)
		frame.stuckLowHealth = nil
	end
end

function mod:PostCreate(msg, frame)
	frame.oldHealth:HookScript("OnValueChanged", OnHealthValueChanged)
end

function mod:PostShow(msg, frame)
	-- call our hook onshow, too
	OnHealthValueChanged(frame.oldHealth, frame.oldHealth:GetValue())
end

-- config changed hooks ########################################################
mod:AddConfigChanged("enabled", function(v) mod:Toggle(v) end)
mod:AddConfigChanged("colour", function(v) LOW_HEALTH_COLOR = v end)
mod:AddConfigChanged("over_tankmode", function(v) PRIORITY = v and 15 or 5 end)
mod:AddConfigChanged("over_classcolour", function(v) OVER_CLASSCOLOUR = v end)
-- config hooks ################################################################
function mod:GetOptions()
	return {
		enabled = {
			type = "toggle",
			name = L["Change colour of health bars at low health"],
			desc = L['Change the colour of low health units\' health bars. "Low health" is determined by the "Low health value" option under "General display".'],
			width = "double",
			order = 10
		},
		over_tankmode = {
			type = "toggle",
			name = L["Override tank mode"],
			desc = L["When using tank mode, allow the low health colour to override tank mode colouring"],
			order = 20
		},
		over_classcolour = {
			type = "toggle",
			name = L["Show on enemy players"],
			desc = L["Show on enemy players - i.e. override class colours"],
			order = 30
		},
		colour = {
			type = "color",
			name = L["Low health colour"],
			desc = L["The colour to use"],
			order = 40
		}
	}
end
function mod:OnInitialize()
	self.db = addon.db:RegisterNamespace(self.moduleName, {profile = {
		enabled = true,
		over_tankmode = false,
		over_classcolour = true,
		colour = {1, 1, .85}
	}})

	addon:InitModuleOptions(self)

	LOW_HEALTH_COLOR = self.db.profile.colour
	PRIORITY = self.db.profile.over_tankmode and 15 or 5
	OVER_CLASSCOLOUR = self.db.profile.over_classcolour

	self:SetEnabledState(self.db.profile.enabled)
end
function mod:OnEnable()
	self:RegisterMessage("KuiNameplates_PostCreate", "PostCreate")
	self:RegisterMessage("KuiNameplates_PostShow", "PostShow")
end
function mod:OnDisable()
	self:UnregisterMessage("KuiNameplates_PostCreate", "PostCreate")
	self:UnregisterMessage("KuiNameplates_PostShow", "PostShow")
end