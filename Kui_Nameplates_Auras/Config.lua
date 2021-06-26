--[[
-- Kui_SpellList_Config
-- By Kesava at curse.com
-- All rights reserved
-- Backported by: Kader at https://github.com/bkader
]]
local addon, ns = ...
local spelllist = LibStub("KuiSpellList-1.0")
local KUI = LibStub("AceAddon-3.0"):GetAddon("KuiNameplates")
local L = LibStub("AceLocale-3.0"):GetLocale("KuiNameplatesAuras")
local category = L["Kui |cff9966ffSpell List|r"]

local f = CreateFrame("Frame")
f.UpdateDisplay = {}

KuiSpellListCustom = {}

local _
local whitelist = {}
local class  -- the currently selected class
local spellFrames = {}
local classes = {
	"DEATHKNIGHT",
	"DRUID",
	"HUNTER",
	"MAGE",
	"PALADIN",
	"PRIEST",
	"ROGUE",
	"SHAMAN",
	"WARLOCK",
	"WARRIOR",
	"GLOBAL"
}

------------------------------------------------- whitelist control functions --
local function RemoveAddedSpell(spellid)
	KuiSpellListCustom.Classes[class] = KuiSpellListCustom.Classes[class] or {}
	KuiSpellListCustom.Classes[class][spellid] = nil
	f.UpdateDisplay()
end
local function AddSpellByName(spellname)
	spellname = strlower(spellname)
	KuiSpellListCustom.Classes[class] = KuiSpellListCustom.Classes[class] or {}
	KuiSpellListCustom.Classes[class][spellname] = true
	f.UpdateDisplay()
end
local function AddSpellByID(spellid)
	KuiSpellListCustom.Classes[class] = KuiSpellListCustom.Classes[class] or {}
	KuiSpellListCustom.Classes[class][spellid] = true
	f.UpdateDisplay()
end

local function IgnoreSpellID(spellid)
	KuiSpellListCustom.Ignore[class] = KuiSpellListCustom.Ignore[class] or {}
	KuiSpellListCustom.Ignore[class][spellid] = true
	f.UpdateDisplay()
end
local function UnignoreSpellID(spellid)
	KuiSpellListCustom.Ignore[class] = KuiSpellListCustom.Ignore[class] or {}
	KuiSpellListCustom.Ignore[class][spellid] = nil
	f.UpdateDisplay()
end
------------------------------------------------------------- create category --
local opt = CreateFrame("Frame", "KuiNameplatesAuras", InterfaceOptionsFramePanelContainer)
opt:Hide()
opt.name = category

------------------------------------------------------------- create elements --
-- class drop down menu
local classDropDown = CreateFrame("Frame", "KuiNameplatesAurasClassDropDown", opt, "UIDropDownMenuTemplate")
classDropDown:SetPoint("TOPLEFT", 0, -10)
UIDropDownMenu_SetWidth(classDropDown, 150)

-- reset spells for class button
local classResetButton = CreateFrame("Button", "KuiNameplatesAurasClassResetButton", opt, "UIPanelButtonTemplate")
classResetButton:SetText(RESET)
classResetButton:SetPoint("TOPRIGHT", -10, -10)
classResetButton:SetSize(100, 25)

-- frame for default spells ----------------------------------------------------
local defaultSpellListFrame = CreateFrame("Frame", "KuiNameplatesAurasDefaultSpellListFrame", opt)
defaultSpellListFrame:SetSize(260, 200)

local defaultSpellListScroll = CreateFrame("ScrollFrame", "KuiNameplatesAurasDefaultSpellListScrollFrame", opt, "UIPanelScrollFrameTemplate")
defaultSpellListScroll:SetSize(260, 200)
defaultSpellListScroll:SetScrollChild(defaultSpellListFrame)
defaultSpellListScroll:SetPoint("TOPLEFT", 20, -65)

local defaultSpellListBg = CreateFrame("Frame", nil, opt)
defaultSpellListBg:SetBackdrop({
	bgFile = "Interface/ChatFrame/ChatFrameBackground",
	edgeFile = "Interface/Tooltips/UI-Tooltip-border",
	edgeSize = 16,
	insets = {left = 4, right = 4, top = 4, bottom = 4}
})
defaultSpellListBg:SetBackdropColor(.1, .1, .1, .3)
defaultSpellListBg:SetBackdropBorderColor(.5, .5, .5)
defaultSpellListBg:SetPoint("TOPLEFT", defaultSpellListScroll, -10, 10)
defaultSpellListBg:SetPoint("BOTTOMRIGHT", defaultSpellListScroll, 30, -10)

-- frame for custom spells -----------------------------------------------------
local customSpellListFrame = CreateFrame("Frame", "KuiNameplatesAurasCustomSpellListFrame", opt)
customSpellListFrame:SetSize(260, 200)

local customSpellListScroll = CreateFrame("ScrollFrame", "KuiNameplatesAurasCustomSpellListScrollFrame", opt, "UIPanelScrollFrameTemplate")
customSpellListScroll:SetSize(260, 200)
customSpellListScroll:SetScrollChild(customSpellListFrame)
customSpellListScroll:SetPoint("TOPLEFT", defaultSpellListScroll, "TOPRIGHT", 45, 0)

local customSpellListBg = CreateFrame("Frame", nil, opt)
customSpellListBg:SetBackdrop({
	bgFile = "Interface/ChatFrame/ChatFrameBackground",
	edgeFile = "Interface/Tooltips/UI-Tooltip-border",
	edgeSize = 16,
	insets = {left = 4, right = 4, top = 4, bottom = 4}
})
customSpellListBg:SetBackdropColor(.1, .1, .1, .3)
customSpellListBg:SetBackdropBorderColor(.5, .5, .5)
customSpellListBg:SetPoint("TOPLEFT", customSpellListScroll, -10, 10)
customSpellListBg:SetPoint("BOTTOMRIGHT", customSpellListScroll, 30, -10)

-- scroll list titles
local defaultListTitle = opt:CreateFontString(nil, "ARTWORK", "GameFontNormal")
defaultListTitle:SetText(DEFAULT)
defaultListTitle:SetPoint("BOTTOMLEFT", defaultSpellListBg, "TOPLEFT", 10, 3)

-- scroll list titles
local customListTitle = opt:CreateFontString(nil, "ARTWORK", "GameFontNormal")
customListTitle:SetText(CUSTOM)
customListTitle:SetPoint("BOTTOMLEFT", customSpellListBg, "TOPLEFT", 10, 3)

-- spell entry text box
local spellEntryBox = CreateFrame("EditBox", "KuiNameplatesAurasSpellEntryBox", opt, "InputBoxTemplate")
spellEntryBox:SetAutoFocus(false)
spellEntryBox:EnableMouse(true)
spellEntryBox:SetMaxLetters(100)
spellEntryBox:SetPoint("TOPLEFT", defaultSpellListScroll, "BOTTOMLEFT", 125, -10)
spellEntryBox:SetSize(250, 25)

-- spell add button
local spellAddButton = CreateFrame("Button", "KuiNameplatesAurasSpellAddButton", opt, "UIPanelButtonTemplate")
spellAddButton:SetText(ADD)
spellAddButton:SetPoint("LEFT", spellEntryBox, "RIGHT")
spellAddButton:SetSize(40, 25)
spellAddButton.tooltipText = L["ADD_DESC "]

-- add by name button
local spellAddByNameButton = CreateFrame("Button", "KuiNameplatesAurasSpellAddByNameButton", opt, "UIPanelButtonTemplate")
spellAddByNameButton:SetText(L["Verbatim"])
spellAddByNameButton:SetPoint("LEFT", spellAddButton, "RIGHT")
spellAddByNameButton:SetSize(60, 25)
spellAddByNameButton.tooltipText = L["VERBATIM_DESC"]

-- help text
local helpText = opt:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
helpText:SetText(L["HELP_TEXT"])
helpText:SetPoint("TOPLEFT", defaultSpellListBg, "BOTTOMLEFT", 0, -30)
helpText:SetPoint("BOTTOMRIGHT", -10, 0)
helpText:SetWordWrap(true)
helpText:SetJustifyH("LEFT")
helpText:SetJustifyV("TOP")

-- position/size elements ######################################################
local function FrameSizeChanged(self)
	local width = self:GetWidth()
	local list_width = width / 2 - 53

	defaultSpellListFrame:SetWidth(list_width)
	defaultSpellListScroll:SetWidth(list_width)

	customSpellListFrame:SetWidth(list_width)
	customSpellListScroll:SetWidth(list_width)

	spellEntryBox:SetPoint("TOPLEFT", defaultSpellListScroll, "BOTTOMLEFT", (width / 2) - 175, -10)
end

--------------------------------------------------- class drop down functions --
local function ClassDropDownChanged(self, val)
	class = val
	f.UpdateDisplay()
end

function classDropDown:initialize(level, menuList)
	local info = UIDropDownMenu_CreateInfo()

	for _, thisClass in pairs(classes) do
		info.text = thisClass
		info.arg1 = thisClass
		info.checked = (class == thisClass)
		info.func = ClassDropDownChanged
		UIDropDownMenu_AddButton(info)
	end
end

----------------------------------------------------- element script handlers --
-- tooltip functions
local function ButtonTooltip(button)
	if not button.tooltipText then
		return
	end

	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	GameTooltip:SetWidth(200)
	GameTooltip:AddLine(button:GetText())
	GameTooltip:AddLine(button.tooltipText, 1, 1, 1, true)
	GameTooltip:Show()
end
local function ButtonTooltipHide(button)
	GameTooltip:Hide()
end

local function SpellFrameOnEnter(self)
	self.highlight:Show()

	if self.link then
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		GameTooltip:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", 0, -2)
		GameTooltip:SetHyperlink(self.link)
		GameTooltip:Show()
	end
end
local function SpellFrameOnLeave(self)
	self.highlight:Hide()
	GameTooltip:Hide()
end

local function DefaultSpellFrameOnMouseUp(self, button)
	if button == "RightButton" then
		if self.ignored then
			-- unignore a default spell
			UnignoreSpellID(self.id)
		else
			-- ignore default spell
			IgnoreSpellID(self.id)
		end
	end
end

local function SpellFrameOnMouseUp(self, button)
	if button == "RightButton" then
		-- remove an added spell
		RemoveAddedSpell(self.id)
	end
end

local function ClearSpellEntryBox()
	spellEntryBox:SetText("")
	spellEntryBox:SetTextColor(1, 1, 1)
	spellEntryBox:SetFocus()
end

local function SpellAddByNameButtonOnClick(self)
	-- just add the text itself
	AddSpellByName(spellEntryBox:GetText())
	ClearSpellEntryBox()
end

local function SpellAddButtonOnClick(self)
	if spellEntryBox.spellID then
		AddSpellByID(spellEntryBox.spellID)
	elseif spellEntryBox:GetText() ~= "" then
		AddSpellByName(spellEntryBox:GetText())
	end

	ClearSpellEntryBox()
end

local function SpellEntryBoxOnEnterPressed(self)
	if IsShiftKeyDown() then
		spellAddByNameButton:Click()
	else
		spellAddButton:Click()
	end
end

local function SpellEntryBoxOnEscapePressed(self)
	self:ClearFocus()
end

local function SpellEntryBoxOnTextChanged(self, user)
	self.spellID = nil
	if not user then
		return
	end

	local text = self:GetText()

	if text == "" then
		spellEntryBox:SetTextColor(1, 1, 1)
		return
	end

	local usedID, name

	if strmatch(text, "^%d+$") then
		-- using a spell ID
		text = tonumber(text)
		usedID = true
	end

	name = GetSpellInfo(text)

	if name then
		self:SetTextColor(0, 1, 0)

		if not usedID then
			-- get the spell ID from the link
			self.spellID = strmatch(GetSpellLink(name), ":(%d+).h")
		else
			self.spellID = text
		end

		self.spellID = tonumber(self.spellID)
	else
		self:SetTextColor(1, 0, 0)
	end
end

local function ClassResetButtonOnClick(self)
	-- reset the currently selected class
	KuiSpellListCustom.Ignore[class] = {}
	KuiSpellListCustom.Classes[class] = {}
	f.UpdateDisplay()
end

------------------------------------------------------------------- functions --
-- creates frame for spells (icon + name + id)
local function CreateSpellFrame(spellid, default, ignored)
	local name, icon, f, _

	if string.match(spellid, "^%d+$") then
		-- spellid is actually an ID, not a string
		name, _, icon = GetSpellInfo(spellid)
	end

	if not name then
		-- either the spell id doesn't exist or spellid is a spell name
		name = spellid
		icon = "Interface/ICONS/INV_Misc_QuestionMark"
	else
		-- show the ID, mostly for my sake
		name = name .. " |cff888888(" .. spellid .. ")|r"
	end

	for _, frame in pairs(spellFrames) do
		if not frame:IsShown() then
			-- recycle an old frame
			f = frame
		end
	end

	if not f then
		f = CreateFrame("Frame", nil, default and defaultSpellListFrame or customSpellListFrame)

		f:EnableMouse(true)

		f.highlight = f:CreateTexture("HIGHLIGHT")
		f.highlight:SetTexture("Interface/BUTTONS/UI-Listbox-Highlight")
		f.highlight:SetBlendMode("add")
		f.highlight:SetAlpha(.5)
		f.highlight:Hide()

		f.icon = f:CreateTexture("ARTWORK")

		f.name = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")

		f:SetSize(300, 20)

		f.highlight:SetAllPoints(f)

		f.icon:SetSize(18, 18)
		f.icon:SetPoint("LEFT")

		f.name:SetSize(280, 18)
		f.name:SetPoint("LEFT", f.icon, "RIGHT", 4, 0)
		f.name:SetJustifyH("LEFT")

		f:SetScript("OnEnter", SpellFrameOnEnter)
		f:SetScript("OnLeave", SpellFrameOnLeave)
	end

	f.ignored = nil
	f.link = nil
	f.id = spellid
	f.name:SetTextColor(1, 1, 1)
	f.icon:SetAlpha(1)

	if default then
		f:SetParent(defaultSpellListFrame)
		f:SetScript("OnMouseUp", DefaultSpellFrameOnMouseUp)

		if ignored then
			f.ignored = true
			f.name:SetTextColor(.6, .6, .6)
			f.icon:SetAlpha(.6)
		end
	else
		f:SetParent(customSpellListFrame)
		f:SetScript("OnMouseUp", SpellFrameOnMouseUp)
	end

	if string.match(spellid, "^%d+$") then
		-- only get links for spell ids - not verbatim text entries
		f.link = GetSpellLink(spellid)
	end

	f.icon:SetTexture(icon)
	f.name:SetText(name)

	tinsert(spellFrames, f)

	return f
end

-- hides all spellFrames for reuse
local function HideAllSpellFrames()
	for _, frame in pairs(spellFrames) do
		frame:Hide()
		frame.highlight:Hide()
	end
end

-- iterate through given spell list by name
-- where spelllist { [spellid] => [ignored], ... }
local function PairsBySpellName(whitelist)
	local name_list = {}

	for spellid, ignored in pairs(whitelist) do
		local name = GetSpellInfo(spellid)
		tinsert(name_list, {name or tostring(spellid), spellid, ignored})
	end

	table.sort(name_list, function(a, b) return a[1] < b[1] end)

	local i = 0
	return function()
		i = i + 1
		if name_list[i] == nil then
			return nil
		else
			return name_list[i][2], name_list[i][3]
		end
	end
end

-- called upon load or when a different class is selected
local function ClassUpdate()
	local pv
	HideAllSpellFrames()

	UIDropDownMenu_SetText(classDropDown, class)

	whitelist.default = spelllist.GetDefaultSpells(class, true)
	whitelist.custom = {}

	-- merge ignored spells with default list
	if KuiSpellListCustom.Ignore[class] then
		for spellid, _ in pairs(KuiSpellListCustom.Ignore[class]) do
			if whitelist.default[spellid] then
				whitelist.default[spellid] = 2
			end
		end
	end

	-- fill custom spell list
	if KuiSpellListCustom.Classes[class] then
		for spellid, _ in pairs(KuiSpellListCustom.Classes[class]) do
			whitelist.custom[spellid] = true
		end
	end

	-- print default spells
	for spellid, ignored in PairsBySpellName(whitelist.default) do
		local f = CreateSpellFrame(spellid, true, (ignored == 2))

		if pv then
			f:SetPoint("TOPLEFT", pv, "BOTTOMLEFT", 0, -2)
		else
			f:SetPoint("TOPLEFT")
		end

		f:Show()
		pv = f
	end

	-- print custom spells
	pv = nil
	for spellid, _ in PairsBySpellName(whitelist.custom) do
		local f = CreateSpellFrame(spellid)

		if pv then
			f:SetPoint("TOPLEFT", pv, "BOTTOMLEFT", 0, -2)
		else
			f:SetPoint("TOPLEFT")
		end

		f:Show()
		pv = f
	end
end
------------------------------------------------------------- script handlers --
local function OnOptionsShow(self)
	class = select(2, UnitClass("player"))
	ClassUpdate()

	spellEntryBox:SetFocus()
end
local function OnOptionsHide(self)
	HideAllSpellFrames()
	spelllist.WhitelistChanged()
end

local function OnEvent(self, event, ...)
	self[event](self, ...)
end
-------------------------------------------------------------- event handlers --
function f:ADDON_LOADED(loaded)
	self:UnregisterEvent("ADDON_LOADED")

	KuiSpellListCustom = KuiSpellListCustom or {}
	KuiSpellListCustom.Ignore = KuiSpellListCustom.Ignore or {}
	KuiSpellListCustom.Classes = KuiSpellListCustom.Classes or {}

	self.UpdateDisplay = function() ClassUpdate() end

	InterfaceOptionsFramePanelContainer:HookScript("OnSizeChanged", FrameSizeChanged)
	FrameSizeChanged(InterfaceOptionsFramePanelContainer)

	spelllist.WhitelistChanged()
end
-------------------------------------------------------------------- finalise --
opt:SetScript("OnShow", OnOptionsShow)
opt:SetScript("OnHide", OnOptionsHide)

spellEntryBox:SetScript("OnEnterPressed", SpellEntryBoxOnEnterPressed)
spellEntryBox:SetScript("OnEscapePressed", SpellEntryBoxOnEscapePressed)
spellEntryBox:SetScript("OnTextChanged", SpellEntryBoxOnTextChanged)

spellAddButton:SetScript("OnClick", SpellAddButtonOnClick)
spellAddButton:SetScript("OnEnter", ButtonTooltip)
spellAddButton:SetScript("OnLeave", ButtonTooltipHide)

spellAddByNameButton:SetScript("OnClick", SpellAddByNameButtonOnClick)
spellAddByNameButton:SetScript("OnEnter", ButtonTooltip)
spellAddByNameButton:SetScript("OnLeave", ButtonTooltipHide)

classResetButton:SetScript("OnClick", ClassResetButtonOnClick)

f:SetScript("OnEvent", OnEvent)
f:RegisterEvent("ADDON_LOADED")

InterfaceOptions_AddCategory(opt)

--------------------------------------------------------------- slash command --
_G.SLASH_KUISPELLLIST1 = "/kuislc"
_G.SLASH_KUISPELLLIST2 = "/kslc"

function SlashCmdList.KUISPELLLIST(msg)
	if msg == "dump" then
		-- dump list of auras on target
		local f = UnitIsFriend("player", "target") and "HELPFUL" or "HARMFUL"

		for i = 1, 40 do
			local n, _, _, _, _, _, _, _, _, _, id = UnitAura("target", i, f .. " PLAYER")
			if n and id then
				print("|cff9966ffKNP Auras|r: " .. n .. " = " .. id)
			end
		end
	else
		KUI:CloseConfig()
		InterfaceOptionsFrame_OpenToCategory(category)
		InterfaceOptionsFrame_OpenToCategory(category)
	end
end