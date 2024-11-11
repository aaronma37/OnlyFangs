local addonName, ns = ...
ns.item_id_obs = {}
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

passive_achievement_kill_handler = CreateFrame("Frame")
passive_achievement_kill_handler:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")

local registered_kill_event_achievements = {}
function passive_achievement_kill_handler:RegisterKillEvent(achievement_name)
	if ns.passive_achievements[achievement_name] then
		registered_kill_event_achievements[achievement_name] = ns.passive_achievements[achievement_name]
	end
end

passive_achievement_kill_handler:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "CHAT_MSG_COMBAT_XP_GAIN" then
		local combat_log_payload = { CombatLogGetCurrentEventInfo() }
		local v = arg[1]:match("(.+) dies")
		if kill_list_dict[v] then
			if HardcoreUnlocked_Character then
				if HardcoreUnlocked_Character.kill_list_dict == nil then
					HardcoreUnlocked_Character.kill_list_dict = {}
				end

				if HardcoreUnlocked_Character.kill_list_dict[v] == nil then
					if ns.passive_achievements[kill_list_dict[v]] then
						Hardcore:Print(
							"["
								.. ns.passive_achievements[kill_list_dict[v]].title
								.. "] You have slain "
								.. v
								.. "!  Remember to /reload when convenient to save your progress."
						)
					end
					for _, registered_kill_event_achievement in pairs(registered_kill_event_achievements) do
						registered_kill_event_achievement:HandleKillEvent(v, HardcoreUnlocked_Character)
					end
				end
				HardcoreUnlocked_Character.kill_list_dict[v] = 1
			end
		end
	end
end)

function OnlyFangsCommonPassiveAchievementAltBasicQuestCheck(_achievement, _event, _args)
	if _event == "QUEST_TURNED_IN" then
		if
			_args[1] ~= nil
			and (_args[1] == _achievement.quest_num or _args[1] == _achievement.quest_num_alt)
			and (
				UnitLevel("player") <= _achievement.level_cap
				or (hc_recent_level_up and UnitLevel("player") <= _achievement.level_cap + 1)
			)
		then
			_achievement.succeed_function_executor.Succeed(_achievement.name)
		end
	end
end

function OnlyFangsCommonPassiveAchievementBasicQuestCheck(_achievement, _event, _args)
	if _event == "QUEST_TURNED_IN" then
		if
			_args[1] == _achievement.quest_num
			and (
				UnitLevel("player") <= _achievement.level_cap
				or (hc_recent_level_up and UnitLevel("player") <= _achievement.level_cap + 1)
			)
		then
			_achievement.succeed_function_executor.Succeed(_achievement.name)
		end
	end
end

function OnlyFangsCommonPassiveAchievementKillCheck(_achievement, _event, _args)
	if _event == "QUEST_TURNED_IN" then
		if
			_args[1] == _achievement.quest_num
			and (
				UnitLevel("player") <= _achievement.level_cap
				or (hc_recent_level_up and UnitLevel("player") <= _achievement.level_cap + 1)
			)
		then
			if
				HardcoreUnlocked_Character.kill_list_dict ~= nil
				and HardcoreUnlocked_Character.kill_list_dict[_achievement.kill_target]
			then
				_achievement.succeed_function_executor.Succeed(_achievement.name)
			else
				Hardcore:Print(
					"["
						.. _achievement.title
						.. "] You have completed the "
						.. _achievement.quest_name
						.. " quest, but "
						.. _achievement.kill_target
						.. " was not slain!"
				)
			end
		end
	end
end

function OnlyFangsCommonPassiveAchievementItemAcquiredCheck(_achievement, _event, _args)
	if _achievement.item == nil then
		Hardcore:Print("Achievement doesn't have a specified item")
	end
	if _event == "CHAT_MSG_LOOT" then
		if string.match(_args[1], _achievement.item) and UnitLevel("player") <= _achievement.level_cap then
			_achievement.succeed_function_executor.Succeed(_achievement.name)
		end
	end
end

function OnlyFangsCommonPassiveAchievementCraftedCheck(_achievement, _event, _args)
	if _achievement.craft_set == nil then
		Hardcore:Print("Achievement doesn't have a specified item")
	end
	if _event == "CHAT_MSG_LOOT" then
		for k, _ in pairs(_achievement.craft_set) do
			if
				string.match(_args[1], k)
				and string.match(_args[1], "You create")
				and UnitLevel("player") <= _achievement.level_cap
			then
				if HardcoreUnlocked_Character then
					if HardcoreUnlocked_Character.crafted_list_dict == nil then
						HardcoreUnlocked_Character.crafted_list_dict = {}
					end

					HardcoreUnlocked_Character.crafted_list_dict[k] = 1
					for craft_item, _ in pairs(_achievement.craft_set) do
						if HardcoreUnlocked_Character.crafted_list_dict[craft_item] == nil then
							Hardcore:Print(
								"["
									.. _achievement.title
									.. "] You have crafted "
									.. k
									.. "!  Remember to /reload when convenient to save your progress."
							)
							return
						end
					end
					_achievement.succeed_function_executor.Succeed(_achievement.name)
				end
			end
		end
	end
end

function OnlyFangsCommonPassiveAchievementProfLevelCheck(_achievement, _event, _args)
	if _achievement.level_cap and UnitLevel("player") > _achievement.level_cap then
		return
	end
	if _event == "SKILL_LINES_CHANGED" or _event == "PLAYER_ENTERING_WORLD" then
		for i = 1, GetNumSkillLines() do
			local arg, _, _, lvl = GetSkillLineInfo(i)
			if arg == _achievement.profession_name then
				if lvl >= _achievement.profession_threshold then
					_achievement.succeed_function_executor.Succeed(_achievement.name)
				end
			end
		end
	end
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

ns.triggerEvent = function(event_name)
	ns.showToast(event_name, ns.event[event_name].icon_path, ns.event[event_name].type)
	ns.sendEvent(event_name)
end
