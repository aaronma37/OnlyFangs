local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.First315Skinning = _event

-- General info
_event.name = "First315Skinning"
_event.type = "Milestone"
_event.title = "1st 315 Skinning"
_event.icon_path = "Interface\\ICONS\\INV_BannerPVP_01"
_event.pts = 100
_event.description = "First to obtain reach 315 skinning gets this milestone!"
_event.subtype = "General"
_event.incomplete = 1

-- Aggregation
_event.aggregrate = function(distributed_log, event_log)
	local race_name = ns.id_race[event_log[2]]
	distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
end

-- Registers

-- Register Definitions
local sent = false
_event:SetScript("OnEvent", function(self, e, ...)
	if ns.claimed_milestones[_event.name] == nil then
		return
	end
end)
