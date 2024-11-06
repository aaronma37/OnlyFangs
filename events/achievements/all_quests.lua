local addonName, ns = ...

local quest_metadata = {
	{
		["name"] = "HighChiefWinterfall",
		["title"] = "High Chief Winterfall",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
		["max_lvl"] = 56,
		["quest_id"] = 5121,
	},
	{
		["name"] = "OfForgottenMemories",
		["title"] = "Grave Digger",
		["icon_path"] = "Interface\\ICONS\\INV_Misc_Shovel_01",
		["max_lvl"] = 55,
		["quest_id"] = 5781,
	},
}

local function loadQuestEvent(_metadata)
	local _event = CreateFrame("Frame")
	ns.event[_metadata["name"]] = _event

	-- General info
	_event.name = _metadata.name
	_event.type = "Achievement"
	_event.title = _metadata.title
	_event.icon_path = _metadata.icon_path
	_event.pts = 10
	_event.max_lvl = _metadata.max_lvl
	_event.description = "Complete high chief winterfall by lvl. " .. _event.max_lvl .. "."

	-- Aggregation
	_event.aggregrate = function(distributed_log, event_log)
		local race_name = ns.id_race[event_log[2]]
		distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
	end

	-- Registers
	function _event:Register(succeed_function_executor)
		_event:RegisterEvent("QUEST_TURNED_IN")
	end

	function _event:Unregister()
		_event:UnregisterAllEvents()
	end

	-- Register Definitions
	local sent = false
	_event:SetScript("OnEvent", function(self, e, _args)
		if e == "QUEST_TURNED_IN" then
			if
				_args[1] ~= nil
				and _args[1] == _event.quest_id
				and (
					UnitLevel("player") <= _event.max_lvl
					or (ns.recent_level_up ~= nil and UnitLevel("player") <= _event.max_lvl + 1)
				)
			then
				ns.triggerEvent(_event.name)
			end
		end
	end)
end

for _, v in ipairs(quest_metadata) do
	loadQuestEvent(v)
end
