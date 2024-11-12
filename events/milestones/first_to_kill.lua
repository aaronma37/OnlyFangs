local addonName, ns = ...

local target_metadata = {
	{ ["target_name"] = "Swiftmane" },
	{ ["target_name"] = "Rocklance" },
	{ ["target_name"] = "Gesharahan" },
	{ ["target_name"] = "Taskmaster Whipfang" },
	{ ["target_name"] = "Foreman Rigger" },
	{ ["target_name"] = "Brother Ravenoak" },
	{ ["target_name"] = "Narillasanz" },
	{ ["target_name"] = "Warleader Krazzilak" },
	{ ["target_name"] = "Grimungous" },
	{ ["target_name"] = "Captain Flat Tusk" },
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
	_event.pts = 20
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
			return
		end

		ns.triggerEvent(_event.name)
		sent = true
	end
end

for _, v in ipairs(target_metadata) do
	loadEvent(v)
end
