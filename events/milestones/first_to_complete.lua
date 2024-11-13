local addonName, ns = ...

local quest_metadata = {
	{
		["name"] = "Hidden Enemies",
		["title"] = "First to Complete Hidden Enemies",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
		["quest_name"] = "Hidden Enemies",
		["zone"] = "Ragefire Chasm",
		["quest_id"] = 5726,
		["pts"] = 30,
	},
	{
		["name"] = "In Nightmares",
		["title"] = "First to Complete In Nightmares",
		["quest_name"] = "In Nightmares",
		["zone"] = "Wailing Caverns",
		["quest_id"] = 3369,
		["pts"] = 30,
	},
	{
		["name"] = "Arugal Must Die",
		["title"] = "First to Complete Arugal Must Die",
		["quest_name"] = "Arugal Must Die",
		["zone"] = "Shadowfang Keep",
		["quest_id"] = 1014,
		["pts"] = 30,
	},
	{
		["name"] = "Blackfathom Villainy",
		["title"] = "First to Complete Blackfathom Villainy",
		["quest_name"] = "Blackfathom Villainy",
		["zone"] = "Blackfathom Deeps",
		["quest_id"] = 6561,
		["pts"] = 30,
	},
	{
		["name"] = "A Vengeful Fate",
		["title"] = "First to Complete A Vengeful Fate",
		["quest_name"] = "A Vengeful Fate",
		["zone"] = "Razorfen Kraul",
		["quest_id"] = 1102,
		["pts"] = 30,
	},
	{
		["name"] = "Rig Wars",
		["title"] = "First to Complete Rig Wars",
		["quest_name"] = "Rig Wars",
		["zone"] = "Gnomeregan",
		["quest_id"] = 2841,
		["pts"] = 30,
	},
	{
		["name"] = "Bring the End",
		["title"] = "First to Complete Bring the End",
		["quest_name"] = "Bring the End",
		["zone"] = "Razorfen Downs",
		["quest_id"] = 3341,
		["pts"] = 30,
	},
	{
		["name"] = "Into the Scarlet Monastery",
		["title"] = "First to Complete Into the Scarlet Monastery",
		["quest_name"] = "Into the Scarlet Monastery",
		["zone"] = "Scarlet Monastery",
		["quest_id"] = 1048,
		["pts"] = 30,
	},
	{
		["name"] = "Platinum Discs",
		["title"] = "First to Complete Platinum Discs",
		["quest_name"] = "Platinum Discs",
		["zone"] = "Uldaman",
		["quest_id"] = 2440,
		["pts"] = 30,
	},
	{
		["name"] = "Gahz'rilla",
		["title"] = "First to Complete Gahz'rilla",
		["quest_name"] = "Gahz'rilla",
		["zone"] = "Uldaman",
		["quest_id"] = 2770,
		["pts"] = 30,
	},
	{
		["name"] = "Corruption of Earth and Seed",
		["title"] = "First to Complete Corruption of Earth and Seed",
		["quest_name"] = "Corruption of Earth and Seed",
		["zone"] = "Maraudon",
		["quest_id"] = 7065,
		["pts"] = 30,
	},
	{
		["name"] = "Arcane Refreshment",
		["title"] = "First to Complete Arcane Refreshment",
		["quest_name"] = "Arcane Refreshment",
		["zone"] = "Dire Maul",
		["quest_id"] = 7463,
		["pts"] = 30,
	},
	{
		["name"] = "Dreadsteed of Xoroth",
		["title"] = "First to Complete Dreadsteed of Xoroth",
		["quest_name"] = "Dreadsteed of Xoroth",
		["zone"] = "Dire Maul",
		["quest_id"] = 7631,
		["pts"] = 50,
	},
	{
		["name"] = "Master Angler",
		["title"] = "First to Complete Master Angler",
		["quest_name"] = "Master Angler",
		["zone"] = "Stranglethorn Vale",
		["quest_id"] = 8193,
		["pts"] = 50,
	},
	{
		["name"] = "Attunement to the Core",
		["title"] = "First to Complete Attunement to the Core",
		["quest_name"] = "Attunement to the Core",
		["zone"] = "Molten Core",
		["quest_id"] = 7848,
		["pts"] = 50,
	},
	{
		["name"] = "Seal of Ascension",
		["title"] = "First to Complete Seal of Ascension",
		["quest_name"] = "Seal of Ascension",
		["zone"] = "Blackrock Spire",
		["quest_id"] = 7848,
		["pts"] = 50,
	},
	{
		["name"] = "Blood of the Black Dragon Champion",
		["title"] = "First to Complete Blood of the Black Dragon Champion",
		["quest_name"] = "Blood of the Black Dragon Champion",
		["zone"] = "Onyxia's Liar",
		["quest_id"] = 6602,
		["pts"] = 50,
	},
	{
		["name"] = "The Green Hills of Stranglethorn",
		["title"] = "First to Complete The Green Hills of Stranglethorn",
		["quest_name"] = "The Green Hills of Stranglethorn",
		["zone"] = "Stranglethorn Vale",
		["quest_id"] = 338,
		["pts"] = 30,
	},
	{
		["name"] = "Big Game Hunter",
		["title"] = "First to Complete Big Game Hunter",
		["quest_name"] = "Big Game Hunter",
		["zone"] = "Stranglethorn Vale",
		["quest_id"] = 208,
		["pts"] = 15,
	},
	{
		["name"] = "The Binding",
		["title"] = "First to Complete The Binding",
		["quest_name"] = "The Binding",
		["zone"] = "Stranglethorn Vale",
		["quest_id"] = 1795,
		["pts"] = 50,
	},

	First315Skinning,
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
	_event:RegisterEvent("QUEST_TURNED_IN")

	-- Register Definitions
	local sent = false
	_event:SetScript("OnEvent", function(self, e, _args)
		if sent == true then
			return
		end
		if ns.claimed_milestones[_event.name] ~= nil then
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
