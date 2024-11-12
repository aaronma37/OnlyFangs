local addonName, ns = ...

local level_metadata = {
	{
		["name"] = "ReachLvl10",
		["title"] = "Reach Level 10",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
		["lvl"] = 10,
	},
	{
		["name"] = "ReachLvl20",
		["title"] = "Reach Level 20",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
		["lvl"] = 20,
	},
	{
		["name"] = "ReachLvl30",
		["title"] = "Reach Level 30",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
		["lvl"] = 30,
	},
	{
		["name"] = "ReachLvl40",
		["title"] = "Reach Level 40",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
		["lvl"] = 40,
	},
	{
		["name"] = "ReachLvl50",
		["title"] = "Reach Level 50",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
		["lvl"] = 50,
	},
	{
		["name"] = "ReachLvl60",
		["title"] = "Reach Level 60",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
		["lvl"] = 60,
	},
}

local function loadLevelEvent(_metadata)
	local _event = CreateFrame("Frame")
	ns.event[_metadata["name"]] = _event

	-- General info
	_event.name = _metadata.name
	_event.type = "Achievement"
	_event.subtype = "Leveling"
	_event.title = _metadata.title
	_event.icon_path = _metadata.icon_path
	_event.pts = 10
	_event.lvl = _metadata.lvl
	_event.description = "|cffddddddReach level |r|cffFFA500[" .. _event.lvl .. "]|r |cffdddddd."

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
	_event:SetScript("OnEvent", function(self, e, _args)
		if sent == true then
			return
		end

		if UnitLevel("Player") == _event.lvl and sent == false then
			ns.triggerEvent(_event.name)
			sent = true
		end
	end)
end

for _, v in ipairs(level_metadata) do
	loadLevelEvent(v)
end
