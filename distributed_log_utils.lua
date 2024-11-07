local addonName, ns = ...

local CTL = _G.ChatThrottleLib
local COMM_NAME = "OnlyFangsAddon"
local COMM_COMMAND_HEARTBEAT = "HB"
local COMM_COMMAND_DIRECT_EVENT = "DE"
local COMM_COMMAND_DELIM = "|"
local COMM_FIELD_DELIM = "~"
local COMM_CHANNEL = "SAY"
local HB_DUR = 1
-- Node
local VALUE_IDX = 1
local KEY_IDX = 4
-- Value
local DATE_IDX = 1
local RACE_IDX = 2
local EVENT_IDX = 3
local CLASS_IDX = 4

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

local distributed_log = ns.lru.new(100)
ns.claimed_milestones = {}
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

ns.eventName = function(event_id)
	return ns.id_event[event_id]
end

ns.stampEvent = function(date, race_id, event_id, class_id)
	local flecher = ns.fletcher16(UnitName("Player"), race_id, event_id, date)
	return flecher, { tonumber(date), tonumber(race_id), tonumber(event_id), tonumber(class_id) }
end

local function toMessage(log_event)
	local comm_message = log_event[KEY_IDX]
		.. COMM_FIELD_DELIM
		.. log_event[VALUE_IDX][DATE_IDX]
		.. COMM_FIELD_DELIM
		.. log_event[VALUE_IDX][RACE_IDX]
		.. COMM_FIELD_DELIM
		.. log_event[VALUE_IDX][EVENT_IDX]
		.. COMM_FIELD_DELIM
		.. log_event[VALUE_IDX][CLASS_IDX]
	return comm_message
end

local k, v = ns.stampEvent(adjustedTime(), ns.race_id["Orc"], ns.event_id["FirstToSixty"], ns.class_id["Warlock"])
distributed_log:set(k, v)

k, v = ns.stampEvent(adjustedTime(), ns.race_id["Troll"], ns.event_id["FirstToSixty"], ns.class_id["Warrior"])
distributed_log:set(k, v)

k, v = ns.stampEvent(adjustedTime(), ns.race_id["Tauren"], ns.event_id["FirstToSixty"], ns.class_id["Mage"])
distributed_log:set(k, v)

ns.getScore = function(team_name)
	return estimated_score[team_name]
end

ns.aggregateLog = function()
	for k, _ in pairs(distributed_log.points) do
		distributed_log.points[k] = 0
	end
	for k, v in pairs(distributed_log:getMap()) do
		local event_log = v[1]
		local event_name = ns.id_event[event_log[EVENT_IDX]]
		ns.event[event_name].aggregrate(distributed_log, event_log)
	end
end

ns.aggregateLog()

local event_handler = CreateFrame("Frame")
event_handler:RegisterEvent("CHAT_MSG_ADDON")

event_handler:SetScript("OnEvent", function(self, e, ...)
	local prefix, datastr, scope, sender = ...
	if prefix == COMM_NAME then
		local command, data = string.split(COMM_COMMAND_DELIM, datastr)
		if command == COMM_COMMAND_HEARTBEAT then
			local _num_entries, _orc_score, _undead_score, _tauren_score, _troll_score, _fletcher, _date, _race_id, _event_id, _class_id =
				string.split(COMM_FIELD_DELIM, data)
			if distributed_log.get(_fletcher) == nil then
				local _new_data = { tonumber(_date), tonumber(_race_id), tonumber(_event_id), tonumber(_class_id) }
				local _event_name = ns.id_event[tonumber(_event_id)]
				distributed_log:set(_fletcher, _new_data)
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
			if distributed_log.get(_fletcher) == nil then
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
				distributed_log:set(_fletcher, _new_data)
				ns.event[_event_name].aggregrate(distributed_log, _new_data)
			end
		end
	end
end)

-- Heartbeat
C_Timer.NewTicker(HB_DUR, function(self)
	local comm_message = COMM_COMMAND_HEARTBEAT
		.. COMM_COMMAND_DELIM
		.. distributed_log:getSize()
		.. COMM_FIELD_DELIM
		.. distributed_log.points["Orc"]
		.. COMM_FIELD_DELIM
		.. distributed_log.points["Undead"]
		.. COMM_FIELD_DELIM
		.. distributed_log.points["Tauren"]
		.. COMM_FIELD_DELIM
		.. distributed_log.points["Troll"]
		.. COMM_FIELD_DELIM
		.. toMessage(distributed_log:getOldest())

	CTL:SendAddonMessage("ALERT", COMM_NAME, comm_message, COMM_CHANNEL)
end)

ns.sendEvent = function(event_name)
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
	CTL:SendAddonMessage("ALERT", COMM_NAME, comm_message, COMM_CHANNEL)
end

ns.logAsList = function()
	local new_list = {}
	for k, v in pairs(distributed_log:getMap()) do
		new_list[#new_list + 1] = {
			["Name"] = k,
			["Date"] = v[1][DATE_IDX],
			["Race"] = v[1][RACE_IDX],
			["Event"] = v[1][EVENT_IDX],
			["Class"] = v[1][CLASS_IDX],
		}
	end
	return new_list
end

ns.triggerEvent("FirstToSixty")
-- ns.showToast("Yazpad", "warlock")
