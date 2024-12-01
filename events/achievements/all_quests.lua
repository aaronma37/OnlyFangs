local addonName, ns = ...

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

local quest_metadata = {
	{
		["name"] = "YourPlaceInTheWorld",
		["title"] = "Your Place In The World",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
		["quest_name"] = "Your Place In The World",
		["zone"] = "Durotar",
		["quest_id"] = 4641,
		["max_lvl"] = 5,
		["pts"] = 5,
		["test_only"] = 1,
	},
	{
		["name"] = "HighChiefWinterfall",
		["title"] = "High Chief Winterfall",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
		["quest_name"] = "High Chief Winterfall",
		["zone"] = "Winterfall",
		["max_lvl"] = 56,
		["quest_id"] = 5121,
	},
	{
		["name"] = "OfForgottenMemories",
		["title"] = "Grave Digger",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Of Forgotten Memories",
		["zone"] = "Eastern Plaguelands",
		["max_lvl"] = 55,
		["quest_id"] = 5781,
	},
	{
		["name"] = "Maltorious",
		["title"] = "Head of the Dark Iron Slag Pit",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "WANTED: Overseer Maltorious",
		["zone"] = "Searing Gorge",
		["max_lvl"] = 52,
		["quest_id"] = 7701,
	},
	{
		["name"] = "PawnCapturesQueen",
		["title"] = "Brain of the Queen",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Pawn Captures Queen",
		["zone"] = "Un'Goro",
		["max_lvl"] = 54,
		["quest_id"] = 4507,
	},
	{
		["name"] = "Deathclasp",
		["title"] = "Terror of the Sands Eliminated",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Wanted: Deathclasp, Terror of the Sands",
		["zone"] = "Silithus",
		["max_lvl"] = 59,
		["quest_id"] = 8283,
	},
	{
		["name"] = "KingOfTheJungle",
		["title"] = "Big Game Hunter",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Big Game Hunter",
		["zone"] = "Stranglethorn Vale",
		["max_lvl"] = 39,
		["quest_id"] = 208,
	},
	{
		["name"] = "AFinalBlow",
		["title"] = "Death to the Legion",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "A Final Blow",
		["zone"] = "Felwood",
		["max_lvl"] = 53,
		["quest_id"] = 5242,
	},
	{
		["name"] = "SummoningThePrincess",
		["title"] = "Myzrael to the Shadowrealm",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Summoning the Princess",
		["zone"] = "Arathi Highlands",
		["max_lvl"] = 54,
		["quest_id"] = 656,
	},
	{
		["name"] = "TheHuntCompleted",
		["title"] = "Eradicate the Beasts",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "The Hunt Completed",
		["zone"] = "Ashenvale",
		["max_lvl"] = 25,
		["quest_id"] = 247,
	},
	{
		["name"] = "EarthenArise",
		["title"] = "Death to Goggeroc",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Earthen Arise",
		["zone"] = "Stonetalon Mountains",
		["max_lvl"] = 21,
		["quest_id"] = 6481,
	},
	{
		["name"] = "GetMeOutOfHere",
		["title"] = "An Ally Saved",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Get Me Out of Here!",
		["zone"] = "Desolace",
		["max_lvl"] = 38,
		["quest_id"] = 6132,
	},
	{
		["name"] = "RitesOfTheEarthmother",
		["title"] = "Arra'chea goes down",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Rites of the Earthmother",
		["zone"] = "Mulgore",
		["max_lvl"] = 11,
		["quest_id"] = 776,
	},
	{
		["name"] = "KimjaelIndeed",
		["title"] = "Kim'Jael's Equipment Found",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Kim'Jael Indeed!",
		["zone"] = "Azshara",
		["max_lvl"] = 47,
		["quest_id"] = 3601,
	},
	{
		["name"] = "Counterattack",
		["title"] = "Finishing of the Kolkar",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Counterattack!",
		["zone"] = "The Barrens",
		["max_lvl"] = 19,
		["quest_id"] = 4021,
	},
	{
		["name"] = "StinkysEscape",
		["title"] = "Stinky's Escape",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Stinky's Escape",
		["zone"] = "Dustwallow Marsh Quest",
		["max_lvl"] = 34,
		["quest_id"] = 1270,
	},
	{
		["name"] = "DarkHeart",
		["title"] = "Edana the Evil Harpy",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Dark Heart",
		["zone"] = "Feralas",
		["max_lvl"] = 48,
		["quest_id"] = 3062,
	},
	{
		["name"] = "TestOfEndurance",
		["title"] = "Army of the Harpies",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Test of Endurance",
		["zone"] = "Thousand Needles",
		["max_lvl"] = 30,
		["quest_id"] = 1150,
	},
	{
		["name"] = "CuergosGold",
		["title"] = "The Hidden Treasure",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Cuergo's Gold",
		["zone"] = "Tanaris",
		["max_lvl"] = 43,
		["quest_id"] = 2882,
	},
	{
		["name"] = "TheStonesThatBindUs",
		["title"] = "Not So Invincible",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "The Stones That Bind Us",
		["zone"] = "Blasted Lands",
		["max_lvl"] = 53,
		["quest_id"] = 2681,
	},
	{
		["name"] = "GalensEscape",
		["title"] = "Galen's Escape",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Galen's Escape",
		["zone"] = "Swamp of Sorrows",
		["max_lvl"] = 36,
		["quest_id"] = 1393,
	},
	{
		["name"] = "Kromgrul",
		["title"] = "Taking Back the Ring",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Krom'Grul",
		["zone"] = "Burning Steppes",
		["max_lvl"] = 50,
		["quest_id"] = 3822,
	},
	{
		["name"] = "TheCrownOfWill",
		["title"] = "The Crown of Will",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "The Crown of Will",
		["zone"] = "Alterac Mountains",
		["max_lvl"] = 44,
		["quest_id"] = 521,
	},
	{
		["name"] = "BattleOfHillsbrad",
		["title"] = "Battle of Hillsbrad",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Battle of Hillsbrad",
		["zone"] = "Hillsbrad Foothills",
		["max_lvl"] = 33,
		["quest_id"] = 550,
	},
	{
		["name"] = "TheWeaver",
		["title"] = "Dalaran Archmage Goes Down!",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "The Weaver",
		["zone"] = "Silverpine Forest",
		["max_lvl"] = 20,
		["quest_id"] = 480,
	},
	{
		["name"] = "TheFamilyCrypt",
		["title"] = "Captain Dargol Goes Back to the Grave",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "The Family Crypt",
		["zone"] = "Tirisfal Glades",
		["max_lvl"] = 11,
		["quest_id"] = 408,
	},
	{
		["name"] = "BurningShadows",
		["title"] = "Burning Shadows",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Burning Shadows",
		["zone"] = "Durotar",
		["max_lvl"] = 11,
		["quest_id"] = 832,
	},
	{
		["name"] = "RecoverTheKey",
		["title"] = "The Key has been Recovered",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Recover the Key",
		["zone"] = "Hinterlands",
		["max_lvl"] = 55,
		["quest_id"] = 7846,
	},
	{
		["name"] = "Isha Awak",
		["title"] = "Isha Awak",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Isha Awak",
		["zone"] = "The Barrens",
		["max_lvl"] = 23,
		["quest_id"] = 873,
	},
	{
		["name"] = "Serena Bloodfeather",
		["title"] = "Serena Bloodfeather",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Serena Bloodfeather",
		["zone"] = "The Barrens",
		["max_lvl"] = 17,
		["quest_id"] = 876,
	},
	{
		["name"] = "Free From the Hold",
		["title"] = "Free From the Hold",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Free From the Hold",
		["zone"] = "The Barrens",
		["max_lvl"] = 15,
		["quest_id"] = 898,
	},
	{
		["name"] = "The Tear of the Moons",
		["title"] = "The Tear of the Moons",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "The Tear of the Moons",
		["zone"] = "The Barrens",
		["max_lvl"] = 27,
		["quest_id"] = 857,
	},
	{
		["name"] = "Voodoo Dues",
		["title"] = "Voodoo Dues",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Voodoo Dues",
		["zone"] = "Stranglethorn Vale",
		["max_lvl"] = 40,
		["quest_id"] = 609,
	},
	{
		["name"] = "Challenge Overlord Mok'Morokk",
		["title"] = "Challenge Overlord Mok'Morokk",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "Challenge Overlord Mok'Morokk",
		["zone"] = "Dustwallow Marsh",
		["max_lvl"] = 46,
		["quest_id"] = 1173,
	},
	{
		["name"] = "The Ranger Lord's Behest",
		["title"] = "The Ranger Lord's Behest",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["quest_name"] = "The Ranger Lord's Behest",
		["zone"] = "Eastern Plaguelands",
		["max_lvl"] = 57,
		["quest_id"] = 6133,
	},
	{
		["name"] = "Master Angler2",
		["title"] = "Master Angler",
		["quest_name"] = "Master Angler",
		["zone"] = "Stranglethorn Vale",
		["quest_id"] = 8193,
		["max_lvl"] = 60,
	},
}

ns.all_quests_menu_order = {}
for k, v in
	spairs(quest_metadata, function(t, a, b)
		return t[a].max_lvl < t[b].max_lvl
	end)
do
	ns.all_quests_menu_order[#ns.all_quests_menu_order + 1] = quest_metadata[k].name
end

local function loadQuestEvent(_metadata)
	local _event = CreateFrame("Frame")
	ns.event[_metadata["name"]] = _event

	-- General info
	_event.name = _metadata.name
	_event.zone = _metadata.zone
	_event.quest_name = _metadata.quest_name
	_event.type = "Achievement"
	_event.title = _metadata.title
	_event.icon_path = _metadata.icon_path
	_event.test_only = _metadata.test_only
	_event.quest_id = _metadata.quest_id
	_event.pts = 3
	_event.subtype = "Quest"
	_event.max_lvl = _metadata.max_lvl
	_event.description = "|cffddddddComplete |r|cffFFA500["
		.. _event.quest_name
		.. "]|r |cffddddddat or before lvl. "
		.. _event.max_lvl
		.. ".|r"

	-- Aggregation
	_event.aggregrate = function(distributed_log, event_log)
		local race_name = ns.id_race[event_log[2]]
		distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
	end

	-- Registers
	_event:RegisterEvent("QUEST_TURNED_IN")

	-- Register Definitions
	local sent = false
	_event:SetScript("OnEvent", function(self, e, _args)
		if sent == true then
			return
		end
		if e == "QUEST_TURNED_IN" then
			if
				_args ~= nil
				and UnitInParty("player") == false
				and tonumber(_args) == _event.quest_id
				and (
					UnitLevel("player") <= _event.max_lvl
					or (ns.recent_level_up ~= nil and UnitLevel("player") <= _event.max_lvl + 1)
				)
			then
				ns.triggerEvent(_event.name)
				sent = true
			end
		end
	end)
end

for _, v in ipairs(quest_metadata) do
	loadQuestEvent(v)
end
