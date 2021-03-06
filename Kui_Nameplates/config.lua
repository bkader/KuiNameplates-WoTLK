local addon, ns = ...

------------------------------------------------------------------ Ace config --
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

--------------------------------------------------------------- Options table --
do
    local handler = {}
    local options = {
        name = "Kui Nameplates",
        handler = handler,
        type = "group",
        get = "Get",
        set = "Set",
        args = {
            header = {
                type = "header",
                name = "|cffff0000Many options currently require a UI reload to take effect.|r",
                order = 0
            },
            general = {
                name = "General display",
                type = "group",
                inline = true,
                order = 1,
                args = {
                    combat = {
                        name = "Auto toggle in combat",
                        desc = "Automatically toggle on/off hostile nameplates upon entering/leaving combat",
                        type = "toggle",
                        order = 0
                    },
                    highlight = {
                        name = "Highlight",
                        desc = "Highlight plates on mouse over (when not targeted)",
                        type = "toggle",
                        order = 1
                    },
                    combopoints = {
                        name = "Combo points",
                        desc = "Show combo points",
                        type = "toggle",
                        order = 2
                    },
                    fixaa = {
                        name = "Fix aliasing",
                        desc = "Attempt to make plates appear sharper, with some drawbacks",
                        type = "toggle",
                        order = 3
                    },
                    fontscale = {
                        name = "Font scale",
                        desc = "The scale of all fonts displayed on nameplates",
                        type = "range",
                        min = 0,
                        softMax = 2,
                        order = 4
                    }
                }
            },
            fade = {
                name = "Frame fading",
                type = "group",
                inline = true,
                order = 2,
                args = {
                    fadedalpha = {
                        name = "Faded alpha",
                        desc = "The alpha value to which plates fade out to",
                        type = "range",
                        min = 0,
                        max = 1,
                        isPercent = true,
                        order = 4
                    },
                    fademouse = {
                        name = "Fade in with mouse",
                        desc = "Fade plates in on mouse-over",
                        type = "toggle",
                        order = 1
                    },
                    fadeall = {
                        name = "Fade all frames",
                        desc = "Fade out all frames by default (rather than in)",
                        type = "toggle",
                        order = 2
                    },
                    smooth = {
                        name = "Smoothly fade",
                        desc = "Smoothly fade plates in/out (fading is instant disabled)",
                        type = "toggle",
                        order = 0
                    },
                    fadespeed = {
                        name = "Smooth fade speed",
                        desc = "Fade animation speed modifier (lower is faster)",
                        type = "range",
                        min = 0,
                        softMax = 5,
                        order = 3,
                        disabled = function(info)
                            return not ns.db.profile.fade.smooth
                        end
                    }
                }
            },
            hp = {
                name = "Health display",
                type = "group",
                inline = true,
                order = 3,
                args = {
                    showalt = {
                        name = "Show contextual health",
                        desc = "Show alternate (contextual) health values as well as main values",
                        type = "toggle",
                        order = 1
                    },
                    mouseover = {
                        name = "Show on mouse over",
                        desc = "Show health only on mouse over or on the targeted plate",
                        type = "toggle",
                        order = 2
                    },
                    smooth = {
                        name = "Smooth health bar",
                        desc = "Smoothly animate health bar value updates",
                        type = "toggle",
                        order = 3
                    },
                    friendly = {
                        name = "Friendly health format",
                        desc = "The health display pattern for friendly units",
                        type = "input",
                        pattern = "([<=]:[dmcp];)",
                        order = 4
                    },
                    hostile = {
                        name = "Hostile health format",
                        desc = "The health display pattern for hostile or neutral units",
                        type = "input",
                        pattern = "([<=]:[dmcp];)",
                        order = 5
                    }
                }
            },
            tank = {
                name = "Tank mode",
                type = "group",
                inline = true,
                order = 4,
                disabled = function(info)
                    return not ns.db.profile.tank.enabled
                end,
                args = {
                    enabled = {
                        name = "Enable tank mode",
                        desc = "Change the colour of a plate's health bar and border when you have threat on its unit",
                        type = "toggle",
                        order = 0,
                        disabled = false
                    },
                    barcolour = {
                        name = "Bar colour",
                        desc = "The bar colour to use when you have threat",
                        type = "color",
                        order = 1
                    },
                    glowcolour = {
                        name = "Glow colour",
                        desc = "The glow (border) colour to use when you have threat",
                        type = "color",
                        hasAlpha = true,
                        order = 2
                    }
                }
            },
            castbar = {
                name = "Cast bars",
                type = "group",
                inline = true,
                order = 5,
                disabled = function(info)
                    return not ns.db.profile.castbar.enabled
                end,
                args = {
                    enabled = {
                        name = "Enable cast bar",
                        desc = "Show cast bars (at all)",
                        type = "toggle",
                        order = 0,
                        disabled = false
                    },
                    casttime = {
                        name = "Show cast time",
                        desc = "Show cast time and time remaining",
                        type = "toggle",
                        order = 4
                    },
                    spellname = {
                        name = "Show spell name",
                        type = "toggle",
                        order = 3
                    },
                    spellicon = {
                        name = "Show spell icon",
                        type = "toggle",
                        order = 2
                    },
                    barcolour = {
                        name = "Bar colour",
                        desc = "The colour of the cast bar (during interruptible casts)",
                        type = "color",
                        width = "double",
                        order = 1
                    },
                    warnings = {
                        name = "Show cast warnings",
                        desc = "Display cast and healing warnings on plates",
                        type = "toggle",
                        order = 5,
                        disabled = false
                    },
                    usenames = {
                        name = "Use names for warnings",
                        desc = "Use unit names to display cast warnings on their correct frames. May increase memory usage and may cause warnings to be displayed on incorrect frames when there are many units with the same name. Reccommended on for PvP, off for PvE.",
                        type = "toggle",
                        order = 6,
                        disabled = function(info)
                            return not ns.db.profile.castbar.warnings
                        end
                    }
                }
            },
            reload = {
                name = "Reload UI",
                type = "execute",
                func = ReloadUI
            }
        }
    }

    function handler:Get(info)
        local k = ns.db.profile[info[1]][info[#info]]

        if info.type == "color" then
            return unpack(k)
        else
            return k
        end
    end

    function handler:Set(info, val, ...)
        if info.type == "color" then
            ns.db.profile[info[1]][info[#info]] = {val, ...}
        else
            ns.db.profile[info[1]][info[#info]] = val
        end
    end

    AceConfig:RegisterOptionsTable("kuinameplates", options)
    AceConfigDialog:AddToBlizOptions("kuinameplates", "Kui Nameplates")
end

--------------------------------------------------------------- Slash command --
SLASH_KUINAMEPLATES1 = "/kuinameplates"
SLASH_KUINAMEPLATES2 = "/knp"

function SlashCmdList.KUINAMEPLATES()
    InterfaceOptionsFrame_OpenToCategory("Kui Nameplates")
end
