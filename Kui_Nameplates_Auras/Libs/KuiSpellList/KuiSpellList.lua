local MAJOR, MINOR = "KuiSpellList-1.0", 18
local KuiSpellList = LibStub:NewLibrary(MAJOR, MINOR)
if not KuiSpellList then return end

local _

--[[
-- HELPFUL = targets friendly characters
-- HARMFUL = targets hostile characters
-- CONTROL = slows, stuns, roots, morphs, etc
--]]
local listeners = {}
local auras = {
	DEATHKNIGHT = {
		HELPFUL = {
			[3714] = true, -- Path of Frost
			[49222] = true, -- Bone Shield
			[57330] = true -- Horn of Winter
		},
		HARMFUL = {
			[43265] = true, -- Death and Decay
			[55095] = true, -- Frost Fever
			[55078] = true -- Blood Plague
		},
		CONTROL = {
			[50435] = true, -- Icy Clutch
			[56222] = true, -- Dark Command
			[45524] = true, -- Chains of Ice
			[47476] = true, -- Strangulate
			[49560] = true -- Death Grip
		}
	},
	DRUID = {
		HELPFUL = {
			[1126] = true, -- Mark of the Wild
			[774] = true, -- Rejuvenation
			[8936] = true, -- Regrowth
			[33763] = true, -- Lifebloom
			[48438] = true -- Wild Growth
		},
		HARMFUL = {
			[770] = true, -- Faerie Fire
			[16857] = true, -- Faerie Fire (Feral)
			[1079] = true, -- Rip
			[1822] = true, -- Rake
			[8921] = true, -- Moonfire
			[33745] = true -- Lacerate
		},
		CONTROL = {
			[339] = true, -- Entangling Roots
			[6795] = true, -- Growl
			[16914] = true, -- Hurricane
			[22570] = true, -- Main
			[33786] = true, -- Cyclone
			[99] = true, -- Demoralizing Roar
			[5211] = true, -- Bash
			[61391] = true -- Typhoon
		}
	},
	HUNTER = {
		HELPFUL = {
			[34477] = true, -- Misdirection
			[13159] = true -- Aspect of the pack
		},
		HARMFUL = {
			[1130] = true, -- Hunter's Mark
			[3674] = true, -- Black Arrow
			[53301] = true, -- Explosive Shot
			[1978] = true, -- Serpent Sting
			[13812] = true -- Explosive Trap Effect
		},
		CONTROL = {
			[5116] = true, -- Concussive Shot
			[20736] = true, -- Distracting Shot
			[24394] = true, -- Intimidation
			[64803] = true, -- Entrapment
			[3355] = true, -- Freezing Trap Effect
			[19386] = true -- Wyvern Sting
		}
	},
	MAGE = {
		HELPFUL = {
			[1459] = true, -- Arcane Intellect
			[23028] = true, -- Arcane Brilliance
			[130] = true -- Slow Fall
		},
		HARMFUL = {
			[2120] = true, -- Flamestrike
			[10] = true, -- Blizzard
			[11366] = true, -- Pyroblast
			[12654] = true, -- Ignite
			[44457] = true, -- Living Bomb
			[22959] = true, -- Improved Scorch
			[133] = true -- Fireball
		},
		CONTROL = {
			[31589] = true, -- Slow
			[116] = true, -- Frostbolt
			[120] = true, -- Cone of Cold
			[31661] = true, -- Dragon's Breath
			[44572] = true, -- Deep Freeze
			[118] = true, -- Polymorph
			[28271] = true, -- Polymorph (Turtle)
			[28272] = true, -- Polymorph (Pig)
			[61305] = true, -- Polymorph (Black Cat)
			[61721] = true, -- Polymorph (Rabbit)
			[61780] = true -- Polymorph (Turkey)
		}
	},
	PALADIN = {
		HELPFUL = {
			[20925] = true, -- Holy Shield
			[53601] = true, -- Sacred Shield
			[53563] = true, -- Beacon of Light
			[19740] = true, -- Blessing of Might
			[48932] = true, -- Greater Blessing of Might
			[20217] = true, -- Blessing of Kings
			[25898] = true, -- Greater Blessing of Kings
			[6940] = true, -- Hand of Sacrifice
			[1044] = true, -- Hand of Freedom
			[1038] = true, -- Hand of Salvation
			[1022] = true -- Hand of Protection
		},
		HARMFUL = {
			[2812] = true, -- Holy Wrath
			[26573] = true, -- Consecration
			[31803] = true, -- Holy Vengeance
			[61840] = true, -- Righteous Vengeance
			[20184] = true, -- Judgement of Justice
			[20185] = true, -- Judgement of Light
			[20186] = true -- Judgement of Wisdom
		},
		CONTROL = {
			[853] = true, -- Hammer of Justice
			[10326] = true, -- Turn Evil
			[20066] = true, -- Repentance
			[20170] = true, -- Seal of Justice (Stun)
			[31935] = true, -- Avenger's Shield
			[62124] = true -- Hand of Reckoning
		}
	},
	PRIEST = {
		HELPFUL = {
			[17] = true, -- Power Word: Shield
			[139] = true, -- Renew
			[1706] = true, -- Levitate
			[6346] = true, -- Fear Ward
			[21562] = true, -- Prayer of Fortitude
			[33206] = true, -- Pain Suppression
			[41635] = true, -- Prayer of Mending
			[47753] = true, -- Divine Aegis
			[47788] = true, -- Guardian Spirit
			[10060] = true -- Power Infusion
		},
		HARMFUL = {
			[2096] = true, -- Mind Vision
			[589] = true, -- Shadow Word: Pain
			[2944] = true, -- Devouring Plague
			[14914] = true, -- Holy Fire
			[34914] = true, -- Vampiric Touch
			[32379] = true -- Shadow Word: Death
		},
		CONTROL = {
			[605] = true, -- Mind Control
			[8122] = true, -- Psychic Scream
			[64044] = true, -- Psychic Horror
			[9484] = true -- Shackle Undead
		}
	},
	ROGUE = {
		HELPFUL = {
			[57934] = true -- Tricks of the Trade
		},
		HARMFUL = {
			[703] = true, -- Garrote
			[1943] = true, -- Rupture
			[16511] = true, -- Hemorrhage
			[2818] = true, -- Deadly Poison
			[8680] = true -- Instant Poison
		},
		CONTROL = {
			[408] = true, -- kidney shot
			[1330] = true, -- garrote silence
			[1776] = true, -- gouge
			[1833] = true, -- cheap shot
			[2094] = true, -- blind
			[6770] = true, -- sap
			[26679] = true, -- deadly throw
			[3409] = true -- crippling poison
		}
	},
	SHAMAN = {
		HELPFUL = {
			[546] = true, -- Water Walking
			[974] = true, -- Earth Shield
			[61295] = true -- Riptide
		},
		HARMFUL = {
			[8050] = true, -- Flame Shock
			[17364] = true -- Stormstrike
		},
		CONTROL = {
			[3600] = true, -- Earthbind
			[51514] = true, -- Hex
			[8056] = true, -- Frost Shock
			[63685] = true, -- Freeze
			[51490] = true -- Thunderstorm
		}
	},
	WARLOCK = {
		HELPFUL = {
			[5697] = true, -- Unending Breath
			[20707] = true -- Soulstone Resurrection
		},
		HARMFUL = {
			[980] = true, -- Curse of Agony
			[603] = true, -- Curse of Doom
			[172] = true, -- Corruption
			[348] = true, -- Immolate
			[27243] = true, -- Seed of Corruption
			[30108] = true, -- Unstable Affliction
			[47960] = true, -- Shadowflame
			[48181] = true, -- Haunt
			[17793] = true -- Improved Shadow Bolt
		},
		CONTROL = {
			[710] = true, -- Banish
			[1098] = true, -- Enslave Demon
			[5484] = true, -- Howl of Terror
			[5782] = true, -- Fear
			[30283] = true -- Shadowfury
		}
	},
	WARRIOR = {
		HELPFUL = {
			[469] = true, -- Commanding Shout
			[3411] = true, -- Intervene
			[6673] = true -- Battle Shout
		},
		HARMFUL = {
			[12162] = true, -- Deep Wounds
			[1160] = true, -- Demoralizing Shout
			[772] = true, -- Rend
			[64382] = true -- Shattering Throw
		},
		CONTROL = {
			[355] = true, -- Taunt
			[1715] = true, -- Hamstring
			[5246] = true, -- Intimidating Shout
			[7922] = true, -- Charge Stun
			[12323] = true, -- Piercing Howl
			[18498] = true, -- Silenced - Gag Order
			[46968] = true -- Shockwave
		}
	},
	GLOBAL = {
		HELPFUL = {},
		HARMFUL = {},
		CONTROL = {
			[28730] = true, -- arcane torrent/s
			[25046] = true,
			[50613] = true
		}
	}
}

KuiSpellList.GetSingleList = function(class)
	-- return a single table of all spells caused by the given class
	if not auras[class] then
		return {}
	end
	local list = {}

	for _, spells in pairs(auras[class]) do
		for spellid, _ in pairs(spells) do
			list[spellid] = true
		end
	end

	return list
end

KuiSpellList.RegisterChanged = function(table, method)
	-- register listener for whitelist updates
	tinsert(listeners, {table, method})
end

KuiSpellList.WhitelistChanged = function()
	-- inform listeners of whitelist update
	for _, listener in ipairs(listeners) do
		if (listener[1])[listener[2]] then
			(listener[1])[listener[2]]()
		end
	end
end

KuiSpellList.GetDefaultSpells = function(class, onlyClass)
	-- get spell list, ignoring KuiSpellListCustom
	local list = KuiSpellList.GetSingleList(class)

	-- apend global spell list (i.e. racials)
	if not onlyClass then
		local global = KuiSpellList.GetSingleList("GLOBAL")

		for spellid, _ in pairs(global) do
			list[spellid] = true
		end
	end

	return list
end

KuiSpellList.GetImportantSpells = function(class)
	-- get spell list and merge with KuiSpellListCustom if it is set
	local list = KuiSpellList.GetDefaultSpells(class)

	if KuiSpellListCustom then
		for _, group in pairs({class, "GLOBAL"}) do
			if KuiSpellListCustom.Ignore and KuiSpellListCustom.Ignore[group] then
				-- remove ignored spells
				for spellid, _ in pairs(KuiSpellListCustom.Ignore[group]) do
					list[spellid] = nil
				end
			end

			if KuiSpellListCustom.Classes and KuiSpellListCustom.Classes[group] then
				-- merge custom added spells
				for spellid, _ in pairs(KuiSpellListCustom.Classes[group]) do
					list[spellid] = true
				end
			end
		end
	end

	return list
end