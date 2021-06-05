local L = LibStub("AceLocale-3.0"):NewLocale("KuiNameplatesAuras", "enUS", true)
if not L then return end

L["Show my auras"] = true
L["Display auras cast by you on the current target's nameplate"] = true
L["Show on trivial units"] = true
L["Show auras on trivial (half-size, lower maximum health) nameplates."] = true
L["Behaviour"] = true
L["Use whitelist"] = true
L["Only display spells which your class needs to keep track of for PVP or an effective DPS rotation. Most passive effects are excluded."] = true
L["Show on secondary targets"] = true
L["Attempt to show and refresh auras on secondary targets - i.e. nameplates which do not have a visible unit frame on the default UI. Particularly useful when tanking."] = true
L["Display"] = true
L["Pulsate auras"] = true
L["Pulsate aura icons when they have less than 5 seconds remaining.\nSlightly increases memory usage."] = true
L["Show decimal places"] = true
L["Show decimal places (.9 to .0) when an aura has less than one second remaining, rather than just showing 0."] = true
L["Sort auras by time remaining"] = true
L["Increases memory usage."] = true
L["Timer threshold (s)"] = true
L["Timer text will be displayed on auras when their remaining length is less than or equal to this value. -1 to always display timer."] = true
L["Effect length minimum (s)"] = true
L["Auras with a total duration of less than this value will never be displayed. 0 to disable."] = true
L["Effect length maximum (s)"] = true
L["Auras with a total duration greater than this value will never be displayed. -1 to disable."] = true
L["Size"] = true
L["Aura icon size on normal frames"] = true
L["Size (trivial)"] = true
L["Aura icon size on trivial frames"] = true
L["Squareness"] = true
L["Where 1 is completely square and .5 is completely rectangular"] = true

L["Edit spell list"] = true
L["Kui |cff9966ffSpell List|r"] = true
L["Verbatim"] = true
L["ADD_DESC "] = [[
Resolve this name to the ID of a spell in your spellbook and add it to the tracked list.
This is the default behaviour when the entry text is |cff88ff88green|r.
]]
L["VERBATIM_DESC"] = [[
Add this spell without trying to resolve it to its ID. In other words, track any aura which matches this name.
This is the default behaviour when the entry text is |cffff0088red|r.
Hold shift while pressing enter to force this action.
]]

L["HELP_TEXT"] = [[
Type the |cffffff00name|r or |cffffff00spell ID|r of an ability to track and press enter.
|cffffff00Right-click|r spells to remove or ignore them.

Abilities will only be recognised by name if they are in your currently active set of skills (i.e. visible and active in your specialisation's page of your spell book). You can use the slash command |cffffff00/kslc dump|r to find spell IDs of auras once you have applied them to your target.

Mouseover the "Add" and "Verbatim" buttons for more detail about what each of them does.
]]