local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.FirstBlueBoeHunter = _event

-- General info
_event.name = "FirstBlueBoeHunter"
_event.type = "Milestone"
_event.title = "1st Blue BoE Hunter Ranged Weapon"
_event.icon_path = "Interface\\ICONS\\INV_BannerPVP_01"
_event.pts = 50
_event.description = "First to find a blue BoE ranged weapon as a hunter"
_event.subtype = "Class"
_event.class = "Hunter"

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
		if _class_id == 3 then
			ns.triggerEvent(_event.name)
			sent = true
		end
	end
end

for _, v in ipairs({
	6469,
	3021,
	13019,
	10567,
	13020,
	9426,
	13037,
	13038,
	13136,
	2098,
	9487,
	7729,
	13137,
	9456,
	13138,
	9422,
}) do
	ns.item_id_obs[v] = function()
		triggerCondition()
	end
end
