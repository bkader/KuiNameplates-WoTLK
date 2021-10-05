--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
-- Backported by: Kader at https://github.com/bkader
]]
local addon = LibStub("AceAddon-3.0"):NewAddon("KuiNameplates", "AceEvent-3.0", "AceTimer-3.0")
addon.version = GetAddOnMetadata("Kui_Nameplates", "Version")
addon.website = GetAddOnMetadata("Kui_Nameplates", "X-Website")
_G.KuiNameplates = addon

local kui = LibStub("Kui-1.0")
local LSM = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("KuiNameplates")

local group_update
local GROUP_UPDATE_INTERVAL = 1
local group_update_elapsed

addon.font = ""
addon.uiscale = nil

addon.frameList = {}
addon.numFrames = 0

-- sizes of frame elements
-- some populated by UpdateSizesTable & ScaleFontSizes
addon.sizes = {
	frame = {
		bgOffset = 8 -- inset of the frame glow
	},
	tex = {
		targetGlowH = 7,
		targetArrow = 33
	},
	font = {}
}

-- as these are scaled with the user option we need to store the default
addon.defaultFontSizes = {
	large = 12,
	spellname = 11,
	name = 11,
	level = 11,
	health = 11,
	small = 9
}

-- add latin-only fonts to LSM
LSM:Register(LSM.MediaType.FONT, "Yanone Kaffesatz Bold", kui.m.f.yanone)
LSM:Register(LSM.MediaType.FONT, "FrancoisOne", kui.m.f.francois)
local DEFAULT_FONT = "FrancoisOne"

-- add my status bar textures too..
LSM:Register(LSM.MediaType.STATUSBAR, "Kui status bar", kui.m.t.bar)
LSM:Register(LSM.MediaType.STATUSBAR, "Kui shaded bar", kui.m.t.oldbar)
local DEFAULT_BAR = "Kui status bar"

local locale = GetLocale()
local latin = (locale ~= "zhCN" and locale ~= "zhTW" and locale ~= "koKR" and locale ~= "ruRU")

-------------------------------------------------------------- Default config --
local defaults = {
	profile = {
		general = {
			combataction_hostile = 1,
			combataction_friendly = 1,
			highlight = true, -- highlight plates on mouse-over
			highlight_target = false,
			fixaa = true, -- attempt to make plates appear sharper
			compatibility = false,
			bartexture = DEFAULT_BAR,
			targetglow = true,
			targetglowcolour = {.3, 0.7, 1, 1},
			targetarrows = false,
			hheight = 13,
			thheight = 9,
			width = 130,
			twidth = 72,
			glowshadow = true,
			strata = "BACKGROUND",
			lowhealthval = 20,
			raidicon_size = 30,
			raidicon_side = 3
		},
		fade = {
			smooth = true, -- smoothy fade plates
			fadespeed = .5, -- fade animation speed modifier
			fademouse = false, -- fade in plates on mouse-over
			fadeall = false, -- fade all plates by default
			fadedalpha = .5, -- the alpha value to fade plates out to
			rules = {
				avoidhostilehp = false,
				avoidfriendhp = false,
				avoidcast = false,
				avoidraidicon = true
			}
		},
		text = {
			level = false, -- display levels
			nameanchorpoint = "TOP",
			nameoffsetx = 0,
			nameoffsety = 0,
			levelanchorpoint = "BOTTOMLEFT",
			leveloffsetx = 0,
			leveloffsety = 2.5,
			healthanchorpoint = "BOTTOMRIGHT",
			healthoffsetx = 0,
			healthoffsety = 2.5
		},
		hp = {
			reactioncolours = {
				hatedcol = {.7, 0.2, 0.1},
				neutralcol = {1, 0.8, 0},
				friendlycol = {.2, 0.6, 0.1},
				tappedcol = {.5, 0.5, 0.5},
				playercol = {.2, 0.5, 0.9}
			},
			bar = {
				animation = 2
			},
			text = {
				hp_text_disabled = false,
				mouseover = false,
				hp_friend_max = 5,
				hp_friend_low = 4,
				hp_hostile_max = 5,
				hp_hostile_low = 3
			}
		},
		fonts = {
			options = {
				font = (latin and DEFAULT_FONT or LSM:GetDefault(LSM.MediaType.FONT)),
				fontscale = 1,
				outline = true,
				monochrome = false,
				onesize = false,
				noalpha = false
			},
			sizes = {
				large = 12,
				spellname = 11,
				name = 11,
				level = 11,
				health = 11,
				small = 9
			}
		}
	}
}
------------------------------------------ GUID/name storage functions --
do
	local knownGUIDs = {} -- GUIDs that we can relate to names (i.e. players)
	local knownIndex = {}

	-- loaded = visible frames that currently possess this key
	local loadedGUIDs, loadedNames = {}, {}

	function addon:StoreNameWithGUID(name, guid)
		-- used to provide aggressive name -> guid matching
		-- should only be used for players
		if not name or not guid then
			return
		end
		if knownGUIDs[name] then
			return
		end
		knownGUIDs[name] = guid
		tinsert(knownIndex, name)

		-- purging index > 100 names
		if #knownIndex > 100 then
			knownGUIDs[tremove(knownIndex, 1)] = nil
		end
	end

	function addon:GetGUID(f)
		-- give this frame a guid if we think we already know it
		if f.player and knownGUIDs[f.name.text] then
			f.guid = knownGUIDs[f.name.text]
			loadedGUIDs[f.guid] = f

			addon:SendMessage("KuiNameplates_GUIDAssumed", f)
		end
	end
	function addon:StoreGUID(f, unit, guid)
		if not unit then
			return
		end
		if not guid then
			guid = UnitGUID(unit)
			if not guid then
				return
			end
		end

		if f.guid and loadedGUIDs[f.guid] then
			if f.guid ~= guid then
				-- the currently stored guid is incorrect
				loadedGUIDs[f.guid] = nil
			else
				return
			end
		end

		f.guid = guid
		loadedGUIDs[guid] = f

		if UnitIsPlayer(unit) then
			-- we can probably assume this unit has a unique name
			-- nevertheless, overwrite this each time. just in case.
			self:StoreNameWithGUID(f.name.text, guid)
		elseif loadedNames[f.name.text] == f then
			-- force the registered f for this name to change
			loadedNames[f.name.text] = nil
		end

		--print('got GUID for: '..f.name.text.. '; '..f.guid)
		addon:SendMessage("KuiNameplates_GUIDStored", f, unit)
	end
	function addon:StoreName(f)
		if not f.name.text or f.guid then
			return
		end
		if not loadedNames[f.name.text] then
			loadedNames[f.name.text] = f
		end
	end
	function addon:FrameHasName(f)
		return loadedNames[f.name.text] == f
	end
	function addon:FrameHasGUID(f)
		return loadedGUIDs[f.guid] == f
	end
	function addon:ClearName(f)
		if self:FrameHasName(f) then
			loadedNames[f.name.text] = nil
		end
	end
	function addon:ClearGUID(f)
		if self:FrameHasGUID(f) then
			loadedGUIDs[f.guid] = nil
		end
		f.guid = nil
	end
	function addon:GetNameplate(guid, name)
		local gf, nf = loadedGUIDs[guid], loadedNames[name]

		if gf then
			return gf
		elseif nf then
			return nf
		else
			return nil
		end
	end

	-- return the given unit's nameplate
	function addon:GetUnitPlate(unit)
		return self:GetNameplate(UnitGUID(unit), GetUnitName(unit))
	end

	-- store an assumed unique name with its guid before it becomes visible
	local function StoreUnit(unit)
		if not unit then
			return
		end
		if not UnitIsPlayer(unit) then
			return
		end

		local guid = UnitGUID(unit)
		if not guid then
			return
		end
		if loadedGUIDs[guid] then
			return
		end

		local name = GetUnitName(unit)
		if not name or knownGUIDs[name] then
			return
		end
		addon:StoreNameWithGUID(name, guid)

		-- also send GUIDStored if the frame currently exists
		local f = addon:GetNameplate(guid, name)
		if f then
			addon:StoreGUID(f, unit, guid)
		else
			-- equivalent to GUIDStored, but with no currently-visible frame
			addon:SendMessage("KuiNameplates_UnitStored", unit, name, guid)
		end
	end

	function addon:UPDATE_MOUSEOVER_UNIT(event)
		StoreUnit("mouseover")
		if UnitExists("mouseovertarget") then
			StoreUnit("mouseovertarget")
		end
	end
	function addon:PLAYER_TARGET_CHANGED(event)
		StoreUnit("target")
		if UnitExists("targettarget") then
			StoreUnit("targettarget")
		end
	end
	function addon:PLAYER_FOCUS_CHANGED(event)
		StoreUnit("focus")
		if UnitExists("focustarget") then
			StoreUnit("focustarget")
		end
	end

	local function GetGroupTypeAndCount()
		local t, stop, start = "raid", GetNumRaidMembers(), 1
		if stop == 0 then
			t, stop, start = "party", GetNumPartyMembers(), 0
		end
		if stop == 0 then
			t = nil
		end
		return t, stop, start
	end

	function addon:GroupUpdate()
		group_update = nil

		local t, stop, start = GetGroupTypeAndCount()
		if not t then
			return
		end

		for i = start, stop do
			StoreUnit(t .. i)
		end
	end
end
function addon:QueueGroupUpdate()
	group_update = true
	group_update_elapsed = 0
end
------------------------------------------------------------ helper functions --
-- cycle all frames' fontstrings and reset the font
function addon:UpdateAllFonts()
	for _, frame in pairs(addon.frameList) do
		for _, fs in pairs(frame.kui.fontObjects) do
			local _, size, flags = fs:GetFont()
			fs:SetFont(addon.font, size, flags)
		end
	end
end

-- given to fontstrings created with frame:CreateFontString (below)
local function SetFontSize(fs, size)
	size = size or (addon.db.profile.fonts.options.onesize and "name" or fs.osize or fs.size)

	if type(size) == "string" and fs.size and addon.sizes.font[size] then
		-- if fontsize is a key of the font sizes table, store it so that
		-- we can scale this font correctly
		fs.size = size
		size = addon.sizes.font[size]
	end

	local font, _, flags = fs:GetFont()
	fs:SetFont(font, size, flags)
end

-- given to frames
local function CreateFontString(self, parent, obj)
	-- store size as a key of addon.fontSizes so that it can be recalled & scaled
	-- correctly. Used by SetFontSize.
	local sizeKey

	obj = obj or {}
	obj.mono = addon.db.profile.fonts.options.monochrome
	obj.outline = addon.db.profile.fonts.options.outline
	obj.size = (addon.db.profile.fonts.options.onesize and "name") or obj.size or "name"

	if type(obj.size) == "string" then
		sizeKey = obj.size
		obj.size = addon.sizes.font[sizeKey]
	end

	if not obj.font then
		obj.font = addon.font
	end

	if obj.alpha and addon.db.profile.fonts.options.noalpha then
		obj.alpha = nil
	end

	local fs = kui.CreateFontString(parent, obj)
	fs.size = sizeKey
	fs.SetFontSize = SetFontSize
	fs:SetWordWrap(false)

	tinsert(self.fontObjects, fs)
	return fs
end

addon.CreateFontString = CreateFontString
----------------------------------------------------------- scaling functions --
-- scale font sizes with the fontscale option
function addon:ScaleFontSize(key)
	local size

	if self.db.profile.fonts.sizes and self.db.profile.fonts.sizes[key] then
		size = self.db.profile.fonts.sizes[key]
	else
		size = self.defaultFontSizes[key]
	end

	self.sizes.font[key] = size * self.db.profile.fonts.options.fontscale
end
-- the same, for all registered sizes
function addon:ScaleFontSizes()
	for key, _ in pairs(self.defaultFontSizes) do
		self:ScaleFontSize(key)
	end
end
-- modules should use this to add font sizes which scale correctly with the
-- fontscale option
-- keys must be unique
function addon:RegisterFontSize(key, size)
	-- TODO should add an option to the interface
	addon.defaultFontSizes[key] = size
	self:ScaleFontSize(key)
end
-- once upon a time, equivalent logic was necessary for all frame sizes
function addon:RegisterSize(type, key, size)
	error("deprecated function call: RegisterSize " .. (type or "nil") .. " " .. (key or "nil") .. " " .. (size or "nil"))
end

function addon:UpdateSizesTable()
	-- populate sizes table with profile values
	addon.sizes.frame.height = addon.db.profile.general.hheight
	addon.sizes.frame.theight = addon.db.profile.general.thheight
	addon.sizes.frame.width = addon.db.profile.general.width
	addon.sizes.frame.twidth = addon.db.profile.general.twidth
	addon.sizes.tex.raidicon = addon.db.profile.general.raidicon_size
	addon.sizes.tex.healthOffsetX = addon.db.profile.text.healthoffsetx
	addon.sizes.tex.healthOffsetY = addon.db.profile.text.healthoffsety
	addon.sizes.tex.levelOffsetX = addon.db.profile.text.leveloffsetx
	addon.sizes.tex.levelOffsetY = addon.db.profile.text.leveloffsety
	addon.sizes.tex.nameOffsetX = addon.db.profile.text.nameoffsetx
	addon.sizes.tex.nameOffsetY = addon.db.profile.text.nameoffsety
	addon.sizes.tex.targetGlowW = addon.sizes.frame.width - 5
	addon.sizes.tex.ttargetGlowW = addon.sizes.frame.twidth - 5
end
------------------------------------------- Listen for LibSharedMedia changes --
function addon:LSMMediaRegistered(msg, mediatype, key)
	if mediatype == LSM.MediaType.FONT then
		if key == self.db.profile.fonts.options.font then
			self.font = LSM:Fetch(mediatype, key)
			addon:UpdateAllFonts()
		end
	elseif mediatype == LSM.MediaType.STATUSBAR then
		if key == self.db.profile.general.bartexture then
			self.bartexture = LSM:Fetch(mediatype, key)
			addon:UpdateAllFonts()
		end
	end
end
------------------------------------------------------------ main update loop --
do
	local WorldFrame, tinsert, select = WorldFrame, tinsert, select
	function addon:OnUpdate()
		-- find new nameplates
		local frames = select("#", WorldFrame:GetChildren())
		if frames ~= self.numFrames then
			local f
			for i = 1, frames do
				f = select(i, WorldFrame:GetChildren())
				if self:IsNameplate(f) and not f.kui then
					self:InitFrame(f)
					tinsert(self.frameList, f)
				end
			end
			self.numFrames = frames
		end
		-- process group update queue
		if group_update then
			group_update_elapsed = group_update_elapsed + .1
			if group_update_elapsed > GROUP_UPDATE_INTERVAL then
				self:GroupUpdate()
			end
		end
	end
end
------------------------------------------------------------------------ init --
function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("KuiNameplatesGDB", defaults)
	self:FinalizeOptions()

	self.db.RegisterCallback(self, "OnProfileChanged", "ProfileChanged")
	LSM.RegisterCallback(self, "LibSharedMedia_Registered", "LSMMediaRegistered")

	-- we treat these like built in elements rather than having them rely
	-- on messages
	addon.Castbar = addon:GetModule("Castbar")
	addon.TankModule = addon:GetModule("TankMode")
end
---------------------------------------------------------------------- enable --
function addon:OnEnable()
	-- force enable threat on nameplates - this is a hidden CVar
	SetCVar("threatWarning", 3)

	-- get font and status bar texture from LSM
	self.font = LSM:Fetch(LSM.MediaType.FONT, self.db.profile.fonts.options.font)
	self.bartexture = LSM:Fetch(LSM.MediaType.STATUSBAR, self.db.profile.general.bartexture)

	-- handle deleted or invalid files
	if not self.font then
		self.font = LSM:Fetch(LSM.MediaType.FONT, DEFAULT_FONT)
	end
	if not self.bartexture then
		self.bartexture = LSM:Fetch(LSM.MediaType.STATUSBAR, DEFAULT_BAR)
	end

	self.uiscale = UIParent:GetEffectiveScale()

	self:UpdateSizesTable()
	self:ScaleFontSizes()

	-------------------------------------- Health bar smooth update functions --
	if self.db.profile.hp.bar.animation == 2 then
		local f, smoothing, GetFramerate, min, max, abs = CreateFrame("Frame"), {}, GetFramerate, math.min, math.max, math.abs

		function self.SetValueSmooth(self, value)
			local _, maxv = self:GetMinMaxValues()

			if value == self:GetValue() or (self.prevMax and self.prevMax ~= maxv) then
				-- finished smoothing/max health updated
				smoothing[self] = nil
				self:OrigSetValue(value)
			else
				smoothing[self] = value
			end

			self.prevMax = maxv
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

				if cur == value or abs(new - value) < .005 then
					bar:OrigSetValue(value)
					smoothing[bar] = nil
				end
			end
		end)
	elseif self.db.profile.hp.bar.animation == 3 then
		local select = select
		local SetValueCutaway = function(self, value)
			if value < self:GetValue() then
				if not kui.frameIsFading(self.KuiFader) then
					self.KuiFader:SetPoint("RIGHT", self, "LEFT", (self:GetValue() / select(2, self:GetMinMaxValues())) * self:GetWidth(), 0)

					-- store original rightmost value
					self.KuiFader.right = self:GetValue()
				end

				kui.frameFade(self.KuiFader, {mode = "OUT", timeToFade = 0.3})
			end

			if self.KuiFader.right and value > self.KuiFader.right then
				-- stop animation if new value overlaps old end point
				kui.frameFadeRemoveFrame(self.KuiFader)
				self.KuiFader:SetAlpha(0)
			end

			self:orig_SetValue(value)
		end
		local SetColour = function(self, ...)
			self:orig_SetStatusBarColor(...)
			self.KuiFader:SetVertexColor(...)
		end

		function self.CutawayBar(bar)
			bar.KuiFader = bar:CreateTexture(nil, "ARTWORK")
			bar.KuiFader:SetTexture(kui.m.t.solid)
			bar.KuiFader:SetVertexColor(bar:GetStatusBarColor())
			bar.KuiFader:SetAlpha(0)

			bar.KuiFader:SetPoint("TOP")
			bar.KuiFader:SetPoint("BOTTOM")
			bar.KuiFader:SetPoint("LEFT", bar:GetStatusBarTexture(), "RIGHT")

			bar.orig_SetValue = bar.SetValue
			bar.SetValue = SetValueCutaway

			bar.orig_SetStatusBarColor = bar.SetStatusBarColor
			bar.SetStatusBarColor = SetColour
		end
	end

	self:configChangedListener()

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "QueueGroupUpdate")
	self:RegisterEvent("RAID_ROSTER_UPDATE", "QueueGroupUpdate")

	self:ScheduleRepeatingTimer("OnUpdate", 0.1)
end