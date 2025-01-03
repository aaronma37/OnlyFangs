local addonName, ns = ...

local items = {
    {["name"] = "Gromsblood", ["quantity"] = 20, ["pts"] = 2},
    {["name"] = "Dreamfoil", ["quantity"] = 20, ["pts"] = 1},
    {["name"] = "Sungrass", ["quantity"] = 20, ["pts"] = 1},
    {["name"] = "Black Lotus", ["quantity"] = 1, ["pts"] = 1},
    {["name"] = "Stonescale Eel", ["quantity"] = 20, ["pts"] = 1},
    {["name"] = "Elemental Fire", ["quantity"] = 10, ["pts"] = 1}, 
}

if not OnlyFangsGatheredMaterials then
    OnlyFangsGatheredMaterials = {}
end

local function loadEvent(item_metadata)
    local _event = CreateFrame("Frame")
	local _name = "Gather " .. item_metadata.name
	ns.event[_name] = _event

    -- General info
	_event.name = _name
	_event.type = "Raid Prep"
	_event.title = "Gather " .. tostring(item_metadata.quantity) .. " " .. item_metadata.name
	_event.pts = item_metadata.pts
    _event.repeatable = 1
	_event.description = "|cffddddddBe Gather " .. tostring(item_metadata.quantity) .. " " .. item_metadata.name .. "|cffdddddd.|r"

    -- Aggregation
	_event.aggregrate = function(distributed_log, event_log)
		local race_name = ns.id_race[event_log[2]]
		distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
	end

    _event:RegisterEvent("LOOT_READY")
    _event:RegisterEvent("LOOT_CLOSED")
    _event:RegisterEvent("LOOT_SLOT_CLEARED")

    local lootInfo = nil

    _event:SetScript("OnEvent", function(self, event, ...) 
        if event == "LOOT_READY" then
            lootInfo = GetLootInfo()
        elseif event == "LOOT_CLOSED" then
            lootInfo = nil
        elseif event == "LOOT_SLOT_CLEARED" then
            local slot = ...
            if lootInfo and slot then
                local item = lootInfo[slot].item
                if item == item_metadata.name then
                    local quantity = lootInfo[slot].quantity
                    OnlyFangsGatheredMaterials[item] = OnlyFangsGatheredMaterials[item] or 0
                    OnlyFangsGatheredMaterials[item] = OnlyFangsGatheredMaterials[item] + quantity
                    while OnlyFangsGatheredMaterials[item] >= item_metadata.quantity do
                        OnlyFangsGatheredMaterials[item] = OnlyFangsGatheredMaterials[item] - item_metadata.quantity
                        ns.triggerEvent(_event.name)
                    end
                end
            end
        end
    end)

end

for _, v in ipairs(items) do
	loadEvent(v)
end