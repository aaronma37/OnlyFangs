local addonName, ns = ...

local CTL = _G.ChatThrottleLib
local COMM_NAME = "OnlyFangsAddon"
local COMM_COMMAND_HEARTBEAT = "HB"
local COMM_COMMAND_DIRECT_EVENT = "DE"
local COMM_COMMAND_DELIM = "|"
local COMM_FIELD_DELIM = "~"
local COMM_CHANNEL = "GUILD"
local HB_DUR = 2
local ERASE_CACHE = false
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

local function adjustedTime()
	return GetServerTime() - INIT_TIME
end
local function fromAdjustedTime(t)
	return t + INIT_TIME
end

local estimated_score_num_entries = 0
local estimated_score = {
	["Orc"] = 0,
	["Undead"] = 0,
	["Tauren"] = 0,
	["Troll"] = 0,
}

local function guildName()
	local guild_name, _, _ = GetGuildInfo("Player")
	local in_guild = (guild_name ~= nil)
	guild_name = guild_name or "guildless"
	return guild_name, in_guild
end

--- [key] = {value: {}, prev: string or nil, next: string or nil}
--- [guild][meta] -> {newest, oldest}
--- [guild][data][key] -> {value: {}, prev: string or nil, next: string or nil}

local distributed_log = nil
ns.claimed_milestones = {}

local function refreshClaimedMilestones()
	local guild_name = guildName()
	for k, v in pairs(distributed_log[guild_name]["data"]) do
		local event_name = ns.id_event[v["value"][EVENT_IDX]]
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

ns.loadDistributedLog = function()
	distributed_log = ns.distributed_log
	local guild_name = guildName()

	if ERASE_CACHE then
		distributed_log[guild_name] = nil
	end
	if distributed_log[guild_name] == nil then
		distributed_log[guild_name] = { ["meta"] = { ["newest"] = nil, ["oldest"] = nil, ["size"] = 0 }, ["data"] = {} }
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
end

-- got a node that points to itself
local function lruSet(key, v)
	local guild_name = guildName()
	if distributed_log[guild_name]["data"][key] == nil then
		distributed_log[guild_name]["meta"]["size"] = distributed_log[guild_name]["meta"]["size"] + 1
	end

	local oldest = distributed_log[guild_name]["meta"]["oldest"]
	if oldest == key then
		oldest = distributed_log[guild_name]["data"][key]["next"]
	end
	distributed_log[guild_name]["data"][key] = {
		["value"] = v,
		["next"] = oldest,
		["prev"] = nil,
	}
	if oldest ~= nil then
		distributed_log[guild_name]["data"][oldest]["prev"] = key
	end
	distributed_log[guild_name]["meta"]["oldest"] = key
	if distributed_log[guild_name]["meta"]["newest"] == nil then
		distributed_log[guild_name]["meta"]["newest"] = key
	end
end

-- local num_gets = {}
local function lruGet(key_id)
	local guild_name = guildName()
	if distributed_log[guild_name]["data"][key_id] == nil then
		return nil
	end

	-- if num_gets[key_id] == nil then
	-- 	num_gets[key_id] = 0
	-- end
	-- num_gets[key_id] = num_gets[key_id] + 1
	-- print("Gets: ")
	-- for k, v in pairs(num_gets) do
	-- 	print(k .. ": " .. v)
	-- end

	local v = distributed_log[guild_name]["data"][key_id]["value"]
	local prev = distributed_log[guild_name]["data"][key_id]["prev"]
	local next = distributed_log[guild_name]["data"][key_id]["next"]

	if key_id == distributed_log[guild_name]["meta"]["newest"] and prev ~= nil then
		distributed_log[guild_name]["meta"]["newest"] = prev
	end
	if prev ~= nil then
		distributed_log[guild_name]["data"][prev]["next"] = next
	end
	if next ~= nil then
		distributed_log[guild_name]["data"][next]["prev"] = prev
	end

	local oldest = distributed_log[guild_name]["meta"]["oldest"]

	if oldest ~= key_id then
		distributed_log[guild_name]["data"][key_id]["next"] = oldest
	end
	distributed_log[guild_name]["data"][key_id]["prev"] = nil

	if oldest ~= nil then
		distributed_log[guild_name]["data"][oldest]["prev"] = key_id
	end

	distributed_log[guild_name]["meta"]["oldest"] = key_id
	return v
end

ns.eventName = function(event_id)
	return ns.id_event[event_id]
end

ns.stampEvent = function(date, race_id, event_id, class_id)
	local flecher = ns.fletcher16(UnitName("Player"), race_id, event_id, date)
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
	return estimated_score[team_name]
end

ns.aggregateLog = function()
	local guild_name = guildName()
	for k, _ in pairs(distributed_log.points) do
		distributed_log.points[k] = 0
	end
	for k, v in pairs(distributed_log[guild_name]["data"]) do
		local event_log = v["value"]
		local event_name = ns.id_event[event_log[EVENT_IDX]]
		if ns.event[event_name].type == "Milestone" then
			if ns.claimed_milestones[event_name] == k then
				ns.event[event_name].aggregrate(distributed_log, event_log)
			end
		else
			ns.event[event_name].aggregrate(distributed_log, event_log)
		end
	end
end

local event_handler = CreateFrame("Frame")
event_handler:RegisterEvent("CHAT_MSG_ADDON")

event_handler:SetScript("OnEvent", function(self, e, ...)
	local prefix, datastr, scope, sender = ...
	if prefix == COMM_NAME and scope == "GUILD" then
		local command, data = string.split(COMM_COMMAND_DELIM, datastr)
		if command == COMM_COMMAND_HEARTBEAT then
			local _num_entries, _orc_score, _undead_score, _tauren_score, _troll_score, _fletcher, _date, _race_id, _event_id, _class_id =
				string.split(COMM_FIELD_DELIM, data)
			if _date ~= nil and lruGet(_fletcher) == nil then
				local _new_data = { tonumber(_date), tonumber(_race_id), tonumber(_event_id), tonumber(_class_id) }
				local _event_name = ns.id_event[tonumber(_event_id)]
				lruSet(_fletcher, _new_data)
				ns.event[_event_name].aggregrate(distributed_log, _new_data)
			end
			if tonumber(_num_entries) > estimated_score_num_entries then
				estimated_score_num_entries = tonumber(_num_entries)
				estimated_score = {
					["Orc"] = tonumber(_orc_score),
					["Undead"] = tonumber(_undead_score),
					["Tauren"] = tonumber(_tauren_score),
					["Troll"] = tonumber(_troll_score),
				}
			end
		elseif command == COMM_COMMAND_DIRECT_EVENT then
			local _fletcher, _date, _race_id, _event_id, _class_id = string.split(COMM_FIELD_DELIM, data)
			if lruGet(_fletcher) == nil then
				local _new_data = { tonumber(_date), tonumber(_race_id), tonumber(_event_id), tonumber(_class_id) }
				local _event_name = ns.id_event[tonumber(_event_id)]
				local _event_type = ns.event[_event_name].type
				if _event_type == "Achievement" then
					print("|cff33ff99OnlyFangs: " .. sender .. " completed achievement: " .. _event_name .. "|r")
				elseif _event_type == "Milestone" then
					print("|cff33ff99OnlyFangs: " .. sender .. " has completed milestone: " .. _event_name .. "|r")
				elseif _event_type == "Failure" then
					print("|cff33ff99OnlyFangs: " .. sender .. " " .. _event_name .. "|r")
				end
				lruSet(_fletcher, _new_data)
				ns.event[_event_name].aggregrate(distributed_log, _new_data)
			end
		end
	end
end)

-- Heartbeat
C_Timer.NewTicker(HB_DUR, function(self)
	local guild_name, in_guild = guildName()
	if distributed_log == nil or distributed_log[guild_name] == nil then
		return
	end
	local newest = distributed_log[guild_name]["meta"]["newest"]
	local message = nil
	if newest == nil then
		message = ""
	else
		message = toMessage(newest, distributed_log[guild_name]["data"][newest]["value"])
	end
	local comm_message = COMM_COMMAND_HEARTBEAT
		.. COMM_COMMAND_DELIM
		.. distributed_log[guild_name]["meta"]["size"]
		.. COMM_FIELD_DELIM
		.. distributed_log.points["Orc"]
		.. COMM_FIELD_DELIM
		.. distributed_log.points["Undead"]
		.. COMM_FIELD_DELIM
		.. distributed_log.points["Tauren"]
		.. COMM_FIELD_DELIM
		.. distributed_log.points["Troll"]
		.. COMM_FIELD_DELIM
		.. message

	if in_guild then
		CTL:SendAddonMessage("ALERT", COMM_NAME, comm_message, COMM_CHANNEL)
	else
		CTL:SendAddonMessage("ALERT", COMM_NAME, comm_message, "SAY")
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
		CTL:SendAddonMessage("ALERT", COMM_NAME, comm_message, "SAY")
	end
end

ns.logAsList = function()
	local guild_name = guildName()
	local new_list = {}
	for k, v in pairs(distributed_log[guild_name]["data"]) do
		new_list[#new_list + 1] = {
			["Name"] = k,
			["Date"] = v["value"][DATE_IDX],
			["Race"] = v["value"][RACE_IDX],
			["Event"] = v["value"][EVENT_IDX],
			["Class"] = v["value"][CLASS_IDX],
			["AdditionalArgs"] = (v["value"][ADD_ARGS_IDX] or ""),
		}
	end
	return new_list
end

ns.fakeEntries = function()
	local k, v = ns.stampEvent(adjustedTime(), ns.race_id["Orc"], ns.event_id["FirstToSixty"], ns.class_id["Warlock"])
	-- ns.distributed_log:set(k, v)
	lruSet(k, v)

	k, v = ns.stampEvent(adjustedTime(), ns.race_id["Troll"], ns.event_id["FirstToSixty"], ns.class_id["Warrior"])
	-- distributed_log:set(k, v)
	lruSet(k, v)

	k, v = ns.stampEvent(adjustedTime(), ns.race_id["Tauren"], ns.event_id["FirstToSixty"], ns.class_id["Mage"])
	-- distributed_log:set(k, v)
	lruSet(k, v)

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
