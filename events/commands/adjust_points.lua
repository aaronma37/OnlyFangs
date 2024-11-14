local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.AdjustPoints = _event

-- General info
_event.name = "AdjustPoints"
_event.title = "Adjust Points"
_event.type = "OfficerCommand"
_event.icon_path = "Interface\\Addons\\HardcoreUnlocked\\Media\\icon_a_final_blow.blp"
_event.pts = 0 -- Unused
_event.description = "[Guild Master Only] Allows guild master to add or subtract points for a race."

-- Aggregation
_event.aggregrate = function(distributed_log, event_log)
	local str = "return " .. event_log[5]
	local func = assert(loadstring(str))
	local args = func()

	local race_name = ns.id_race[event_log[2]]
	distributed_log.points[race_name] = distributed_log.points[race_name] + tonumber(args["pts"])
end

-- Registers

-- Register Definitions
_event:SetScript("OnEvent", function(self, e, ...) end)
