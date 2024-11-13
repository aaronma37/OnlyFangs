local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.PVPDeath = _event

-- General info
_event.name = "PVPDeath"
_event.type = "Failure"
_event.title = "PvP Death"
_event.icon_path = "Interface\\ICONS\\INV_Misc_Bone_ElfSkull_01"
_event.pts = -50
_event.description = "Lose points if you die from PvP."
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
	if sent == false then
		ns.triggerEvent(_event.name)
		sent = true
	end
end)
