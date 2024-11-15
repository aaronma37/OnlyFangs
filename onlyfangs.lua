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
local full_load = nil

local player_name = UnitName("Player")

local onlyfangs_minimap_button_stub = nil
local onlyfangs_minimap_button_info = {}
local onlyfangs_minimap_button = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
	type = "data source",
	text = addonName,
	icon = "Interface\\FriendsFrame\\PlusManz-Horde.PNG",
	OnClick = function(self, btn)
		if btn == "LeftButton" then
			ns.showMenu()
		else
			InterfaceAddOnsList_Update()
			InterfaceOptionsFrame_OpenToCategory(addonName)
		end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:AddLine(addonName)
		tooltip:AddLine(Deathlog_L.minimap_btn_left_click)
		tooltip:AddLine(Deathlog_L.minimap_btn_right_click .. GAMEOPTIONS_MENU)
		tooltip:AddLine("Score:")
		tooltip:AddDoubleLine("Orc:", ns.getScore("Orc"), 1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Troll:", ns.getScore("Troll"), 1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Tauren:", ns.getScore("Tauren"), 1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Undead:", ns.getScore("Undead"), 1, 1, 1, 1, 1, 1)
	end,
})
local function initMinimapButton()
	onlyfangs_minimap_button_stub = LibStub("LibDBIcon-1.0", true)
	if onlyfangs_minimap_button_stub:IsRegistered("OnlyFangs") then
		return
	end
	onlyfangs_minimap_button_stub:Register("OnlyFangs", onlyfangs_minimap_button, onlyfangs_minimap_button_info)
end

local function handleEvent(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		initMinimapButton()
		C_ChatInfo.RegisterAddonMessagePrefix("OnlyFangsAddon")
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
		OnlyFangsDistributedLog = OnlyFangsDistributedLog or {}
		ns.distributed_log = OnlyFangsDistributedLog
		ns.loadDistributedLog()
		-- ns.fakeEntries()
	elseif event == "UNIT_INVENTORY_CHANGED" then -- CUSTOM EVENT
		if full_load then
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
		end
	elseif event == "PLAYER_TARGET_CHANGED" then
		local _t_name, _ = UnitName("target")
		local _t_guid = UnitGUID("target")
		if _t_name ~= nil then
			creature_guid_map[_t_guid] = _t_name
		end
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		-- local time, token, hidding, source_serial, source_name, caster_flags, caster_flags2, target_serial, target_name, target_flags, target_flags2, ability_id, ability_name, ability_type, extraSpellID, extraSpellName, extraSchool = CombatLogGetCurrentEventInfo()
		local _, ev, ok, _, source_name, _, target_name, target_guid, _, cc, _, environmental_type, overkill_swing, _, _, overkill_range, _ =
			CombatLogGetCurrentEventInfo()
		-- print(ev, source_name, cc, target_guid)

		if source_name ~= player_name and target_guid == player_guid then
			if not (source_name == nil) then
				if string.find(ev, "DAMAGE") ~= nil then
					ns.last_attack_source = source_name
				end
			end
		elseif ev == "SWING_DAMAGE" then
			if
				overkill_swing > -1
				and player_name == source_name
				and creature_guid_map[target_guid]
				and ns.kill_target_exec[creature_guid_map[target_guid]]
			then
				ns.kill_target_exec[creature_guid_map[target_guid]]()
			end
		elseif ev == "RANGE_DAMAGE" or ev == "SPELL_DAMAGE" or ev == "SPELL_PERIODIC_DAMAGE" then
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
		end
	elseif event == "GUILD_ROSTER_UPDATE" then
		if full_load == nil then
			OnlyFangsDistributedLog = OnlyFangsDistributedLog or {}
			ns.distributed_log = OnlyFangsDistributedLog
			ns.loadDistributedLog()
			full_load = true
		end
		local arg = { ... }
		-- Create a new dictionary of just online people every time roster is updated
		ns.guild_online = {}
		local numTotal, numOnline, numOnlineAndMobile = GetNumGuildMembers()
		for i = 1, numTotal, 1 do
			local name, rankName, rankIndex, level, classDisplayName, zone, _public_note, _officer_note, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID =
				GetGuildRosterInfo(i)

			-- For testing
			-- if name == "Yazpad-DefiasPillager" then
			-- 	_officer_note = "~Yazpad~ Some other Stuff"
			-- end
			if OnlyFangsStreamerMap[name] == nil or ns.streamer_map[name] == nil then
				-- local _, streamer_name = string.split(STREAMER_TAG_DELIM, "~Yazpad~ Some other Stuff")
				local _, streamer_name = string.split(STREAMER_TAG_DELIM, _officer_note)
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

LibStub("AceConfig-3.0"):RegisterOptionsTable("OnlyFangs", options)
optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("OnlyFangs", "OnlyFangs", nil)

-- testing

if ns.enable_testing == true then
	ns.checkEvents()
end
