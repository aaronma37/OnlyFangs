--
--[[
Copyright 2023 Yazpad
The Deathlog AddOn is distributed under the terms of the GNU General Public License (or the Lesser GPL).
This file is part of Hardcore.

The Deathlog AddOn is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The Deathlog AddOn is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the Deathlog AddOn. If not, see <http://www.gnu.org/licenses/>.
--]]
--
--
local _, ns = ...

ns.instance_tbl = OnlyFangs_L.instance_tbl

ns.id_to_instance_tbl = {}
for _, v in pairs(ns.instance_tbl) do
	ns.id_to_instance_tbl[v[1]] = v[3]
end

ns.zone_tbl = OnlyFangs_L.deathlog_zone_tbl

ns.class_tbl = {
	["Warrior"] = 1,
	["Paladin"] = 2,
	["Hunter"] = 3,
	["Rogue"] = 4,
	["Priest"] = 5,
	["Shaman"] = 7,
	["Mage"] = 8,
	["Warlock"] = 9,
	["Druid"] = 11,
}

ns.id_to_class_tbl = {
	[1] = "Warrior",
	[2] = "Paladin",
	[3] = "Hunter",
	[4] = "Rogue",
	[5] = "Priest",
	[7] = "Shaman",
	[8] = "Mage",
	[9] = "Warlock",
	[11] = "Druid",
}

ns.class_colors = {}
for k, _ in pairs(ns.class_tbl) do
	ns.class_colors[k] = RAID_CLASS_COLORS[string.upper(k)]
end
ns.class_colors["Shaman"] = CreateColor(36 / 255, 89 / 255, 255 / 255)

ns.race_id = {
	["Human"] = 1,
	["Orc"] = 2,
	["Dwarf"] = 3,
	["Night Elf"] = 4,
	["Undead"] = 5,
	["Tauren"] = 6,
	["Gnome"] = 7,
	["Troll"] = 8,
}
ns.id_race = {
	[1] = "Human",
	[2] = "Orc",
	[3] = "Dwarf",
	[4] = "Night Elf",
	[5] = "Undead",
	[6] = "Tauren",
	[7] = "Gnome",
	[8] = "Troll",
}

ns.class_id = {
	["Warrior"] = 1,
	["Paladin"] = 2,
	["Hunter"] = 3,
	["Rogue"] = 4,
	["Priest"] = 5,
	["Shaman"] = 7,
	["Mage"] = 8,
	["Warlock"] = 9,
	["Druid"] = 11,
}

ns.id_class = {
	[1] = "Warrior",
	[2] = "Paladin",
	[3] = "Hunter",
	[4] = "Rogue",
	[5] = "Priest",
	[7] = "Shaman",
	[8] = "Mage",
	[9] = "Warlock",
	[11] = "Druid",
}

ns.fletcher16 = function(name, race_id, entry_id, date)
	local data = name .. race_id .. entry_id .. date
	local sum1 = 0
	local sum2 = 0
	for index = 1, #data do
		sum1 = (sum1 + string.byte(string.sub(data, index, index))) % 255
		sum2 = (sum2 + sum1) % 255
	end
	return name .. "-" .. bit.bor(bit.lshift(sum2, 8), sum1)
end

ns.getVersion = function()
	local name = GetAddOnInfo("OnlyFangs")
	local version

	if version_string then
		version = version_string
	else
		version = GetAddOnMetadata(name, "Version")
	end

	local major, minor, patch = string.match(version, "(%d+)%p(%d+)%p(%d+)")
	local hash = "nil"

	local buildType

	return tonumber(major), tonumber(minor), tonumber(patch), tostring(hash), tostring(buildType)
end
ns.getVersion()

local race_in_chat_loaded = false
ns.loadRaceInChat = function()
	if race_in_chat_loaded == true then
		return
	end
	race_in_chat_loaded = true
	ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", function(frame, event, message, sender, ...)
		local _race = ""
		if ns.character_race_type and ns.character_race_type[sender] then
			if ns.character_race_type[sender] == "Tauren" then
				_race = "|TInterface\\Glues\\CHARACTERCREATE\\UI-CHARACTERCREATE-RACES:16:16:0:0:64:64:0:16:16:32|t "
			elseif ns.character_race_type[sender] == "Undead" then
				_race = "|TInterface\\Glues\\CHARACTERCREATE\\UI-CHARACTERCREATE-RACES:16:16:0:0:64:64:16:32:16:32|t "
			elseif ns.character_race_type[sender] == "Troll" then
				_race = "|TInterface\\Glues\\CHARACTERCREATE\\UI-CHARACTERCREATE-RACES:16:16:0:0:64:64:32:48:16:32|t "
			elseif ns.character_race_type[sender] == "Orc" then
				_race = "|TInterface\\Glues\\CHARACTERCREATE\\UI-CHARACTERCREATE-RACES:16:16:0:0:64:64:48:64:16:32|t "
			end
		else
			local _streamer = ns.streamer_map[sender]
			if _streamer and ns.streamer_to_race and ns.streamer_to_race[_streamer] then
				if ns.streamer_to_race[_streamer] == "Tauren" then
					_race =
						"|TInterface\\Glues\\CHARACTERCREATE\\UI-CHARACTERCREATE-RACES:16:16:0:0:64:64:0:16:16:32|t "
				elseif ns.streamer_to_race[_streamer] == "Undead" then
					_race =
						"|TInterface\\Glues\\CHARACTERCREATE\\UI-CHARACTERCREATE-RACES:16:16:0:0:64:64:16:32:16:32|t "
				elseif ns.streamer_to_race[_streamer] == "Troll" then
					_race =
						"|TInterface\\Glues\\CHARACTERCREATE\\UI-CHARACTERCREATE-RACES:16:16:0:0:64:64:32:48:16:32|t "
				elseif ns.streamer_to_race[_streamer] == "Orc" then
					_race =
						"|TInterface\\Glues\\CHARACTERCREATE\\UI-CHARACTERCREATE-RACES:16:16:0:0:64:64:48:64:16:32|t "
				end
			end
		end
		message = _race .. message
		return false, message, sender, ... -- don't hide this message
	end)
end
