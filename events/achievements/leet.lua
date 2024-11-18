local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event["leet"] = _event

-- General info
_event.name = "leet"
_event.type = "Achievement"
_event.subtype = "GeneralAchievement"
_event.title = "Crit for 1337"
_event.icon_path = ""
_event.pts = 5
_event.description = "|cffddddddScore a critical strike for |r|cffFFA5001337|r |cffdddddddamage|r."

-- Aggregation
_event.aggregrate = function(distributed_log, event_log)
	local race_name = ns.id_race[event_log[2]]
	distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
end

-- Register Definitions
local sent = false
ns.triggerLeet = function()
	if sent == true then
		return
	end
	ns.triggerEvent(_event.name)
	sent = true
end
