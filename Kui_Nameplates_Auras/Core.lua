--[[
-- Kui_Nameplates_Auras
-- By Kesava at curse.com
-- All rights reserved
-- Backported by: Kader at https://github.com/bkader
-- Auras module for Kui_Nameplates core layout.
]]
local addon = LibStub("AceAddon-3.0"):GetAddon("KuiNameplates")
local spelllist = LibStub("KuiSpellList-1.0")
local kui = LibStub("Kui-1.0")
local mod = addon:NewModule("Auras", addon.Prototype, "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("KuiNameplatesAuras")
local whitelist, namedlist, _

local GetTime, floor, ceil, format = GetTime, floor, ceil, format
local UnitExists, UnitGUID = UnitExists, UnitGUID

local PLAYER_GUID = UnitGUID("player")

local sizes = {}
local num_per_column, trivial_num_per_column
local size_ratio, icon_ratio

-- store profiles to reduce lookup in OnAuraUpdate
local db_display, db_behav

-- auras pulsate when they have less than this many seconds remaining
local FADE_THRESHOLD = 5

-- combat log events to listen to for fading auras
local REMOVAL_EVENTS = {
	["SPELL_AURA_REMOVED"] = true,
	["SPELL_AURA_BROKEN"] = true,
	["SPELL_AURA_BROKEN_SPELL"] = true
}
local ADDITION_EVENTS = {
	["SPELL_AURA_APPLIED"] = true,
	["SPELL_AURA_REFRESH"] = true,
	["SPELL_AURA_REMOVED_DOSE"] = true,
	["SPELL_AURA_APPLIED_DOSE"] = true
}

local function UpdateSizes()
	-- Update size/position related variables
	size_ratio = mod.db.profile.icons.squareness
	sizes.auraWidth = mod.db.profile.icons.icon_size
	sizes.tauraWidth = mod.db.profile.icons.trivial_icon_size

	sizes.auraHeight = floor(sizes.auraWidth * size_ratio)
	sizes.tauraHeight = floor(sizes.tauraWidth * size_ratio)

	-- used by SetTexCoord
	icon_ratio = (1 - (sizes.auraHeight / sizes.auraWidth)) / 2

	sizes.aurasOffset = 14
	sizes.taurasOffset = 14

	-- calculate width of container & number of icons per column
	local normal_width = addon.db.profile.general.width
	num_per_column = floor(normal_width / (sizes.auraWidth + 1))
	sizes.container_width = (sizes.auraWidth * num_per_column) + (1 * (num_per_column - 1))
	sizes.container_offset = (normal_width - sizes.container_width) / 2

	-- and the trivial version...
	local trivial_width = addon.db.profile.general.twidth
	trivial_num_per_column = floor(trivial_width / (sizes.tauraWidth + 1))
	sizes.trivial_container_width = (sizes.tauraWidth * trivial_num_per_column) + (1 * (trivial_num_per_column - 1))
	sizes.trivial_container_offset = (trivial_width - sizes.trivial_container_width) / 2
end
local function UpdateButtonSize(self, button)
	-- Set size of an aura icon
	-- Used whenever a button is requested to be shown
	button.icon:SetTexCoord(.1, .9, .1 + icon_ratio, .9 - icon_ratio)

	if self.frame.trivial then
		-- shrink icons for trivial frames!
		button:SetHeight(sizes.tauraHeight)
		button:SetWidth(sizes.tauraWidth)
	else
		-- normal size!
		button:SetHeight(sizes.auraHeight)
		button:SetWidth(sizes.auraWidth)
	end

	if button:GetWidth() <= 21 then
		-- use small text for small icons
		button.time:SetFontSize("small")
		button.count:SetFontSize("small")
	else
		button.time:SetFontSize("name")
		button.count:SetFontSize("name")
	end
end
local function UpdateContainerSize(frame)
	-- Set size and position of the container frame
	-- Used OnFrameShow
	local v_offset = frame.trivial and sizes.taurasOffset or sizes.aurasOffset
	frame.auras.num_per_column = frame.trivial and trivial_num_per_column or num_per_column

	frame.auras:SetWidth(frame.trivial and sizes.trivial_container_width or sizes.container_width)
	frame.auras:SetPoint("BOTTOMLEFT", frame.health, "TOPLEFT", -1 + (frame.trivial and sizes.trivial_container_offset or sizes.container_offset), v_offset)
end
local function UpdateAllButtons(frame)
	-- Update the container and button sizes
	-- Used only by configChangedFuncs
	UpdateContainerSize(frame)

	for k, b in ipairs(frame.auras.buttons) do
		UpdateButtonSize(frame.auras, b)
	end

	frame.auras:ArrangeButtons()
end

-- stored spell id durations
-- used for giving timers to aura icons when they're added by the combat log
local stored_spells = {}

local function ArrangeButtons(self)
	local pv, pc
	self.visible = 0

	for k, b in ipairs(self.buttons) do
		if b:IsShown() then
			self.visible = self.visible + 1

			b:ClearAllPoints()

			if pv then
				if (self.visible - 1) % self.num_per_column == 0 then
					-- start of row
					b:SetPoint("BOTTOMLEFT", pc, "TOPLEFT", 0, 1)
					pc = b
				else
					-- subsequent button in a row
					b:SetPoint("LEFT", pv, "RIGHT", 1, 0)
				end
			else
				-- first button
				b:SetPoint("BOTTOMLEFT")
				pc = b
			end

			pv = b
		end
	end

	if self.visible == 0 then
		self:Hide()
	else
		self:Show()
	end
end
-- aura pulsating functions ----------------------------------------------------
local DoPulsateAura
do
	local function OnFadeOutFinished(button)
		button.fading = nil
		button.faded = true
		DoPulsateAura(button)
	end
	local function OnFadeInFinished(button)
		button.fading = nil
		button.faded = nil
		DoPulsateAura(button)
	end

	DoPulsateAura = function(button)
		if button.fading or not button.doPulsate then
			return
		end
		button.fading = true

		if button.faded then
			kui.frameFade(button, {
				startAlpha = .5,
				timeToFade = .5,
				finishedFunc = OnFadeInFinished
			})
		else
			kui.frameFade(button, {
				mode = "OUT",
				endAlpha = .5,
				timeToFade = .5,
				finishedFunc = OnFadeOutFinished
			})
		end
	end
end
local function StopPulsatingAura(button)
	kui.frameFadeRemoveFrame(button)
	button.doPulsate = nil
	button.fading = nil
	button.faded = nil
	button:SetAlpha(1)
end
--------------------------------------------------------------------------------
local function OnAuraUpdate(self, elapsed)
	self.elapsed = self.elapsed - elapsed

	if self.elapsed <= 0 then
		local timeLeft = (self.expirationTime or 0) - GetTime()

		if db_display.pulsate then
			if self.doPulsate and timeLeft > FADE_THRESHOLD then
				-- reset pulsating status if the time is extended
				StopPulsatingAura(self)
			elseif not self.doPulsate and timeLeft <= FADE_THRESHOLD then
				-- make the aura pulsate
				self.doPulsate = true
				DoPulsateAura(self)
			end
		end

		if db_display.timerThreshold > -1 and timeLeft > db_display.timerThreshold then
			self.time:Hide()
		else
			local timeLeftS

			if db_display.decimal and timeLeft <= 1 and timeLeft > 0 then
				-- decimal places for the last second
				timeLeftS = format("%.1f", timeLeft)
			else
				timeLeftS = (timeLeft > 60 and ceil(timeLeft / 60) .. "m" or floor(timeLeft))
			end

			if timeLeft <= 5 then
				-- red text
				self.time:SetTextColor(1, 0, 0)
			elseif timeLeft <= 20 then
				-- yellow text
				self.time:SetTextColor(1, 1, 0)
			else
				-- white text
				self.time:SetTextColor(1, 1, 1)
			end

			self.time:SetText(timeLeftS)
			self.time:Show()
		end

		if timeLeft < 0 then
			-- used when a non-targeted mob's auras timer gets below 0
			-- but the combat log hasn't reported that it has faded yet.
			self.time:Hide()
			self:SetScript("OnUpdate", nil)
			StopPulsatingAura(self)
			return
		end

		if db_display.decimal and timeLeft <= 2 and timeLeft > 0 then
			-- faster updates in the last two seconds
			self.elapsed = .05
		else
			self.elapsed = .5
		end
	end
end
local function OnAuraShow(self)
	local parent = self:GetParent()
	if not parent or parent.frame.MOVING then
		return
	end
	parent:ArrangeButtons()

	addon:SendMessage("KuiNameplates_PostAuraShow", parent.frame, self.spellid)
end
local function OnAuraHide(self)
	local parent = self:GetParent()
	if not parent or parent.frame.MOVING then
		return
	end

	if parent.spellids[self.spellid] == self then
		-- remove spell id from parent list
		parent.spellids[self.spellid] = nil
	end

	self.time:Hide()

	-- reset button pulsating
	StopPulsatingAura(self)

	parent:ArrangeButtons()

	addon:SendMessage("KuiNameplates_PostAuraHide", parent.frame, self.spellid)
	self.spellid = nil
end
local function UpdateButtonDuration(button, duration)
	if duration then
		-- set duration & expire time to given value
		button.duration = duration
		button.expirationTime = GetTime() + duration
	end

	if not button.expirationTime or not button.duration or button.duration == 0 then
		-- hide time on timeless auras
		button:SetScript("OnUpdate", nil)
		button.time:Hide()
	else
		button:SetScript("OnUpdate", OnAuraUpdate)
	end

	if db_display.sort then
		-- sort by expiration time
		table.sort(button:GetParent().buttons, function(a, b)
			if a.expirationTime and b.expirationTime then
				return a.expirationTime > b.expirationTime
			else
				return a.expirationTime and not b.expirationTime
			end
		end)

		button:GetParent():ArrangeButtons()
	end
end
local function GetAuraButton(self, spellid, icon, count, duration, expirationTime)
	local button

	if self.spellids[spellid] then
		-- use this spell's current button...
		button = self.spellids[spellid]
	elseif self.visible ~= #self.buttons then
		-- .. or reuse a hidden button...
		for k, b in pairs(self.buttons) do
			if not b:IsShown() then
				button = b
				break
			end
		end
	end

	if not button then
		-- ... or create a new button
		button = CreateFrame("Frame", nil, self)
		button:Hide()

		button.icon = button:CreateTexture(nil, "ARTWORK")

		button.time = self.frame:CreateFontString(button)
		button.time:SetJustifyH("LEFT")
		button.time:SetPoint("TOPLEFT", -1, 1)
		button.time:Hide()

		button.count = self.frame:CreateFontString(button)
		button.count:SetJustifyH("RIGHT")
		button.count:SetPoint("BOTTOMRIGHT", 2, -2)
		button.count:Hide()

		button:SetBackdrop({bgFile = kui.m.t.solid})
		button:SetBackdropColor(0, 0, 0)

		button.icon:SetPoint("TOPLEFT", 1, -1)
		button.icon:SetPoint("BOTTOMRIGHT", -1, 1)

		tinsert(self.buttons, button)

		button:SetScript("OnHide", OnAuraHide)
		button:SetScript("OnShow", OnAuraShow)
	end

	button.icon:SetTexture(icon)

	if count > 1 and not self.frame.trivial then
		button.count:SetText(count)
		button.count:Show()
	else
		button.count:Hide()
	end

	button.duration = duration
	button.expirationTime = expirationTime
	button.spellid = spellid
	button.elapsed = 0

	UpdateButtonSize(self, button)
	UpdateButtonDuration(button)

	-- store this spell's original duration
	stored_spells[spellid] = duration or 0

	self.spellids[spellid] = button

	return button
end
local function DisplayAura(self, spellid, name, icon, count, duration, expirationTime)
	if not spellid then
		return
	end
	name = name or GetSpellInfo(spellid)
	if not name then
		return
	end

	if db_behav.useWhitelist and not (whitelist[spellid] or whitelist[name] or namedlist[name]) then
		-- not in whitelist
		return
	end

	-- apply duration from spell store
	if not duration then
		duration = stored_spells[spellid]

		if duration then
			expirationTime = GetTime() + duration
		end
	-- otherwise, this is a timeless aura
	end

	if duration and duration > 0 and duration < db_display.lengthMin then
		-- duration below minimum
		return
	end

	if db_display.lengthMax > -1 and (not duration or duration <= 0 or duration > db_display.lengthMax) then
		-- duration above maximum or timeless and a maximum duration is set
		return
	end

	local button = self:GetAuraButton(spellid, icon, count, duration, expirationTime)
	self:Show()

	button:Show()
	button.used = true
end
----------------------------------------------------------------------- hooks --
function mod:Create(msg, frame)
	frame.auras = CreateFrame("Frame", nil, frame)
	frame.auras.frame = frame

	-- Position and size is set OnShow (below)
	frame.auras:SetHeight(10)
	frame.auras:Hide()

	frame.auras.visible = 0
	frame.auras.buttons = {}
	frame.auras.spellids = {}
	frame.auras.GetAuraButton = GetAuraButton
	frame.auras.ArrangeButtons = ArrangeButtons
	frame.auras.DisplayAura = DisplayAura

	frame.auras:SetScript("OnHide", function(self)
		if self.frame.MOVING then
			return
		end
		for k, b in pairs(self.buttons) do
			b:Hide()
		end

		self.visible = 0
	end)
end
function mod:Show(msg, frame)
	UpdateContainerSize(frame)
end
function mod:Hide(msg, frame)
	if frame.auras then
		frame.auras:Hide()
	end
end
-------------------------------------------------------------- event handlers --
function mod:COMBAT_LOG_EVENT_UNFILTERED(_, castTime, event, guid, name, _, destGUID, destName, _, spellid, spellname)
	-- used to hide expired auras on previously known frames
	-- to detect aura updates on the mouseover, if it exists
	-- (since UNIT_AURA doesn't fire for mouseover)
	-- and place auras on frames for which GUIDs are known, if possible
	if not guid and guid ~= PLAYER_GUID then
		return
	end

	if REMOVAL_EVENTS[event] or (db_behav.showSecondary and ADDITION_EVENTS[event]) then
		-- events on the current target will be caught by UNIT_AURA
		-- some other units will fire twice too, but this catches the majority
		if destGUID == UnitGUID("target") then
			return
		end

		if destGUID == UnitGUID("mouseover") then
			-- event on the mouseover unit - update directly
			self:UNIT_AURA("UNIT_AURA", "mouseover")
			return
		end

		-- only listen for simple removals/additions from now
		-- fetch the subject's nameplate
		local f = addon:GetNameplate(destGUID, destName)
		if not f or not f.auras then
			return
		end
		if (f.trivial and not self.db.profile.showtrivial) or f.friend then
			return
		end

		if not (spellid or spellname) then
			return
		end

		if REMOVAL_EVENTS[event] then
			-- hide an aura button when the combat log reports it has expired
			local btn = f.auras.spellids[spellid] or f.auras.spellids[namedlist[spellname]]
			if btn then
				btn:Hide()
			end
		elseif ADDITION_EVENTS[event] then
			local btn = f.auras.spellids[spellid] or f.auras.spellids[namedlist[spellname]]
			if btn then
				-- reset timer to original duration
				UpdateButtonDuration(btn, stored_spells[spellid])
			else
				-- show a placeholder button with no timer when possible
				f.auras:DisplayAura(spellid, spellname, select(3, GetSpellInfo(spellid)), 1)
			end
		end
	end
end
function mod:PostTarget(msg, frame, is_target)
	if is_target then
		self:UNIT_AURA("UNIT_AURA", "target")
	end
end
function mod:UPDATE_MOUSEOVER_UNIT()
	self:UNIT_AURA("UNIT_AURA", "mouseover")
end
function mod:GUIDStored(msg, f, unit)
	self:UNIT_AURA("UNIT_AURA", unit, f)
end
function mod:UNIT_AURA(event, unit, frame)
	-- select the unit's nameplate
	--unit = 'target' -- DEBUG
	frame = frame or addon:GetNameplate(UnitGUID(unit))
	if not frame or not frame.auras then
		return
	end
	if frame.trivial and not self.db.profile.showtrivial then
		return
	end

	local filter = "PLAYER"
	if UnitIsFriend(unit, "player") then
		filter = filter .. "|HELPFUL"
	else
		filter = filter .. "|HARMFUL"
	end

	for i = 1, 40 do
		local name, _, icon, count, _, duration, expirationTime, _, _, _, spellid = UnitAura(unit, i, filter)

		if spellid then
			frame.auras:DisplayAura(spellid, name, icon, count, duration, expirationTime)
		else
			break -- nothing found
		end
	end

	for _, button in pairs(frame.auras.buttons) do
		-- hide buttons that weren't used this update
		if not button.used then
			button:Hide()
		end

		button.used = nil
	end
end
function mod:PLAYER_ENTERING_WORLD(event)
	PLAYER_GUID = PLAYER_GUID or UnitGUID("player")
end
function mod:WhitelistChanged()
	-- update spell whitelist
	whitelist = spelllist.GetImportantSpells(select(2, UnitClass("player")))
	namedlist = {}
	for spellid, _ in pairs(whitelist) do
		namedlist[GetSpellInfo(spellid)] = spellid
	end
end
---------------------------------------------------- Post db change functions --
mod.configChangedListener = function(self)
	db_display = self.db.profile.display
	db_behav = self.db.profile.behav

	if not db_display.lengthMax then
		db_display.lengthMax = -1
	end

	if not db_display.lengthMin then
		db_display.lengthMin = 0
	end
end

mod:AddConfigChanged("enabled", function(v) mod:Toggle(v) end)
mod:AddConfigChanged("icons", UpdateSizes, UpdateAllButtons)
mod:AddGlobalConfigChanged("addon", {{"general", "width"}, {"general", "twidth"}}, UpdateSizes, UpdateAllButtons)

---------------------------------------------------- initialisation functions --
function mod:GetOptions()
	return {
		enabled = {
			type = "toggle",
			name = L["Show my auras"],
			desc = L["Display auras cast by you on the current target's nameplate"],
			order = 1,
			disabled = false
		},
		showtrivial = {
			type = "toggle",
			name = L["Show on trivial units"],
			desc = L["Show auras on trivial (half-size, lower maximum health) nameplates."],
			order = 3,
			disabled = function()
				return not self.db.profile.enabled
			end
		},
		behav = {
			type = "group",
			name = L["Behaviour"],
			inline = true,
			disabled = function()
				return not self.db.profile.enabled
			end,
			order = 5,
			args = {
				useWhitelist = {
					type = "toggle",
					name = L["Use whitelist"],
					desc = L["Only display spells which your class needs to keep track of for PVP or an effective DPS rotation. Most passive effects are excluded."],
					order = 0
				},
				showSecondary = {
					type = "toggle",
					name = L["Show on secondary targets"],
					desc = L["Attempt to show and refresh auras on secondary targets - i.e. nameplates which do not have a visible unit frame on the default UI. Particularly useful when tanking."],
					order = 10
				},
				customize = {
					type = "execute",
					name = L["Edit spell list"],
					order = 20,
					width = "double",
					func = function()
						addon:CloseConfig()
						InterfaceOptionsFrame_OpenToCategory(L["Kui |cff9966ffSpell List|r"])
						InterfaceOptionsFrame_OpenToCategory(L["Kui |cff9966ffSpell List|r"])
					end
				}
			}
		},
		display = {
			type = "group",
			name = L["Display"],
			inline = true,
			disabled = function()
				return not self.db.profile.enabled
			end,
			order = 10,
			args = {
				pulsate = {
					type = "toggle",
					name = L["Pulsate auras"],
					desc = L["Pulsate aura icons when they have less than 5 seconds remaining.\nSlightly increases memory usage."],
					order = 5
				},
				decimal = {
					type = "toggle",
					name = L["Show decimal places"],
					desc = L["Show decimal places (.9 to .0) when an aura has less than one second remaining, rather than just showing 0."],
					order = 8
				},
				sort = {
					type = "toggle",
					name = L["Sort auras by time remaining"],
					desc = L["Increases memory usage."],
					order = 10,
					width = "double"
				},
				timerThreshold = {
					type = "range",
					name = L["Timer threshold (s)"],
					desc = L["Timer text will be displayed on auras when their remaining length is less than or equal to this value. -1 to always display timer."],
					order = 15,
					min = -1,
					softMax = 180,
					step = 1
				},
				lengthMin = {
					type = "range",
					name = L["Effect length minimum (s)"],
					desc = L["Auras with a total duration of less than this value will never be displayed. 0 to disable."],
					order = 20,
					min = 0,
					softMax = 60,
					step = 1
				},
				lengthMax = {
					type = "range",
					name = L["Effect length maximum (s)"],
					desc = L["Auras with a total duration greater than this value will never be displayed. -1 to disable."],
					order = 30,
					min = -1,
					softMax = 1800,
					step = 1
				}
			}
		},
		icons = {
			type = "group",
			name = "Icons",
			inline = true,
			disabled = function()
				return not self.db.profile.enabled
			end,
			order = 20,
			args = {
				icon_size = {
					type = "range",
					name = L["Size"],
					desc = L["Aura icon size on normal frames"],
					order = 10,
					min = 1,
					softMin = 10,
					softMax = 50,
					step = 1
				},
				trivial_icon_size = {
					type = "range",
					name = L["Size (trivial)"],
					desc = L["Aura icon size on trivial frames"],
					order = 20,
					min = 5,
					softMax = 50,
					step = 1
				},
				squareness = {
					type = "range",
					name = L["Squareness"],
					desc = L["Where 1 is completely square and .5 is completely rectangular"],
					order = 30,
					min = .1,
					softMin = .5,
					max = 1,
					step = .1
				}
			}
		}
	}
end
function mod:OnInitialize()
	self.db = addon.db:RegisterNamespace(self.moduleName, {
		profile = {
			enabled = true,
			showtrivial = false,
			behav = {
				useWhitelist = true,
				showSecondary = true
			},
			display = {
				pulsate = true,
				decimal = true,
				sort = false,
				timerThreshold = 60,
				lengthMin = 0,
				lengthMax = -1
			},
			icons = {
				icon_size = 25,
				trivial_icon_size = 20,
				squareness = .7
			}
		}
	})

	addon:InitModuleOptions(self)
	mod:SetEnabledState(self.db.profile.enabled)

	UpdateSizes()

	self:WhitelistChanged()
	spelllist.RegisterChanged(self, "WhitelistChanged")
end
function mod:OnEnable()
	self:RegisterMessage("KuiNameplates_PostCreate", "Create")
	self:RegisterMessage("KuiNameplates_PostShow", "Show")
	self:RegisterMessage("KuiNameplates_PostHide", "Hide")
	self:RegisterMessage("KuiNameplates_GUIDStored", "GUIDStored")
	self:RegisterMessage("KuiNameplates_PostTarget", "PostTarget")

	self:RegisterEvent("UNIT_AURA")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	-- get guid immediately if enabled while in game
	self:PLAYER_ENTERING_WORLD()

	for _, frame in pairs(addon.frameList) do
		if not frame.auras then
			self:Create(nil, frame.kui)
		end
	end
end
function mod:OnDisable()
	self:UnregisterMessage("KuiNameplates_PostShow", "Show")
	self:UnregisterMessage("KuiNameplates_GUIDStored", "GUIDStored")
	self:UnregisterMessage("KuiNameplates_PostTarget", "PostTarget")

	self:UnregisterEvent("UNIT_AURA")
	self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")

	for _, frame in pairs(addon.frameList) do
		self:Hide(nil, frame.kui)
	end
end