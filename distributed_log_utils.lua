local addonName, ns = ...

local distributed_log = ns.lru.new(100)
ns.claimed_milestones = {}
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
	return 12345, { date, race_id, event_id }
end

local k, v = ns.stampEvent(time(), ns.race_id["Orc"], ns.event_id["FirstToSixty"])
distributed_log:set(k, v)

ns.getScore = function(team_name)
	return distributed_log.points[team_name]
end

for k, v in pairs(distributed_log:getMap()) do
	print("key" .. k)
	for k2, v2 in ipairs(v[1]) do
		print(v2)
	end
end

ns.aggregateLog = function()
	for k, v in pairs(distributed_log.points) do
		v = 0
	end
	for k, v in pairs(distributed_log:getMap()) do
		local event_log = v[1]
		print(event_log[1], event_log[2], event_log[3])
		local event_name = ns.id_event[event_log[event_id_idx]]
		print(event_log[event_id_idx], event_name, ns.event[event_name])
		ns.event[event_name].aggregrate(distributed_log, event_log)
	end
end

ns.aggregateLog()
