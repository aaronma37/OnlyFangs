local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.FirstToSixty = _event

-- General info
_event.name = "FirstToSixty"
_event.type = "Milestone"
_event.title = "1st to 60"
_event.icon_path = "Interface\\ICONS\\INV_BannerPVP_01"
_event.pts = 125
_event.description = "First to reach level 60 gets this milestone!"
_event.subtype = "General"

-- Aggregation
_event.aggregrate = function(distributed_log, event_log)
	local race_name = ns.id_race[event_log[2]]
	distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
end

-- Registers
_event:RegisterEvent("PLAYER_LEVEL_UP")

-- Register Definitions
local sent = false
_event:SetScript("OnEvent", function(self, e, _)
	if ns.claimed_milestones[_event.name] ~= nil then
		return
	end

	C_Timer.After(1, function()
		local lvl = UnitLevel("player")
		if lvl == 60 and sent == false then
			ns.triggerEvent(_event.name)
			sent = true
		end
	end)
end)
