local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.FirstToDie = _event

-- General info
_event.name = "FirstToDie"
_event.type = "Milestone"
_event.title = "1st to Die (over lvl 12)"
_event.icon_path = "Interface\\ICONS\\INV_BannerPVP_01"
_event.pts = -250
_event.description = "First to die when lvl 12 or above"
_event.subtype = "MilestoneFailure"

-- Aggregation
_event.aggregrate = function(distributed_log, event_log)
	local race_name = ns.id_race[event_log[2]]
	distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
end

-- Registers
_event:RegisterEvent("PLAYER_DEAD")

-- Register Definitions
local sent = false
_event:SetScript("OnEvent", function(self, e, ...)
	if ns.claimed_milestones[_event.name] ~= nil then
		return
	end
	if UnitLevel("player") >= 12 then
		if sent == false then
			ns.triggerEvent(_event.name)
			sent = true
		end
	end
end)
