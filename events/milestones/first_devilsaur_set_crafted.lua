local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.FirstDevilsaurCrafted = _event

-- General info
_event.name = "FirstDevilsaurCrafted"
_event.type = "Milestone"
_event.title = "1st devilsaur set crafted"
_event.icon_path = "Interface\\ICONS\\INV_BannerPVP_01"
_event.pts = 30
_event.description = "First to a devilsaur set gets this milestone!"
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
local has = { [15062] = false, [15063] = false }
local function triggerCondition()
	if sent == true then
		return
	end
	if ns.claimed_milestones[_event.name] == nil then
		ns.triggerEvent(_event.name)
		sent = true
	end
end

for _, v in ipairs({ 15062, 15063 }) do
	ns.item_id_obs[v] = function()
		has[v] = true
		for k, v2 in pairs(has) do
			if v2 == false then
				return
			end
		end
		triggerCondition()
	end
end
