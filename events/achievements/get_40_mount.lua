local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.Get40Mount = _event

-- General info
_event.name = "Get40Mount"
_event.type = "Achievement"
_event.title = "[Removed]"
_event.subtype = "GeneralAchievement"
_event.icon_path = "Interface\\ICONS\\INV_BannerPVP_01"
_event.pts = 0
_event.test_only = 1
_event.description = "Obtain a level 40 mount.  Mount up to get this achievement."

-- Aggregation
_event.aggregrate = function(distributed_log, event_log)
	local race_name = ns.id_race[event_log[2]]
	distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
end
