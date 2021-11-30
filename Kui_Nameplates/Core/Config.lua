--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
-- Backported by: Kader at https://github.com/bkader
]]
local addon = LibStub("AceAddon-3.0"):GetAddon("KuiNameplates")
local kui = LibStub("Kui-1.0")
local LSM = LibStub("LibSharedMedia-3.0")
local category = "Kui |cff9966ffNameplates|r"
local L = LibStub("AceLocale-3.0"):GetLocale("KuiNameplates")
------------------------------------------------------------------ Ace config --
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LDS = LibStub("LibDualSpec-1.0", true)

local RELOAD_HINT = L["\n|cffff0000UI reload required to take effect."]
--------------------------------------------------------------- Options table --
do
	local StrataSelectList = {
		["BACKGROUND"] = "1. BACKGROUND",
		["LOW"] = "2. LOW",
		["MEDIUM"] = "3. MEDIUM",
		["HIGH"] = "4. HIGH",
		["DIALOG"] = "5. DIALOG",
		["TOOLTIP"] = "6. TOOLTIP"
	}

	local AnchorSelectList = {
		TOP = L["Top"],
		BOTTOM = L["Bottom"],
		LEFT = L["Left"],
		RIGHT = L["Right"],
		TOPLEFT = L["Top Left"],
		TOPRIGHT = L["Top Right"],
		BOTTOMLEFT = L["Bottom Left"],
		BOTTOMRIGHT = L["Bottom Right"]
	}

	local SimpleAnchorSelectList = {
		TOP = L["Top"],
		BOTTOM = L["Bottom"],
		LEFT = L["Left"],
		RIGHT = L["Right"]
	}

	local HealthTextSelectList = {
		L["Current"] .. " |cff888888(145k)",
		L["Maximum"] .. " |cff888888(156k)",
		L["Percent"] .. " |cff888888(93)",
		L["Deficit"] .. " |cff888888(-10.9k)",
		L["Blank"] .. " |cff888888(  )"
	}

	local HealthAnimationSelectList = {NONE, L["Smooth"], L["Cutaway"]}

	local globalConfigChangedListeners = {}

	local handlers = {}
	local handlerProto = {}
	local handlerMeta = {__index = handlerProto}

	-- called by handler:Set when configuration is changed
	local function ConfigChangedSkeleton(mod, info, profile)
		if mod.configChangedListener then
			-- notify that any option has changed
			mod:configChangedListener()
		end

		local key = info[#info]

		if mod.configChangedFuncs then
			if mod.configChangedFuncs.NEW then
				-- new ConfigChanged support (TODO: voyeurs)
				local cc_table, gcc_table, k
				for i = 1, #info do
					k = info[i]

					if not cc_table then
						cc_table = mod.configChangedFuncs
					end

					if not gcc_table then
						gcc_table = globalConfigChangedListeners[mod:GetName()]
					end

					-- call the modules functions..
					if cc_table and cc_table[k] then
						cc_table = cc_table[k]

						if type(cc_table.ro) == "function" then
							cc_table.ro(profile[key])
						end

						if type(cc_table.pf) == "function" then
							for _, frame in pairs(addon.frameList) do
								cc_table.pf(frame.kui, profile[key])
							end
						end
					end

					-- call any voyeur's functions..
					if gcc_table and gcc_table[k] then
						gcc_table = gcc_table[k]

						if gcc_table.ro then
							for _, voyeur in ipairs(gcc_table.ro) do
								voyeur(profile[key])
							end
						end

						if gcc_table.pf then
							for _, voyeur in ipairs(gcc_table.pf) do
								for _, frame in pairs(addon.frameList) do
									voyeur(frame.kui, profile[key])
								end
							end
						end
					end
				end

				return
			end

			-- call option specific callbacks
			if mod.configChangedFuncs.runOnce and mod.configChangedFuncs.runOnce[key] then
				-- call runOnce function
				mod.configChangedFuncs.runOnce[key](profile[key])
			end
		end

		-- find and call global config changed listeners
		local voyeurs = {}
		if globalConfigChangedListeners[mod:GetName()] and globalConfigChangedListeners[mod:GetName()][key] then
			for _, voyeur in ipairs(globalConfigChangedListeners[mod:GetName()][key]) do
				voyeur = addon:GetModule(voyeur)

				if voyeur.configChangedFuncs.global.runOnce[key] then
					voyeur.configChangedFuncs.global.runOnce[key](profile[key])
				end

				if voyeur.configChangedFuncs.global[key] then
					-- also call when iterating frames
					tinsert(voyeurs, voyeur)
				end
			end
		end

		-- iterate frames and call
		for _, frame in pairs(addon.frameList) do
			if mod.configChangedFuncs and mod.configChangedFuncs[key] then
				mod.configChangedFuncs[key](frame.kui, profile[key])
			end

			for _, voyeur in ipairs(voyeurs) do
				voyeur.configChangedFuncs.global[key](frame.kui, profile[key])
			end
		end
	end

	local function ResolveKeys(mod, keys, ro, pf, g, global)
		if not g then
			g = mod.configChangedFuncs
		end

		if type(keys) == "table" then
			for _, key in ipairs(keys) do
				if not g[key] then
					g[key] = {}
				end

				g = g[key]
			end
		elseif type(keys) == "string" then
			if not g[keys] then
				g[keys] = {}
			end

			g = g[keys]
		else
			return
		end

		if not global then
			if g.ro or g.pf then
				kui.print("ConfigChanged callback overwritten in " .. (mod:GetName() or "nil"))
			end

			g.ro = ro
			g.pf = pf
		else
			if ro then
				if not g.ro then
					g.ro = {}
				end
				tinsert(g.ro, ro)
			end
			if pf then
				if not g.pf then
					g.pf = {}
				end
				tinsert(g.pf, pf)
			end
		end
	end

	local function AddConfigChanged(mod, key_groups, ro, pf)
		if not mod.configChangedFuncs then
			mod.configChangedFuncs = {}
		end
		mod.configChangedFuncs.NEW = true

		if type(key_groups) == "table" and type(key_groups[1]) == "table" then
			-- multiple key groups
			for _, keys in ipairs(key_groups) do
				ResolveKeys(mod, keys, ro, pf)
			end
		else
			-- one key group, or a string
			ResolveKeys(mod, key_groups, ro, pf)
		end
	end

	local function AddGlobalConfigChanged(mod, target_module, key_groups, ro, pf)
		if not globalConfigChangedListeners then
			globalConfigChangedListeners = {}
		end

		if not target_module or target_module == "addon" then
			target_module = "KuiNameplates"
		end

		if not globalConfigChangedListeners[target_module] then
			globalConfigChangedListeners[target_module] = {}
		end

		local target_table = globalConfigChangedListeners[target_module]

		if type(key_groups) == "table" and type(key_groups[1]) == "table" then
			for _, keys in ipairs(key_groups) do
				ResolveKeys(mod, keys, ro, pf, target_table, true)
			end
		else
			ResolveKeys(mod, key_groups, ro, pf, target_table, true)
		end
	end

	function handlerProto:ResolveInfo(info)
		local profile = self.dbPath.db.profile
		local child, k

		for i = 1, #info do
			k = info[i]

			if i < #info then
				if not child then
					child = profile[k]
				else
					child = child[k]
				end
			end
		end

		return child or profile, k
	end

	function handlerProto:Get(info, ...)
		local p, k = self:ResolveInfo(info)
		if not p[k] then
			return
		end

		if info.type == "color" then
			return unpack(p[k])
		else
			return p[k]
		end
	end

	function handlerProto:Set(info, val, ...)
		local p, k = self:ResolveInfo(info)

		if info.type == "color" then
			p[k] = {val, ...}
		else
			p[k] = val
		end

		if self.dbPath.ConfigChanged then
			-- inform module of configuration change
			self.dbPath:ConfigChanged(info, p)
		end
	end

	function addon:GetOptionHandler(mod)
		if not handlers[mod] then
			handlers[mod] = setmetatable({dbPath = mod}, handlerMeta)
		end

		return handlers[mod]
	end

	local options = {
		name = category .. " - r|cfff58cba" .. addon.version .. "|r",
		handler = addon:GetOptionHandler(addon),
		type = "group",
		get = "Get",
		set = "Set",
		args = {
			header = {
				type = "header",
				name = L["|cffff6666Many options currently require a UI reload to take effect"],
				order = 0
			},
			reload = {
				type = "execute",
				name = L["Reload UI"],
				func = function() ReloadUI() end,
				order = 1
			},
			website = {
				type = "execute",
				name = L["Website"],
				func = function() StaticPopup_Show("KUINAMEPLATES_GITHUB") end,
				order = 2
			},
			general = {
				type = "group",
				name = L["General display"],
				order = 10,
				args = {
					combataction_hostile = {
						type = "select",
						name = L["Combat action: hostile"],
						desc = L["Automatically toggle hostile nameplates when entering/leaving combat. Setting will be inverted upon leaving combat."],
						values = {
							L["Do nothing"],
							L["Hide enemies"],
							L["Show enemies"]
						},
						order = 0
					},
					combataction_friendly = {
						type = "select",
						name = L["Combat action: friendly"],
						desc = L["Automatically toggle friendly nameplates when entering/leaving combat. Setting will be inverted upon leaving combat."],
						values = {
							L["Do nothing"],
							L["Hide friendlies"],
							L["Show friendlies"]
						},
						order = 1
					},
					bartexture = {
						type = "select",
						name = L["Status bar texture"],
						desc = L["The texture used for both the health and cast bars."],
						dialogControl = "LSM30_Statusbar",
						values = AceGUIWidgetLSMlists.statusbar,
						order = 5
					},
					strata = {
						type = "select",
						name = L["Frame strata"],
						desc = L['The frame strata used by all frames, which determines what "layer" of the UI the frame is on. Untargeted frames are displayed at frame level 0 of this strata. Targeted frames are bumped to frame level 3.\n\nThis does not and can not affect the click-box of the frames, only their visibility.'],
						values = StrataSelectList,
						order = 6
					},
					raidicon_size = {
						type = "range",
						name = L["Raid icon size"],
						desc = L["Size of the raid marker texture on nameplates (skull, cross, etc)"],
						order = 7,
						bigStep = 1,
						min = 1,
						softMin = 10,
						softMax = 100
					},
					raidicon_side = {
						type = "select",
						name = L["Raid icon position"],
						desc = L["Which side of the nameplate the raid icon should be displayed on"],
						values = {L["Left"], L["Top"], L["Right"], L["Bottom"]},
						order = 8
					},
					fixaa = {
						type = "toggle",
						name = L["Fix aliasing"],
						desc = L["Attempt to make plates appear sharper.\nWorks best when WoW's UI Scale system option is disabled and at larger resolutions.\n\n|cff88ff88This has a positive effect on performance.|r"] .. RELOAD_HINT,
						order = 10
					},
					compatibility = {
						type = "toggle",
						name = L["Stereo compatibility"],
						desc = L["Fix compatibility with stereo video. This has a negative effect on performance when many nameplates are visible."] .. RELOAD_HINT,
						order = 20
					},
					highlight = {
						type = "toggle",
						name = L["Highlight"],
						desc = L["Highlight plates on mouse over."],
						order = 40
					},
					highlight_target = {
						type = "toggle",
						name = L["Highlight target"],
						desc = L["Also highlight the current target."],
						order = 50,
						disabled = function() return not addon.db.profile.general.highlight end
					},
					glowshadow = {
						type = "toggle",
						name = L["Use glow as shadow"],
						desc = L["The frame glow is used to indicate threat. It becomes black when a unit has no threat status. Disabling this option will make it transparent instead."],
						order = 70
					},
					targetglow = {
						type = "toggle",
						name = L["Show target glow"],
						desc = L["Make your target's nameplate glow"],
						order = 80
					},
					targetglowcolour = {
						type = "color",
						name = L["Target glow colour"],
						order = 90,
						hasAlpha = true,
						disabled = function()
							return not addon.db.profile.general.targetglow and not addon.db.profile.general.targetarrows
						end
					},
					targetarrows = {
						type = "toggle",
						name = L["Show target arrows"],
						desc = L["Show arrows around your target's nameplate. They will inherit the colour of the target glow, set above."],
						order = 100,
						width = "double"
					},
					hheight = {
						type = "range",
						name = L["Health bar height"],
						desc = L["Note that these values do not affect the size or shape of the click-box, which cannot be changed."],
						order = 110,
						step = 1,
						min = 1,
						softMin = 3,
						softMax = 30
					},
					thheight = {
						type = "range",
						name = L["Trivial health bar height"],
						desc = L["Height of the health bar of trivial (small, low maximum health) units."],
						order = 120,
						step = 1,
						min = 1,
						softMin = 3,
						softMax = 30
					},
					width = {
						type = "range",
						name = L["Frame width"],
						order = 130,
						step = 1,
						min = 1,
						softMin = 25,
						softMax = 220
					},
					twidth = {
						type = "range",
						name = L["Trivial frame width"],
						order = 140,
						step = 1,
						min = 1,
						softMin = 25,
						softMax = 220
					},
					lowhealthval = {
						type = "range",
						name = L["Low health value"],
						desc = L["Low health value used by some modules, such as frame fading."],
						min = 1,
						max = 100,
						bigStep = 1,
						order = 170
					}
				}
			},
			fade = {
				name = L["Frame fading"],
				type = "group",
				order = 20,
				args = {
					smooth = {
						type = "toggle",
						name = L["Smoothly fade"],
						desc = L["Smoothly fade plates in/out (fading is instant when disabled)"],
						order = 0
					},
					fademouse = {
						type = "toggle",
						name = L["Fade in with mouse"],
						desc = L["Fade plates in on mouse-over"],
						order = 5
					},
					fadeall = {
						type = "toggle",
						name = L["Fade all frames"],
						desc = L["Fade out all frames by default (rather than in)"],
						order = 10
					},
					rules = {
						type = "group",
						name = L["Fading rules"],
						inline = true,
						order = 20,
						args = {
							avoidhostilehp = {
								type = "toggle",
								name = L["Don't fade hostile units at low health"],
								desc = L["Avoid fading hostile units which are at or below a health value, determined by low health value under general display options."],
								order = 1
							},
							avoidfriendhp = {
								type = "toggle",
								name = L["Don't fade friendly units at low health"],
								desc = L["Avoid fading friendly units which are at or below a health value, determined by low health value under general display options."],
								order = 2
							},
							avoidcast = {
								type = "toggle",
								name = L["Don't fade casting units"],
								desc = L["Avoid fading units which are casting."],
								order = 5
							},
							avoidraidicon = {
								type = "toggle",
								name = L["Don't fade units with raid icons"],
								desc = L["Avoid fading units which have a raid icon (skull, cross, etc)."],
								order = 10
							}
						}
					},
					fadedalpha = {
						type = "range",
						name = L["Faded alpha"],
						desc = L["The alpha value to which plates fade out to"],
						min = 0,
						max = 1,
						bigStep = .01,
						isPercent = true,
						order = 30
					},
					fadespeed = {
						type = "range",
						name = L["Smooth fade speed"],
						desc = L["Fade animation speed modifier (lower is faster)"],
						min = 0,
						softMax = 5,
						order = 40,
						disabled = function() return not addon.db.profile.fade.smooth end
					}
				}
			},
			text = {
				type = "group",
				name = L["Text"],
				order = 30,
				args = {
					level = {
						type = "toggle",
						name = L["Show levels"],
						desc = L["Show levels on nameplates."] .. RELOAD_HINT,
						order = 0
					},
					nametext = {
						type = "group",
						name = NAME,
						inline = true,
						order = 1,
						args = {
							nameanchorpoint = {
								type = "select",
								name = L["Anchor Point"],
								values = SimpleAnchorSelectList,
								order = 1,
								width = "double"
							},
							nameoffsetx = {
								type = "range",
								name = L["X Offset"],
								bigStep = 0.5,
								softMin = -20,
								softMax = 20,
								order = 20
							},
							nameoffsety = {
								type = "range",
								name = L["Y Offset"],
								bigStep = 0.5,
								softMin = -20,
								softMax = 20,
								order = 30
							}
						}
					},
					leveltext = {
						type = "group",
						name = LEVEL,
						inline = true,
						order = 2,
						args = {
							levelanchorpoint = {
								type = "select",
								name = L["Anchor Point"],
								values = AnchorSelectList,
								order = 1,
								width = "double"
							},
							leveloffsetx = {
								type = "range",
								name = L["X Offset"],
								bigStep = 0.5,
								softMin = -20,
								softMax = 20,
								order = 1
							},
							leveloffsety = {
								type = "range",
								name = L["Y Offset"],
								bigStep = 0.5,
								softMin = -20,
								softMax = 20,
								order = 2
							}
						}
					},
					healthtext = {
						type = "group",
						name = HEALTH,
						inline = true,
						order = 3,
						args = {
							healthanchorpoint = {
								type = "select",
								name = L["Anchor Point"],
								values = AnchorSelectList,
								order = 1,
								width = "double"
							},
							healthoffsetx = {
								type = "range",
								name = L["X Offset"],
								bigStep = 0.5,
								softMin = -20,
								softMax = 20,
								order = 1
							},
							healthoffsety = {
								type = "range",
								name = L["Y Offset"],
								bigStep = 0.5,
								softMin = -20,
								softMax = 20,
								order = 2
							}
						}
					}
				}
			},
			hp = {
				name = L["Health display"],
				type = "group",
				order = 40,
				args = {
					reactioncolours = {
						type = "group",
						name = L["Reaction colours"],
						inline = true,
						order = 1,
						args = {
							hatedcol = {
								type = "color",
								name = L["Hostile"],
								order = 1
							},
							neutralcol = {
								type = "color",
								name = L["Neutral"],
								order = 2
							},
							friendlycol = {
								type = "color",
								name = L["Friendly"],
								order = 3
							},
							tappedcol = {
								type = "color",
								name = L["Tapped"],
								order = 4
							},
							playercol = {
								type = "color",
								name = L["Friendly player"],
								order = 5
							}
						}
					},
					bar = {
						type = "group",
						name = L["Health bar"],
						inline = true,
						order = 20,
						args = {
							animation = {
								type = "select",
								name = L["Animation"],
								desc = L["Health bar animation style."] .. RELOAD_HINT,
								values = HealthAnimationSelectList,
								order = 0,
								width = "double"
							}
						}
					},
					text = {
						type = "group",
						name = L["Health text"],
						inline = true,
						order = 30,
						args = {
							hp_text_disabled = {
								type = "toggle",
								name = L["Never show health text"],
								order = 0
							},
							mouseover = {
								type = "toggle",
								name = L["Mouseover & target only"],
								desc = L["Only show health text upon mouseover or on the current target"],
								order = 10,
								disabled = function(info) return addon.db.profile.hp.text.hp_text_disabled end
							},
							hp_friend_max = {
								type = "select",
								name = L["Max. health friend"],
								desc = L["Health text to show on maximum health friendly units"],
								values = HealthTextSelectList,
								order = 20,
								disabled = function(info) return addon.db.profile.hp.text.hp_text_disabled end
							},
							hp_friend_low = {
								type = "select",
								name = L["Damaged friend"],
								desc = L["Health text to show on damaged friendly units"],
								values = HealthTextSelectList,
								order = 30,
								disabled = function(info) return addon.db.profile.hp.text.hp_text_disabled end
							},
							hp_hostile_max = {
								type = "select",
								name = L["Max. health hostile"],
								desc = L["Health text to show on maximum health hostile units"],
								values = HealthTextSelectList,
								order = 40,
								disabled = function(info) return addon.db.profile.hp.text.hp_text_disabled end
							},
							hp_hostile_low = {
								type = "select",
								name = L["Damaged hostile"],
								desc = L["Health text to show on damaged hostile units"],
								values = HealthTextSelectList,
								order = 50,
								disabled = function(info) return addon.db.profile.hp.text.hp_text_disabled end
							}
						}
					}
				}
			},
			fonts = {
				type = "group",
				name = L["Fonts"],
				order = 50,
				args = {
					options = {
						type = "group",
						name = L["Global font settings"],
						inline = true,
						order = 10,
						args = {
							font = {
								type = "select",
								name = L["Font"],
								desc = L["The font used for all text on nameplates"],
								dialogControl = "LSM30_Font",
								values = AceGUIWidgetLSMlists.font,
								order = 5
							},
							fontscale = {
								type = "range",
								name = L["Font scale"],
								desc = L["The scale of all fonts displayed on nameplates"],
								min = 0.01,
								softMax = 3,
								order = 1
							},
							outline = {
								type = "toggle",
								name = L["Outline"],
								desc = L["Display an outline on all fonts"],
								order = 10
							},
							monochrome = {
								type = "toggle",
								name = L["Monochrome"],
								desc = L["Don't anti-alias fonts"],
								order = 15
							},
							onesize = {
								type = "toggle",
								name = L["Use one font size"],
								desc = L["Use the same font size for all strings. Useful when using a pixel font."],
								order = 20
							},
							noalpha = {
								type = "toggle",
								name = L["All fonts opaque"],
								desc = L["Use 100% alpha value on all fonts."] .. RELOAD_HINT,
								order = 25
							}
						}
					},
					sizes = {
						type = "group",
						name = L["Font sizes"],
						inline = true,
						order = 20,
						disabled = function()
							return addon.db.profile.fonts.options.onesize
						end,
						args = {
							desc = {
								type = "description",
								name = L["These are the default font sizes used by various modules. Their names may or may not match what they actually change."],
								fontSize = "medium",
								order = 1
							},
							name = {
								type = "range",
								name = NAME,
								order = 2,
								step = 1,
								min = 1,
								softMin = 1,
								softMax = 30
							},
							level = {
								type = "range",
								name = LEVEL,
								order = 3,
								step = 1,
								min = 1,
								softMin = 1,
								softMax = 30
							},
							health = {
								type = "range",
								name = HEALTH,
								order = 4,
								step = 1,
								min = 1,
								softMin = 1,
								softMax = 30
							},
							spellname = {
								type = "range",
								name = L["Spell name"],
								order = 5,
								step = 1,
								min = 1,
								softMin = 1,
								softMax = 30
							},
							large = {
								type = "range",
								name = L["Large"],
								order = 6,
								step = 1,
								min = 1,
								softMin = 1,
								softMax = 30
							},
							small = {
								type = "range",
								name = L["Small"],
								order = 7,
								step = 1,
								min = 1,
								softMin = 1,
								softMax = 30
							}
						}
					}
				}
			}
		}
	}

	function addon:ProfileChanged()
		-- call all configChangedListeners
		if addon.configChangedListener then
			addon:configChangedListener()
		end

		for _, module in addon:IterateModules() do
			if module.configChangedListener then
				module:configChangedListener()
			end
		end
	end

	local function ToggleModule(mod, v)
		if v then
			mod:Enable()
		else
			mod:Disable()
		end
	end

	-- module prototype
	addon.Prototype = {
		ConfigChanged = ConfigChangedSkeleton,
		AddConfigChanged = AddConfigChanged,
		AddGlobalConfigChanged = AddGlobalConfigChanged,
		Toggle = ToggleModule
	}

	-- create an options table for the given module
	function addon:InitModuleOptions(module)
		if not module.GetOptions then
			return
		end
		local opts = module:GetOptions()
		local name = module.uiName or module.moduleName

		if module.configChangedListener then
			-- run listener upon initialisation
			module:configChangedListener()
		end

		if not module.ConfigChanged then
			-- this module wasn't created with the prototype, so mix it in now
			-- (legacy support)
			for k, v in pairs(addon.Prototype) do
				module[k] = v
			end
		end

		options.args[name] = {
			name = name,
			handler = self:GetOptionHandler(module),
			type = "group",
			order = 50 + (#handlers * 10),
			get = "Get",
			set = "Set",
			args = opts
		}
	end

	function addon:FinalizeOptions()
		if LDS then LDS:EnhanceDatabase(self.db, "kuinameplates") end

		options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
		options.args.profiles.order = -1

		if LDS then LDS:EnhanceOptions(options.args.profiles, self.db) end

		AceConfig:RegisterOptionsTable("kuinameplates", options)
		AceConfigDialog:AddToBlizOptions("kuinameplates", category)

		self.FinalizeOptions = nil
	end

	-- apply prototype to addon
	for k, v in pairs(addon.Prototype) do
		addon[k] = v
	end
end
--------------------------------------------------------------- Github repository --
StaticPopupDialogs.KUINAMEPLATES_GITHUB = {
	text = "Press Ctrl-C to copy the link to your clipboard.",
	button1 = OKAY,
	OnShow = function(self)
		self.wideEditBox:SetText(addon.website)
		self.wideEditBox:HighlightText()
		self.wideEditBox:SetFocus()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
		ClearCursor()
	end,
	hasEditBox = 1,
	hasWideEditBox = 1,
	timeout = 30,
	whileDead = 1,
	hideOnEscape = 1
}
--------------------------------------------------------------- Slash command --
_G.SLASH_KUINAMEPLATES1 = "/kuinameplates"
_G.SLASH_KUINAMEPLATES2 = "/knp"

function SlashCmdList.KUINAMEPLATES()
	addon:OpenConfig()
end

function addon:OpenConfig()
	AceConfigDialog:SetDefaultSize("kuinameplates", 610, 500)
	AceConfigDialog:Open("kuinameplates")
end
function addon:CloseConfig()
	AceConfigDialog:Close("kuinameplates")
end
-- config handlers #############################################################
do
	-- cycle all frames and reset the health and castbar status bar textures
	local function UpdateAllBars()
		for _, frame in pairs(addon.frameList) do
			if frame.kui.health then
				frame.kui.health:SetStatusBarTexture(addon.bartexture)
			end

			if frame.kui.highlight then
				frame.kui.highlight:SetTexture(addon.bartexture)
			end

			if frame.kui.castbar then
				frame.kui.castbar.bar:SetStatusBarTexture(addon.bartexture)
			end
		end
	end

	-- post db change hooks ####################################################
	-- n.b. this is better
	addon:AddConfigChanged(
		{"fonts", "options", "font"},
		function(v)
			addon.font = LSM:Fetch(LSM.MediaType.FONT, v)
			addon:UpdateAllFonts()
		end
	)

	addon:AddConfigChanged(
		{"fonts", "options", "outline"},
		nil,
		function(f, v)
			for _, fontObject in pairs(f.fontObjects) do
				kui.ModifyFontFlags(fontObject, v, "OUTLINE")
			end
		end
	)

	addon:AddConfigChanged(
		{"fonts", "options", "monochrome"},
		nil,
		function(f, v)
			for _, fontObject in pairs(f.fontObjects) do
				kui.ModifyFontFlags(fontObject, v, "MONOCHROME")
			end
		end
	)

	addon:AddConfigChanged(
		{
			{"fonts", "options", "fontscale"},
			{"fonts", "options", "onesize"},
			{"fonts", "sizes"}
		},
		function()
			addon:ScaleFontSizes()
		end,
		function(f)
			for _, fontObject in pairs(f.fontObjects) do
				if fontObject.size then
					fontObject:SetFontSize(fontObject.size)
				end
			end
		end
	)

	addon:AddConfigChanged(
		{"text", "nametext", "nameanchorpoint"},
		function(val)
			addon.db.profile.text.nameanchorpoint = val
		end,
		function(f)
			addon:UpdateName(f, f.trivial)
		end
	)

	addon:AddConfigChanged(
		{"text", "nametext", "nameoffsetx"},
		function(val)
			addon.db.profile.text.nameoffsetx = val
			addon.sizes.tex.nameOffsetX = addon.db.profile.text.nameoffsetx
		end,
		function(f)
			addon:UpdateName(f, f.trivial)
		end
	)
	addon:AddConfigChanged(
		{"text", "nametext", "nameoffsety"},
		function(val)
			addon.db.profile.text.nameoffsety = val
			addon.sizes.tex.nameOffsetY = addon.db.profile.text.nameoffsety
		end,
		function(f)
			addon:UpdateName(f, f.trivial)
		end
	)

	addon:AddConfigChanged(
		{"text", "leveltext", "levelanchorpoint"},
		function(val)
			addon.db.profile.text.levelanchorpoint = val
		end,
		function(f)
			addon:UpdateLevel(f, f.trivial)
		end
	)

	addon:AddConfigChanged(
		{"text", "leveltext", "leveloffsetx"},
		function(val)
			addon.db.profile.text.leveloffsetx = val
			addon.sizes.tex.levelOffsetX = addon.db.profile.text.leveloffsetx
		end,
		function(f)
			addon:UpdateLevel(f, f.trivial)
		end
	)
	addon:AddConfigChanged(
		{"text", "leveltext", "leveloffsety"},
		function(val)
			addon.db.profile.text.leveloffsety = val
			addon.sizes.tex.levelOffsetY = addon.db.profile.text.leveloffsety
		end,
		function(f)
			addon:UpdateLevel(f, f.trivial)
		end
	)

	addon:AddConfigChanged(
		{"text", "healthtext", "healthanchorpoint"},
		function(val)
			addon.db.profile.text.healthanchorpoint = val
		end,
		function(f)
			addon:UpdateHealthText(f, f.trivial)
		end
	)

	addon:AddConfigChanged(
		{"text", "healthtext", "healthoffsetx"},
		function(val)
			addon.db.profile.text.healthoffsetx = val
			addon.sizes.tex.healthOffsetX = addon.db.profile.text.healthoffsetx
		end,
		function(f)
			addon:UpdateHealthText(f, f.trivial)
		end
	)
	addon:AddConfigChanged(
		{"text", "healthtext", "healthoffsety"},
		function(val)
			addon.db.profile.text.healthoffsety = val
			addon.sizes.tex.healthOffsetY = addon.db.profile.text.healthoffsety
		end,
		function(f)
			addon:UpdateHealthText(f, f.trivial)
		end
	)

	addon:AddConfigChanged(
		{"hp", "text"},
		nil,
		function(f)
			if f:IsShown() then
				f:OnHealthValueChanged()
			end
		end
	)
	addon:AddConfigChanged(
		{"hp", "text", "mouseover"},
		nil,
		function(f, v)
			if not v and f.health and f.health.p then
				f.health.p:Show()
			end
		end
	)

	addon:AddConfigChanged(
		{"general", "bartexture"},
		function(v)
			addon.bartexture = LSM:Fetch(LSM.MediaType.STATUSBAR, v)
			UpdateAllBars()
		end
	)

	addon:AddConfigChanged(
		{"general", "targetglowcolour"},
		nil,
		function(f, v)
			if f.targetGlow then
				f.targetGlow:SetVertexColor(unpack(v))
			end

			if f.targetArrows then
				f.targetArrows.left:SetVertexColor(unpack(v))
				f.targetArrows.right:SetVertexColor(unpack(v))
			end
		end
	)

	addon:AddConfigChanged(
		{"general", "strata"},
		nil,
		function(f, v)
			f:SetFrameStrata(v)
		end
	)

	do
		local function UpdateFrameSize(frame)
			addon:UpdateBackground(frame, frame.trivial)
			addon:UpdateHealthBar(frame, frame.trivial)
			addon:UpdateName(frame, frame.trivial)
			addon:UpdateRaidIcon(frame)
			frame:SetCentre()
		end

		addon:AddConfigChanged(
			{
				{"general", "width"},
				{"general", "twidth"},
				{"general", "hheight"},
				{"general", "thheight"},
				{"general", "raidicon_size"},
				{"general", "raidicon_side"}
			},
			addon.UpdateSizesTable,
			UpdateFrameSize
		)
	end
end