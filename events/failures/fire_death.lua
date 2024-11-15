local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.FireDeath = _event

-- General info
_event.name = "FireDeath"
_event.type = "Failure"
_event.title = "Fire Death"
_event.icon_path = "Interface\\ICONS\\INV_Misc_Bone_ElfSkull_01"
_event.pts = -50
_event.description = "Lose points if you die from fire."

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
		if ns.last_attack_source == nil or tonumber(ns.last_attack_source) ~= -5 then
			return
		end
		ns.triggerEvent(_event.name)
		sent = true
	end
end)
-- Register Definitions
