local addonName, ns = ...

local rarity_colors = {
	["common"] = "ffffff",
	["uncommon"] = "1eff00",
	["rare"] = "0070dd",
	["epic"] = "a335ee",
	["legendary"] = "ff8000",
}

local item_metadata = {
	{
		["item_id"] = 7098,
		["item_name"] = "Splintered Tusk",
		["rarity"] = "common",
		["pts"] = 5,
		["test_only"] = 1,
	},
	{ ["item_id"] = 8350, ["item_name"] = "The 1 Ring", ["rarity"] = "uncommon", ["pts"] = 100 },
	{ ["item_id"] = 14551, ["item_name"] = "Edgemaster's Handguards", ["rarity"] = "epic", ["pts"] = 25 },
	{ ["item_id"] = 13468, ["item_name"] = "Black Lotus", ["rarity"] = "uncommon", ["pts"] = 20 },
	{ ["item_id"] = 18706, ["item_name"] = "Arena Master", ["rarity"] = "rare", ["pts"] = 25 },
	{ ["item_id"] = 23192, ["item_name"] = "Tabard of the Scarlet Crusade", ["rarity"] = "common", ["pts"] = 25 },
	{ ["item_id"] = 19024, ["item_name"] = "Arena Grand Master", ["rarity"] = "rare", ["pts"] = 100 },
	{ ["item_id"] = 8345, ["item_name"] = "Wolfshead Helm", ["rarity"] = "rare", ["pts"] = 50, ["class"] = "Druid" },
	{ ["item_id"] = 6975, ["item_name"] = "Whirlwind Axe", ["rarity"] = "rare", ["pts"] = 50, ["class"] = "Warrior" },
	{
		["item_id"] = 16252,
		["item_name"] = "Formula: Enchant Weapon - Crusader",
		["rarity"] = "uncommon",
		["pts"] = 50,
	},
	{ ["item_id"] = 6661, ["item_name"] = "Recipe: Savory Deviate Delight", ["rarity"] = "uncommon", ["pts"] = 50 },
	{ ["item_id"] = 12717, ["item_name"] = "Plans: Lionheart Helm", ["rarity"] = "epic", ["pts"] = 50 },
	{
		["item_id"] = 13494,
		["item_name"] = "Recipe: Greater Fire Protection Potion",
		["rarity"] = "uncommon",
		["pts"] = 50,
	},
	{ ["item_id"] = 19445, ["item_name"] = "Formula: Enchant Weapon - Agility", ["rarity"] = "common", ["pts"] = 50 },
	{ ["item_id"] = 2555, ["item_name"] = "Recipe: Swiftness Potion", ["rarity"] = "uncommon", ["pts"] = 50 },
	{ ["item_id"] = 2553, ["item_name"] = "Recipe: Elixir of Minor Agility", ["rarity"] = "uncommon", ["pts"] = 50 },
	{ ["item_id"] = 6663, ["item_name"] = "Recipe: Elixir of Giant Growth", ["rarity"] = "uncommon", ["pts"] = 50 },
	{ ["item_id"] = 7054, ["item_name"] = "Robe of Power", ["rarity"] = "rare", ["pts"] = 50 },
	{ ["item_id"] = 13520, ["item_name"] = "Recipe: Flask of Distilled Wisdom", ["rarity"] = "uncommon", ["pts"] = 50 },
	{ ["item_id"] = 13521, ["item_name"] = "Recipe: Flask of Supreme Power", ["rarity"] = "uncommon", ["pts"] = 50 },
	{ ["item_id"] = 13518, ["item_name"] = "Recipe: Flask of Petrification", ["rarity"] = "uncommon", ["pts"] = 50 },
	{ ["item_id"] = 18518, ["item_name"] = "Pattern: Hide of the Wild", ["rarity"] = "epic", ["pts"] = 100 },
	{ ["item_id"] = 18519, ["item_name"] = "Pattern: Shifting Cloak", ["rarity"] = "epic", ["pts"] = 100 },
}

local function loadEvent(item_metadata)
	local _item_id = item_metadata.item_id
	local _item_name = item_metadata.item_name
	local _item_link = "|cff" .. rarity_colors[item_metadata.rarity] .. "[" .. _item_name .. "]|r"
	local _event = CreateFrame("Frame")
	local _name = "First to Find " .. _item_name
	ns.event[_name] = _event

	-- General info
	_event.name = _name
	_event.type = "Milestone"
	_event.title = _name
	_event.item_id = _item_id
	_event.subtype = "First to Find"
	_event.class = item_metadata.class
	if item_metadata.class ~= nil then
		_event.subtype = "Class"
	end
	_event.pts = item_metadata.pts
	_event.test_only = item_metadata.test_only
	_event.description = "|cffddddddBe the first to find " .. _item_link .. " |cffdddddd.|r"

	-- Aggregation
	_event.aggregrate = function(distributed_log, event_log)
		local race_name = ns.id_race[event_log[2]]
		distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
	end

	-- Custom Register
	local sent = false
	ns.item_id_obs[_event.item_id] = function()
		if sent == true then
			return
		end
		if ns.claimed_milestones[_event.name] == nil then
			local guild_name, _, _ = GetGuildInfo("Player")
			if guild_name ~= nil then
				ns.triggerEvent(_event.name)
				sent = true
			end
		end
	end
end

for _, v in ipairs(item_metadata) do
	loadEvent(v)
end
