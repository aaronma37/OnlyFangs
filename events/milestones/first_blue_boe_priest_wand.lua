local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.FirstBlueBoePriestWand = _event

-- General info
_event.name = "FirstBlueBoePriestWand"
_event.type = "Milestone"
_event.title = "1st Blue BoE Priest Wand"
_event.icon_path = "Interface\\ICONS\\INV_BannerPVP_01"
_event.pts = 50
_event.description = "First to find a blue BoE wand as a priest"
_event.subtype = "General"

-- Aggregation
_event.aggregrate = function(distributed_log, event_log)
	local race_name = ns.id_race[event_log[2]]
	distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
end

-- Register Definitions
local sent = false

local function triggerCondition()
	if sent == true then
		return
	end
	if ns.claimed_milestones[_event.name] == nil then
		local _, _, _class_id = UnitClass("player")
		if _class_id == 5 then
			ns.triggerEvent(_event.name)
			sent = true
		end
	end
end

for _, v in ipairs({ 9381, 23177, 13064, 13063, 217295, 5243, 12984, 5198, 13062, 7001 }) do
	ns.item_id_obs[v] = function()
		triggerCondition()
	end
end
