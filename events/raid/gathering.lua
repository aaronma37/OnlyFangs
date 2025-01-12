local addonName, ns = ...

local items = {
    {["name"] = "Gromsblood", ["quantity"] = 20, ["pts"] = 2},
    {["name"] = "Dreamfoil", ["quantity"] = 20, ["pts"] = 1},
    {["name"] = "Sungrass", ["quantity"] = 20, ["pts"] = 1},
    {["name"] = "Black Lotus", ["quantity"] = 1, ["pts"] = 1},
    {["name"] = "Stonescale Eel", ["quantity"] = 20, ["pts"] = 1},
    {["name"] = "Elemental Fire", ["quantity"] = 10, ["pts"] = 1}, 
    {["name"] = "Righteous Orb", ["quantity"] = 1, ["pts"] = 1}, 
}


-- pattern matching taken from https://www.wowinterface.com/downloads/info19374-ELootChatMonitor.html
-- patterns to match. {pattern, {itemIndex, quantityIndex}}
local CHAT_MSG_TABLE = {
    {LOOT_ITEM_PUSHED_SELF_MULTIPLE, {1, 2}},
    {LOOT_ITEM_PUSHED_SELF,          {1, nil}},
    {LOOT_ITEM_SELF_MULTIPLE,        {1, 2}},
    {LOOT_ITEM_SELF,                 {1, nil}},
}

local function sanitizePattern(pattern)
	pattern = string.gsub(pattern, "%(", "%%(")
	pattern = string.gsub(pattern, "%)", "%%)")
	pattern = string.gsub(pattern, "%%s", "(.+)")
	pattern = string.gsub(pattern, "%%d", "(%%d+)")
	pattern = string.gsub(pattern, "%-", "%%-")

	return pattern
end

-- Converts a format string into a pattern and list of capture group indices
-- e.g. %2$s won the %1$s
local function patternFromFormat(format)
	local pattern = ""
	local captureIndices = {}

	local start = 1
	local captureIndex = 0
	repeat
		-- find the next group
		local s, e, group, position = format:find("(%%([%d$]*)[ds])", start)
		if s then
			-- add the text between the last group and this group
			pattern = pattern..sanitizePattern(format:sub(start, s-1))
			-- update the current capture index, using the position bit in the
			-- group if it exists, otherwise just increment
			if #position > 0 then
				-- chop off the $ and convert to a number
				captureIndex = tonumber(position:sub(1, #position-1))
			else
				captureIndex = captureIndex + 1
			end
			-- add the current capture index to our list
			tinsert(captureIndices, captureIndex)
			-- remove the position bit from the group, sanitize the remainder
			-- and add it to the pattern
			pattern = pattern..sanitizePattern(group:gsub("%d%$", "", 1))
			-- start searching again from past the end of the group
			start = e + 1
		else
			-- if no more groups can be found, but there's still more text
			-- remaining in the format string, sanitize the remainder, add it
			-- to the pattern and finish the loop
			if start <= #format then
				pattern = pattern..sanitizePattern(format:sub(start))
			end
			break
		end
	until start > #format

	return pattern, captureIndices
end

-- Like string:find but uses a list of capture indices to re-order the capture
-- groups. For use with converted format strings that use positional args.
-- e.g. %2$s won the %1$s.
local function superFind(text, pattern, captureIndices)
	local results = { text:find(pattern) }
	if #results == 0 then
		return
	end

	local s, e = tremove(results, 1), tremove(results, 1)

	local captures = {}
	for _, index in ipairs(captureIndices) do
		tinsert(captures, results[index])
	end

	return s, e, unpack(captures)
end

local CONVERTED_FORMATS = {}
local function unformat(fmt, msg)
	local pattern, captureIndices
	if CONVERTED_FORMATS[fmt] then
		pattern, captureIndices = unpack(CONVERTED_FORMATS[fmt])
	else
		pattern, captureIndices = patternFromFormat(fmt)
		CONVERTED_FORMATS[fmt] = {pattern, captureIndices}
	end

	local _, _, a1, a2, a3, a4 = superFind(msg, pattern, captureIndices)
	return a1, a2, a3, a4
end

local function parseChatMessage(msg, msgtable)
	local stringValues, inputs
	for _, message in ipairs(msgtable) do
		stringValues = {unformat(message[1], msg)}
		if #stringValues > 0 then
			inputs = message[2]
            local itemLink = stringValues[inputs[1]]
            local itemName = GetItemInfo(itemLink)
			local quantity = stringValues[inputs[2]] or 1
            return itemName, quantity
		end
	end
end


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
    _event:RegisterEvent("LOOT_ITEM_ROLL_WON")
    _event:RegisterEvent("CHAT_MSG_LOOT")

    local lootInfo = nil
    local lootAllowed = false

    _event:SetScript("OnEvent", function(self, event, ...) 
        if event == "LOOT_READY" then
            lootInfo = GetLootInfo()
            lootAllowed = false
        elseif event == "LOOT_CLOSED" then
            lootInfo = nil
        elseif event == "LOOT_SLOT_CLEARED" then
            local slot = ...
            if lootInfo and slot then
                local item = lootInfo[slot].item
                if item == item_metadata.name then
                    lootAllowed = true
                end
            end
        elseif event == "LOOT_ITEM_ROLL_WON" then
            itemLink = ...
            itemName = GetItemInfo(itemLink)
            if itemName == item_metadata.name then
                lootAllowed = true
            end
        elseif event == "CHAT_MSG_LOOT" then
            local msg = ...

            if not lootAllowed then return end
            local item, quantity = parseChatMessage(msg, CHAT_MSG_TABLE)

            if item == item_metadata.name then
                OnlyFangsGatheredMaterials[item] = OnlyFangsGatheredMaterials[item] or 0
                OnlyFangsGatheredMaterials[item] = OnlyFangsGatheredMaterials[item] + quantity
                while OnlyFangsGatheredMaterials[item] >= item_metadata.quantity do
                    OnlyFangsGatheredMaterials[item] = OnlyFangsGatheredMaterials[item] - item_metadata.quantity
                    ns.triggerEvent(_event.name)
                end
                lootAllowed = false
            end
        end
    end)

end

for _, v in ipairs(items) do
	loadEvent(v)
end