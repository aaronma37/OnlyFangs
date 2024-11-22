local addonName, ns = ...

local target_metadata = {
	{ ["target_name"] = "Swiftmane", ["pts"] = 10 },
	{ ["target_name"] = "Rocklance", ["pts"] = 10 },
	{ ["target_name"] = "Gesharahan", ["pts"] = 10 },
	{ ["target_name"] = "Taskmaster Whipfang", ["pts"] = 10 },
	{ ["target_name"] = "Foreman Rigger", ["pts"] = 10 },
	{ ["target_name"] = "Brother Ravenoak", ["pts"] = 10 },
	{ ["target_name"] = "Narillasanz", ["pts"] = 10 },
	{ ["target_name"] = "Warleader Krazzilak", ["pts"] = 10 },
	{ ["target_name"] = "Grimungous", ["pts"] = 10 },
	{ ["target_name"] = "Captain Flat Tusk", ["pts"] = 10 },
	{ ["target_name"] = "Gamon", ["pts"] = 15 },
	{ ["target_name"] = "Mottled Boar", ["pts"] = 15, ["test_only"] = 1 },
	{ ["target_name"] = "Sarkoth", ["pts"] = 15, ["test_only"] = 1 },
	{ ["target_name"] = "Scorpid Worker", ["pts"] = 30, ["test_only"] = 1 },
	{ ["target_name"] = "Adder", ["pts"] = 0, ["test_only"] = 1 },
	{ ["target_name"] = "Hare", ["pts"] = 0, ["test_only"] = 1 },
}

local function loadEvent(target_metadata)
	local _event = CreateFrame("Frame")
	local _name = "First to Kill " .. target_metadata.target_name
	ns.event[_name] = _event

	-- General info
	_event.name = _name
	_event.type = "Milestone"
	_event.title = _name
	_event.subtype = "First to Kill"
	_event.pts = target_metadata.pts
	_event.test_only = target_metadata.test_only
	_event.description = "|cffddddddBe the first to kill " .. target_metadata.target_name .. " |cffdddddd.|r"

	-- Aggregation
	_event.aggregrate = function(distributed_log, event_log)
		local race_name = ns.id_race[event_log[2]]
		distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
	end

	-- Custom Register
	local sent = false
	ns.kill_target_exec[target_metadata.target_name] = function()
		if sent == true then
			return
		end
		if ns.claimed_milestones[_event.name] == nil then
			ns.triggerEvent(_event.name)
			sent = true
		end
	end
end

for _, v in ipairs(target_metadata) do
	loadEvent(v)
end
