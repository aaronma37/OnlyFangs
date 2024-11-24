local addonName, ns = ...

local CTL = _G.ChatThrottleLib
local COMM_NAME = "OnlyFangsAddon"
local COMM_COMMAND_HEARTBEAT = "HB"
local COMM_COMMAND_DIRECT_EVENT = "DE"
local COMM_COMMAND_DELIM = "|"
local COMM_FIELD_DELIM = "~"
local COMM_SUBFIELD_DELIM = "&"
local COMM_CHANNEL = "GUILD"
local HB_DUR = 5
local HB_DUR_MAX = 60
local ERASE_CACHE = false
local DEBUG = false
-- Node
local VALUE_IDX = 1
local KEY_IDX = 4
-- Value
local DATE_IDX = 1
local RACE_IDX = 2
local EVENT_IDX = 3
local CLASS_IDX = 4
local ADD_ARGS_IDX = 5

local INIT_TIME = 1730639674
local WEEK_SECONDS = 604800
local LAUNCH_DATE = 1732186800 - WEEK_SECONDS

local DAY_SECONDS = 86400

local function getThisWeekPeriodStart()
	local this_week_start_time = OnlyFangsWeekStart or LAUNCH_DATE
	return tonumber(this_week_start_time), tonumber(this_week_start_time - WEEK_SECONDS)
end

local REALM_NAME = GetRealmName()
REALM_NAME = REALM_NAME:gsub("%s+", "")

local player_guid = UnitGUID("player")
local player_guid_last_four = string.sub(player_guid, -4)
local player_name = UnitName("player")
local this_player_guid_tag = player_name .. "-" .. player_guid_last_four
ns.already_achieved = {}
ns.streamer_to_race = {}

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

local function adjustedTime()
	return GetServerTime() - INIT_TIME
end
local function fromAdjustedTime(t)
	return t + INIT_TIME
end

local top_players_daily = {}
local top_players_weekly = {}
local top_players_all_time = {}

ns.getTopPlayers = function()
	local top_daily_list = {}
	local top_weekly_list = {}
	local top_all_time_list = {}

	-- Ordered
	for k, v in
		spairs(top_players_daily, function(t, a, b)
			return t[a].pts > t[b].pts
		end)
	do
		top_daily_list[#top_daily_list + 1] = { ["streamer_name"] = k, ["pts"] = v.pts }
	end

	for k, v in
		spairs(top_players_weekly, function(t, a, b)
			return t[a].pts > t[b].pts
		end)
	do
		top_weekly_list[#top_weekly_list + 1] = { ["streamer_name"] = k, ["pts"] = v.pts }
	end

	for k, v in
		spairs(top_players_all_time, function(t, a, b)
			return t[a].pts > t[b].pts
		end)
	do
		top_all_time_list[#top_all_time_list + 1] = { ["streamer_name"] = k, ["pts"] = v.pts }
	end

	return top_daily_list, top_weekly_list, top_all_time_list
end

local estimated_score_num_entries = 0
local estimated_score = {
	["Orc"] = 0,
	["Undead"] = 0,
	["Tauren"] = 0,
	["Troll"] = 0,
}
local last_week_estimated_score = {
	["Orc"] = 0,
	["Undead"] = 0,
	["Tauren"] = 0,
	["Troll"] = 0,
}
local this_week_estimated_score = {
	["Orc"] = 0,
	["Undead"] = 0,
	["Tauren"] = 0,
	["Troll"] = 0,
}
ns.guild_member_addon_info = {}

local function guildName()
	local guild_name, _, _ = GetGuildInfo("Player")
	local in_guild = (guild_name ~= nil)
	guild_name = guild_name or "guildless"
	guild_name = guild_name .. "-" .. REALM_NAME
	return guild_name, in_guild
end

local distributed_log = nil
local key_list = nil
ns.claimed_milestones = {}

local function updateThisWeeksPoints(_event, event_log)
	if _event and _event.pts and event_log[2] and ns.id_race[event_log[2]] then
		local race_name = ns.id_race[event_log[2]]
		if distributed_log and distributed_log.this_week_points then
			distributed_log.this_week_points[race_name] = distributed_log.this_week_points[race_name] + _event.pts
		end
	end
end

local function refreshClaimedMilestones()
	local guild_name = guildName()
	for k, v in pairs(distributed_log[guild_name]["data"]) do
		local event_name = ns.id_event[v["value"][EVENT_IDX]]
		if event_name then
			local type = ns.event[event_name].type
			if type == "Milestone" then
				if ns.claimed_milestones[event_name] == nil then
					ns.claimed_milestones[event_name] = k
				elseif
					v["value"][DATE_IDX]
					< distributed_log[guild_name]["data"][ns.claimed_milestones[event_name]]["value"][DATE_IDX]
				then
					ns.claimed_milestones[event_name] = k
				end
			end
		end
	end
end

local num_keys = 0
local key_counter = 0

local function checkAndAddKeyList()
	local guild_name = guildName()
	if key_list[guild_name] == nil or (#key_list[guild_name] ~= distributed_log[guild_name]["meta"]["size"]) then
		distributed_log[guild_name]["meta"]["size"] = 0
		key_list[guild_name] = {}
		for k, _ in pairs(distributed_log[guild_name]["data"]) do
			key_list[guild_name][#key_list[guild_name] + 1] = k
			distributed_log[guild_name]["meta"]["size"] = distributed_log[guild_name]["meta"]["size"] + 1
		end
	end
	num_keys = #key_list[guild_name]
end

local function getNextEntry()
	local guild_name = guildName()
	if num_keys < 1 then
		return nil
	end
	local idx = num_keys - key_counter
	key_counter = key_counter + 1
	if key_counter >= num_keys then
		checkAndAddKeyList()
		key_counter = 0
	end
	return key_list[guild_name][idx]
end

ns.loadDistributedLog = function()
	distributed_log = ns.distributed_log
	key_list = ns.key_list
	local guild_name = guildName()

	if ERASE_CACHE then
		distributed_log = {}
		key_list = {}
	end
	if distributed_log[guild_name] == nil then
		distributed_log[guild_name] = { ["meta"] = { ["newest"] = nil, ["oldest"] = nil, ["size"] = 0 }, ["data"] = {} }
	end

	if distributed_log["points"] == nil then
		distributed_log["points"] = {
			["Orc"] = 0,
			["Troll"] = 0,
			["Tauren"] = 0,
			["Undead"] = 0,
			["Human"] = 0,
			["Gnome"] = 0,
			["Night Elf"] = 0,
			["Dwarf"] = 0,
		}
	end
	if distributed_log["last_week_points"] == nil then
		distributed_log["last_week_points"] = {
			["Orc"] = 0,
			["Troll"] = 0,
			["Tauren"] = 0,
			["Undead"] = 0,
			["Human"] = 0,
			["Gnome"] = 0,
			["Night Elf"] = 0,
			["Dwarf"] = 0,
		}
	end
	if distributed_log["this_week_points"] == nil then
		distributed_log["this_week_points"] = {
			["Orc"] = 0,
			["Troll"] = 0,
			["Tauren"] = 0,
			["Undead"] = 0,
			["Human"] = 0,
			["Gnome"] = 0,
			["Night Elf"] = 0,
			["Dwarf"] = 0,
		}
	end
	refreshClaimedMilestones()
	ns.aggregateLog()
	estimated_score_num_entries = distributed_log[guild_name]["meta"]["size"]
	estimated_score = {
		["Orc"] = distributed_log.points["Orc"],
		["Undead"] = distributed_log.points["Undead"],
		["Tauren"] = distributed_log.points["Tauren"],
		["Troll"] = distributed_log.points["Troll"],
	}
	last_week_estimated_score = {
		["Orc"] = distributed_log.last_week_points["Orc"],
		["Undead"] = distributed_log.last_week_points["Undead"],
		["Tauren"] = distributed_log.last_week_points["Tauren"],
		["Troll"] = distributed_log.last_week_points["Troll"],
	}
	this_week_estimated_score = {
		["Orc"] = distributed_log.this_week_points["Orc"],
		["Undead"] = distributed_log.this_week_points["Undead"],
		["Tauren"] = distributed_log.this_week_points["Tauren"],
		["Troll"] = distributed_log.this_week_points["Troll"],
	}
	checkAndAddKeyList()
end

-- got a node that points to itself
local function lruSet(key, v)
	local guild_name = guildName()
	if distributed_log[guild_name]["data"][key] == nil then
		distributed_log[guild_name]["meta"]["size"] = distributed_log[guild_name]["meta"]["size"] + 1
	end

	distributed_log[guild_name]["data"][key] = {
		["value"] = v,
	}
	key_list[guild_name][#key_list[guild_name] + 1] = key
end

-- local num_gets = {}
local function lruGet(key_id)
	local guild_name = guildName()
	if distributed_log[guild_name]["data"][key_id] == nil then
		return nil
	end
	return distributed_log[guild_name]["data"][key_id]
end

ns.eventName = function(event_id)
	return ns.id_event[event_id]
end

ns.stampEvent = function(date, race_id, event_id, class_id)
	local flecher = ns.fletcher16(UnitName("Player"), race_id, event_id, date) .. "-" .. player_guid_last_four
	return flecher, { tonumber(date), tonumber(race_id), tonumber(event_id), tonumber(class_id) }
end

local function toMessage(key, log_event)
	local comm_message = key
		.. COMM_FIELD_DELIM
		.. log_event[DATE_IDX]
		.. COMM_FIELD_DELIM
		.. log_event[RACE_IDX]
		.. COMM_FIELD_DELIM
		.. log_event[EVENT_IDX]
		.. COMM_FIELD_DELIM
		.. log_event[CLASS_IDX]
		.. COMM_FIELD_DELIM
		.. (log_event[ADD_ARGS_IDX] or "")
	return comm_message
end

ns.getScore = function(team_name)
	return estimated_score[team_name], last_week_estimated_score[team_name], this_week_estimated_score[team_name]
end

local function addPointsToLeaderBoardData(_fletcher, _event_name, _event_log, current_adjusted_time, pts)
	local this_week_period_start, last_week_period_start = getThisWeekPeriodStart()
	local _char_name, _, _last_guid = string.split("-", _fletcher)
	if _char_name == player_name and _last_guid ~= nil then
		local _player_tag = _char_name .. "-" .. _last_guid
		if _player_tag == this_player_guid_tag then
			ns.already_achieved[_event_name] = 1
		end
	end
	_char_name = _char_name .. "-" .. REALM_NAME

	local _adjusted_pts = nil
	if _event_log[EVENT_IDX] == 2 then
		_adjusted_pts, _char_name = ns.getAdjustPoints(_event_log)
		_char_name = _char_name:gsub("^%l", string.upper)
		_char_name = _char_name .. "-" .. REALM_NAME
	else
		_adjusted_pts = ns.event[_event_name].pts
	end

	local streamer_name = ns.streamer_map[_char_name] or OnlyFangsStreamerMap[_char_name]

	if streamer_name then
		if top_players_all_time[streamer_name] == nil then
			top_players_all_time[streamer_name] = { ["pts"] = 0 }
			ns.streamer_to_race[streamer_name] = ns.id_race[_event_log[RACE_IDX]]
		end
		top_players_all_time[streamer_name].pts = top_players_all_time[streamer_name].pts + _adjusted_pts

		if _event_log[DATE_IDX] + WEEK_SECONDS > current_adjusted_time then
			if top_players_weekly[streamer_name] == nil then
				top_players_weekly[streamer_name] = { ["pts"] = 0 }
			end
			top_players_weekly[streamer_name].pts = top_players_weekly[streamer_name].pts + _adjusted_pts
		end
		if _event_log[DATE_IDX] + DAY_SECONDS > current_adjusted_time then
			if top_players_daily[streamer_name] == nil then
				top_players_daily[streamer_name] = { ["pts"] = 0 }
			end
			top_players_daily[streamer_name].pts = top_players_daily[streamer_name].pts + _adjusted_pts
		end
	end

	local adjusted_time = fromAdjustedTime(_event_log[DATE_IDX])
	local race_name = ns.id_race[_event_log[RACE_IDX]]
	if adjusted_time > this_week_period_start then
		distributed_log.this_week_points[race_name] = distributed_log.this_week_points[race_name] + _adjusted_pts
	elseif adjusted_time > last_week_period_start then
		distributed_log.last_week_points[race_name] = distributed_log.last_week_points[race_name] + _adjusted_pts
	end
end

ns.aggregateLog = function()
	top_players_daily = {}
	top_players_weekly = {}
	top_players_all_time = {}
	ns.already_achieved = {}
	local current_adjusted_time = adjustedTime()
	local guild_name = guildName()
	for k, _ in pairs(distributed_log.points) do
		distributed_log.points[k] = 0
		distributed_log.last_week_points[k] = 0
		distributed_log.this_week_points[k] = 0
	end
	for k, v in pairs(distributed_log[guild_name]["data"]) do
		local event_log = v["value"]
		local event_name = ns.id_event[event_log[EVENT_IDX]]
		if
			event_name
			and tonumber(event_log[RACE_IDX]) ~= nil
			and tonumber(event_log[RACE_IDX]) > 0
			and tonumber(event_log[RACE_IDX]) < 9
		then
			if ns.event[event_name].type == "Milestone" then
				if ns.claimed_milestones[event_name] == k then
					ns.event[event_name].aggregrate(distributed_log, event_log)
					addPointsToLeaderBoardData(
						k,
						event_name,
						event_log,
						current_adjusted_time,
						ns.event[event_name].pts
					)
				end
			else
				ns.event[event_name].aggregrate(distributed_log, event_log)
				addPointsToLeaderBoardData(k, event_name, event_log, current_adjusted_time, ns.event[event_name].pts)
			end
		end
	end
end

local event_handler = CreateFrame("Frame")
event_handler:RegisterEvent("CHAT_MSG_ADDON")

event_handler:SetScript("OnEvent", function(self, e, ...)
	local prefix, datastr, scope, sender = ...
	if prefix == COMM_NAME and (DEBUG == true or scope == "GUILD") then
		local command, data = string.split(COMM_COMMAND_DELIM, datastr)
		if command == COMM_COMMAND_HEARTBEAT then
			local _addon_version, _num_entries, _orc_score, _undead_score, _tauren_score, _troll_score, _fletcher, _date, _race_id, _event_id, _class_id, _add_args =
				string.split(COMM_FIELD_DELIM, data)
			ns.guild_member_addon_info[sender] = { ["version"] = _addon_version, ["version_status"] = "updated" }
			if _date ~= nil and lruGet(_fletcher) == nil then
				local _new_data =
					{ tonumber(_date), tonumber(_race_id), tonumber(_event_id), tonumber(_class_id), _add_args }
				local _event_name = ns.id_event[tonumber(_event_id)]
				lruSet(_fletcher, _new_data)
				if ns.event[_event_name].type == "Milestone" then
					if ns.claimed_milestones[_event_name] == nil then
						ns.event[_event_name].aggregrate(distributed_log, _new_data)
						ns.claimed_milestones[_event_name] = _fletcher
						updateThisWeeksPoints(ns.event[_event_name], _new_data)
					end
				else
					ns.event[_event_name].aggregrate(distributed_log, _new_data)
					updateThisWeeksPoints(ns.event[_event_name], _new_data)
				end
			end
			-- print(_num_entries, _addon_version, sender)
			if tonumber(_num_entries) > estimated_score_num_entries then
				estimated_score_num_entries = tonumber(_num_entries)

				local orc_all_time, orc_last_week, orc_this_week = string.split(COMM_SUBFIELD_DELIM, _orc_score)
				local troll_all_time, troll_last_week, troll_this_week = string.split(COMM_SUBFIELD_DELIM, _troll_score)
				local tauren_all_time, tauren_last_week, tauren_this_week =
					string.split(COMM_SUBFIELD_DELIM, _tauren_score)
				local undead_all_time, undead_last_week, undead_this_week =
					string.split(COMM_SUBFIELD_DELIM, _undead_score)

				estimated_score = {
					["Orc"] = tonumber(orc_all_time),
					["Undead"] = tonumber(undead_all_time),
					["Tauren"] = tonumber(tauren_all_time),
					["Troll"] = tonumber(troll_all_time),
				}

				last_week_estimated_score = {
					["Orc"] = tonumber(orc_last_week) or -1,
					["Undead"] = tonumber(undead_last_week) or -1,
					["Tauren"] = tonumber(tauren_last_week) or -1,
					["Troll"] = tonumber(troll_last_week) or -1,
				}

				this_week_estimated_score = {
					["Orc"] = tonumber(orc_this_week) or -1,
					["Undead"] = tonumber(undead_this_week) or -1,
					["Tauren"] = tonumber(tauren_this_week) or -1,
					["Troll"] = tonumber(troll_this_week) or -1,
				}
			end
		elseif command == COMM_COMMAND_DIRECT_EVENT then
			local _fletcher, _date, _race_id, _event_id, _class_id, _add_args = string.split(COMM_FIELD_DELIM, data)
			if lruGet(_fletcher) == nil then
				local _new_data =
					{ tonumber(_date), tonumber(_race_id), tonumber(_event_id), tonumber(_class_id), _add_args }
				local _event_name = ns.id_event[tonumber(_event_id)]
				local _event_type = ns.event[_event_name].type
				local _race_name = ""
				if tonumber(_race_id) ~= nil then
					_race_name = ns.id_race[tonumber(_race_id)] or ""
					if _race_name then
						if _race_name == "Tauren" then
							_race_name =
								"|TInterface\\Glues\\CHARACTERCREATE\\UI-CHARACTERCREATE-RACES:16:16:0:0:64:64:0:16:16:32|t "
						elseif _race_name == "Undead" then
							_race_name =
								"|TInterface\\Glues\\CHARACTERCREATE\\UI-CHARACTERCREATE-RACES:16:16:0:0:64:64:16:32:16:32|t "
						elseif _race_name == "Troll" then
							_race_name =
								"|TInterface\\Glues\\CHARACTERCREATE\\UI-CHARACTERCREATE-RACES:16:16:0:0:64:64:32:48:16:32|t "
						elseif _race_name == "Orc" then
							_race_name =
								"|TInterface\\Glues\\CHARACTERCREATE\\UI-CHARACTERCREATE-RACES:16:16:0:0:64:64:48:64:16:32|t "
						end
					end
				end
				local _sender_short, _ = string.split("-", sender)

				if _event_type == "Achievement" then
					print(
						"|cff33ff99"
							.. _race_name
							.. (_sender_short or "")
							.. " completed achievement: "
							.. ns.event[_event_name].title
							.. ". ("
							.. (ns.event[_event_name].pts or "")
							.. ")|r"
					)
				elseif _event_type == "Milestone" then
					print(
						"|cff33ff99"
							.. _race_name
							.. (_sender_short or "")
							.. " has completed milestone: "
							.. ns.event[_event_name].title
							.. ". ("
							.. (ns.event[_event_name].pts or "")
							.. ")|r"
					)
				elseif _event_type == "Failure" then
					print(
						"|cffB32133"
							.. _race_name
							.. (_sender_short or "")
							.. " "
							.. ns.event[_event_name].title
							.. ". ("
							.. (ns.event[_event_name].pts or "")
							.. ")|r"
					)
				end
				lruSet(_fletcher, _new_data)
				if ns.event[_event_name].type == "Milestone" then
					if ns.claimed_milestones[_event_name] == nil then
						ns.event[_event_name].aggregrate(distributed_log, _new_data)
						ns.claimed_milestones[_event_name] = _fletcher
						updateThisWeeksPoints(ns.event[_event_name], _new_data)
					end
				else
					ns.event[_event_name].aggregrate(distributed_log, _new_data)
					updateThisWeeksPoints(ns.event[_event_name], _new_data)
				end
			end
		end
	end
end)
-- local _checker = {}

local last_ticked = nil
-- Heartbeat
C_Timer.NewTicker(HB_DUR, function(self)
	local d_dur = ns.num_guild_online or 1
	if d_dur < HB_DUR then
		d_dur = HB_DUR
	elseif d_dur > HB_DUR_MAX then
		d_dur = HB_DUR_MAX
	end
	local st = GetServerTime()
	if st - (last_ticked or 0) >= d_dur then
		last_ticked = GetServerTime()
		local guild_name, in_guild = guildName()
		if distributed_log == nil or distributed_log[guild_name] == nil then
			return
		end
		local newest = getNextEntry() --distributed_log[guild_name]["meta"]["newest"]
		local message = nil
		if newest == nil or distributed_log[guild_name]["data"][newest] == nil then
			message = ""
		else
			message = toMessage(newest, distributed_log[guild_name]["data"][newest]["value"])
		end
		-- _checker[newest] = (_checker[newest] or 0) + 1
		-- print(newest, message, _checker[newest])
		local comm_message = COMM_COMMAND_HEARTBEAT
			.. COMM_COMMAND_DELIM
			.. GetAddOnMetadata("OnlyFangs", "Version")
			.. COMM_FIELD_DELIM
			.. distributed_log[guild_name]["meta"]["size"] + 4
			.. COMM_FIELD_DELIM
			.. distributed_log.points["Orc"]
			.. COMM_SUBFIELD_DELIM
			.. distributed_log.last_week_points["Orc"]
			.. COMM_SUBFIELD_DELIM
			.. distributed_log.this_week_points["Orc"]
			.. COMM_FIELD_DELIM
			.. distributed_log.points["Undead"]
			.. COMM_SUBFIELD_DELIM
			.. distributed_log.last_week_points["Undead"]
			.. COMM_SUBFIELD_DELIM
			.. distributed_log.this_week_points["Undead"]
			.. COMM_FIELD_DELIM
			.. distributed_log.points["Tauren"]
			.. COMM_SUBFIELD_DELIM
			.. distributed_log.last_week_points["Tauren"]
			.. COMM_SUBFIELD_DELIM
			.. distributed_log.this_week_points["Tauren"]
			.. COMM_FIELD_DELIM
			.. distributed_log.points["Troll"]
			.. COMM_SUBFIELD_DELIM
			.. distributed_log.last_week_points["Troll"]
			.. COMM_SUBFIELD_DELIM
			.. distributed_log.this_week_points["Troll"]
			.. COMM_FIELD_DELIM
			.. message

		if in_guild then
			CTL:SendAddonMessage("ALERT", COMM_NAME, comm_message, COMM_CHANNEL)
		else
			CTL:SendAddonMessage("ALERT", COMM_NAME, comm_message, "SAY")
		end
	end
end)

ns.sendEvent = function(event_name)
	local guild_name, in_guild = guildName()
	local _, _, _race_id = UnitRace("Player")
	local _, _, _class_id = UnitClass("Player")
	local _fletcher, _event = ns.stampEvent(adjustedTime(), _race_id, ns.event_id[event_name], tonumber(_class_id))
	local comm_message = COMM_COMMAND_DIRECT_EVENT
		.. COMM_COMMAND_DELIM
		.. _fletcher
		.. COMM_FIELD_DELIM
		.. _event[DATE_IDX]
		.. COMM_FIELD_DELIM
		.. _event[RACE_IDX]
		.. COMM_FIELD_DELIM
		.. _event[EVENT_IDX]
		.. COMM_FIELD_DELIM
		.. _event[CLASS_IDX]
		.. COMM_FIELD_DELIM
		.. (_event[ADD_ARGS_IDX] or "")
	if in_guild then
		CTL:SendAddonMessage("ALERT", COMM_NAME, comm_message, COMM_CHANNEL)
	else
		local _n, _ = UnitName("player")
		CTL:SendAddonMessage("ALERT", COMM_NAME, comm_message, "SAY")
	end
end

ns.sendOffEvent = function(event_name, _race_id, _add)
	local guild_name, in_guild = guildName()
	local _, _, _class_id = UnitClass("Player")
	local _fletcher, _event = ns.stampEvent(adjustedTime(), _race_id, ns.event_id[event_name], tonumber(_class_id))
	local comm_message = COMM_COMMAND_DIRECT_EVENT
		.. COMM_COMMAND_DELIM
		.. _fletcher
		.. COMM_FIELD_DELIM
		.. _event[DATE_IDX]
		.. COMM_FIELD_DELIM
		.. _event[RACE_IDX]
		.. COMM_FIELD_DELIM
		.. _event[EVENT_IDX]
		.. COMM_FIELD_DELIM
		.. _event[CLASS_IDX]
		.. COMM_FIELD_DELIM
		.. tostring(_add)
	if in_guild then
		CTL:SendAddonMessage("ALERT", COMM_NAME, comm_message, COMM_CHANNEL)
	else
		local _n, _ = UnitName("player")
		CTL:SendAddonMessage("ALERT", COMM_NAME, comm_message, "SAY")
	end
end

ns.logAsList = function()
	local guild_name = guildName()
	local new_list = {}
	if distributed_log[guild_name] == nil then
		ns.loadDistributedLog()
	end
	if key_list[guild_name] then
		for _idx = #key_list[guild_name], 1, -1 do
			local k = key_list[guild_name][_idx]
			local v = distributed_log[guild_name]["data"][k]
			if v ~= nil then
				new_list[#new_list + 1] = {
					["Name"] = k,
					["Date"] = v["value"][DATE_IDX],
					["Race"] = v["value"][RACE_IDX],
					["Event"] = v["value"][EVENT_IDX],
					["Class"] = v["value"][CLASS_IDX],
					["AdditionalArgs"] = (v["value"][ADD_ARGS_IDX] or ""),
				}
			end
		end
	end
	return new_list
end

ns.fakeEntries = function()
	local k, v = ns.stampEvent(adjustedTime(), ns.race_id["Orc"], ns.event_id["FirstToSixty"], ns.class_id["Warlock"])
	-- ns.distributed_log:set(k, v)
	-- lruSet(k, v)

	k, v = ns.stampEvent(adjustedTime(), ns.race_id["Troll"], ns.event_id["FirstToSixty"], ns.class_id["Warrior"])
	-- distributed_log:set(k, v)
	-- lruSet(k, v)

	k, v = ns.stampEvent(adjustedTime(), ns.race_id["Tauren"], ns.event_id["FirstToSixty"], ns.class_id["Mage"])
	-- distributed_log:set(k, v)
	-- lruSet(k, v)

	distributed_log.points = {
		["Human"] = 0,
		["Gnome"] = 0,
		["Night Elf"] = 0,
		["Dwarf Elf"] = 0,
		["Troll"] = -100,
		["Orc"] = 100,
		["Undead"] = 400,
		["Tauren"] = 200,
		["Troll"] = -100,
	} -- race -> int

	ns.triggerEvent("FirstToSixty")

	ns.aggregateLog()
end

-- local test_name = "FirstTo10Unarmed"
-- ns.showToast(ns.event[test_name].title, ns.event[test_name].icon_path, ns.event[test_name].type)
-- ns.triggerEvent("FirstToSixty")
--
local working_checker = nil
working_checker = C_Timer.NewTicker(10, function()
	local guild_name, _, _ = GetGuildInfo("Player")
	local in_guild = (guild_name ~= nil)
	if in_guild then
		if ns.guild_member_addon_info[UnitName("player") .. "-" .. REALM_NAME] == nil then
			print("|cff33ff99OnlyFangs: Addon is not connected.  Log off and log back in to fix.|r")
		else
			print("|cff33ff99OnlyFangs: Addon is connected and working.|r")
			working_checker:Cancel()
		end
	end
end)
