--[[
  Kui Nameplates
  Kesava-Auchindoun EU
]]
local addon, ns = ...
LibStub("AceAddon-3.0"):NewAddon(ns, "KuiNameplates")

-------------------------------------------------------------- Default config --
local defaults = {
    profile = {
        general = {
            combat = false, -- automatically show hostile plates upon entering combat
            highlight = true, -- highlight plates on mouse-over
            combopoints = true, -- display combo points
            fixaa = true, -- attempt to make plates appear sharper (with some drawbacks)
            fontscale = 1.0 -- the scale of all displayed font sizes
        },
        fade = {
            smooth = true, -- smoothy fade plates (fading is instant if disabled)
            fadespeed = .5, -- fade animation speed modifier
            fademouse = false, -- fade in plates on mouse-over
            fadeall = false, -- fade all plates by default
            fadedalpha = .3 -- the alpha value to fade plates out to
        },
        tank = {
            enabled = false, -- recolour a plate's bar and glow colour when you have threat
            barcolour = {.2, .9, .1, 1}, -- the bar colour to use when you have threat
            glowcolour = {1, 0, 0, 1, 1} -- the glow colour to use when you have threat
        },
        hp = {
            --[[
        syntax help:

        A simple pattern is used to determine what text should be displayed for health.
        A pattern consists of rules seperated by semi-colons (;).
        A rule consists of the condition followed by the result of the rule seperated by a colon (:).

        For example:
          A rule: condition:result
          A pattern: rule1;rule2;rule3 (etc)

        Valid conditions are as follows:
          <= : When health is less than or equal to its maximum value...
          <  : When health is less than its maximum value...
          =  : When health is equal to its maximum value...

        Valid results are:
          c : the current, precise health value (i.e. 128.4k)
          d : precise value of health that is currently missing (i.e. -12.3k)
          m : the maximum amount of health
          p : the current amount of health in percent

        Health display defaults to blank if no rule is matched.

        The default patterns and their meanings are:

          Friendly: =:m;<:d
          Meaning:  When at max health, display max health (=:max)
                    When below max health, display health deficit (<:deficit)

          Hostile: <:p
          Meaning: When below max health, display health as a percentage.
                   Otherwise, display nothing.
      ]]
            friendly = "=:m;<:d", -- health display pattern for friendly units
            hostile = "<:p", -- health display pattern for hostile/neutral units
            showalt = true, -- show alternate (contextual) health values as well as main values
            mouseover = false, -- hide health values until you mouse over or target the plate
            smooth = true -- smoothly animate health bar changes
        },
        castbar = {
            enabled = true, -- show a castbar (at all)
            casttime = true, -- display cast time and time remaining
            spellname = true, -- display spell name
            spellicon = true, -- display spell icon
            barcolour = {.43, .47, .55, 1}, -- the colour of the spell bar (interruptible casts)
            warnings = true, -- display spell cast warnings on any plates
            usenames = true -- use unit names to display cast warnings on their correct frames: may increase memory usage and may cause warnings to be displayed on incorrect frames when there are many units with the same name. Reccommended on for PvP, off for PvE.
        }
    }
}

------------------------------------------------------------------------ init --
function ns:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("KuiNameplatesDB", defaults)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("kuinameplates-profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("kuinameplates-profiles", "Profiles", "Kui Nameplates")
end
