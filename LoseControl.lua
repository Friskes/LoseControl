--[[ Code Credits - to the people whose code I borrowed and learned from:
Vendethiel, Lawz, Wowwiki, Kollektiv, Tuller, ckknight, The authors of Nao!!
Thanks! :)
]]
--Modify Addon - Friskes, Atom, RomanSpector. =)

local L = "LoseControl"
local UIParent = UIParent -- it's faster to keep local references to frequently used global vars

local FONT_SIZE = 2.1 -- 1.9-6.0
--local FONT_TEXT = "Fonts\\FRIZQT__.ttf"
local FONT_TEXT = "Interface\\AddOns\\LoseControl\\Media\\LiberationSans.ttf"
local FONT_OUTLINE = "THICKOUTLINE"
local timeThreshold = 2 -- Порог времени для отображения десятых долей секунд.

local function log(msg) DEFAULT_CHAT_FRAME:AddMessage(msg) end -- alias for convenience

local InArena = function() return (select(2,IsInInstance() ) == "arena") end

local CC      = "CC"
local Silence = "Silence"
local Disarm  = "Disarm"
local Root    = "Root"
local Snare   = "Snare"
local Immune  = "Immune"
local PvE     = "PvE"

local TypeMap = {
	[CC] = "CC",
	[Silence] = "Silence",
	[Disarm] = "Disarm",
	[Root] = "Root",
	[Snare] = "Snare",
	[Immune] = "Immune",
	[PvE] = "PvE",
}

local spellIds = {
	-- Death Knight
	[47481] = CC,		-- Gnaw (Ghoul)
	[51209] = CC,		-- Hungering Cold
	[47476] = Silence,	-- Strangulate
	[45524] = Snare,	-- Chains of Ice
	[55666] = Snare,	-- Desecration (no duration, lasts as long as you stand in it)
	[58617] = Snare,	-- Glyph of Heart Strike
	[50436] = Snare,	-- Icy Clutch (Chilblains)
	-- Druid
	[5211]  = CC,		-- Bash (also Shaman Spirit Wolf ability)
	[2637]  = CC,		-- Hibernate (works against Druids in most forms and Shamans using Ghost Wolf)
	[22570] = CC,		-- Maim
	[9005]  = CC,		-- Pounce
	[339]   = Root,		-- Entangling Roots
	[19675] = Root,		-- Feral Charge Effect (immobilize with interrupt [spell lockout, not silence])
	[58179] = Snare,	-- Infected Wounds
	[61391] = Snare,	-- Typhoon
	-- Hunter
	[60210] = CC,		-- Freezing Arrow Effect
	[3355]  = CC,		-- Freezing Trap Effect
	[24394] = CC,		-- Intimidation
	[1513]  = CC,		-- Scare Beast (works against Druids in most forms and Shamans using Ghost Wolf)
	[19503] = CC,		-- Scatter Shot
	[19386] = CC,		-- Wyvern Sting
	[34490] = Silence,	-- Silencing Shot
	[53359] = Disarm,	-- Chimera Shot - Scorpid
	[19306] = Root,		-- Counterattack
	[19185] = Root,		-- Entrapment
	[35101] = Snare,	-- Concussive Barrage
	[5116]  = Snare,	-- Concussive Shot
	[13810] = Snare,	-- Frost Trap Aura (no duration, lasts as long as you stand in it)
	[61394] = Snare,	-- Glyph of Freezing Trap
	[2974]  = Snare,	-- Wing Clip
	-- Hunter Pets
	[50519] = CC,		-- Sonic Blast (Bat)
	[50541] = Disarm,	-- Snatch (Bird of Prey)
	[54644] = Snare,	-- Froststorm Breath (Chimera)
	[50245] = Root,		-- Pin (Crab)
	[50271] = Snare,	-- Tendon Rip (Hyena)
	[50518] = CC,		-- Ravage (Ravager)
	[54706] = Root,		-- Venom Web Spray (Silithid)
	[4167]  = Root,		-- Web (Spider)
	[53148] = Root,  	-- Рывок (Обездвиживание 1с. Питомец охотника)
	-- Mage
	[44572] = CC,		-- Deep Freeze
	[31661] = CC,		-- Dragon's Breath
	[12355] = CC,		-- Impact
	[118]   = CC,		-- Polymorph
	[18469] = Silence,	-- Silenced - Improved Counterspell
	[64346] = Disarm,	-- Fiery Payback
	[33395] = Root,		-- Freeze (Water Elemental)
	[122]   = Root,		-- Frost Nova
	[11071] = Root,		-- Frostbite
	[55080] = Root,		-- Shattered Barrier
	[11113] = Snare,	-- Blast Wave
	[6136]  = Snare,	-- Chilled (generic effect, used by lots of spells [looks weird on Improved Blizzard, might want to comment out])
	[120]   = Snare,	-- Cone of Cold
	[116]   = Snare,	-- Frostbolt
	[47610] = Snare,	-- Frostfire Bolt
	[31589] = Snare,	-- Slow
	-- Paladin
	[853]   = CC,		-- Hammer of Justice
	[2812]  = CC,		-- Holy Wrath (works against Warlocks using Metamorphasis and Death Knights using Lichborne)
	[20066] = CC,		-- Repentance
	[20170] = CC,		-- Stun (Seal of Justice proc)
	[10326] = CC,		-- Turn Evil (works against Warlocks using Metamorphasis and Death Knights using Lichborne)
	[63529] = Silence,	-- Shield of the Templar
	[20184] = Snare,	-- Judgement of Justice (100% movement snare, druids and shamans might want this though)
	-- Priest
	[605]   = CC,		-- Mind Control
	[8122]  = CC,		-- Psychic Scream
	[9484]  = CC,		-- Shackle Undead (works against Death Knights using Lichborne)
	[15487] = Silence,	-- Silence
	[64044] = CC,		-- Psychic Horror
	[64058] = Disarm,	-- Psychic Horror (duplicate debuff names not allowed atm, need to figure out how to support this later)
	[15407] = Snare,	-- Mind Flay
	-- Rogue
	[2094]  = CC,		-- Blind
	[1833]  = CC,		-- Cheap Shot
	[1776]  = CC,		-- Gouge
	[408]   = CC,		-- Kidney Shot
	[6770]  = CC,		-- Sap
	[1330]  = Silence,	-- Garrote - Silence
	[18425] = Silence,	-- Silenced - Improved Kick
	[51722] = Disarm,	-- Dismantle
	[31125] = Snare,	-- Blade Twisting
	[3409]  = Snare,	-- Crippling Poison
	[26679] = Snare,	-- Deadly Throw
	[51693] = Snare,	-- Засада
	-- Shaman
	[39796] = CC,		-- Stoneclaw Stun
	[51514] = CC,		-- Hex (although effectively a silence+disarm effect, it is conventionally thought of as a CC, plus you can trinket out of it)
	[64695] = Root,		-- Earthgrab (Storm, Earth and Fire)
	[63685] = Root,		-- Freeze (Frozen Power)
	[3600]  = Snare,	-- Earthbind (5 second duration per pulse, but will keep re-applying the debuff as long as you stand within the pulse radius)
	[8056]  = Snare,	-- Frost Shock
	[8034]  = Snare,	-- Frostbrand Attack
	[58861] = CC,		-- Оглушить (Оглушение 2с. Питомец шамана)
	-- Warlock
	[710]   = CC,		-- Banish (works against Warlocks using Metamorphasis and Druids using Tree Form)
	[6789]  = CC,		-- Death Coil
	[5782]  = CC,		-- Fear
	[5484]  = CC,		-- Howl of Terror
	[6358]  = CC,		-- Seduction (Succubus)
	[30283] = CC,		-- Shadowfury
	[24259] = Silence,  -- Spell Lock (Felhunter)
	[31117] = Silence,  -- Unstable Affliction
	[18118] = Snare,	-- Aftermath
	[18223] = Snare,	-- Curse of Exhaustion
	[32752] = CC,       -- Summoning Disorientations (stun for active pet while summoning new one)
	[60995] = CC,  		-- Демонический прыжок (Оглушение 3с. Питомец чернокнижника)
	[22703] = CC,  		-- Эффект инфернала (Оглушение 2с. Питомец чернокнижника)
	-- Warrior
	[7922]  = CC,		-- Charge Stun
	[12809] = CC,		-- Concussion Blow
	[20253] = CC,		-- Intercept (also Warlock Felguard ability)
	[5246]  = CC,		-- Intimidating Shout
	[12798] = CC,		-- Revenge Stun
	[46968] = CC,		-- Shockwave
	[18498] = Silence,	-- Silenced - Gag Order
	[676]   = Disarm,	-- Disarm
	[58373] = Root,		-- Glyph of Hamstring
	[23694] = Root,		-- Improved Hamstring
	[1715]  = Snare,	-- Hamstring
	[12323] = Snare,	-- Piercing Howl
	-- Immune
	[33786] = Immune,   -- Cyclone
	[642]   = Immune,   -- Divine Shield (Paladin)
	[19753] = Immune,   -- Божественное вмешательство (Полная неуязвимость и неподвижность 3м. Паладин)
	[45438] = Immune,   -- Ice Block (Mage)
	[51690] = Immune,   -- Череда убийств (Невосприимчивость 2с. Разбойник)
	[6615] = Immune,    -- Свободное действие (Невосприимчивость к оглушающим и затрудняющим передвижение эффектам 30с. Алхимия)
	[24364] = Immune,   -- Живая свобода (Невосприимчивость к эффектам оглушения и затрудняющим передвижение эффектам 5с. Алхимия)
	-- Immune magic
	[48707] = Immune,   -- Anti-Magic Shell
	--[50461] = Immune,   -- Anti-Magic Zone
	[23920] = Immune,   -- Reflect (Warrior)
	--[8178]  = Immune,   -- Grounding Totem
	[31224] = Immune,   -- Cloak of Shadows (Rogue)
	--[31821] = Immune,   -- Мастер аур (Невосприимчивыми к немоте и эффектам прерывания заклинаний 6с. Паладин)
	-- Immune physic
	[10278] = Immune,   -- Hand of Protection (Paladin)
	-- Immune magic + physic
	[47585] = Immune,   -- Dispersion
	[34692] = Immune,   -- The Beast Within (Hunter)
	[19263] = Immune,   -- Deterrence (Hunter)
	[46924] = Immune,   -- Bladestorm (Warrior)
	--[18499] = Immune,   -- Berserker Rage (Warrior)
	--[48792] = Immune,   -- Icebound Fortitude (Death Knight)
	--[49039] = Immune,   -- Lichborne (Death Knight)
	-- Other
	--[5118] = Immune,    -- Aspect of the Cheetah
	--[13159] = Immune,   -- Aspect of the Pack
	[5384] = Immune,    -- Feign Death
	[13181] = CC,       -- Гномская шапка контроля над разумом (Оглушение 30с. Инженерное дело)
	[13327] = CC,		-- Безрассудная атака (Оглушение 30с. Инжереное дело)
	[71988] = CC,		-- Мерзкие духи (Оглушение 30с. Маска злобного фумигатора)
	[19821] = Silence,  -- Чародейская бомба (Немота 5с. Инженерное дело)
	[30217] = CC,		-- Adamantite Grenade
	[67769] = CC,		-- Cobalt Frag Bomb
	[30216] = CC,		-- Fel Iron Bomb
	[20549] = CC,		-- War Stomp
	[25046] = Silence,	-- Arcane Torrent
	[39965] = Root,		-- Frost Grenade
	[55536] = Root,		-- Frostweave Net
	[13099] = Root,		-- Net-o-Matic
	[29703] = Snare,	-- Dazed
	-- PvE
	[14030] = PvE,		-- Сеть с крючьями (Обездвиживание 6с. ПВЕ)
	[50396] = PvE,		-- Психоз (Оглушение ПВЕ)
	[20685] = PvE,		-- Молот бурь (Оглушение ПВЕ)
	[28169] = PvE,		-- Mutating Injection (Grobbulus)
	[28059] = PvE,		-- Positive Charge (Thaddius)
	[28084] = PvE,		-- Negative Charge (Thaddius)
	[27819] = PvE,		-- Detonate Mana (Kel'Thuzad)
	[63024] = PvE,		-- Gravity Bomb (XT-002 Deconstructor)
	[63018] = PvE,		-- Light Bomb (XT-002 Deconstructor)
	[62589] = PvE,		-- Nature's Fury (Freya, via Ancient Conservator)
	[63276] = PvE,		-- Mark of the Faceless (General Vezax)
	[66770] = PvE,	    -- Ferocious Butt (Icehowl)
}

local INTERRUPTS = {
	[6552]	= 4,	-- [Warrior] Pummel
	[72]	= 6,	-- [Warrior] Shield Bash
	[1766]	= 5,	-- [Rogue] Kick
	[47528]	= 4,	-- [DK] Mind Freeze
	[57994]	= 2,	-- [Shaman] Wind Shear
	[19647]	= 6,	-- [Warlock] Spell Lock
	[2139]	= 8,	-- [Mage] Counterspell
	[16979]	= 4,	-- [Feral] Feral Charge (Bear)
	[26090]	= 2,	-- Pummel (Pet)
}

local abilities = {} -- localized names are saved here
for k, v in pairs(spellIds) do
	local name = GetSpellInfo(k)
	if name then
		abilities[name] = v
	else -- Thanks to inph for this idea. Keeps things from breaking when Blizzard changes things.
		log(L .. " unknown spellId: " .. k)
	end
end

-- Global references for attaching icons to various unit frames
local anchors = {
	None = {}, -- empty but necessary
	Blizzard = {
		player = "PlayerPortrait",
		pet    = "PetPortrait",
		target = "TargetFramePortrait",
		focus  = "FocusFramePortrait",
		party1 = "PartyMemberFrame1Portrait",
		party2 = "PartyMemberFrame2Portrait",
		party3 = "PartyMemberFrame3Portrait",
		party4 = "PartyMemberFrame4Portrait",
		partypet1 = "PartyMemberFrame1PetFramePortrait",
		partypet2 = "PartyMemberFrame2PetFramePortrait",
		partypet3 = "PartyMemberFrame3PetFramePortrait",
		partypet4 = "PartyMemberFrame4PetFramePortrait",
		arena1 = "ArenaEnemyFrame1ClassPortrait",
		arena2 = "ArenaEnemyFrame2ClassPortrait",
		arena3 = "ArenaEnemyFrame3ClassPortrait",
		arena4 = "ArenaEnemyFrame4ClassPortrait",
		arena5 = "ArenaEnemyFrame5ClassPortrait",
		arenapet1 = "ArenaEnemyFrame1PetFramePortrait",
		arenapet2 = "ArenaEnemyFrame2PetFramePortrait",
		arenapet3 = "ArenaEnemyFrame3PetFramePortrait",
		arenapet4 = "ArenaEnemyFrame4PetFramePortrait",
		arenapet5 = "ArenaEnemyFrame5PetFramePortrait",
	},
	Perl = {
		player = "Perl_Player_Portrait",
		pet    = "Perl_Player_Pet_Portrait",
		target = "Perl_Target_Portrait",
		focus  = "Perl_Focus_Portrait",
		party1 = "Perl_Party_MemberFrame1_Portrait",
		party2 = "Perl_Party_MemberFrame2_Portrait",
		party3 = "Perl_Party_MemberFrame3_Portrait",
		party4 = "Perl_Party_MemberFrame4_Portrait",
	},
	XPerl = {
		player = "XPerl_PlayerportraitFrameportrait",
		pet    = "XPerl_Player_PetportraitFrameportrait",
		target = "XPerl_TargetportraitFrameportrait",
		focus  = "XPerl_FocusportraitFrameportrait",
		party1 = "XPerl_party1portraitFrameportrait",
		party2 = "XPerl_party2portraitFrameportrait",
		party3 = "XPerl_party3portraitFrameportrait",
		party4 = "XPerl_party4portraitFrameportrait",
	},
	--[[SUF = {
	    player = "SUFUnitplayerTexture",
        pet    = "SUFUnitpetTexture",
        target = "SUFUnittargetTexture",
        focus  = "SUFUnitfocusTexture",
        party1 = "SUFHeaderpartyUnitButton1Texture",
        party2 = "SUFHeaderpartyUnitButton2Texture",
        party3 = "SUFHeaderpartyUnitButton3Texture",
        party4 = "SUFHeaderpartyUnitButton4Texture",
		partypet1 = "SUFChildpartypet1Texture",
		partypet2 = "SUFChildpartypet2Texture",
		partypet3 = "SUFChildpartypet3Texture",
		partypet4 = "SUFChildpartypet4Texture",
		arena1 = "SUFHeaderarenaUnitButton1Texture",
		arena2 = "SUFHeaderarenaUnitButton2Texture",
		arena3 = "SUFHeaderarenaUnitButton3Texture",
		arena4 = "SUFHeaderarenaUnitButton4Texture",
		arena5 = "SUFHeaderarenaUnitButton5Texture",
		arenapet1 = "SUFChildarenapet1Texture",
		arenapet2 = "SUFChildarenapet2Texture",
		arenapet3 = "SUFChildarenapet3Texture",
		arenapet4 = "SUFChildarenapet4Texture",
		arenapet5 = "SUFChildarenapet5Texture",
	},
	Gladius = {
	    arena1 = "GladiusButton1Texture",
	    arena2 = "GladiusButton2Texture",
	    arena3 = "GladiusButton3Texture",
	    arena4 = "GladiusButton4Texture",
	    arena5 = "GladiusButton5Texture",
	},]]
	-- more to come here?
}

local ALL_CATS = {
	"Immune",
	"CC",
	"PvE",
	"Silence",
	"Root",
	"Disarm",
	"Snare",
}

-- Default settings
local DBdefaults = {
	version = 3.44,
	disableCooldownCount = false,
	enablecirclecooldown = true,
	enabledrawedge = true,
	disablecircleanimation = false,
	enablecustomtimer = false,
	enableimmuneonplayer = false,
	trackinterrupt = false,
	changeinterruptprio = false,
	priorities = ALL_CATS,
	tracking = {
		CC      = true,
		Silence = true,
		Disarm  = true,
		Root    = true,
		Snare   = false,
		Immune  = true,
		PvE     = true,
	},
	frames = {
		player = {
			enabled = true,
			inarena = false,
			size = 40,
			alpha = 1,
			anchor = "None",
			point = "TOPLEFT",
			relativePoint = "TOPLEFT",
			x = 662.5335100550784,
			y = -385.1997901058846,
		},
		pet = {
			enabled = true,
			inarena = false,
			size = 50,
			alpha = 1,
			anchor = "None",
			point = "TOPLEFT",
			relativePoint = "TOPLEFT",
			x = 207.9555067149088,
			y = -170.2666753564052,
		},
		target = {
			enabled = true,
			inarena = false,
			size = 48.70000076293945,
			alpha = 1,
			anchor = "None",
			point = "TOPLEFT",
			relativePoint = "TOPLEFT",
			x = 497.3034268640532,
			y = -221.7663589628419,
		},
		focus = {
			enabled = true,
			inarena = false,
			size = 48.70000076293945,
			alpha = 1,
			anchor = "None",
			point = "TOPLEFT",
			relativePoint = "TOPLEFT",
			x = 497.3034268640532,
			y = -417.5220198362659,
		},
		party1 = {
			enabled = true,
			inarena = true,
			size = 48.29999923706055,
			alpha = 1,
			anchor = "None",
			point = "TOPLEFT",
			relativePoint = "TOPLEFT",
			x = 191.105468647152,
			y = -299.5169385275995,
		},
		party2 = {
			enabled = true,
			inarena = true,
			size = 48.29999923706055,
			alpha = 1,
			anchor = "None",
			point = "TOPLEFT",
			relativePoint = "TOPLEFT",
			x = 191.1054861542853,
			y = -412.0831137476064,
		},
		party3 = {
			enabled = false,
			inarena = true,
			size = 41,
			alpha = 1,
			anchor = "Blizzard",
		},
		party4 = {
			enabled = false,
			inarena = true,
			size = 41,
			alpha = 1,
			anchor = "Blizzard",
		},
		partypet1 = {
			enabled = false,
			inarena = true,
			size = 18,
			alpha = 1,
			anchor = "Blizzard",
		},
		partypet2 = {
			enabled = false,
			inarena = true,
			size = 18,
			alpha = 1,
			anchor = "Blizzard",
		},
		partypet3 = {
			enabled = false,
			inarena = true,
			size = 18,
			alpha = 1,
			anchor = "Blizzard",
		},
		partypet4 = {
			enabled = false,
			inarena = true,
			size = 18,
			alpha = 1,
			anchor = "Blizzard",
		},
		arena1 = {
			enabled = true,
			inarena = false,
			size = 44.59999847412109,
			alpha = 1,
			anchor = "None",
			point = "TOPLEFT",
			relativePoint = "TOPLEFT",
			x = 895.4168986646776,
			y = -272.9132038047104,
		},
		arena2 = {
			enabled = true,
			inarena = false,
			size = 44.59999847412109,
			alpha = 1,
			anchor = "None",
			point = "TOPLEFT",
			relativePoint = "TOPLEFT",
			x = 895.6000933075495,
			y = -342.7104677817115,
		},
		arena3 = {
			enabled = true,
			inarena = false,
			size = 44.59999847412109,
			alpha = 1,
			anchor = "None",
			point = "TOPLEFT",
			relativePoint = "TOPLEFT",
			x = 895.9948441492426,
			y = -413.1490180515641,
		},
		arena4 = {
			enabled = false,
			inarena = false,
			size = 41,
			alpha = 1,
			anchor = "Blizzard",
		},
		arena5 = {
			enabled = false,
			inarena = false,
			size = 41,
			alpha = 1,
			anchor = "Blizzard",
		},
		arenapet1 = {
			enabled = false,
			inarena = false,
			size = 18,
			alpha = 1,
			anchor = "Blizzard",
		},
		arenapet2 = {
			enabled = false,
			inarena = false,
			size = 18,
			alpha = 1,
			anchor = "Blizzard",
		},
		arenapet3 = {
			enabled = false,
			inarena = false,
			size = 18,
			alpha = 1,
			anchor = "Blizzard",
		},
		arenapet4 = {
			enabled = false,
			inarena = false,
			size = 18,
			alpha = 1,
			anchor = "Blizzard",
		},
		arenapet5 = {
			enabled = false,
			inarena = false,
			size = 18,
			alpha = 1,
			anchor = "Blizzard",
		},
	},
}
local LoseControlDB -- local reference to the addon settings. this gets initialized when the ADDON_LOADED event fires

-- Create the main class
local LoseControl = CreateFrame("Frame", nil, UIParent)
LoseControl.SquareCooldown = CreateFrame("Cooldown", nil, LoseControl, "CooldownFrameTemplate") -- Exposes the SetCooldown method
LoseControl.CircleCooldown = CreateFrame("Frame", nil, LoseControl, "CircleCooldownFrameTemplate")

function LoseControl:OnEvent(event, ...) -- functions created in "object:method"-style have an implicit first parameter of "self", which points to object
	self[event](self, ...) -- route event parameters to LoseControl:event methods
end
LoseControl:SetScript("OnEvent", LoseControl.OnEvent)

-- Handle default settings
function LoseControl:ADDON_LOADED(arg1)
	if arg1 == L then
		if _G.LoseControlDB and _G.LoseControlDB.version then
			if _G.LoseControlDB.version < DBdefaults.version then
				_G.LoseControlDB = CopyTable(DBdefaults)
				log(LOSECONTROL["LoseControl reset."])
			end
		else -- never installed before
			_G.LoseControlDB = CopyTable(DBdefaults)
			log(LOSECONTROL["LoseControl reset."])
		end
		LoseControlDB = _G.LoseControlDB
		LoseControl.disableCooldownCount = LoseControlDB.disableCooldownCount
		LoseControl.enablecirclecooldown = LoseControlDB.enablecirclecooldown
		LoseControl.enabledrawedge = LoseControlDB.enabledrawedge
		LoseControl.disablecircleanimation = LoseControlDB.disablecircleanimation
		LoseControl.enablecustomtimer = LoseControlDB.enablecustomtimer
		LoseControl.enableimmuneonplayer = LoseControlDB.enableimmuneonplayer
		LoseControl.trackinterrupt = LoseControlDB.trackinterrupt
		LoseControl.changeinterruptprio = LoseControlDB.changeinterruptprio
	end
end
LoseControl:RegisterEvent("ADDON_LOADED")

-- Initialize a frame's position
function LoseControl:PLAYER_ENTERING_WORLD() -- this correctly anchors enemy arena frames that aren't created until you zone into an arena
	self.frame = LoseControlDB.frames[self.unitId] -- store a local reference to the frame's settings
	local frame = self.frame
	self.anchor = _G[anchors[frame.anchor][self.unitId]] or UIParent

	-- Отключает цифры хила/урона на портретах игрока и питомца при закреплении на фрейме
	if frame.anchor == "Blizzard" then
		if self.unitId == "player" then
			PlayerHitIndicator.Show = function() end
		elseif self.unitId == "pet" then
			PetHitIndicator.Show = function() end
		end
	end

	self.timer:SetFont(FONT_TEXT, frame.size / FONT_SIZE, FONT_OUTLINE)

	self:SetParent(self.anchor:GetParent()) -- or LoseControl) -- If Hide() is called on the parent frame, its children are hidden too. This also sets the frame strata to be the same as the parent's.
	--self:SetFrameStrata(frame.strata or "LOW")
	self:ClearAllPoints() -- if we don't do this then the frame won't always move
	self:SetWidth(frame.size)
	self:SetHeight(frame.size)
	self:SetPoint(
		frame.point or "CENTER",
		self.anchor,
		frame.relativePoint or "CENTER",
		frame.x or 0,
		frame.y or 0
	)
	--self:SetAlpha(frame.alpha) -- doesn't seem to work; must manually set alpha after the cooldown is displayed, otherwise it doesn't apply.
end

local function IndexOf(tabl, value)
	for k, v in pairs(tabl) do
		if v == value then
			return k
		end
	end
	return 0
end

-- DeBuff
local WYVERN_STING = GetSpellInfo(24131)
local PSYCHIC_HORROR = GetSpellInfo(64058)
local UNSTABLE_AFFLICTION = GetSpellInfo(30108)

-- Buff
local GROUNDING_TOTEM = GetSpellInfo(8178)
local ASPECT_OF_THE_CHEETAH = GetSpellInfo(5118)
local ASPECT_OF_THE_PACK = GetSpellInfo(13159)
local ANTI_MAGIC_ZONE = GetSpellInfo(50461)

local UnitDebuff = UnitDebuff
local UnitBuff = UnitBuff

-- This is the main event
function LoseControl:UNIT_AURA(unitId) -- fired when a (de)buff is gained/lost
	local frame = LoseControlDB.frames[unitId]

	--if not ( unitId == self.unitId and frame.enabled and self.anchor:IsVisible() ) then return end
	if not ( unitId == self.unitId and frame.enabled and self.anchor:IsVisible() ) or ( frame.inarena and not InArena() ) then return end

	-- the unit is currently kicked, don't show anything else
	if self.trackinterrupt and self:GetKick() then return end

	local maxExpirationTime = 0
	local maxPriority = 99
	local _, name, icon, Icon, duration, Duration, expirationTime, spellID, wyvernsting

	for i = 1, 40 do
		name, _, icon, _, _, duration, expirationTime,_,_,_,spellID = UnitDebuff(unitId, i)

		if not name then break end -- no more debuffs, terminate the loop
		--log(i .. ") " .. name .. " | " .. rank .. " | " .. icon .. " | " .. count .. " | " .. debuffType .. " | " .. duration .. " | " .. expirationTime )

		-- exceptions
		if name == WYVERN_STING then
			wyvernsting = 1

			if not self.wyvernsting then
				self.wyvernsting = 1 -- this is the first time the debuff has been applied
			elseif expirationTime > self.wyvernsting_expirationTime then
				self.wyvernsting = 2 -- this is the second time the debuff has been applied
			end
			self.wyvernsting_expirationTime = expirationTime

			if self.wyvernsting == 2 then
				name = nil -- hack to skip the next if condition since LUA doesn't have a "continue" statement
			end

		-- hack to remove Psychic Horror disarm effect -- hack to remove Unstable Affliction dot effect
		elseif ( name == PSYCHIC_HORROR and icon == "Interface\\Icons\\Ability_Warrior_Disarm" ) or ( name == UNSTABLE_AFFLICTION and icon == "Interface\\Icons\\Spell_Shadow_UnstableAffliction_3" ) then
			name = nil
		end

		if LoseControlDB.tracking[abilities[name]] then
			-- only do indexof here to save on iterations
			local prio = IndexOf(LoseControlDB.priorities, TypeMap[abilities[name]])
			-- low prio = beginning of table = better
			if prio < maxPriority or (prio == maxPriority and expirationTime > maxExpirationTime) then
				maxPriority = prio
				maxExpirationTime = expirationTime
				Duration = duration
				Icon = icon
			end
		end
	end

	-- continue hack for Wyvern Sting
	if self.wyvernsting == 2 and not wyvernsting then -- dot either removed or expired
		self.wyvernsting = nil
	end

	-- Track Immunities
	local immuPrio = IndexOf(LoseControlDB.priorities, Immune) -- use a string

	local variable = true
	if not self.enableimmuneonplayer then
		if unitId ~= "player" then
			variable = true
		else
			variable = false
		end
	end

	if variable and not Icon and LoseControlDB.tracking[Immune] and immuPrio < maxPriority then -- only bother checking for immunities if there were no debuffs found
		for i = 1, 40 do
			name, _, icon, _, _, duration, expirationTime = UnitBuff(unitId, i)

			-- exceptions
			if name == GROUNDING_TOTEM or name == ASPECT_OF_THE_CHEETAH or name == ASPECT_OF_THE_PACK or name == ANTI_MAGIC_ZONE then
				expirationTime = GetTime()
			end

			if not name then break

			elseif abilities[name] == Immune and expirationTime > maxExpirationTime then
				maxExpirationTime = expirationTime
				Duration = duration
				Icon = icon
			end
		end
	end

	if maxExpirationTime == 0 then -- no (de)buffs found
		self:ClearIcon()
	else--if maxExpirationTime ~= self.maxExpirationTime then -- this is a different (de)buff, so initialize the cooldown
		self.maxExpirationTime = maxExpirationTime
		self:DisplayIcon(frame, Icon, maxExpirationTime - Duration, Duration)
	end
end

function LoseControl:GetKick()
	if not self.interrupt then return end
	if GetTime() > self.interrupt then
		self.interrupt = nil
		return false
	end
	return true
end

function LoseControl:COMBAT_LOG_EVENT_UNFILTERED(...)
	local subEvent = select(2, ...)
	--local destName = select(7, ...)
	local destGUID = select(6, ...)
	local spellId = select(9, ...)

	if UnitGUID(self.unitId) ~= destGUID then return end

	if subEvent ~= "SPELL_CAST_SUCCESS" and subEvent ~= "SPELL_INTERRUPT" then
		return
	end
	-- it is necessary to check ~= false, as if the unit isn't casting a channeled spell, it will be nil
	if subEvent == "SPELL_CAST_SUCCESS" and select(8, UnitChannelInfo(self.unitId)) ~= false then
		-- not interruptible
		return
	end
	local frame = LoseControlDB.frames[self.unitId]

	local interruptDuration = INTERRUPTS[spellId]
	if not interruptDuration then return end

	self.interrupt = GetTime() + interruptDuration
	local icon = select(3, GetSpellInfo(spellId))

	if self.trackinterrupt and not frame.inarena and not InArena() then
		self:DisplayIcon(frame, icon, GetTime(), interruptDuration)
	end
end

function LoseControl:DisplayIcon(frame, Icon, start, duration)

	if self.enabledrawedge then
		--self.SquareCooldown:SetDrawEdge(true)
		--self.CircleCooldown:SetDrawEdge(true) -- не корректно работает с круглой анимацией
	end

	if self.anchor ~= UIParent then
		self:SetFrameLevel(self.anchor:GetParent():GetFrameLevel()) -- must be dynamic, frame level changes all the time
		self.SquareCooldown:SetFrameLevel(self.anchor:GetParent():GetFrameLevel())
		self.CircleCooldown:SetFrameLevel(self.anchor:GetParent():GetFrameLevel())

		if not self.drawlayer then
			self.drawlayer = self.anchor:GetDrawLayer() -- back up the current draw layer
		end

		self.anchor:SetDrawLayer("BACKGROUND") -- Temporarily put the portrait texture below the debuff texture. This is the only reliable method I've found for keeping the debuff texture visible with the cooldown spiral on top of it.
	else
		self:SetFrameLevel(50)
		self.SquareCooldown:SetFrameLevel(self:GetFrameLevel() )
	end

	if frame.anchor == "Blizzard" then
		SetPortraitToTexture(self.texture, Icon) -- Sets the texture to be displayed from a file applying a circular opacity mask making it look round like portraits. TO DO: mask the cooldown frame somehow so the corners don't stick out of the portrait frame. Maybe apply a circular alpha mask in the OVERLAY draw layer.

		LoseControlplayer:SetPoint("CENTER", PlayerPortrait, "CENTER", 0.5, -0.7)
		LoseControlpet:SetPoint("CENTER", PetPortrait, "CENTER", -1.4, -0.5)
		LoseControltarget:SetPoint("CENTER", TargetFramePortrait, "CENTER", -0.4, -0.7)
		LoseControlfocus:SetPoint("CENTER", FocusFramePortrait, "CENTER", -0.4, -0.7)
		LoseControlparty1:SetPoint("CENTER", PartyMemberFrame1Portrait, "CENTER", -0.7, -1.3)
		LoseControlpartypet1:SetPoint("CENTER", PartyMemberFrame1PetFramePortrait, "CENTER", 0.5, -1.1)
		LoseControlparty2:SetPoint("CENTER", PartyMemberFrame2Portrait, "CENTER", -0.7, -1.3)
		LoseControlpartypet2:SetPoint("CENTER", PartyMemberFrame2PetFramePortrait, "CENTER", 0.5, -1.1)
		LoseControlparty3:SetPoint("CENTER", PartyMemberFrame3Portrait, "CENTER", -0.7, -1.3)
		LoseControlpartypet3:SetPoint("CENTER", PartyMemberFrame3PetFramePortrait, "CENTER", 0.5, -1.1)
		LoseControlparty4:SetPoint("CENTER", PartyMemberFrame4Portrait, "CENTER", -0.7, -1.3)
		LoseControlpartypet4:SetPoint("CENTER", PartyMemberFrame4PetFramePortrait, "CENTER", 0.5, -1.1)
		LoseControlarena1:SetPoint("CENTER", ArenaEnemyFrame1ClassPortrait, "CENTER", 0.4, 1.3)
		LoseControlarenapet1:SetPoint("CENTER", ArenaEnemyFrame1PetFramePortrait, "CENTER", -1, -1.3)
		LoseControlarena2:SetPoint("CENTER", ArenaEnemyFrame2ClassPortrait, "CENTER", 0.4, 1.3)
		LoseControlarenapet2:SetPoint("CENTER", ArenaEnemyFrame2PetFramePortrait, "CENTER", -1, -1.3)
		LoseControlarena3:SetPoint("CENTER", ArenaEnemyFrame3ClassPortrait, "CENTER", 0.4, 1.3)
		LoseControlarenapet3:SetPoint("CENTER", ArenaEnemyFrame3PetFramePortrait, "CENTER", -1, -1.3)
		LoseControlarena4:SetPoint("CENTER", ArenaEnemyFrame4ClassPortrait, "CENTER", 0.4, 1.3)
		LoseControlarenapet4:SetPoint("CENTER", ArenaEnemyFrame4PetFramePortrait, "CENTER", -1, -1.3)
		LoseControlarena5:SetPoint("CENTER", ArenaEnemyFrame5ClassPortrait, "CENTER", 0.4, 1.3)
		LoseControlarenapet5:SetPoint("CENTER", ArenaEnemyFrame5PetFramePortrait, "CENTER", -1, -1.3)

		if self.enablecirclecooldown then
			self.CircleCooldown:SetDrawBling(false)
			self.CircleCooldown:SetCooldown(start, duration)
			self.CircleCooldown:SetAllPoints()
		else
			if ( Icon == "Interface\\Icons\\Spell_Nature_GroundingTotem" ) or ( Icon == "Interface\\Icons\\Ability_Mount_JungleTiger" ) or ( Icon == "Interface\\Icons\\Ability_Mount_WhiteTiger" ) or ( Icon == "Interface\\Icons\\Spell_DeathKnight_AntiMagicZone" ) then
				self.SquareCooldown:SetDrawEdge(false) -- hack for hide animation
				self.SquareCooldown:SetCooldown(start, -1) -- hack for disable cd
			else
				if self.enabledrawedge then
					self.SquareCooldown:SetDrawEdge(true)
				end

				self.SquareCooldown:SetCooldown(start, duration)
			end
		end
	else
		self.texture:SetTexture(Icon)

		if ( Icon == "Interface\\Icons\\Spell_Nature_GroundingTotem" ) or ( Icon == "Interface\\Icons\\Ability_Mount_JungleTiger" ) or ( Icon == "Interface\\Icons\\Ability_Mount_WhiteTiger" ) or ( Icon == "Interface\\Icons\\Spell_DeathKnight_AntiMagicZone" ) then
			self.SquareCooldown:SetDrawEdge(false) -- hack for hide animation
			self.SquareCooldown:SetCooldown(start, -1) -- hack for disable cd
		else
			if self.enabledrawedge then
				self.SquareCooldown:SetDrawEdge(true)
			end

			self.SquareCooldown:SetCooldown(start, duration)
		end
	end

	if self.disablecircleanimation then
		self.SquareCooldown:SetAlpha(0)
		self.CircleCooldown:SetDrawSwipe(false)
	else
		self.SquareCooldown:SetAlpha(0.85)
	end

	if self.disableCooldownCount then
		self.SquareCooldown.noCooldownCount = true
		self.CircleCooldown.noCooldownCount = true
	end

	if self.enablecustomtimer then
		--self.CircleCooldown:UseColorText(false)
		--self.CircleCooldown:SetShownText(true) -- таймер от круглого тимплейта

		self.timeEnd = start + duration
	else
		self.timeEnd = GetTime()
	end

	self:Show()
	self:SetAlpha(frame.alpha) -- hack to apply transparency to the cooldown timer
end

function LoseControl:OnUpdate()
	-- Создаём кастомный таймер
	local remain = self.timeEnd - GetTime()
	if remain > 0 then
		if remain <= timeThreshold then
			--self.timer:SetTextColor(1, 0, 0)
			self.timer:SetTextColor(1, 1, 1)
			self.timer:SetFormattedText("%.01f", remain)
		elseif remain <= 60 then
			--self.timer:SetTextColor(1, 1, 0)
			self.timer:SetTextColor(1, 1, 1)
			self.timer:SetText(ceil(remain))
		elseif remain <= 3600 then
			self.timer:SetText(ceil(remain / 60) .. LOSECONTROL["m"])
			self.timer:SetTextColor(1, 1, 1)
		else
			self.timer:SetText(ceil(remain / 3600) .. LOSECONTROL["h"])
			self.timer:SetTextColor(1, 1, 1)
		end
	else
		self.timer:SetText("")
	end

	-- we *WERE* interrupted, but it just finished
	if self.interrupt and not self:GetKick() then
		-- trigger UNIT_AURA "manually". It will clear the frame if there is no aura to show.
		self:UNIT_AURA(self.unitId)
	end
end

function LoseControl:ClearIcon()
	self.maxExpirationTime = 0
	if self.anchor ~= UIParent and self.drawlayer then
		self.anchor:SetDrawLayer(self.drawlayer) -- restore the original draw layer
	end
	self:Hide()
end

-- V: this is the worst way to go about it
--    basically when we tab-target, since the unitId doesn't change per say ("target"),
--    we do not detect that the kick icon shouldn't be displayed.
--    The right way to go about it would be to store kicks in a table UnitGUID=>Kick,
--    but :effort:. For now, this will do.
function LoseControl:ResetKick(unitId)
	local frame = LoseControlDB.frames[unitId]

	--if not ( unitId == self.unitId and frame and frame.enabled and self.anchor:IsVisible() ) then return end
	if not ( unitId == self.unitId and frame and frame.enabled and self.anchor:IsVisible() ) or ( frame.inarena and not InArena() ) then return end

	self.interrupt = nil
end

function LoseControl:PLAYER_FOCUS_CHANGED()
	self:ResetKick("focus")
	self:UNIT_AURA("focus")
end

function LoseControl:PLAYER_TARGET_CHANGED()
	self:ResetKick("target")
	self:UNIT_AURA("target")
end

function LoseControl:UNIT_PET()
	self:ResetKick("pet")
	self:UNIT_AURA("pet")
end

function LoseControl:PARTY_MEMBERS_CHANGED()
    if UnitExists(self.unitId) then return end
    self:ResetKick(self.unitId)
    self:ClearIcon()
end
LoseControl.ARENA_OPPONENT_UPDATE = LoseControl.PARTY_MEMBERS_CHANGED

local UnitDropDown -- declared here, initialized below in the options panel code
local AnchorDropDown
-- Handle mouse dragging
function LoseControl:StopMoving()
	local frame = LoseControlDB.frames[self.unitId]
	frame.point, frame.anchor, frame.relativePoint, frame.x, frame.y = self:GetPoint()
	if not frame.anchor then
		frame.anchor = "None"
		if UIDropDownMenu_GetSelectedValue(UnitDropDown) == self.unitId then
			UIDropDownMenu_SetSelectedValue(AnchorDropDown, "None") -- update the drop down to show that the frame has been detached from the anchor
		end
	end
	self.anchor = _G[anchors[frame.anchor][self.unitId]] or UIParent
	self:StopMovingOrSizing()
end

-- Constructor method
function LoseControl:new(unitId)

	local o = CreateFrame("Frame", L .. unitId, UIParent)
	o.SquareCooldown = CreateFrame("Cooldown", L .. unitId .. "SquareCooldown", o, "CooldownFrameTemplate")
	o.CircleCooldown = CreateFrame("Frame", L .. unitId .. "CircleCooldown", o, "CircleCooldownFrameTemplate")

	setmetatable(o, self)
	self.__index = self

	o.timer = o:CreateFontString(nil, "OVERLAY")
	o.timer:SetPoint("CENTER")

	-- Init class members
	o.unitId = unitId -- ties the object to a unit
	o.texture = o:CreateTexture(nil, "BORDER") -- "OVERLAY" переместить иконку над текстурой кд -- в слое "ARTWORK" рисуется текстура кд
	o.texture:SetAllPoints(o) -- anchor the texture to the frame
	o.SquareCooldown:SetReverse(true) -- makes the cooldown shade from light to dark instead of dark to light
	o:Hide()

	-- Handle events
	o:SetScript("OnEvent", self.OnEvent)
	o:SetScript("OnDragStart", self.StartMoving) -- this function is already built into the Frame class
	o:SetScript("OnDragStop", self.StopMoving) -- this is a custom function
	o:SetScript("OnUpdate", self.OnUpdate)
	o:RegisterEvent("PLAYER_ENTERING_WORLD")
	o:RegisterEvent("UNIT_AURA")
	if unitId == "focus" then
		o:RegisterEvent("PLAYER_FOCUS_CHANGED")
	elseif unitId == "target" then
		o:RegisterEvent("PLAYER_TARGET_CHANGED")
	elseif unitId:find("^party") then
        o:RegisterEvent("PARTY_MEMBERS_CHANGED")
    elseif unitId:find("^arena") then
        o:RegisterEvent("ARENA_OPPONENT_UPDATE")
	elseif unitId:find("^pet") then
        o:RegisterEvent("UNIT_PET")
    end
	o:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	return o
end

-- Create new object instance for each frame
local LC = {}
for k in pairs(DBdefaults.frames) do
	LC[k] = LoseControl:new(k)
end

-------------------------------------------------------------------------------
-- Add main Interface Option Panel
local O = L .. "OptionsPanel"

local OptionsPanel = CreateFrame("Frame", O)
OptionsPanel.name = L

local title = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetText(L)

local titleInfo = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
titleInfo:SetTextHeight(12)
titleInfo:SetText(LOSECONTROL["titleInfo"])

local subText = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
local notes = GetAddOnMetadata(L, "Notes-" .. GetLocale())
if not notes then
	notes = GetAddOnMetadata(L, "Notes")
end
--subText:SetText(notes)

-- "Unlock" checkbox - allow the frames to be moved
local Unlock = CreateFrame("CheckButton", O.."Unlock", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."UnlockText"]:SetText(LOSECONTROL["Unlock"])
function Unlock:OnClick()
	if self:GetChecked() then
		--_G[O.."UnlockText"]:SetText(LOSECONTROL["Unlock"] .. LOSECONTROL[" (drag an icon to move)"])
		local keys = {} -- for random icon sillyness
		for k in pairs(spellIds) do
			tinsert(keys, k)
		end
		for k, v in pairs(LC) do
			local frame = LoseControlDB.frames[k]
			--if _G[anchors[frame.anchor][k]] or frame.anchor == "None" then -- only unlock frames whose anchor exists
			if frame.enabled and ( _G[anchors[frame.anchor][k]] or frame.anchor == "None" ) then
				v:UnregisterEvent("UNIT_AURA")
				v:UnregisterEvent("PLAYER_FOCUS_CHANGED")
				v:UnregisterEvent("PLAYER_TARGET_CHANGED")
                v:UnregisterEvent("PARTY_MEMBERS_CHANGED")
                v:UnregisterEvent("ARENA_OPPONENT_UPDATE")
				v:UnregisterEvent("UNIT_PET")
				v:SetMovable(true)
				v:RegisterForDrag("LeftButton")
				v:EnableMouse(true)

				if v.enabledrawedge then
					v.SquareCooldown:SetDrawEdge(true)
					--v.CircleCooldown:SetDrawEdge(true) -- не корректно работает с круглой анимацией
				end

				if v.anchor ~= UIParent then
					v:SetFrameLevel(v.anchor:GetParent():GetFrameLevel())
					v.SquareCooldown:SetFrameLevel(v.anchor:GetParent():GetFrameLevel())
					v.CircleCooldown:SetFrameLevel(v.anchor:GetParent():GetFrameLevel())

					if not v.drawlayer then
						v.drawlayer = v.anchor:GetDrawLayer()
					end

					v.anchor:SetDrawLayer("BACKGROUND")
				else
					v:SetFrameLevel(50)
					v.SquareCooldown:SetFrameLevel(v:GetFrameLevel() )
				end

				--[[if v.anchor:GetParent() then
					v:SetFrameLevel(v.anchor:GetParent():GetFrameLevel())
					v.SquareCooldown:SetFrameLevel(v.anchor:GetParent():GetFrameLevel())
					v.CircleCooldown:SetFrameLevel(v.anchor:GetParent():GetFrameLevel())
					v.texture:SetDrawLayer("ARTWORK")
				end]]

				if frame.anchor == "Blizzard" then
					SetPortraitToTexture(v.texture, select(3, GetSpellInfo(keys[random(#keys)])))

					LoseControlplayer:SetPoint("CENTER", PlayerPortrait, "CENTER", 0.5, -0.7)
					LoseControlpet:SetPoint("CENTER", PetPortrait, "CENTER", -1.4, -0.5)
					LoseControltarget:SetPoint("CENTER", TargetFramePortrait, "CENTER", -0.4, -0.7)
					LoseControlfocus:SetPoint("CENTER", FocusFramePortrait, "CENTER", -0.4, -0.7)
					LoseControlparty1:SetPoint("CENTER", PartyMemberFrame1Portrait, "CENTER", -0.7, -1.3)
					LoseControlpartypet1:SetPoint("CENTER", PartyMemberFrame1PetFramePortrait, "CENTER", 0.5, -1.1)
					LoseControlparty2:SetPoint("CENTER", PartyMemberFrame2Portrait, "CENTER", -0.7, -1.3)
					LoseControlpartypet2:SetPoint("CENTER", PartyMemberFrame2PetFramePortrait, "CENTER", 0.5, -1.1)
					LoseControlparty3:SetPoint("CENTER", PartyMemberFrame3Portrait, "CENTER", -0.7, -1.3)
					LoseControlpartypet3:SetPoint("CENTER", PartyMemberFrame3PetFramePortrait, "CENTER", 0.5, -1.1)
					LoseControlparty4:SetPoint("CENTER", PartyMemberFrame4Portrait, "CENTER", -0.7, -1.3)
					LoseControlpartypet4:SetPoint("CENTER", PartyMemberFrame4PetFramePortrait, "CENTER", 0.5, -1.1)
					LoseControlarena1:SetPoint("CENTER", ArenaEnemyFrame1ClassPortrait, "CENTER", 0.4, 1.3)
					LoseControlarenapet1:SetPoint("CENTER", ArenaEnemyFrame1PetFramePortrait, "CENTER", -1, -1.3)
					LoseControlarena2:SetPoint("CENTER", ArenaEnemyFrame2ClassPortrait, "CENTER", 0.4, 1.3)
					LoseControlarenapet2:SetPoint("CENTER", ArenaEnemyFrame2PetFramePortrait, "CENTER", -1, -1.3)
					LoseControlarena3:SetPoint("CENTER", ArenaEnemyFrame3ClassPortrait, "CENTER", 0.4, 1.3)
					LoseControlarenapet3:SetPoint("CENTER", ArenaEnemyFrame3PetFramePortrait, "CENTER", -1, -1.3)
					LoseControlarena4:SetPoint("CENTER", ArenaEnemyFrame4ClassPortrait, "CENTER", 0.4, 1.3)
					LoseControlarenapet4:SetPoint("CENTER", ArenaEnemyFrame4PetFramePortrait, "CENTER", -1, -1.3)
					LoseControlarena5:SetPoint("CENTER", ArenaEnemyFrame5ClassPortrait, "CENTER", 0.4, 1.3)
					LoseControlarenapet5:SetPoint("CENTER", ArenaEnemyFrame5PetFramePortrait, "CENTER", -1, -1.3)

					if v.enablecirclecooldown then
						v.CircleCooldown:SetDrawBling(false)
						v.CircleCooldown:SetCooldown( GetTime(), 30 )
						v.CircleCooldown:SetAllPoints()
					else
						v.SquareCooldown:SetCooldown( GetTime(), 30 )
					end

				else
					v.texture:SetTexture(select(3, GetSpellInfo(keys[random(#keys)])))
					v.SquareCooldown:SetCooldown( GetTime(), 30 )
				end

				if v.disablecircleanimation then
					v.SquareCooldown:SetAlpha(0)
					v.CircleCooldown:SetDrawSwipe(false)
				else
					v.SquareCooldown:SetAlpha(0.85)
				end

				if v.disableCooldownCount then
					v.SquareCooldown.noCooldownCount = true
					v.CircleCooldown.noCooldownCount = true
				end

				if v.enablecustomtimer then
					--v.CircleCooldown:UseColorText(false)
					--v.CircleCooldown:SetShownText(true) -- таймер от круглого тимплейта

					v.timeEnd = GetTime() + 30
				else
					v.timeEnd = GetTime()
				end

				--v:SetParent(nil) -- detach the frame from its parent or else it won't show if the parent is hidden
				--v:SetFrameStrata(frame.strata or "LOW")
				v:Show()
				v:SetAlpha(frame.alpha) -- hack to apply the alpha to the cooldown timer
			end
		end
	else
		_G[O.."UnlockText"]:SetText(LOSECONTROL["Unlock"])
		for k, v in pairs(LC) do
			local frame = LoseControlDB.frames[k]
			v:RegisterEvent("UNIT_AURA")
			if k == "focus" then
				v:RegisterEvent("PLAYER_FOCUS_CHANGED")
			elseif k == "target" then
				v:RegisterEvent("PLAYER_TARGET_CHANGED")
			elseif k:find("^party") then
                v:RegisterEvent("PARTY_MEMBERS_CHANGED")
            elseif k:find("^arena") then
                v:RegisterEvent("ARENA_OPPONENT_UPDATE")
			elseif k:find("^pet") then
				v:RegisterEvent("UNIT_PET")
            end
			v:SetMovable(false)
			v:RegisterForDrag()
			v:EnableMouse(false)
			v:SetParent(v.anchor:GetParent()) -- or UIParent)
			--v:SetFrameStrata(frame.strata or "LOW")
			v:Hide()
		end
	end
end
Unlock:SetScript("OnClick", Unlock.OnClick)
Unlock:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(LOSECONTROL["UnlockTooltip"], 1, 0.82, 0, 1, false)
end)

local DisableCooldownCount = CreateFrame("CheckButton", O.."DisableCooldownCount", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."DisableCooldownCountText"]:SetText(LOSECONTROL["Disable OmniCC/CooldownCount Support"])
DisableCooldownCount:SetScript("OnClick", function(self)
	LoseControlDB.disableCooldownCount = self:GetChecked()
	LoseControl.disableCooldownCount = LoseControlDB.disableCooldownCount
end)

local EnableCircleCooldown = CreateFrame("CheckButton", O.."EnableCircleCooldown", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."EnableCircleCooldownText"]:SetText(LOSECONTROL["Circle CD Animation"])
EnableCircleCooldown:SetScript("OnClick", function(self)
	LoseControlDB.enablecirclecooldown = self:GetChecked()
	LoseControl.enablecirclecooldown = LoseControlDB.enablecirclecooldown
end)
EnableCircleCooldown:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(LOSECONTROL["Only for Blizzard anchor"], 1, 0.82, 0, 1, false)
end)

local EnableDrawEdge = CreateFrame("CheckButton", O.."EnableDrawEdge", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."EnableDrawEdgeText"]:SetText(LOSECONTROL["Draw Edge"])
EnableDrawEdge:SetScript("OnClick", function(self)
	LoseControlDB.enabledrawedge = self:GetChecked()
	LoseControl.enabledrawedge = LoseControlDB.enabledrawedge
end)
EnableDrawEdge:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(LOSECONTROL["Only for square animation"], 1, 0.82, 0, 1, false)
end)

local DisableCircleAnimation = CreateFrame("CheckButton", O.."DisableCircleAnimation", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."DisableCircleAnimationText"]:SetText(LOSECONTROL["Disable Circle Animation"])
DisableCircleAnimation:SetScript("OnClick", function(self)
	LoseControlDB.disablecircleanimation = self:GetChecked()
	LoseControl.disablecircleanimation = LoseControlDB.disablecircleanimation
end)

local EnableCustomTimer = CreateFrame("CheckButton", O.."EnableCustomTimer", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."EnableCustomTimerText"]:SetText(LOSECONTROL["Enable Custom Timer"])
EnableCustomTimer:SetScript("OnClick", function(self)
	LoseControlDB.enablecustomtimer = self:GetChecked()
	LoseControl.enablecustomtimer = LoseControlDB.enablecustomtimer
end)

local EnableImmuneOnPlayer = CreateFrame("CheckButton", O.."EnableImmuneOnPlayer", OptionsPanel, "OptionsCheckButtonTemplate")
EnableImmuneOnPlayer:SetSize(19, 19)
_G[O.."EnableImmuneOnPlayerText"]:SetTextHeight(10)
_G[O.."EnableImmuneOnPlayerText"]:SetText(LOSECONTROL["Immune On Player"])
EnableImmuneOnPlayer:SetScript("OnClick", function(self)
	LoseControlDB.enableimmuneonplayer = self:GetChecked()
	LoseControl.enableimmuneonplayer = LoseControlDB.enableimmuneonplayer
end)
EnableImmuneOnPlayer:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(LOSECONTROL["Display Immune category on player"], 1, 0.82, 0, 1, false)
end)

local TrackInterrupt = CreateFrame("CheckButton", O.."TrackInterrupt", OptionsPanel, "OptionsCheckButtonTemplate")
TrackInterrupt:SetHitRectInsets(0, -65, 0, 0)
_G[O.."TrackInterruptText"]:SetText(LOSECONTROL["Track Interrupt"])
TrackInterrupt:SetScript("OnClick", function(self)
	LoseControlDB.trackinterrupt = self:GetChecked()
	LoseControl.trackinterrupt = LoseControlDB.trackinterrupt
end)
TrackInterrupt:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(LOSECONTROL["Interrupts are above all other categories."], 1, 0.82, 0, 1, false)
end)

local ChangeInterruptPrio = CreateFrame("CheckButton", O.."ChangeInterruptPrio", OptionsPanel, "OptionsCheckButtonTemplate")
ChangeInterruptPrio:SetHitRectInsets(0, -65, 0, 0)
ChangeInterruptPrio:SetSize(19, 19)
_G[O.."ChangeInterruptPrioText"]:SetTextHeight(10)
_G[O.."ChangeInterruptPrioText"]:SetText(LOSECONTROL["Change Interrupt Prio"])
ChangeInterruptPrio:SetScript("OnClick", function(self)
	LoseControlDB.changeinterruptprio = self:GetChecked()
	LoseControl.changeinterruptprio = LoseControlDB.changeinterruptprio
end)
ChangeInterruptPrio:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(LOSECONTROL["Change Interrupt Prio Tooltip"], 1, 0.82, 0, 1, false)
end)
ChangeInterruptPrio:Hide() -- скрываю т.к. не смог найти решение

local Tracking = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
Tracking:SetText(LOSECONTROL["Tracking"])

local TrackCCs = CreateFrame("CheckButton", O.."TrackCCs", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackCCsText"]:SetText(LOSECONTROL["CC"])
TrackCCs:SetScript("OnClick", function(self)
	LoseControlDB.tracking[CC] = self:GetChecked()
end)

local TrackSilences = CreateFrame("CheckButton", O.."TrackSilences", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackSilencesText"]:SetText(LOSECONTROL["Silence"])
TrackSilences:SetScript("OnClick", function(self)
	LoseControlDB.tracking[Silence] = self:GetChecked()
end)

local TrackDisarms = CreateFrame("CheckButton", O.."TrackDisarms", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackDisarmsText"]:SetText(LOSECONTROL["Disarm"])
TrackDisarms:SetScript("OnClick", function(self)
	LoseControlDB.tracking[Disarm] = self:GetChecked()
end)

local TrackRoots = CreateFrame("CheckButton", O.."TrackRoots", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackRootsText"]:SetText(LOSECONTROL["Root"])
TrackRoots:SetScript("OnClick", function(self)
	LoseControlDB.tracking[Root] = self:GetChecked()
end)

local TrackSnares = CreateFrame("CheckButton", O.."TrackSnares", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackSnaresText"]:SetText(LOSECONTROL["Snare"])
TrackSnares:SetScript("OnClick", function(self)
	LoseControlDB.tracking[Snare] = self:GetChecked()
end)

local TrackImmune = CreateFrame("CheckButton", O.."TrackImmune", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackImmuneText"]:SetText(LOSECONTROL["Immune"])
TrackImmune:SetScript("OnClick", function(self)
	LoseControlDB.tracking[Immune] = self:GetChecked()
end)

local TrackPvE = CreateFrame("CheckButton", O.."TrackPvE", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackPvEText"]:SetText(LOSECONTROL["PvE"])
TrackPvE:SetScript("OnClick", function(self)
	LoseControlDB.tracking[PvE] = self:GetChecked()
end)

-------------------------------------------------------------------------------
-- DropDownMenu helper function
local info = UIDropDownMenu_CreateInfo()
local function AddItem(owner, text, value)
	info.owner = owner
	info.func = owner.OnClick
	info.text = text
	info.value = value
	info.checked = nil -- initially set the menu item to being unchecked
	UIDropDownMenu_AddButton(info)
	return info
end

local UnitDropDownLabel = OptionsPanel:CreateFontString(O.."UnitDropDownLabel", "ARTWORK", "GameFontNormal")
UnitDropDownLabel:SetText(LOSECONTROL["Unit Configuration"])
UnitDropDown = CreateFrame("Frame", O.."UnitDropDown", OptionsPanel, "UIDropDownMenuTemplate")
function UnitDropDown:OnClick()
	UIDropDownMenu_SetSelectedValue(UnitDropDown, self.value)
	OptionsPanel.refresh() -- easy way to update all the other controls
end
UIDropDownMenu_Initialize(UnitDropDown, function() -- sets the initialize function and calls it
	for _, v in ipairs({ "player", "pet", "target", "focus", "party1", "party2", "party3", "party4", "partypet1", "partypet2", "partypet3", "partypet4", --[["raidpet1", "raidpet2", "raidpet3", "raidpet4", "raidpet5",]] "arena1", "arena2", "arena3", "arena4", "arena5", "arenapet1", "arenapet2", "arenapet3", "arenapet4", "arenapet5" }) do -- indexed manually so they appear in order
		AddItem(UnitDropDown, LOSECONTROL[v], v)
	end
end)
UIDropDownMenu_SetSelectedValue(UnitDropDown, "player") -- set the initial drop down choice

local AnchorDropDownLabel = OptionsPanel:CreateFontString(O.."AnchorDropDownLabel", "ARTWORK", "GameFontNormal")
AnchorDropDownLabel:SetText(LOSECONTROL["Anchor"])
AnchorDropDown = CreateFrame("Frame", O.."AnchorDropDown", OptionsPanel, "UIDropDownMenuTemplate")
function AnchorDropDown:OnClick()
	local unit = UIDropDownMenu_GetSelectedValue(UnitDropDown)
	local frame = LoseControlDB.frames[unit]
	local icon = LC[unit]

	UIDropDownMenu_SetSelectedValue(AnchorDropDown, self.value)
	frame.anchor = self.value
	if self.value ~= "None" then -- reset the frame position so it centers on the anchor frame
		frame.point = nil
		frame.relativePoint = nil
		frame.x = nil
		frame.y = nil
	end

	icon.anchor = _G[anchors[frame.anchor][unit]] or UIParent

	if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
		icon:SetParent(icon.anchor:GetParent())
	end

	icon:ClearAllPoints() -- if we don't do this then the frame won't always move
	icon:SetPoint(
		frame.point or "CENTER",
		icon.anchor,
		frame.relativePoint or "CENTER",
		frame.x or 0,
		frame.y or 0
	)
end
function AnchorDropDown:initialize() -- called from OptionsPanel.refresh() and every time the drop down menu is opened
	local unit = UIDropDownMenu_GetSelectedValue(UnitDropDown)
	AddItem(self, LOSECONTROL["None"], "None")
	AddItem(self, "Blizzard", "Blizzard")
	if _G[anchors["Perl"][unit]] then AddItem(self, "Perl", "Perl") end
	if _G[anchors["XPerl"][unit]] then AddItem(self, "XPerl", "XPerl") end
	--AddItem(self, "SUF", "SUF")
	--AddItem(self, "Gladius", "Gladius")
end

local StrataDropDownLabel = OptionsPanel:CreateFontString(O.."StrataDropDownLabel", "ARTWORK", "GameFontNormal")
StrataDropDownLabel:SetText(LOSECONTROL["Strata"])
local StrataDropDown = CreateFrame("Frame", O.."StrataDropDown", OptionsPanel, "UIDropDownMenuTemplate")
function StrataDropDown:OnClick()
	local unit = UIDropDownMenu_GetSelectedValue(UnitDropDown)
	UIDropDownMenu_SetSelectedValue(StrataDropDown, self.value)
	LoseControlDB.frames[unit].strata = self.value
	LC[unit]:SetFrameStrata(self.value)
end
function StrataDropDown:initialize() -- called from OptionsPanel.refresh() and every time the drop down menu is opened
	for _, v in ipairs({ "HIGH", "MEDIUM", "LOW", "BACKGROUND" }) do -- indexed manually so they appear in order
		AddItem(self, v, v)
	end
end

-------------------------------------------------------------------------------
-- Slider helper function, thanks to Kollektiv
local function CreateSlider(text, parent, low, high, step)
	local name = parent:GetName() .. text
	local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
	--slider:SetWidth(160)
	slider:SetMinMaxValues(low, high)
	slider:SetValueStep(step)
	--_G[name .. "Text"]:SetText(text)
	_G[name .. "Low"]:SetText(low)
	_G[name .. "High"]:SetText(high)
	return slider
end

local SizeSlider = CreateSlider(LOSECONTROL["Icon Size"], OptionsPanel, 18, 61, 0.2) -- скалирование иконок
SizeSlider:SetWidth(220)
SizeSlider:SetScript("OnValueChanged", function(self, value)
	local unit = UIDropDownMenu_GetSelectedValue(UnitDropDown)
	_G[self:GetName() .. "Text"]:SetText(LOSECONTROL["Icon Size"] .. string.format(" %.1f", value) )
	LoseControlDB.frames[unit].size = value
	LC[unit]:SetWidth(value)
	LC[unit]:SetHeight(value)
	LC[unit].timer:SetFont(FONT_TEXT, LC[unit]:GetHeight() / FONT_SIZE, FONT_OUTLINE)
end)

local AlphaSlider = CreateSlider(LOSECONTROL["Opacity"], OptionsPanel, 0, 100, 1) -- I was going to use a range of 0 to 1 but Blizzard's slider chokes on decimal values
AlphaSlider:SetWidth(120)
AlphaSlider:SetScript("OnValueChanged", function(self, value)
	local unit = UIDropDownMenu_GetSelectedValue(UnitDropDown)
	_G[self:GetName() .. "Text"]:SetText(LOSECONTROL["Opacity"] .. " " .. value .. "%")
	LoseControlDB.frames[unit].alpha = value / 100 -- the real alpha value
	LC[unit]:SetAlpha(value / 100)
end)
-------------------------------------------------------------------------------

local INarena = CreateFrame("CheckButton", O.."INarena", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."INarenaText"]:SetText(LOSECONTROL["Only In Arena"])
function INarena:OnClick()
	local inarena = self:GetChecked()
	LoseControlDB.frames[UIDropDownMenu_GetSelectedValue(UnitDropDown)].inarena = inarena
end
INarena:SetScript("OnClick", INarena.OnClick)

-------------------------------------------------------------------------------
-- Defined last because it references earlier declared variables
local Enabled = CreateFrame("CheckButton", O.."Enabled", OptionsPanel, "OptionsCheckButtonTemplate")
Enabled:SetHitRectInsets(0, -55, 0, 0)
_G[O.."EnabledText"]:SetText(LOSECONTROL["Enabled"])
function Enabled:OnClick()
	local enabled = self:GetChecked()
	LoseControlDB.frames[UIDropDownMenu_GetSelectedValue(UnitDropDown)].enabled = enabled
	if enabled then
		UIDropDownMenu_EnableDropDown(AnchorDropDown)
		UIDropDownMenu_EnableDropDown(StrataDropDown)
		BlizzardOptionsPanel_Slider_Enable(SizeSlider)
		BlizzardOptionsPanel_Slider_Enable(AlphaSlider)
		BlizzardOptionsPanel_CheckButton_Enable(INarena)
	else
		UIDropDownMenu_DisableDropDown(AnchorDropDown)
		UIDropDownMenu_DisableDropDown(StrataDropDown)
		BlizzardOptionsPanel_Slider_Disable(SizeSlider)
		BlizzardOptionsPanel_Slider_Disable(AlphaSlider)
		BlizzardOptionsPanel_CheckButton_Disable(INarena)
	end
end
Enabled:SetScript("OnClick", Enabled.OnClick)
-------------------------------------------------------------------------------

-- Arrange all the options neatly
title:SetPoint("TOPLEFT", 16, -16)
titleInfo:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 240, 15)
subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)

Unlock:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, 6)
DisableCooldownCount:SetPoint("TOPLEFT", Unlock, "BOTTOMLEFT", 0, -2)
EnableCircleCooldown:SetPoint("TOPLEFT", Unlock, "BOTTOMLEFT", 200, 26)
EnableDrawEdge:SetPoint("TOPLEFT", Unlock, "BOTTOMLEFT", 200, -30)
DisableCircleAnimation:SetPoint("TOPLEFT", Unlock, "BOTTOMLEFT", 200, -2)
EnableCustomTimer:SetPoint("TOPLEFT", Unlock, "BOTTOMLEFT", 0, -30)

Tracking:SetPoint("TOPLEFT", DisableCooldownCount, "BOTTOMLEFT", 0, -30)
TrackCCs:SetPoint("TOPLEFT", Tracking, "BOTTOMLEFT", 0, -4)
TrackSilences:SetPoint("TOPLEFT", TrackCCs, "TOPRIGHT", 100, 0)
TrackDisarms:SetPoint("TOPLEFT", TrackSilences, "TOPRIGHT", 100, 0)
TrackRoots:SetPoint("TOPLEFT", TrackCCs, "BOTTOMLEFT", 0, -2)
TrackSnares:SetPoint("TOPLEFT", TrackSilences, "BOTTOMLEFT", 0, -2)
TrackPvE:SetPoint("TOPLEFT", TrackDisarms, "BOTTOMLEFT", 0, -2)
TrackImmune:SetPoint("TOPLEFT", TrackRoots, "BOTTOMLEFT", 0, -2)
EnableImmuneOnPlayer:SetPoint("TOPLEFT", TrackImmune, "BOTTOMLEFT", 3.5, 2.5)
TrackInterrupt:SetPoint("TOPLEFT", TrackImmune, "BOTTOMLEFT", 126, 26)
ChangeInterruptPrio:SetPoint("TOPLEFT", TrackInterrupt, "BOTTOMLEFT", 3.5, 2.5)

UnitDropDownLabel:SetPoint("TOPLEFT", TrackImmune, "BOTTOMLEFT", 0, -22)
UnitDropDown:SetPoint("TOPLEFT", UnitDropDownLabel, "BOTTOMLEFT", 0, -8)
Enabled:SetPoint("TOPLEFT", UnitDropDown, "BOTTOMLEFT") --, 200, -8)
INarena:SetPoint("TOPLEFT", UnitDropDown, "BOTTOMLEFT", 85, 0)

AnchorDropDownLabel:SetPoint("TOPLEFT", Enabled, "BOTTOMLEFT", 0, -3)	--StrataDropDownLabel:SetPoint("TOPLEFT", UnitDropDown, "BOTTOMLEFT", 200, -12)
AnchorDropDown:SetPoint("TOPLEFT", AnchorDropDownLabel, "BOTTOMLEFT", 0, -8)	--StrataDropDown:SetPoint("TOPLEFT", StrataDropDownLabel, "BOTTOMLEFT", 0, -8)

SizeSlider:SetPoint("TOPLEFT", AnchorDropDown, "BOTTOMLEFT", 5, -16)
AlphaSlider:SetPoint("TOPLEFT", AnchorDropDown, "BOTTOMLEFT", 247, -16)

local PriorityLabel = OptionsPanel:CreateFontString(O.."PriorityLabel", "ARTWORK", "GameFontNormal")
PriorityLabel:SetText(LOSECONTROL["Priorities"])
PriorityLabel:SetPoint("TOPLEFT", UnitDropDownLabel, "TOPRIGHT", 120, 41)

local sortLabels = {}
local upButtons = {}
local function RedrawPriorities()
	for i = 1, #LoseControlDB.priorities do
		sortLabels[i]:SetText(LoseControlDB.priorities[i])
	end
end

for i = 1, #ALL_CATS do
	local upButton = CreateFrame("Button", O.."PriorityLabelFor"..i.."Button", OptionsPanel, "OptionsButtonTemplate")
	upButton:SetText("^")
	upButton:SetWidth(20)
	tinsert(upButtons, upButton)
	upButton:SetScript("OnClick", function (self)
		local prios = LoseControlDB.priorities
		if i < 1 then return end
		if i > #prios then return end

		local prev = prios[i - 1]
		prios[i - 1] = prios[i]
		prios[i] = prev

		RedrawPriorities()
	end)
	upButton.i = i

	local catLabel = OptionsPanel:CreateFontString(O.."PriorityLabelFor"..i, "ARTWORK", "GameFontNormal")
	catLabel:SetText(ALL_CATS[i])
	tinsert(sortLabels, catLabel)
	if i == 1 then
		upButton:SetPoint("TOPLEFT", PriorityLabel, "BOTTOMLEFT", 0, -5)
		upButton:Disable()
	else
		upButton:SetPoint("TOPLEFT", upButtons[i - 1], "BOTTOMLEFT", 0, 0)
	end
	catLabel:SetPoint("TOPLEFT", upButton, "TOPRIGHT", 5, -5)
end

-------------------------------------------------------------------------------
OptionsPanel.default = function() -- This method will run when the player clicks "defaults".
	_G.LoseControlDB = nil
	LoseControl:ADDON_LOADED(L)
	for _, v in pairs(LC) do
		v:PLAYER_ENTERING_WORLD()
	end
end

OptionsPanel.refresh = function() -- This method will run when the Interface Options frame calls its OnShow function and after defaults have been applied via the panel.default method described above, and after the Unit Configuration dropdown is changed.
	local tracking = LoseControlDB.tracking
	local unit = UIDropDownMenu_GetSelectedValue(UnitDropDown)
	local frame = LoseControlDB.frames[unit]
	DisableCooldownCount:SetChecked(LoseControlDB.disableCooldownCount)
	EnableCircleCooldown:SetChecked(LoseControlDB.enablecirclecooldown)
	EnableDrawEdge:SetChecked(LoseControlDB.enabledrawedge)
	DisableCircleAnimation:SetChecked(LoseControlDB.disablecircleanimation)
	EnableCustomTimer:SetChecked(LoseControlDB.enablecustomtimer)
	EnableImmuneOnPlayer:SetChecked(LoseControlDB.enableimmuneonplayer)
	TrackInterrupt:SetChecked(LoseControlDB.trackinterrupt)
	ChangeInterruptPrio:SetChecked(LoseControlDB.changeinterruptprio)
	TrackCCs:SetChecked(tracking[CC])
	TrackSilences:SetChecked(tracking[Silence])
	TrackDisarms:SetChecked(tracking[Disarm])
	TrackRoots:SetChecked(tracking[Root])
	TrackSnares:SetChecked(tracking[Snare])
	TrackImmune:SetChecked(tracking[Immune])
	TrackPvE:SetChecked(tracking[PvE])
	Enabled:SetChecked(frame.enabled)
	Enabled:OnClick()
	INarena:SetChecked(frame.inarena)
	INarena:OnClick()
	AnchorDropDown:initialize()
	UIDropDownMenu_SetSelectedValue(AnchorDropDown, frame.anchor)
	StrataDropDown:initialize()
	UIDropDownMenu_SetSelectedValue(StrataDropDown, frame.strata or "LOW")
	SizeSlider:SetValue(frame.size)
	AlphaSlider:SetValue(frame.alpha * 100)
	RedrawPriorities() -- now that we have the actual priorities
end

InterfaceOptions_AddCategory(OptionsPanel)

-------------------------------------------------------------------------------
SLASH_LoseControl1 = "/lc"
SLASH_LoseControl2 = "/losecontrol"
SlashCmdList[L] = function(cmd)
	cmd = cmd:lower()
	if cmd == "reset" then
		OptionsPanel.default()
		OptionsPanel.refresh()
	elseif cmd == "lock" then
		Unlock:SetChecked(false)
		Unlock:OnClick()
--		log(L .. " locked.")
	elseif cmd == "unlock" then
		Unlock:SetChecked(true)
		Unlock:OnClick()
--		log(L .. " unlocked.")
	elseif cmd:sub(1, 6) == "enable" then
		local unit = cmd:sub(8, 14)
		if LoseControlDB.frames[unit] then
			LoseControlDB.frames[unit].enabled = true
			log(L .. ": " .. unit .. " frame enabled.")
		end
	elseif cmd:sub(1, 7) == "disable" then
		local unit = cmd:sub(9, 15)
		if LoseControlDB.frames[unit] then
			LoseControlDB.frames[unit].enabled = false
			log(L .. ": " .. unit .. " frame disabled.")
		end
	elseif cmd:sub(1, 4) == "help" then
		log(L .. " slash commands:")
		log("    reset")
		log("    lock")
		log("    unlock")
		log("    enable <unit>")
		log("    disable <unit>")
		log("<unit> can be: player, pet, target, focus, party1 ... party4, partypet1 ... partypet4, arena1 ... arena5, arenapet1 ... arenapet5") -- raidpet1 ... raidpet5,
	else
		--log(L .. ": Type \"/lc help\" for more options.")
		InterfaceOptionsFrame_OpenToCategory(OptionsPanel)
	end
end
