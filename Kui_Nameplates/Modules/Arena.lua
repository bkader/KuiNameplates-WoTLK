--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
-- Backported by: Kader at github.com/bkader
--
-- Modifications for plates while in an arena
]]
local addon = LibStub("AceAddon-3.0"):GetAddon("KuiNameplates")
local mod = addon:NewModule("Arena", addon.Prototype, "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("KuiNameplates")

mod.uiName = L["Arena modifications"]

local UnitExists, UnitName = UnitExists, UnitName
local in_arena

function mod:IsArenaPlate(frame)
	if frame.friend then
		frame.level:SetText()
		return
	end

	for i = 1, 5 do
		if UnitExists("arena" .. i) and frame.name.text == UnitName("arena" .. i) then
			frame.level:SetText(i)
			return
		elseif UnitExists("arenapet" .. i) and frame.name.text == UnitName("arenapet" .. i) then
			frame.level:SetText(i .. "*")
			return
		end
	end

	-- unhandled name
	frame.level:SetText()
end

function mod:PostShow(msg, frame)
	if in_arena and not frame.friend then
		self:IsArenaPlate(frame)
		frame.level:SetWidth(0)
		frame.level:Show()
	end
end

function mod:UNIT_NAME_UPDATE(event, unit)
	if not strfind(unit, "^arena") then
		return
	end

	local frame = addon:GetUnitPlate(unit)
	if not frame or frame.friend then
		return
	end

	self:IsArenaPlate(frame)
	frame.level:SetWidth(0)
	frame.level:Show()
end

function mod:CheckArena()
	local in_instance, instance_type = IsInInstance()
	if in_instance and instance_type == "arena" then
		in_arena = true
		self:RegisterMessage("KuiNameplates_PostShow", "PostShow")
		self:RegisterEvent("UNIT_NAME_UPDATE")
	else
		in_arena = nil
		self:UnregisterMessage("KuiNameplates_PostShow", "PostShow")
		self:UnregisterEvent("UNIT_NAME_UPDATE")
	end
end

function mod:OnInitialize()
	self:SetEnabledState(true)
end

function mod:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "CheckArena")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "CheckArena")
end

function mod:OnDisable()
	self:UnregisterAllEvents()
end