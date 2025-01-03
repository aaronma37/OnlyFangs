local addonName, ns = ...

local target_metadata = {
    {["target_name"] = "Emperor Dagran Thaurissan", ["dungeon_name"] = "Blackrock Depths", ["pts"] = 1},
    {["target_name"] = "Overlord Wyrmthalak", ["dungeon_name"] = "Lower Blackrock Spire", ["pts"] = 1},
    {["target_name"] = "General Drakkisath", ["dungeon_name"] = "Upper Blackrock Spire", ["pts"] = 1},
    {["target_name"] = "Darkmaster Gandling", ["dungeon_name"] = "Scholomance", ["pts"] = 1},
    {["target_name"] = "Balnazzar", ["dungeon_name"] = "Stratholme (Live)", ["pts"] = 1},
    {["target_name"] = "Baron Rivendare", ["dungeon_name"] = "Stratholme (Undead)", ["pts"] = 1},
    {["target_name"] = "Alzzin the Wildshaper", ["dungeon_name"] = "Dire Maul East", ["pts"] = 1},
    {["target_name"] = "Prince Tortheldrin", ["dungeon_name"] = "Dire Maul West", ["pts"] = 1},
    {["target_name"] = "King Gordok", ["dungeon_name"] = "Dire Maul North", ["pts"] = 1},
}

local function loadEvent(target_metadata)
	local _event = CreateFrame("Frame")
	local _name = target_metadata.dungeon_name
	ns.event[_name] = _event

	-- General info
	_event.name = _name
	_event.type = "Raid Prep"
	_event.title = _name
	_event.pts = target_metadata.pts
	_event.test_only = target_metadata.test_only
    _event.repeatable = 1
	_event.description = "|cffddddddBe" .. target_metadata.dungeon_name .. " |cffdddddd.|r"

	-- Aggregation
	_event.aggregrate = function(distributed_log, event_log)
		local race_name = ns.id_race[event_log[2]]
		distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
	end

	-- Custom Register
	ns.unit_died_exec[target_metadata.target_name] = function()
        ns.triggerEvent(_event.name)
	end
end

for _, v in ipairs(target_metadata) do
	loadEvent(v)
end