local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.Death = _event

-- General info
_event.name = "Death"
_event.type = "Failure"
_event.title = "Death"
_event.icon_path = "Interface\\ICONS\\INV_Misc_Bone_ElfSkull_01"
_event.pts = -10
_event.description = "Don't die!"

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
	if sent == false then
		ns.triggerEvent(_event.name)
		sent = true
	end
end)
