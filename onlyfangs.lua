--[[
Copyright 2023 Yazpad
The Deathlog AddOn is distributed under the terms of the GNU General Public License (or the Lesser GPL).
This file is part of Deathlog.

The Deathlog AddOn is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The Deathlog AddOn is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the Deathlog AddOn. If not, see <http://www.gnu.org/licenses/>.
--]]
local addonName, ns = ...

-- Entry: (event_id, player, time, faction)
ns.recent_level_up = nil -- KEEP GLOBAL
ns.current_profession_levels = {}
OnlyFangsStreamerMap = OnlyFangsStreamerMap or {}
ns.streamer_map = {}
local last_attack_source = nil
local recent_msg = nil
local creature_guid_map = {}
local player_guid = UnitGUID("player")
local STREAMER_TAG_DELIM = "~"
local guild_loaded = false

local REALM_NAME = GetRealmName()
REALM_NAME = REALM_NAME:gsub("%s+", "")

local player_name = UnitName("Player")

local player_name_with_realm_name = player_name .. "-" .. REALM_NAME

local onlyfangs_minimap_button_stub = nil
local onlyfangs_minimap_button_info = {}
local onlyfangs_minimap_button = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
	type = "data source",
	text = addonName,
	icon = "Interface\\FriendsFrame\\PlusManz-Horde.PNG",
	OnClick = function(self, btn)
		if btn == "LeftButton" then
			ns.showMenu()
		end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:AddLine(addonName)
		tooltip:AddLine(OnlyFangs_L.minimap_btn_left_click)

		local orc_all_time, orc_last_week, orc_this_week = ns.getScore("Orc")
		local troll_all_time, troll_last_week, troll_this_week = ns.getScore("Troll")
		local tauren_all_time, tauren_last_week, tauren_this_week = ns.getScore("Tauren")
		local undead_all_time, undead_last_week, undead_this_week = ns.getScore("Undead")

		if ns.modifiers then
			orc_this_week = math.floor(orc_this_week * (ns.modifiers["Orc"] or 1))
			troll_this_week = math.floor(troll_this_week * (ns.modifiers["Troll"] or 1))
			tauren_this_week = math.floor(tauren_this_week * (ns.modifiers["Tauren"] or 1))
			undead_this_week = math.floor(undead_this_week * (ns.modifiers["Undead"] or 1))
		end

		tooltip:AddLine("All Time Score:")
		tooltip:AddDoubleLine("Orc:", orc_all_time, 1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Troll:", troll_all_time, 1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Tauren:", tauren_all_time, 1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Undead:", undead_all_time, 1, 1, 1, 1, 1, 1)

		tooltip:AddLine("Last Week's Score:")
		tooltip:AddDoubleLine("Orc:", orc_last_week, 1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Troll:", troll_last_week, 1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Tauren:", tauren_last_week, 1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Undead:", undead_last_week, 1, 1, 1, 1, 1, 1)

		tooltip:AddLine("This Week's Score:")
		tooltip:AddDoubleLine("Orc:", orc_this_week, 1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Troll:", troll_this_week, 1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Tauren:", tauren_this_week, 1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Undead:", undead_this_week, 1, 1, 1, 1, 1, 1)
	end,
})
local function initMinimapButton()
	onlyfangs_minimap_button_stub = LibStub("LibDBIcon-1.0", true)
	if onlyfangs_minimap_button_stub:IsRegistered("OnlyFangs") then
		return
	end
	onlyfangs_minimap_button_stub:Register("OnlyFangs", onlyfangs_minimap_button, onlyfangs_minimap_button_info)
	onlyfangs_minimap_button_stub:SetButtonToPosition("OnlyFangs", 190)
end

ns.refreshGuildList = function(force_refresh)
	if CanEditOfficerNote() then
		OnlyMonitorOn = true
	end
	local guild_info_text = GetGuildInfoText()
	if guild_info_text then
		local _, _this_week_start, _ = string.split("~", guild_info_text)
		if _this_week_start and tonumber(_this_week_start) then
			OnlyFangsWeekStart = tonumber(_this_week_start)
		end

		local _, _winners, _losers, _modifiers = string.split("$", guild_info_text)
		ns.past_winners = {}
		ns.past_losers = {}
		ns.modifiers = {}
		if _winners then
			for value in string.gmatch(_winners, "([^,]+)") do
				ns.past_winners[#ns.past_winners + 1] = value
			end
		end

		if _losers then
			for value in string.gmatch(_losers, "([^,]+)") do
				ns.past_losers[#ns.past_losers + 1] = value
			end
		end

		if _modifiers then
			for value in string.gmatch(_modifiers, "([^,]+)") do
				local _race, modifier = string.split(":", value)
				ns.modifiers[_race] = tonumber(modifier)
			end
		end
	end
	-- Create a new dictionary of just online people every time roster is updated
	ns.guild_online = {}
	ns.character_race_type = {}
	local numTotal, numOnline, numOnlineAndMobile = GetNumGuildMembers()
	ns.num_guild_online = numOnline
	OnlyFangsRaceMap = {}
	for i = 1, numTotal, 1 do
		local name, rankName, rankIndex, level, classDisplayName, zone, _public_note, _officer_note, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID =
			GetGuildRosterInfo(i)

		if name == player_name_with_realm_name then
			if rankName == "Orc" and OnlyFangsOverrideRace ~= "Orc" then
				OnlyFangsOverrideRace = "Orc"
				print("Onlyfangs: Joining team Orc")
			elseif rankName == "Troll" and OnlyFangsOverrideRace ~= "Troll" then
				OnlyFangsOverrideRace = "Troll"
				print("Onlyfangs: Joining team Troll")
			elseif rankName == "Tauren" and OnlyFangsOverrideRace ~= "Tauren" then
				OnlyFangsOverrideRace = "Tauren"
				print("Onlyfangs: Joining team Tauren")
			elseif rankName == "Undead" and OnlyFangsOverrideRace ~= "Undead" then
				OnlyFangsOverrideRace = "Undead"
				print("Onlyfangs: Joining team Undead")
			end
		end
		if ns.race_id[rankName] then
			ns.character_race_type[name] = rankName
			OnlyFangsRaceMap[name] = rankName
		end

		-- For testing
		-- if name == "Jaytullobald-DefiasPillager" then
		-- 	_public_note = "~Jay~ Some other Stuff"
		-- end
		-- ns.streamer_map["Jaytullobald-DefiasPillager"] = "Jay"
		-- ns.streamer_map["Yazpadc-DefiasPillager"] = "Yazpad"
		-- ns.streamer_map["Tthetester-DefiasPillager"] = "testtest"
		-- ns.streamer_map["Dadreamland-DefiasPillager"] = "ream"
		-- ns.streamer_map["Testnut-DefiasPillager"] = "nut"
		if OnlyFangsStreamerMap[name] == nil or ns.streamer_map[name] == nil or force_refresh then
			-- local _, streamer_name = string.split(STREAMER_TAG_DELIM, "~Yazpad~ Some other Stuff")
			local _, streamer_name = string.split(STREAMER_TAG_DELIM, _public_note)
			if streamer_name then
				streamer_name = string.lower(streamer_name)
				streamer_name = streamer_name:gsub("^%l", string.upper)
			end
			OnlyFangsStreamerMap[name] = streamer_name
			ns.streamer_map[name] = streamer_name
		end

		-- name is nil after a gquit, so nil check here
		if name and isOnline then
			ns.guild_online[name] = {
				name = name,
				level = level,
				classDisplayName = classDisplayName,
			}
		end
	end
	if force_refresh then
		for k, v in pairs(OnlyFangsStreamerMap) do
			OnlyFangsStreamerMap[k] = string.lower(v):gsub("^%l", string.upper)
		end
	end
end

local function handleEvent(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		initMinimapButton()
		if not C_ChatInfo.IsAddonMessagePrefixRegistered("OnlyFangsAddon") then
			C_ChatInfo.RegisterAddonMessagePrefix("OnlyFangsAddon")
		end
	elseif event == "PLAYER_LEVEL_UP" then
		ns.recent_level_up = 1
		C_Timer.After(3, function()
			ns.recent_level_up = nil
		end)

		for i = 1, GetNumSkillLines() do
			local arg, _, _, lvl = GetSkillLineInfo(i)
			ns.current_profession_levels[arg] = lvl
		end
	elseif event == "ADDON_LOADED" then
		local addon_name = ...
		OnlyFangsDistributedLog = OnlyFangsDistributedLog or {}
		ns.distributed_log = OnlyFangsDistributedLog

		OnlyFangsKeyList = OnlyFangsKeyList or {}
		ns.key_list = OnlyFangsKeyList

		ns.loadDistributedLog()
		if OnlyFangsRaceInChat and OnlyFangsRaceInChat == 1 then
			ns.loadRaceInChat()
		end
		if OnlyFangsStreamerNameInChat and OnlyFangsStreamerNameInChat == 1 then
			ns.loadStreamerNameInChat()
		end
	elseif event == "UNIT_INVENTORY_CHANGED" then -- CUSTOM EVENT
		for bag = 0, 5 do
			for slot = 0, 16 do
				local item_id = C_Container.GetContainerItemID(bag, slot)
				if ns.item_id_obs[item_id] ~= nil then
					ns.item_id_obs[item_id]()
				end
				if ns.item_id_epic_obs[item_id] ~= nil then
					ns.item_id_epic_obs[item_id]()
				end
				if item_id ~= nil then
					-- 0: gray, 1: white, 2: green, 3: blue, 4: epic
					-- local item_name, _, _rarity, _, _, _, _, _, _, _, _ = GetItemInfo(item_id)
					-- print(item_name, _rarity)
				end
			end
		end
	elseif event == "PLAYER_TARGET_CHANGED" then
		local _t_name, _ = UnitName("target")
		local _t_guid = UnitGUID("target")
		if _t_name ~= nil then
			creature_guid_map[_t_guid] = _t_name
		end
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		-- local time, token, hidding, source_serial, source_name, caster_flags, caster_flags2, target_serial, target_name, target_flags, target_flags2, ability_id, ability_name, ability_type, extraSpellID, extraSpellName, extraSchool = CombatLogGetCurrentEventInfo()
		local _, ev, ok, _, source_name, _, target_name, target_guid, enemy_name, cc, _, environmental_type, overkill_swing, _, range_dmg, overkill_range, _, swing_crit, _, _, range_crit =
			CombatLogGetCurrentEventInfo()
		-- print(ev, source_name, cc, target_guid)

		if source_name ~= player_name and target_guid == player_guid then
			if not (source_name == nil) then
				if string.find(ev, "DAMAGE") ~= nil then
					ns.last_attack_source = source_name
				end
			end
		elseif ev == "SWING_DAMAGE" then
			if player_name == source_name then
				if tonumber(environmental_type) == 1337 and swing_crit == true then
					ns.triggerLeet()
				end
			end
			if
				overkill_swing > -1
				and player_name == source_name
				and creature_guid_map[target_guid]
				and ns.kill_target_exec[creature_guid_map[target_guid]]
			then
				ns.kill_target_exec[creature_guid_map[target_guid]]()
			end
		elseif ev == "RANGE_DAMAGE" or ev == "SPELL_DAMAGE" or ev == "SPELL_PERIODIC_DAMAGE" then
			if player_name == source_name then
				if tonumber(range_dmg) == 1337 and range_crit == true then
					ns.triggerLeet()
				end
			end
			if
				overkill_range > -1
				and player_name == source_name
				and creature_guid_map[target_guid]
				and ns.kill_target_exec[creature_guid_map[target_guid]]
			then
				ns.kill_target_exec[creature_guid_map[target_guid]]()
			end
		end
		if ev == "ENVIRONMENTAL_DAMAGE" then
			if target_guid == UnitGUID("player") then
				if environmental_type == "Drowning" then
					ns.last_attack_source = -2
				elseif environmental_type == "Falling" then
					ns.last_attack_source = -3
				elseif environmental_type == "Fatigue" then
					ns.last_attack_source = -4
				elseif environmental_type == "Fire" then
					ns.last_attack_source = -5
				elseif environmental_type == "Lava" then
					ns.last_attack_source = -6
				elseif environmental_type == "Slime" then
					ns.last_attack_source = -7
				end
			end
		elseif ev == "UNIT_DIED" then
			if ns.unit_died_exec[enemy_name] then
				ns.unit_died_exec[enemy_name]()
			end
		end
	elseif event == "GUILD_ROSTER_UPDATE" then
		ns.refreshGuildList(false)
		if guild_loaded == false then
			local guild_name, _, _ = GetGuildInfo("Player")
			if guild_name ~= nil then
				OnlyFangsDistributedLog = OnlyFangsDistributedLog or {}
				ns.distributed_log = OnlyFangsDistributedLog

				OnlyFangsKeyList = OnlyFangsKeyList or {}
				ns.key_list = OnlyFangsKeyList

				ns.loadDistributedLog()
				guild_loaded = true
			end
		end
	end
end

local deathlog_event_handler = CreateFrame("Frame", "OnlyFangs", nil, "BackdropTemplate")
deathlog_event_handler:RegisterEvent("PLAYER_ENTERING_WORLD")
deathlog_event_handler:RegisterEvent("PLAYER_LEVEL_UP")
deathlog_event_handler:RegisterEvent("ADDON_LOADED")
deathlog_event_handler:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
deathlog_event_handler:RegisterEvent("UNIT_INVENTORY_CHANGED")
deathlog_event_handler:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
deathlog_event_handler:RegisterEvent("PLAYER_TARGET_CHANGED")
deathlog_event_handler:RegisterEvent("GUILD_ROSTER_UPDATE")

deathlog_event_handler:SetScript("OnEvent", handleEvent)

local LSM30 = LibStub("LibSharedMedia-3.0", true)
local options = {
	name = "OnlyFangs",
	handler = OnlyFangs,
	type = "group",
	args = {},
}

local function SlashHandler(msg, editbox)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
	if cmd == "raceInChat" then
		local opt = ""
		for substring in args:gmatch("%S+") do
			opt = substring
		end
		if opt == "1" then
			OnlyFangsRaceInChat = 1
			ns.loadRaceInChat()
		else
			OnlyFangsRaceInChat = nil
			print("Reload to remove race image in chat")
		end
	elseif cmd == nil then
		ns.showMenu()
	elseif cmd == "settings" then
		Settings.OpenToCategory(addonName)
	elseif cmd == "streamerNameInChat" then
		local opt = ""
		for substring in args:gmatch("%S+") do
			opt = substring
		end
		if opt == "1" then
			OnlyFangsStreamerNameInChat = 1
			ns.loadStreamerNameInChat()
		else
			OnlyFangsStreamerNameInChat = nil
			print("Reload to remove streamer names in chat")
		end
	elseif cmd == "raceInWishList" then
		local opt = ""
		for substring in args:gmatch("%S+") do
			opt = substring
		end
		if opt == "1" then
			OnlyFangsRaceInWishList = 1
			-- print("Reload to see ")
		else
			OnlyFangsRaceInWishList = nil
			-- print("Reload to remove streamer names in chat")
		end
	elseif cmd == "achievementAlertChatFrame" then
		local opt = ""
		for substring in args:gmatch("%S+") do
			OnlyFangsPrintChatFrame = tonumber(substring)
		end
		ns.printToChatFrame("OnlyFangs Achievements alerts will be printed to this frame.")
	end
end

SLASH_ONLYFANGS1 = "/onlyfangs"
SLASH_ONLYFANGS2 = "/of"
SlashCmdList["ONLYFANGS"] = SlashHandler

local options = {
	name = addonName,
	handler = OnlyFangsOptionHandler,
	type = "group",
	args = {
		race_icon_in_chat = {
			type = "toggle",
			name = "Race Icon in Chat",
			desc = "Toggles whether race icons show up in chat.",
			width = 1.3,
			get = function()
				if OnlyFangsRaceInChat == nil or OnlyFangsRaceInChat == false then
					OnlyFangsRaceInChat = false
				end
				if OnlyFangsRaceInChat == 1 then
					return true
				else
					return false
				end
			end,
			set = function()
				if OnlyFangsRaceInChat == nil or OnlyFangsRaceInChat == false then
					OnlyFangsRaceInChat = 1
					ns.loadRaceInChat()
				else
					OnlyFangsRaceInChat = nil
				end
			end,
		},
		race_icon_in_wishlist = {
			type = "toggle",
			name = "Race Icon in Wishlist Menu and Tooltip",
			desc = "Toggles whether race icons show up in wishlist menu and tooltip.",
			width = 1.3,
			get = function()
				if OnlyFangsRaceInWishList == nil or OnlyFangsRaceInWishList == false then
					OnlyFangsRaceInWishList = false
				end
				if OnlyFangsRaceInWishList == 1 then
					return true
				else
					return false
				end
			end,
			set = function()
				if OnlyFangsRaceInWishList == nil or OnlyFangsRaceInWishList == false then
					OnlyFangsRaceInWishList = 1
				else
					OnlyFangsRaceInWishList = nil
				end
			end,
		},
	},
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("OnlyFangs", options)
optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("OnlyFangs", "OnlyFangs", nil)

-- testing

if ns.enable_testing == true then
	ns.checkEvents()
end
