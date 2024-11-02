local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.FirstToSixty = _event

-- General info
_event.name = "FirstToSixty"
_event.title = "First to Sixty"
_event.icon_path = "Interface\\Addons\\HardcoreUnlocked\\Media\\icon_a_final_blow.blp"
_event.pts = 10
_event.description = "First to reach level 60 gets this milestone!"

-- Aggregation
_event.aggregrate = function(distributed_log, event_log)
	local race_name = ns.id_race[event_log[2]]
	distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
end

-- Registers
function _event:Register(succeed_function_executor)
	_event:RegisterEvent("PLAYER_LEVEL_UP")
end

function _event:Unregister()
	_event:UnregisterAllEvents()
end

-- Register Definitions
local sent = false
_event:SetScript("OnEvent", function(self, e, ...)
	if ns.claimed_milestones[_event.name] == nil then
		return
	end

	if UnitLevel("Player") == 60 and sent == false then
		ns.trigger_event(_event.name)
		sent = true
	end
end)
