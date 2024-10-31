local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.AdjustPoints = _event

-- General info
_event.name = "AdjustPoints"
_event.title = "Adjust Points"
_event.icon_path = "Interface\\Addons\\HardcoreUnlocked\\Media\\icon_a_final_blow.blp"
_event.pts = 0 -- Unused
_event.description = "[Guild Master Only] Allows guild master to set points for a race."

-- Aggregation
_event.aggregrate = function(distributed_log, event_log)
	distributed_log.points[event_log.race] = distributed_log.points[event_log.race] + event_log.additional_args[0]
end

-- Registers
function _event:Register(succeed_function_executor) end

function _event:Unregister()
	_event:UnregisterAllEvents()
end

-- Register Definitions
_event:SetScript("OnEvent", function(self, e, ...) end)
