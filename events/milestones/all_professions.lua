local addonName, ns = ...

local profession_metadata = {
	{
		["name"] = "FirstTo300FirstAid",
		["title"] = "1st to 300 First Aid",
		["profession_name"] = "First Aid",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
	},
	{
		["name"] = "FirstTo300Cooking",
		["title"] = "1st to 300 Cooking",
		["profession_name"] = "Cooking",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
	},
	{
		["name"] = "FirstTo300Fishing",
		["title"] = "1st to 300 Fishing",
		["profession_name"] = "Fishing",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
	},
	{
		["name"] = "FirstTo300Herbalism",
		["title"] = "1st to 300 Herbalism",
		["profession_name"] = "Herbalism",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
	},
	{
		["name"] = "FirstTo300Mining",
		["title"] = "1st to 300 Mining",
		["profession_name"] = "Mining",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
	},
	{
		["name"] = "FirstTo300Tailoring",
		["title"] = "1st to 300 Tailoring",
		["profession_name"] = "Tailoring",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
	},
	{
		["name"] = "FirstTo300Enchanting",
		["title"] = "1st to 300 Enchanting",
		["profession_name"] = "Enchanting",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
	},
	{
		["name"] = "FirstTo300Skinning",
		["title"] = "1st to 300 Skinning",
		["profession_name"] = "Skinning",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
	},
	{
		["name"] = "FirstTo300Lockpicking",
		["title"] = "1st to 300 Lockpicking",
		["profession_name"] = "Lockpicking",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
	},
	{
		["name"] = "FirstTo300Blacksmithing",
		["title"] = "1st to 300 Blacksmithing",
		["profession_name"] = "Blacksmithing",
		["icon_path"] = "Interface\\ICONS\\Spell_Frost_IceClaw",
	},
}

local function loadProfessionEvent(_metadata)
	local _event = CreateFrame("Frame")
	ns.event[_metadata["name"]] = _event

	-- General info
	_event.name = _metadata.name
	_event.type = "Milestone"
	_event.title = _metadata.title
	_event.icon_path = _metadata.icon_path
	_event.profession_name = _metadata.profession_name
	_event.subtype = "First to Max Profession"
	_event.pts = 50
	_event.description = "|cffddddddBe the first to reach 300 |r|cffFFA500["
		.. _event.profession_name
		.. "]|r |cffdddddd.|r"

	-- Aggregation
	_event.aggregrate = function(distributed_log, event_log)
		local race_name = ns.id_race[event_log[2]]
		distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
	end

	-- Registers
	_event:RegisterEvent("SKILL_LINES_CHANGED")

	-- Register Definitions
	local sent = false
	_event:SetScript("OnEvent", function(self, e, ...)
		if sent == true then
			return
		end
		if ns.claimed_milestones[_event.name] == nil then
			return
		end

		if _event == "SKILL_LINES_CHANGED" then
			for i = 1, GetNumSkillLines() do
				local arg, _, _, lvl = GetSkillLineInfo(i)
				if arg == _event.profession_name then
					if lvl >= 300 then
						ns.triggerEvent(_event.name)
						sent = true
					end
				end
			end
		end
	end)
end

for _, v in ipairs(profession_metadata) do
	loadProfessionEvent(v)
end
