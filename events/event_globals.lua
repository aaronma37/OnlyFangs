local addonName, ns = ...
ns.item_id_obs = {}
ns.item_id_epic_obs = {}
ns.last_attack_source = nil
ns.kill_target_exec = {}

ns.event = {}
ns.event_order = {}
ns.event_id = {
	FirstToSixty = 1,
	AdjustPoints = 2,
	OfForgottenMemories = 3,
	Death = 4,
	HighChiefWinterfall = 5,
	Maltorious = 6,
	PawnCapturesQueen = 7,
	Deathclasp = 8,
	KingOfTheJungle = 9,
	AFinalBlow = 10,
	SummoningThePrincess = 11,
	TheHuntCompleted = 12,
	EarthenArise = 13,
	GetMeOutOfHere = 14,
	RitesOfTheEarthmother = 15,
	KimjaelIndeed = 16,
	Counterattack = 17,
	StinkysEscape = 18,
	DarkHeart = 19,
	TestOfEndurance = 20,
	CuergosGold = 21,
	TheStonesThatBindUs = 22,
	GalensEscape = 23,
	Kromgrul = 24,
	TheCrownOfWill = 25,
	BattleOfHillsbrad = 26,
	TheWeaver = 27,
	TheFamilyCrypt = 28,
	BurningShadows = 29,
	RecoverTheKey = 30,
	FirstTo300FirstAid = 31,
	FirstTo300Cooking = 32,
	FirstTo300Fishing = 33,
	FirstTo300Herbalism = 34,
	FirstTo300Mining = 35,
	FirstTo300Tailoring = 36,
	FirstTo300Enchanting = 37,
	FirstTo300Skinning = 38,
	FirstTo300Lockpicking = 39,
	FirstTo300Blacksmithing = 40,
	ReachLvl10 = 41,
	ReachLvl20 = 42,
	ReachLvl30 = 43,
	ReachLvl40 = 44,
	ReachLvl50 = 45,
	ReachLvl60 = 46,
	["75FirstAid"] = 47,
	["75Cooking"] = 48,
	["75Fishing"] = 49,
	["75Herbalism"] = 50,
	["75Mining"] = 51,
	["75Tailoring"] = 52,
	["75Enchanting"] = 53,
	["75Skinning"] = 54,
	["75Lockpicking"] = 55,
	["75Blacksmithing"] = 56,
	["150FirstAid"] = 57,
	["150Cooking"] = 58,
	["150Fishing"] = 59,
	["150Herbalism"] = 60,
	["150Mining"] = 61,
	["150Tailoring"] = 62,
	["150Enchanting"] = 63,
	["150Skinning"] = 64,
	["150Lockpicking"] = 65,
	["150Blacksmithing"] = 66,
	["225FirstAid"] = 67,
	["225Cooking"] = 68,
	["225Fishing"] = 69,
	["225Herbalism"] = 70,
	["225Mining"] = 71,
	["225Tailoring"] = 72,
	["225Enchanting"] = 73,
	["225Skinning"] = 74,
	["225Lockpicking"] = 75,
	["225Blacksmithing"] = 76,
	["300FirstAid"] = 77,
	["300Cooking"] = 78,
	["300Fishing"] = 79,
	["300Herbalism"] = 80,
	["300Mining"] = 81,
	["300Tailoring"] = 82,
	["300Enchanting"] = 83,
	["300Skinning"] = 84,
	["300Lockpicking"] = 85,
	["300Blacksmithing"] = 86,
	["First to Kill Swiftmane"] = 87,
	["First to Kill Rocklance"] = 88,
	["First to Kill Gesharahan"] = 89,
	["First to Kill Taskmaster Whipfang"] = 90,
	["First to Kill Foreman Rigger"] = 91,
	["First to Kill Brother Ravenoak"] = 92,
	["First to Kill Narillasanz"] = 93,
	["First to Kill Warleader Krazzilak"] = 94,
	["First to Kill Grimungous"] = 95,
	["First to Kill Captain Flat Tusk"] = 96,
	["First to Find The 1 Ring"] = 97,
	["First to Find Edgemaster's Handguards"] = 98,
	["First to Find Black Lotus"] = 99,
	["First to Find Arena Master"] = 100,
	["First to Find Tabard of the Scarlet Crusade"] = 101,
	["First to Find Arena Grand Master"] = 102,
	["First to Find Wolfshead Helm"] = 103,
	["First to Find Whirlwind Axe"] = 104,
	["First to Find Formula: Enchant Weapon - Crusader"] = 105,
	["First to Find Recipe: Savory Deviate Delight"] = 106,
	["First to Find Plans: Lionheart Helm"] = 107,
	["First to Find Recipe: Greater Fire Protection Potion"] = 108,
	["First to Find Formula: Enchant Weapon - Agility"] = 109,
	["First to Find Recipe: Swiftness Potion"] = 110,
	["First to Find Recipe: Elixir of Minor Agility"] = 111,
	["First to Find Pattern: Hide of the Wild"] = 112,
	["First to Find Recipe: Elixir of Giant Growth"] = 113,
	["First to Find Robe of Power"] = 114,
	["First to Find Recipe: Flask of Distilled Wisdom"] = 115,
	["First to Find Recipe: Flask of Supreme Power"] = 116,
	["First to Find Recipe: Flask of Petrification"] = 117,
	["Hidden Enemies"] = 118,
	["In Nightmares"] = 119,
	["Arugal Must Die"] = 120,
	["Blackfathom Villainy"] = 121,
	["A Vengeful Fate"] = 122,
	["Rig Wars"] = 123,
	["Bring the End"] = 124,
	["Into the Scarlet Monastery"] = 125,
	["Platinum Discs"] = 126,
	["Gahz'rilla"] = 127,
	["Corruption of Earth and Seed"] = 128,
	["Arcane Refreshment"] = 129,
	["Dreadsteed of Xoroth"] = 130,
	["First40Mount"] = 131,
	["First60Mount"] = 132,
	["FirstEpicBOE"] = 133,
	["First16Slot"] = 134,
	["First315Skinning"] = 135,
	["FirstDevilsaurCrafted"] = 136,
	["Coward"] = 137,
	["First to Kill Gamon"] = 138,
	["DrowningDeath"] = 139,
	["Blood of the Black Dragon Champion"] = 140,
	["LavaDeath"] = 141,
	["The Binding"] = 142,
	["The Green Hills of Stranglethorn"] = 143,
	["Seal of Ascension"] = 144,
	["Big Game Hunter"] = 145,
	["FallDamageDeath"] = 146,
	["Attunement to the Core"] = 147,
	["Master Angler"] = 148,
	["PVPDeath"] = 149,
	["First to Find Splintered Tusk"] = 150,
	["First to Kill Mottled Boar"] = 151,
	["ReachLvl3"] = 152,
	["Your Place In The World"] = 153,
	["Sting of the Scorpid"] = 154,
	["1FirstAid"] = 155,
	["1Cooking"] = 156,
	["1Fishing"] = 157,
	["1Herbalism"] = 158,
	["1Mining"] = 159,
	["1Tailoring"] = 160,
	["1Enchanting"] = 161,
	["1Skinning"] = 162,
	["1Lockpicking"] = 163,
	["1Blacksmithing"] = 164,
	["YourPlaceInTheWorld"] = 165,
	["FireDeath"] = 166,
	["FatigueDeath"] = 167,
	["First to Kill Sarkoth"] = 168,
	["ReachLvl2"] = 169,
	["First to Kill Scorpid Worker"] = 170,
	["First to Kill Adder"] = 171,
	["First to Kill Hare"] = 172,
}
ns.id_event = {}
for k, v in pairs(ns.event_id) do
	ns.id_event[v] = k
end

ns.checkEvents = function()
	local length_of_event = 0
	for k, v in pairs(ns.event) do
		length_of_event = length_of_event + 1
		if ns.event_id[k] == nil then
			print("MISSING EVENT ID", k)
		end
	end

	local length_of_event_ids = 0
	for k, v in pairs(ns.event_id) do
		length_of_event_ids = length_of_event_ids + 1
		if ns.event[k] == nil then
			print("MISSING EVENT", k)
		end
	end

	local length_of_id_events = 0
	for k, v in pairs(ns.id_event) do
		length_of_id_events = length_of_id_events + 1
	end

	if length_of_event_ids ~= length_of_id_events then
		print("NUM MISMATCH 1")
	end

	if length_of_event ~= length_of_id_events then
		print("NUM MISMATCH 2")
	end
end

for k in pairs(ns.event_id) do
	table.insert(ns.event_order, k)
end
table.sort(ns.event_order)

-- sort function from stack overflow
local function spairs(t, order)
	local keys = {}
	for k in pairs(t) do
		keys[#keys + 1] = k
	end

	if order then
		table.sort(keys, function(a, b)
			return order(t, a, b)
		end)
	else
		table.sort(keys)
	end

	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end

local sort_functions = {
	["Level"] = function(t, a, b)
		if ns.passive_achievements[t[a]] and ns.passive_achievements[t[b]] then
			return ns.passive_achievements[t[a]].level_cap < ns.passive_achievements[t[b]].level_cap
		end
		if ns.passive_achievements[t[a]] and ns.passive_achievements[t[b]] == nil then
			return true
		end
		if ns.passive_achievements[t[a]] == nil and ns.passive_achievements[t[b]] then
			return false
		end
	end,
}

local kill_list_dict = {}

function reorderPassiveAchievements()
	local order = {}
	for i, v in spairs(ns.passive_event_order, sort_functions["Level"]) do
		if ns.passive_achievements[v] then
			table.insert(order, v)
			if ns.passive_achievements[v].kill_target then
				kill_list_dict[ns.passive_achievements[v].kill_target] = v
			end

			if ns.passive_achievements[v].kill_targets then
				for target, _ in pairs(ns.passive_achievements[v].kill_targets) do
					kill_list_dict[target] = v
				end
			end
		end
	end
	ns.passive_event_order = order
end

other_hardcore_character_cache = {} -- dict of player name & server to character data

function OnlyFangsGeneratePassiveAchievementCraftedDescription(set_name, level_cap, faction)
	local faction_info = ""
	if faction then
		if faction == "Horde" then
			faction_info = "\r|cff8c1616Horde Only|r"
		elseif faction == "Alliance" then
			faction_info = "\r|cff004a93Alliance Only|r"
		end
	end
	return "Complete the Hardcore challenge after crafting "
		.. set_name
		.. " before reaching level "
		.. level_cap + 1
		.. faction_info
end

function OnlyFangsGeneratePassiveAchievementItemAcquiredDescription(item, rarity, level_cap, faction)
	local faction_info = ""
	if faction then
		if faction == "Horde" then
			faction_info = "\r|cff8c1616Horde Only|r"
		elseif faction == "Alliance" then
			faction_info = "\r|cff004a93Alliance Only|r"
		end
	end
	return "Complete the Hardcore challenge after acquiring |cff00FF00["
		.. item
		.. "]|r before reaching level "
		.. level_cap + 1
		.. faction_info
end

function OnlyFangsGeneratePassiveAchievementBasicQuestDescription(quest_name, zone, level_cap, faction)
	local faction_info = ""
	if faction then
		if faction == "Horde" then
			faction_info = "\r|cff8c1616Horde Only|r"
		elseif faction == "Alliance" then
			faction_info = "\r|cff004a93Alliance Only|r"
		end
	end
	return "Complete the Hardcore challenge after having completed the |cffffff00"
		.. quest_name
		.. "|r quest before reaching level "
		.. level_cap + 1
		.. ".\n"
		.. faction_info
end

function OnlyFangsGeneratePassiveAchievementKillDescription(kill_target, quest_name, zone, level_cap, faction)
	local faction_info = ""
	if faction then
		if faction == "Horde" then
			faction_info = "\r|cff8c1616Horde Only|r"
		elseif faction == "Alliance" then
			faction_info = "\r|cff004a93Alliance Only|r"
		end
	end
	return "Complete the Hardcore challenge after killing |cffFFB9AA"
		.. kill_target
		.. "|r and having completed the |cffffff00"
		.. quest_name
		.. "|r quest before reaching level "
		.. level_cap + 1
		.. ".\n"
		.. faction_info
end

function OnlyFangsGeneratePassiveAchievementProfLevelDescription(profession_name, profession_threshold, level_cap)
	return "Complete the Hardcore challenge after reaching |cff00FF00"
		.. profession_threshold
		.. "|r in "
		.. profession_name
		.. " before reaching level "
		.. level_cap + 1
		.. "."
end

function CalculateOnlyFangsAchievementPts(_hardcore_character)
	local pts = 0
	for _, achievement in ipairs(_hardcore_character.achievements) do
		if ns.achievements[achievement] and ns.achievements[achievement].pts then
			pts = pts + ns.achievements[achievement].pts
		end
	end
	for _, achievement in ipairs(_hardcore_character.passive_achievements) do
		if ns.passive_achievements[achievement] and ns.passive_achievements[achievement].pts then
			pts = pts + ns.passive_achievements[achievement].pts
		end
	end
	return pts
end

function SetAchievementTooltip(achievement_icon, achievement, _player_name)
	achievement_icon:SetCallback("OnEnter", function(widget)
		if UnitName("player") == _player_name and achievement.UpdateDescription then
			achievement:UpdateDescription()
		end
		GameTooltip:SetOwner(WorldFrame, "ANCHOR_CURSOR")
		GameTooltip:AddLine(achievement.title)
		GameTooltip:AddLine(achievement.description, 1, 1, 1, true)
		GameTooltip:AddDoubleLine(
			achievement.bl_text or "Starting Achievement",
			(achievement.pts or tostring(0)) .. "pts",
			1,
			0.82,
			0,
			1,
			0.82,
			0
		)
		GameTooltip:Show()
	end)
	achievement_icon:SetCallback("OnLeave", function(widget)
		GameTooltip:Hide()
	end)
end

ns.enable_testing = true
if ns.enable_testing == true then
	print("OnlyFangs Testing Version Enabled")
end

ns.triggerEvent = function(event_name)
	if ns.event[event_name].test_only == nil or ns.enable_testing then
		ns.showToast(event_name, ns.event[event_name].icon_path, ns.event[event_name].type)
		ns.sendEvent(event_name)
	end
end
