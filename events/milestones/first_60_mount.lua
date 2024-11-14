local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.First60Mount = _event

-- General info
_event.name = "First60Mount"
_event.type = "Milestone"
_event.title = "1st 60 Mount"
_event.icon_path = "Interface\\ICONS\\INV_BannerPVP_01"
_event.pts = 50
_event.description = "First to obtain a level 60 mount gets this milestone!"
_event.subtype = "General"

-- Aggregation
_event.aggregrate = function(distributed_log, event_log)
	local race_name = ns.id_race[event_log[2]]
	distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
end

-- Registers

-- Register Definitions
local sent = false
local function triggerCondition()
	if sent == true then
		return
	end
	if ns.claimed_milestones[_event.name] == nil then
		ns.triggerEvent(_event.name)
		sent = true
	end
end

for _, v in ipairs({ 18796, 18798, 18797, 13334, 18791, 18794, 18795, 18793, 18788, 18789, 18790 }) do
	ns.item_id_obs[v] = function()
		triggerCondition()
	end
end
