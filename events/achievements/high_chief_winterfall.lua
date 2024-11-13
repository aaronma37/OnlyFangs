local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.HighChiefWinterfall = _event

-- General info
_event.name = "HighChiefWinterfall"
_event.type = "Achievement"
_event.title = "High Chief Winterfall"
_event.icon_path = "Interface\\ICONS\\Spell_Frost_IceClaw"
_event.pts = 10
_event.description = "Complete high chief winterfall by X level"

-- Aggregation
_event.aggregrate = function(distributed_log, event_log)
	local race_name = ns.id_race[event_log[2]]
	distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
end

-- Registers

-- Register Definitions
local sent = false
_event:SetScript("OnEvent", function(self, e, ...)
	-- if sent == false then
	-- 	ns.triggerEvent(_event.name)
	-- 	sent = true
	-- end
end)
