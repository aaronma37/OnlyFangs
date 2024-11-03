local addonName, ns = ...

local CTL = _G.ChatThrottleLib
local COMM_NAME = "OnlyFangsAddon"
local COMM_COMMAND_HEARTBEAT = "HB"
local COMM_COMMAND_DELIM = "|"
local COMM_FIELD_DELIM = "~"
-- Node
local VALUE_IDX = 1
local KEY_IDX = 4
-- Value
local DATE_IDX = 1
local RACE_IDX = 2
local EVENT_IDX = 3

local INIT_TIME = 1730639674
print("VV", GetServerTime())

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
distributed_log.num_entries = 0
distributed_log.points = {
	["Orc"] = 100,
	["Undead"] = 400,
	["Tauren"] = 200,
	["Troll"] = -100,
} -- race -> int

local date_idx = 1
local race_id_idx = 2
local event_id_idx = 3

ns.stampEvent = function(date, race_id, event_id)
	local flecher = ns.fletcher16(UnitName("Player"), race_id, event_id, date)
	return flecher, { tonumber(date), tonumber(race_id), tonumber(event_id) }
end

local function toMessage(log_event)
	local comm_message = log_event[KEY_IDX]
		.. COMM_FIELD_DELIM
		.. log_event[VALUE_IDX][DATE_IDX]
		.. COMM_FIELD_DELIM
		.. log_event[VALUE_IDX][RACE_IDX]
		.. COMM_FIELD_DELIM
		.. log_event[VALUE_IDX][EVENT_IDX]
	return comm_message
end

local k, v = ns.stampEvent(adjustedTime(), ns.race_id["Orc"], ns.event_id["FirstToSixty"])
distributed_log:set(k, v)

k, v = ns.stampEvent(adjustedTime(), ns.race_id["Troll"], ns.event_id["FirstToSixty"])
distributed_log:set(k, v)

k, v = ns.stampEvent(adjustedTime(), ns.race_id["Tauren"], ns.event_id["FirstToSixty"])
distributed_log:set(k, v)

ns.getScore = function(team_name)
	return estimated_score[team_name]
end

for k, v in pairs(distributed_log:getMap()) do
	for k2, v2 in ipairs(v[1]) do
		print(k, v2)
	end
end

ns.aggregateLog = function()
	distributed_log.num_entries = 0
	for k, v in pairs(distributed_log.points) do
		v = 0
	end
	for k, v in pairs(distributed_log:getMap()) do
		local event_log = v[1]
		local event_name = ns.id_event[event_log[event_id_idx]]
		ns.event[event_name].aggregrate(distributed_log, event_log)
		distributed_log.num_entries = distributed_log.num_entries + 1
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
			local _num_entries, _orc_score, _undead_score, _tauren_score, _troll_score, _fletcher, _date, _race_id, _event_id =
				string.split(COMM_FIELD_DELIM, data)
			print(
				_num_entries,
				_orc_score,
				_undead_score,
				_tauren_score,
				_troll_score,
				_fletcher,
				_date,
				_race_id,
				_event_id
			)
			if distributed_log.get(_fletcher) == nil then
				distributed_log:set(_fletcher, { tonumber(_date), tonumber(_race_id), tonumber(_event_id) })
			end
			if tonumber(_num_entries) > estimated_score_num_entries then
				print("Update Estimated Score")
				estimated_score_num_entries = tonumber(_num_entries)
				estimated_score = {
					["Orc"] = tonumber(_orc_score),
					["Undead"] = tonumber(_undead_score),
					["Tauren"] = tonumber(_tauren_score),
					["Troll"] = tonumber(_troll_score),
				}
			end
		end
	end
end)

-- Heartbeat
C_Timer.NewTicker(1, function(self)
	local comm_message = COMM_COMMAND_HEARTBEAT
		.. COMM_COMMAND_DELIM
		.. distributed_log.num_entries
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

	CTL:SendAddonMessage("ALERT", COMM_NAME, comm_message, "SAY")
end)
