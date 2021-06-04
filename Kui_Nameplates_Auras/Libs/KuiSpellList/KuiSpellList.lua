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
			[57330] = true, -- Horn of Winter (rank 1)
			[57623] = true -- Horn of Winter (rank 2)
		},
		HARMFUL = {
			[43265] = true, -- Death and Decay (rank 1)
			[49936] = true, -- Death and Decay (rank 2)
			[49937] = true, -- Death and Decay (rank 3)
			[49938] = true, -- Death and Decay (rank 4)
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
			[1126] = true, -- Mark of the Wild (rank 1)
			[5232] = true, -- Mark of the Wild (rank 2)
			[6756] = true, -- Mark of the Wild (rank 3)
			[5234] = true, -- Mark of the Wild (rank 4)
			[8907] = true, -- Mark of the Wild (rank 5)
			[9884] = true, -- Mark of the Wild (rank 6)
			[9885] = true, -- Mark of the Wild (rank 7)
			[26990] = true, -- Mark of the Wild (rank 8)
			[48469] = true, -- Mark of the Wild (rank 9)
			[774] = true, -- Rejuvenation (rank 1)
			[1058] = true, -- Rejuvenation (rank 2)
			[1430] = true, -- Rejuvenation (rank 3)
			[2090] = true, -- Rejuvenation (rank 4)
			[2091] = true, -- Rejuvenation (rank 5)
			[3627] = true, -- Rejuvenation (rank 6)
			[8910] = true, -- Rejuvenation (rank 7)
			[9839] = true, -- Rejuvenation (rank 8)
			[9840] = true, -- Rejuvenation (rank 9)
			[9841] = true, -- Rejuvenation (rank 10)
			[25299] = true, -- Rejuvenation (rank 11)
			[26981] = true, -- Rejuvenation (rank 12)
			[26982] = true, -- Rejuvenation (rank 13)
			[48440] = true, -- Rejuvenation (rank 14)
			[48441] = true, -- Rejuvenation (rank 15)
			[8936] = true, -- Regrowth (rank 1)
			[8938] = true, -- Regrowth (rank 2)
			[8939] = true, -- Regrowth (rank 3)
			[8940] = true, -- Regrowth (rank 4)
			[8941] = true, -- Regrowth (rank 5)
			[9750] = true, -- Regrowth (rank 6)
			[9856] = true, -- Regrowth (rank 7)
			[9857] = true, -- Regrowth (rank 8)
			[9858] = true, -- Regrowth (rank 9)
			[26980] = true, -- Regrowth (rank 10)
			[48442] = true, -- Regrowth (rank 11)
			[48443] = true, -- Regrowth (rank 12)
			[33763] = true, -- Lifebloom (rank 1)
			[48450] = true, -- Lifebloom (rank 2)
			[48451] = true, -- Lifebloom (rank 3)
			[48438] = true, -- Wild Growth (rank 1)
			[53248] = true, -- Wild Growth (rank 2)
			[53249] = true, -- Wild Growth (rank 3)
			[53251] = true -- Wild Growth (rank 4)
		},
		HARMFUL = {
			[770] = true, -- Faerie Fire
			[16857] = true, -- Faerie Fire (Feral)
			[1079] = true, -- Rip (rank 1)
			[9492] = true, -- Rip (rank 2)
			[9493] = true, -- Rip (rank 3)
			[9752] = true, -- Rip (rank 4)
			[9894] = true, -- Rip (rank 5)
			[9896] = true, -- Rip (rank 6)
			[27008] = true, -- Rip (rank 7)
			[49799] = true, -- Rip (rank 8)
			[49800] = true, -- Rip (rank 9)
			[1822] = true, -- Rake (rank 1)
			[1823] = true, -- Rake (rank 2)
			[1824] = true, -- Rake (rank 3)
			[9904] = true, -- Rake (rank 4)
			[27003] = true, -- Rake (rank 5)
			[48573] = true, -- Rake (rank 6)
			[48574] = true, -- Rake (rank 7)
			[8921] = true, -- Moonfire (rank 1)
			[8924] = true, -- Moonfire (rank 2)
			[8925] = true, -- Moonfire (rank 3)
			[8926] = true, -- Moonfire (rank 4)
			[8927] = true, -- Moonfire (rank 5)
			[8928] = true, -- Moonfire (rank 6)
			[8929] = true, -- Moonfire (rank 7)
			[9833] = true, -- Moonfire (rank 8)
			[9834] = true, -- Moonfire (rank 9)
			[9835] = true, -- Moonfire (rank 10)
			[26987] = true, -- Moonfire (rank 11)
			[26988] = true, -- Moonfire (rank 12)
			[33745] = true, -- Lacerate (rank 1)
			[48567] = true, -- Lacerate (rank 2)
			[48568] = true -- Lacerate (rank 3)
		},
		CONTROL = {
			[339] = true, -- Entangling Roots (rank 1)
			[1062] = true, -- Entangling Roots (rank 2)
			[5195] = true, -- Entangling Roots (rank 3)
			[5196] = true, -- Entangling Roots (rank 4)
			[9852] = true, -- Entangling Roots (rank 5)
			[9853] = true, -- Entangling Roots (rank 6)
			[26989] = true, -- Entangling Roots (rank 7)
			[53308] = true, -- Entangling Roots (rank 8)
			[6795] = true, -- Growl
			[16914] = true, -- Hurricane (rank 1)
			[17401] = true, -- Hurricane (rank 2)
			[17402] = true, -- Hurricane (rank 3)
			[27012] = true, -- Hurricane (rank 4)
			[48467] = true, -- Hurricane (rank 5)
			[22570] = true, -- Main (rank 1)
			[49802] = true, -- Main (rank 2)
			[33786] = true, -- Cyclone
			[99] = true, -- Demoralizing Roar (rank 1)
			[1735] = true, -- Demoralizing Roar (rank 2)
			[9490] = true, -- Demoralizing Roar (rank 3)
			[9747] = true, -- Demoralizing Roar (rank 4)
			[9898] = true, -- Demoralizing Roar (rank 5)
			[26998] = true, -- Demoralizing Roar (rank 6)
			[48559] = true, -- Demoralizing Roar (rank 7)
			[48560] = true, -- Demoralizing Roar (rank 8)
			[5211] = true, -- Bash (rank 1)
			[6798] = true, -- Bash (rank 2)
			[8983] = true, -- Bash (rank 3)
			[61391] = true, -- Typhoon (rank 1)
			[61390] = true, -- Typhoon (rank 2)
			[61388] = true, -- Typhoon (rank 3)
			[61387] = true, -- Typhoon (rank 4)
			[53227] = true -- Typhoon (rank 5)
		}
	},
	HUNTER = {
		HELPFUL = {
			[34477] = true, -- Misdirection
			[13159] = true -- Aspect of the pack
		},
		HARMFUL = {
			[1130] = true, -- Hunter's Mark (rank 1)
			[14323] = true, -- Hunter's Mark (rank 2)
			[14324] = true, -- Hunter's Mark (rank 3)
			[14325] = true, -- Hunter's Mark (rank 4)
			[53338] = true, -- Hunter's Mark (rank 5)
			[3674] = true, -- Black Arrow (rank 1)
			[63668] = true, -- Black Arrow (rank 2)
			[63669] = true, -- Black Arrow (rank 3)
			[63670] = true, -- Black Arrow (rank 4)
			[63671] = true, -- Black Arrow (rank 5)
			[63672] = true, -- Black Arrow (rank 6)
			[53301] = true, -- Explosive Shot (rank 1)
			[60051] = true, -- Explosive Shot (rank 2)
			[60052] = true, -- Explosive Shot (rank 3)
			[60053] = true, -- Explosive Shot (rank 4)
			[1978] = true, -- Serpent Sting (rank 1)
			[13549] = true, -- Serpent Sting (rank 2)
			[13550] = true, -- Serpent Sting (rank 3)
			[13551] = true, -- Serpent Sting (rank 4)
			[13552] = true, -- Serpent Sting (rank 5)
			[13553] = true, -- Serpent Sting (rank 6)
			[13554] = true, -- Serpent Sting (rank 7)
			[13555] = true, -- Serpent Sting (rank 8)
			[25295] = true, -- Serpent Sting (rank 9)
			[27016] = true, -- Serpent Sting (rank 10)
			[49000] = true, -- Serpent Sting (rank 11)
			[49001] = true, -- Serpent Sting (rank 12)
			[13812] = true, -- Explosive Trap Effect (rank 1)
			[14314] = true, -- Explosive Trap Effect (rank 2)
			[14315] = true, -- Explosive Trap Effect (rank 3)
			[27026] = true, -- Explosive Trap Effect (rank 4)
			[49064] = true, -- Explosive Trap Effect (rank 5)
			[49065] = true -- Explosive Trap Effect (rank 6)
		},
		CONTROL = {
			[5116] = true, -- Concussive Shot
			[20736] = true, -- Distracting Shot
			[24394] = true, -- Intimidation
			[64803] = true, -- Entrapment
			[3355] = true, -- Freezing Trap Effect (rank 1)
			[14308] = true, -- Freezing Trap Effect (rank 2)
			[14309] = true, -- Freezing Trap Effect (rank 3)
			[19386] = true, -- Wyvern Sting (rank 1)
			[24132] = true, -- Wyvern Sting (rank 2)
			[24133] = true, -- Wyvern Sting (rank 3)
			[27068] = true, -- Wyvern Sting (rank 4)
			[49011] = true, -- Wyvern Sting (rank 5)
			[49012] = true -- Wyvern Sting (rank 6)
		}
	},
	MAGE = {
		HELPFUL = {
			[1459] = true, -- Arcane Intellect (rank 1)
			[1460] = true, -- Arcane Intellect (rank 2)
			[1461] = true, -- Arcane Intellect (rank 3)
			[10156] = true, -- Arcane Intellect (rank 4)
			[10157] = true, -- Arcane Intellect (rank 5)
			[27126] = true, -- Arcane Intellect (rank 6)
			[42995] = true, -- Arcane Intellect (rank 7)
			[61024] = true, -- Dalaran Intellect (rank 7)
			[23028] = true, -- Arcane Brilliance (rank 1)
			[27127] = true, -- Arcane Brilliance (rank 2)
			[43002] = true, -- Arcane Brilliance (rank 3)
			[61316] = true, -- Dalaran Brilliance (rank 3)
			[130] = true -- Slow Fall
		},
		HARMFUL = {
			[2120] = true, -- Flamestrike (rank 1)
			[2121] = true, -- Flamestrike (rank 2)
			[8422] = true, -- Flamestrike (rank 3)
			[8423] = true, -- Flamestrike (rank 4)
			[10215] = true, -- Flamestrike (rank 5)
			[10216] = true, -- Flamestrike (rank 6)
			[27086] = true, -- Flamestrike (rank 7)
			[42925] = true, -- Flamestrike (rank 8)
			[42926] = true, -- Flamestrike (rank 9)
			[10] = true, -- Blizzard (rank 1)
			[6141] = true, -- Blizzard (rank 2)
			[8427] = true, -- Blizzard (rank 3)
			[10185] = true, -- Blizzard (rank 4)
			[10186] = true, -- Blizzard (rank 5)
			[10187] = true, -- Blizzard (rank 6)
			[27085] = true, -- Blizzard (rank 7)
			[42939] = true, -- Blizzard (rank 8)
			[42940] = true, -- Blizzard (rank 9)
			[11366] = true, -- Pyroblast (rank 1)
			[12505] = true, -- Pyroblast (rank 2)
			[12522] = true, -- Pyroblast (rank 3)
			[12523] = true, -- Pyroblast (rank 4)
			[12524] = true, -- Pyroblast (rank 5)
			[12525] = true, -- Pyroblast (rank 6)
			[12526] = true, -- Pyroblast (rank 7)
			[18809] = true, -- Pyroblast (rank 8)
			[27132] = true, -- Pyroblast (rank 9)
			[12654] = true, -- Ignite
			[44457] = true, -- Living Bomb (rank 1)
			[55359] = true, -- Living Bomb (rank 2)
			[55360] = true, -- Living Bomb (rank 3)
			[22959] = true, -- Improved Scorch
			[133] = true, -- Fireball (rank 1)
			[143] = true, -- Fireball (rank 2)
			[145] = true, -- Fireball (rank 3)
			[3140] = true, -- Fireball (rank 4)
			[8400] = true, -- Fireball (rank 5)
			[8401] = true, -- Fireball (rank 6)
			[8402] = true, -- Fireball (rank 7)
			[10148] = true, -- Fireball (rank 8)
			[10149] = true, -- Fireball (rank 9)
			[10150] = true, -- Fireball (rank 10)
			[10151] = true, -- Fireball (rank 11)
			[25306] = true, -- Fireball (rank 12)
			[27070] = true, -- Fireball (rank 13)
			[38692] = true, -- Fireball (rank 14)
			[42832] = true, -- Fireball (rank 15)
			[42833] = true -- Fireball (rank 16)
		},
		CONTROL = {
			[31589] = true, -- Slow
			[116] = true, -- Frostbolt (rank 1)
			[205] = true, -- Frostbolt (rank 2)
			[837] = true, -- Frostbolt (rank 3)
			[7322] = true, -- Frostbolt (rank 4)
			[8406] = true, -- Frostbolt (rank 5)
			[8407] = true, -- Frostbolt (rank 6)
			[8408] = true, -- Frostbolt (rank 7)
			[10179] = true, -- Frostbolt (rank 8)
			[10180] = true, -- Frostbolt (rank 9)
			[10181] = true, -- Frostbolt (rank 10)
			[25304] = true, -- Frostbolt (rank 11)
			[27071] = true, -- Frostbolt (rank 12)
			[27072] = true, -- Frostbolt (rank 13)
			[38697] = true, -- Frostbolt (rank 14)
			[42841] = true, -- Frostbolt (rank 15)
			[42842] = true, -- Frostbolt (rank 16)
			[120] = true, -- Cone of Cold (rank 1)
			[8492] = true, -- Cone of Cold (rank 2)
			[10159] = true, -- Cone of Cold (rank 3)
			[10160] = true, -- Cone of Cold (rank 4)
			[10161] = true, -- Cone of Cold (rank 5)
			[27087] = true, -- Cone of Cold (rank 6)
			[42930] = true, -- Cone of Cold (rank 7)
			[42931] = true, -- Cone of Cold (rank 8)
			[31661] = true, -- Dragon's Breath (rank 1)
			[33041] = true, -- Dragon's Breath (rank 2)
			[33042] = true, -- Dragon's Breath (rank 3)
			[33043] = true, -- Dragon's Breath (rank 4)
			[42949] = true, -- Dragon's Breath (rank 5)
			[42950] = true, -- Dragon's Breath (rank 6)
			[44572] = true, -- Deep Freeze
			[118] = true, -- Polymorph (rank 1)
			[12824] = true, -- Polymorph (rank 2)
			[12825] = true, -- Polymorph (rank 3)
			[12826] = true, -- Polymorph (rank 4)
			[28271] = true, -- Polymorph (Turtle)
			[28272] = true, -- Polymorph (Pig)
			[61305] = true, -- Polymorph (Black Cat)
			[61721] = true, -- Polymorph (Rabbit)
			[61780] = true -- Polymorph (Turkey)
		}
	},
	PALADIN = {
		HELPFUL = {
			[20925] = true, -- Holy Shield (rank 1)
			[20927] = true, -- Holy Shield (rank 2)
			[20928] = true, -- Holy Shield (rank 3)
			[27179] = true, -- Holy Shield (rank 4)
			[48951] = true, -- Holy Shield (rank 5)
			[48952] = true, -- Holy Shield (rank 6)
			[53601] = true, -- Sacred Shield
			[53563] = true, -- Beacon of Light
			[19740] = true, -- Blessing of Might (rank 1)
			[19834] = true, -- Blessing of Might (rank 2)
			[19835] = true, -- Blessing of Might (rank 3)
			[19836] = true, -- Blessing of Might (rank 4)
			[19837] = true, -- Blessing of Might (rank 5)
			[19838] = true, -- Blessing of Might (rank 6)
			[25291] = true, -- Blessing of Might (rank 7)
			[27140] = true, -- Blessing of Might (rank 8)
			[48931] = true, -- Blessing of Might (rank 9)
			[48932] = true, -- Blessing of Might (rank 10)
			[48932] = true, -- Greater Blessing of Might (rank 1)
			[25916] = true, -- Greater Blessing of Might (rank 2)
			[27141] = true, -- Greater Blessing of Might (rank 3)
			[48933] = true, -- Greater Blessing of Might (rank 4)
			[48934] = true, -- Greater Blessing of Might (rank 5)
			[20217] = true, -- Blessing of Kings
			[25898] = true, -- Greater Blessing of Kings
			[6940] = true, -- Hand of Sacrifice
			[1044] = true, -- Hand of Freedom
			[1038] = true, -- Hand of Salvation
			[1022] = true, -- Hand of Protection (rank 1)
			[5599] = true, -- Hand of Protection (rank 2)
			[10278] = true -- Hand of Protection (rank 3)
		},
		HARMFUL = {
			[2812] = true, -- Holy Wrath (rank 1)
			[10318] = true, -- Holy Wrath (rank 2)
			[27139] = true, -- Holy Wrath (rank 3)
			[48816] = true, -- Holy Wrath (rank 4)
			[48817] = true, -- Holy Wrath (rank 5)
			[26573] = true, -- Consecration (rank 1)
			[20116] = true, -- Consecration (rank 2)
			[20922] = true, -- Consecration (rank 3)
			[20923] = true, -- Consecration (rank 4)
			[20924] = true, -- Consecration (rank 5)
			[27173] = true, -- Consecration (rank 6)
			[48818] = true, -- Consecration (rank 7)
			[48819] = true, -- Consecration (rank 8)
			[31803] = true, -- Holy Vengeance
			[61840] = true, -- Righteous Vengeance
			[20184] = true, -- Judgement of Justice
			[20185] = true, -- Judgement of Light
			[20186] = true -- Judgement of Wisdom
		},
		CONTROL = {
			[853] = true, -- Hammer of Justice (rank 1)
			[5588] = true, -- Hammer of Justice (rank 2)
			[5589] = true, -- Hammer of Justice (rank 3)
			[10308] = true, -- Hammer of Justice (rank 4)
			[10326] = true, -- Turn Evil
			[20066] = true, -- Repentance
			[20170] = true, -- Seal of Justice (Stun)
			[31935] = true, -- Avenger's Shield (rank 1)
			[32699] = true, -- Avenger's Shield (rank 2)
			[32700] = true, -- Avenger's Shield (rank 3)
			[48826] = true, -- Avenger's Shield (rank 4)
			[48827] = true, -- Avenger's Shield (rank 5)
			[62124] = true -- Hand of Reckoning
		}
	},
	PRIEST = {
		HELPFUL = {
			[17] = true, -- Power Word: Shield (rank 1)
			[592] = true, -- Power Word: Shield (rank 2)
			[600] = true, -- Power Word: Shield (rank 3)
			[3747] = true, -- Power Word: Shield (rank 4)
			[6065] = true, -- Power Word: Shield (rank 5)
			[6066] = true, -- Power Word: Shield (rank 6)
			[10898] = true, -- Power Word: Shield (rank 7)
			[10899] = true, -- Power Word: Shield (rank 8)
			[10900] = true, -- Power Word: Shield (rank 9)
			[10901] = true, -- Power Word: Shield (rank 10)
			[25217] = true, -- Power Word: Shield (rank 11)
			[25218] = true, -- Power Word: Shield (rank 12)
			[48065] = true, -- Power Word: Shield (rank 13)
			[48066] = true, -- Power Word: Shield (rank 14)
			[139] = true, -- Renew (rank 1)
			[6074] = true, -- Renew (rank 2)
			[6075] = true, -- Renew (rank 3)
			[6076] = true, -- Renew (rank 4)
			[6077] = true, -- Renew (rank 5)
			[6078] = true, -- Renew (rank 6)
			[10927] = true, -- Renew (rank 7)
			[10928] = true, -- Renew (rank 8)
			[10929] = true, -- Renew (rank 9)
			[25315] = true, -- Renew (rank 10)
			[25221] = true, -- Renew (rank 11)
			[25222] = true, -- Renew (rank 12)
			[48067] = true, -- Renew (rank 13)
			[48068] = true, -- Renew (rank 14)
			[1706] = true, -- Levitate
			[6346] = true, -- Fear Ward
			[21562] = true, -- Prayer of Fortitude (rank 1)
			[21564] = true, -- Prayer of Fortitude (rank 2)
			[25392] = true, -- Prayer of Fortitude (rank 3)
			[48162] = true, -- Prayer of Fortitude (rank 4)
			[33206] = true, -- Pain Suppression
			[41635] = true, -- Prayer of Mending (rank 1)
			[48110] = true, -- Prayer of Mending (rank 2)
			[48111] = true, -- Prayer of Mending (rank 3)
			[47753] = true, -- Divine Aegis (rank 1)
			[47511] = true, -- Divine Aegis (rank 2)
			[47515] = true, -- Divine Aegis (rank 3)
			[47788] = true, -- Guardian Spirit
			[10060] = true -- Power Infusion
		},
		HARMFUL = {
			[2096] = true, -- Mind Vision (rank 1)
			[10909] = true, -- Mind Vision (rank 2)
			[589] = true, -- Shadow Word: Pain (rank 1)
			[594] = true, -- Shadow Word: Pain (rank 2)
			[970] = true, -- Shadow Word: Pain (rank 3)
			[992] = true, -- Shadow Word: Pain (rank 4)
			[2767] = true, -- Shadow Word: Pain (rank 5)
			[10892] = true, -- Shadow Word: Pain (rank 6)
			[10893] = true, -- Shadow Word: Pain (rank 7)
			[10894] = true, -- Shadow Word: Pain (rank 8)
			[25367] = true, -- Shadow Word: Pain (rank 9)
			[25368] = true, -- Shadow Word: Pain (rank 10)
			[48124] = true, -- Shadow Word: Pain (rank 11)
			[48125] = true, -- Shadow Word: Pain (rank 12)
			[2944] = true, -- Devouring Plague (rank 1)
			[19276] = true, -- Devouring Plague (rank 2)
			[19277] = true, -- Devouring Plague (rank 3)
			[19278] = true, -- Devouring Plague (rank 4)
			[19279] = true, -- Devouring Plague (rank 5)
			[19280] = true, -- Devouring Plague (rank 6)
			[25467] = true, -- Devouring Plague (rank 7)
			[48299] = true, -- Devouring Plague (rank 8)
			[48300] = true, -- Devouring Plague (rank 9)
			[14914] = true, -- Holy Fire (rank 1)
			[15262] = true, -- Holy Fire (rank 2)
			[15263] = true, -- Holy Fire (rank 3)
			[15264] = true, -- Holy Fire (rank 4)
			[15265] = true, -- Holy Fire (rank 5)
			[15266] = true, -- Holy Fire (rank 6)
			[15267] = true, -- Holy Fire (rank 7)
			[15261] = true, -- Holy Fire (rank 8)
			[25384] = true, -- Holy Fire (rank 9)
			[48134] = true, -- Holy Fire (rank 10)
			[48135] = true, -- Holy Fire (rank 11)
			[34914] = true, -- Vampiric Touch (rank 1)
			[34916] = true, -- Vampiric Touch (rank 2)
			[34917] = true, -- Vampiric Touch (rank 3)
			[48159] = true, -- Vampiric Touch (rank 4)
			[48160] = true, -- Vampiric Touch (rank 5)
			[32379] = true, -- Shadow Word: Death (rank 1)
			[32996] = true, -- Shadow Word: Death (rank 2)
			[48157] = true, -- Shadow Word: Death (rank 3)
			[48158] = true -- Shadow Word: Death (rank 4)
		},
		CONTROL = {
			[605] = true, -- Mind Control
			[8122] = true, -- Psychic Scream (rank 1)
			[8124] = true, -- Psychic Scream (rank 2)
			[10888] = true, -- Psychic Scream (rank 3)
			[10890] = true, -- Psychic Scream (rank 4)
			[64044] = true, -- Psychic Horror
			[9484] = true, -- Shackle Undead (rank 1)
			[9485] = true, -- Shackle Undead (rank 2)
			[10955] = true -- Shackle Undead (rank 3)
		}
	},
	ROGUE = {
		HELPFUL = {
			[57934] = true -- Tricks of the Trade
		},
		HARMFUL = {
			[703] = true, -- Garrote (rank 1)
			[8631] = true, -- Garrote (rank 2)
			[8632] = true, -- Garrote (rank 3)
			[8633] = true, -- Garrote (rank 4)
			[11289] = true, -- Garrote (rank 5)
			[11290] = true, -- Garrote (rank 6)
			[26839] = true, -- Garrote (rank 7)
			[26884] = true, -- Garrote (rank 8)
			[48675] = true, -- Garrote (rank 9)
			[1943] = true, -- Rupture (rank 1)
			[8639] = true, -- Rupture (rank 2)
			[8640] = true, -- Rupture (rank 3)
			[11273] = true, -- Rupture (rank 4)
			[11274] = true, -- Rupture (rank 5)
			[11275] = true, -- Rupture (rank 6)
			[26867] = true, -- Rupture (rank 7)
			[48671] = true, -- Rupture (rank 8)
			[48672] = true, -- Rupture (rank 9)
			[16511] = true, -- Hemorrhage (rank 1)
			[17347] = true, -- Hemorrhage (rank 2)
			[17348] = true, -- Hemorrhage (rank 3)
			[26864] = true, -- Hemorrhage (rank 4)
			[48660] = true, -- Hemorrhage (rank 5)
			[2818] = true, -- Deadly Poison (rank 1)
			[2819] = true, -- Deadly Poison (rank 2)
			[11353] = true, -- Deadly Poison (rank 3)
			[11354] = true, -- Deadly Poison (rank 4)
			[25351] = true, -- Deadly Poison (rank 5) -- needs review
			[26968] = true, -- Deadly Poison (rank 6)
			[27187] = true, -- Deadly Poison (rank 7)
			[57969] = true, -- Deadly Poison (rank 8)
			[57970] = true, -- Deadly Poison (rank 9)
			[8680] = true, -- Instant Poison (rank 1)
			[8685] = true, -- Instant Poison (rank 2)
			[8689] = true, -- Instant Poison (rank 3)
			[11335] = true, -- Instant Poison (rank 4)
			[11336] = true, -- Instant Poison (rank 5)
			[11340] = true, -- Instant Poison (rank 6) -- needs review
			[26890] = true, -- Instant Poison (rank 7)
			[57964] = true, -- Instant Poison (rank 8)
			[57965] = true -- Instant Poison (rank 9)
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
			[974] = true, -- Earth Shield (rank 1)
			[32593] = true, -- Earth Shield (rank 2)
			[32594] = true, -- Earth Shield (rank 3)
			[49283] = true, -- Earth Shield (rank 4)
			[49284] = true, -- Earth Shield (rank 5)
			[61295] = true, -- Riptide (rank 1)
			[61299] = true, -- Riptide (rank 2)
			[61300] = true, -- Riptide (rank 3)
			[61301] = true -- Riptide (rank 4)
		},
		HARMFUL = {
			[8050] = true, -- Flame Shock (rank 1)
			[8052] = true, -- Flame Shock (rank 2)
			[8053] = true, -- Flame Shock (rank 3)
			[10447] = true, -- Flame Shock (rank 4)
			[10448] = true, -- Flame Shock (rank 5)
			[29228] = true, -- Flame Shock (rank 6)
			[25457] = true, -- Flame Shock (rank 7)
			[49232] = true, -- Flame Shock (rank 8)
			[49233] = true, -- Flame Shock (rank 9)
			[17364] = true -- Stormstrike
		},
		CONTROL = {
			[3600] = true, -- Earthbind
			[51514] = true, -- Hex
			[8056] = true, -- Frost Shock (rank 1)
			[8058] = true, -- Frost Shock (rank 2)
			[10472] = true, -- Frost Shock (rank 3)
			[10473] = true, -- Frost Shock (rank 4)
			[25464] = true, -- Frost Shock (rank 5)
			[49235] = true, -- Frost Shock (rank 6)
			[49236] = true, -- Frost Shock (rank 7)
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
			[980] = true, -- Curse of Agony (rank 1)
			[1014] = true, -- Curse of Agony (rank 2)
			[6217] = true, -- Curse of Agony (rank 3)
			[11711] = true, -- Curse of Agony (rank 4)
			[11712] = true, -- Curse of Agony (rank 5)
			[11713] = true, -- Curse of Agony (rank 6)
			[27218] = true, -- Curse of Agony (rank 7)
			[47863] = true, -- Curse of Agony (rank 8)
			[47864] = true, -- Curse of Agony (rank 9)
			[603] = true, -- Curse of Doom (rank 1)
			[30910] = true, -- Curse of Doom (rank 2)
			[47867] = true, -- Curse of Doom (rank 3)
			[172] = true, -- Corruption (rank 1)
			[6222] = true, -- Corruption (rank 2)
			[6223] = true, -- Corruption (rank 3)
			[7648] = true, -- Corruption (rank 4)
			[11671] = true, -- Corruption (rank 5)
			[11672] = true, -- Corruption (rank 6)
			[25311] = true, -- Corruption (rank 7)
			[27216] = true, -- Corruption (rank 8)
			[47812] = true, -- Corruption (rank 9)
			[47813] = true, -- Corruption (rank 10)
			[348] = true, -- Immolate (rank 1)
			[707] = true, -- Immolate (rank 2)
			[1094] = true, -- Immolate (rank 3)
			[2941] = true, -- Immolate (rank 4)
			[11665] = true, -- Immolate (rank 5)
			[11667] = true, -- Immolate (rank 6)
			[11668] = true, -- Immolate (rank 7)
			[25309] = true, -- Immolate (rank 8)
			[27215] = true, -- Immolate (rank 9)
			[47810] = true, -- Immolate (rank 10)
			[47811] = true, -- Immolate (rank 11)
			[27243] = true, -- Seed of Corruption (rank 1)
			[47835] = true, -- Seed of Corruption (rank 2)
			[47836] = true, -- Seed of Corruption (rank 3)
			[30108] = true, -- Unstable Affliction (rank 1)
			[30404] = true, -- Unstable Affliction (rank 2)
			[30405] = true, -- Unstable Affliction (rank 3)
			[47841] = true, -- Unstable Affliction (rank 4)
			[47843] = true, -- Unstable Affliction (rank 5)
			[47960] = true, -- Shadowflame
			[48181] = true, -- Haunt (rank 1)
			[59161] = true, -- Haunt (rank 2)
			[59163] = true, -- Haunt (rank 3)
			[59164] = true, -- Haunt (rank 4)
			[17793] = true, -- Improved Shadow Bolt (rank 1)
			[17796] = true, -- Improved Shadow Bolt (rank 2)
			[17801] = true, -- Improved Shadow Bolt (rank 3)
			[17802] = true, -- Improved Shadow Bolt (rank 4)
			[17803] = true -- Improved Shadow Bolt (rank 5)
		},
		CONTROL = {
			[710] = true, -- Banish (rank 1)
			[18647] = true, -- Banish (rank 2)
			[1098] = true, -- Enslave Demon (rank 1)
			[11725] = true, -- Enslave Demon (rank 2)
			[11726] = true, -- Enslave Demon (rank 3)
			[61191] = true, -- Enslave Demon (rank 4)
			[5484] = true, -- Howl of Terror (rank 1)
			[17928] = true, -- Howl of Terror (rank 2)
			[5782] = true, -- Fear (rank 1)
			[6213] = true, -- Fear (rank 2)
			[6215] = true, -- Fear (rank 3)
			[30283] = true, -- Shadowfury (rank 1)
			[30413] = true, -- Shadowfury (rank 2)
			[30414] = true, -- Shadowfury (rank 3)
			[47846] = true, -- Shadowfury (rank 4)
			[47847] = true -- Shadowfury (rank 5)
		}
	},
	WARRIOR = {
		HELPFUL = {
			[469] = true, -- Commanding Shout (rank 1)
			[47439] = true, -- Commanding Shout (rank 2)
			[47440] = true, -- Commanding Shout (rank 3)
			[3411] = true, -- Intervene
			[6673] = true, -- Battle Shout (rank 1)
			[5242] = true, -- Battle Shout (rank 2)
			[6192] = true, -- Battle Shout (rank 3)
			[6673] = true, -- Battle Shout (rank 4)
			[11550] = true, -- Battle Shout (rank 5)
			[11551] = true, -- Battle Shout (rank 6)
			[25289] = true, -- Battle Shout (rank 7)
			[2048] = true, -- Battle Shout (rank 8)
			[47436] = true -- Battle Shout (rank 9)
		},
		HARMFUL = {
			[12162] = true, -- Deep Wounds (rank 1)
			[12850] = true, -- Deep Wounds (rank 2)
			[12868] = true, -- Deep Wounds (rank 3)
			[1160] = true, -- Demoralizing Shout (rank 1)
			[6190] = true, -- Demoralizing Shout (rank 2)
			[11554] = true, -- Demoralizing Shout (rank 3)
			[11555] = true, -- Demoralizing Shout (rank 4)
			[11556] = true, -- Demoralizing Shout (rank 5)
			[25202] = true, -- Demoralizing Shout (rank 6)
			[25203] = true, -- Demoralizing Shout (rank 7)
			[47437] = true, -- Demoralizing Shout (rank 8)
			[772] = true, -- Rend (rank 1)
			[6546] = true, -- Rend (rank 2)
			[6547] = true, -- Rend (rank 3)
			[6548] = true, -- Rend (rank 4)
			[11572] = true, -- Rend (rank 5)
			[11573] = true, -- Rend (rank 6)
			[11574] = true, -- Rend (rank 7)
			[25208] = true, -- Rend (rank 8)
			[46845] = true, -- Rend (rank 9)
			[47465] = true, -- Rend (rank 10)
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