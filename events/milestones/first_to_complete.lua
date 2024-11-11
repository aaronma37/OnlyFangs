local addonName, ns = ...

local quest_metadata = {
	{
		["name"] = "Hidden Enemies",
		["title"] = "First to Complete Hidden Enemies",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
		["quest_name"] = "Hidden Enemies",
		["zone"] = "Ragefire Chasm",
		["quest_id"] = 5726,
	},
	{
		["name"] = "In Nightmares",
		["title"] = "First to Complete In Nightmares",
		["quest_name"] = "In Nightmares",
		["zone"] = "Wailing Caverns",
		["quest_id"] = 3369,
	},
	{
		["name"] = "Arugal Must Die",
		["title"] = "First to Complete Arugal Must Die",
		["quest_name"] = "Arugal Must Die",
		["zone"] = "Shadowfang Keep",
		["quest_id"] = 1014,
	},
	{
		["name"] = "Blackfathom Villainy",
		["title"] = "First to Complete Blackfathom Villainy",
		["quest_name"] = "Blackfathom Villainy",
		["zone"] = "Blackfathom Deeps",
		["quest_id"] = 6561,
	},
	{
		["name"] = "A Vengeful Fate",
		["title"] = "First to Complete A Vengeful Fate",
		["quest_name"] = "A Vengeful Fate",
		["zone"] = "Razorfen Kraul",
		["quest_id"] = 1102,
	},
	{
		["name"] = "Rig Wars",
		["title"] = "First to Complete Rig Wars",
		["quest_name"] = "Rig Wars",
		["zone"] = "Gnomeregan",
		["quest_id"] = 2841,
	},
	{
		["name"] = "Into The Bring the End",
		["title"] = "First to Complete Into The Bring the End",
		["quest_name"] = "Into The Bring the End",
		["zone"] = "Razorfen Downs",
		["quest_id"] = 3341,
	},
	{
		["name"] = "Platinum Discs",
		["title"] = "First to Complete Platinum Discs",
		["quest_name"] = "Platinum Discs",
		["zone"] = "Uldaman",
		["quest_id"] = 2440,
	},
	{
		["name"] = "Gahz'rilla",
		["title"] = "First to Complete Gahz'rilla",
		["quest_name"] = "Gahz'rilla",
		["zone"] = "Uldaman",
		["quest_id"] = 2770,
	},
	{
		["name"] = "Corruption of Earth and Seed",
		["title"] = "First to Complete Corruption of Earth and Seed",
		["quest_name"] = "Corruption of Earth and Seed",
		["zone"] = "Maraudon",
		["quest_id"] = 7065,
	},
	{
		["name"] = "Arcane Refreshment",
		["title"] = "First to Complete Arcane Refreshment",
		["quest_name"] = "Arcane Refreshment",
		["zone"] = "Dire Maul",
		["quest_id"] = 7463,
	},
	{
		["name"] = "Dreadsteed of Xoroth",
		["title"] = "First to Complete Dreadsteed of Xoroth",
		["quest_name"] = "Dreadsteed of Xoroth",
		["zone"] = "Dire Maul",
		["quest_id"] = 7631,
	},
}

local function loadQuestEvent(_metadata)
	local _event = CreateFrame("Frame")
	ns.event[_metadata["name"]] = _event

	-- General info
	_event.name = _metadata.name
	_event.zone = _metadata.zone
	_event.quest_name = _metadata.quest_name
	_event.type = "Milestone"
	_event.title = _metadata.title
	_event.icon_path = _metadata.icon_path
	_event.pts = 10
	_event.subtype = "First to Complete"
	_event.description = "|cffddddddBe the first to complete |r|cffFFA500[" .. _event.quest_name .. "]|r |cffdddddd."

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
		if sent == true then
			return
		end
		if ns.claimed_milestones[_event.name] == nil then
			return
		end
		if e == "QUEST_TURNED_IN" then
			if _args[1] ~= nil and _args[1] == _event.quest_id then
				ns.triggerEvent(_event.name)
				sent = true
			end
		end
	end)
end

for _, v in ipairs(quest_metadata) do
	loadQuestEvent(v)
end
