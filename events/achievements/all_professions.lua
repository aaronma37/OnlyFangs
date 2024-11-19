local addonName, ns = ...
local profs = {
	["1Unarmed"] = { ["name"] = "Unarmed", ["lvl"] = 2, ["test_only"] = 1 },
	["1FirstAid"] = { ["name"] = "First Aid", ["lvl"] = 2, ["test_only"] = 1 },
	["75FirstAid"] = { ["name"] = "First Aid", ["lvl"] = 75 },
	["150FirstAid"] = { ["name"] = "First Aid", ["lvl"] = 150 },
	["225FirstAid"] = { ["name"] = "First Aid", ["lvl"] = 225 },
	["300FirstAid"] = { ["name"] = "First Aid", ["lvl"] = 300 },
	["1Cooking"] = { ["name"] = "Cooking", ["lvl"] = 2, ["test_only"] = 1 },
	["75Cooking"] = { ["name"] = "Cooking", ["lvl"] = 75 },
	["150Cooking"] = { ["name"] = "Cooking", ["lvl"] = 150 },
	["225Cooking"] = { ["name"] = "Cooking", ["lvl"] = 225 },
	["300Cooking"] = { ["name"] = "Cooking", ["lvl"] = 300 },
	["1Fishing"] = { ["name"] = "Fishing", ["lvl"] = 2, ["test_only"] = 1 },
	["75Fishing"] = { ["name"] = "Fishing", ["lvl"] = 75 },
	["150Fishing"] = { ["name"] = "Fishing", ["lvl"] = 150 },
	["225Fishing"] = { ["name"] = "Fishing", ["lvl"] = 225 },
	["300Fishing"] = { ["name"] = "Fishing", ["lvl"] = 300 },
	["1Herbalism"] = { ["name"] = "Herbalism", ["lvl"] = 2, ["test_only"] = 1 },
	["75Herbalism"] = { ["name"] = "Herbalism", ["lvl"] = 75 },
	["150Herbalism"] = { ["name"] = "Herbalism", ["lvl"] = 150 },
	["225Herbalism"] = { ["name"] = "Herbalism", ["lvl"] = 225 },
	["300Herbalism"] = { ["name"] = "Herbalism", ["lvl"] = 300 },
	["1Mining"] = { ["name"] = "Mining", ["lvl"] = 2, ["test_only"] = 1 },
	["75Mining"] = { ["name"] = "Mining", ["lvl"] = 75 },
	["150Mining"] = { ["name"] = "Mining", ["lvl"] = 150 },
	["225Mining"] = { ["name"] = "Mining", ["lvl"] = 225 },
	["300Mining"] = { ["name"] = "Mining", ["lvl"] = 300 },
	["1Tailoring"] = { ["name"] = "Tailoring", ["lvl"] = 2, ["test_only"] = 1 },
	["75Tailoring"] = { ["name"] = "Tailoring", ["lvl"] = 75 },
	["150Tailoring"] = { ["name"] = "Tailoring", ["lvl"] = 150 },
	["225Tailoring"] = { ["name"] = "Tailoring", ["lvl"] = 225 },
	["300Tailoring"] = { ["name"] = "Tailoring", ["lvl"] = 300 },
	["1Enchanting"] = { ["name"] = "Enchanting", ["lvl"] = 2, ["test_only"] = 1 },
	["75Enchanting"] = { ["name"] = "Enchanting", ["lvl"] = 75 },
	["150Enchanting"] = { ["name"] = "Enchanting", ["lvl"] = 150 },
	["225Enchanting"] = { ["name"] = "Enchanting", ["lvl"] = 225 },
	["300Enchanting"] = { ["name"] = "Enchanting", ["lvl"] = 300 },
	["1Skinning"] = { ["name"] = "Skinning", ["lvl"] = 2, ["test_only"] = 1 },
	["75Skinning"] = { ["name"] = "Skinning", ["lvl"] = 75 },
	["150Skinning"] = { ["name"] = "Skinning", ["lvl"] = 150 },
	["225Skinning"] = { ["name"] = "Skinning", ["lvl"] = 225 },
	["300Skinning"] = { ["name"] = "Skinning", ["lvl"] = 300 },
	["1Lockpicking"] = { ["name"] = "Lockpicking", ["lvl"] = 2, ["test_only"] = 1 },
	["75Lockpicking"] = { ["name"] = "Lockpicking", ["lvl"] = 75 },
	["150Lockpicking"] = { ["name"] = "Lockpicking", ["lvl"] = 150 },
	["225Lockpicking"] = { ["name"] = "Lockpicking", ["lvl"] = 225 },
	["300Lockpicking"] = { ["name"] = "Lockpicking", ["lvl"] = 300 },
	["1Blacksmithing"] = { ["name"] = "Blacksmithing", ["lvl"] = 2, ["test_only"] = 1 },
	["75Blacksmithing"] = { ["name"] = "Blacksmithing", ["lvl"] = 75 },
	["150Blacksmithing"] = { ["name"] = "Blacksmithing", ["lvl"] = 150 },
	["225Blacksmithing"] = { ["name"] = "Blacksmithing", ["lvl"] = 225 },
	["300Blacksmithing"] = { ["name"] = "Blacksmithing", ["lvl"] = 300 },
	["1Alchemy"] = { ["name"] = "Alchemy", ["lvl"] = 2, ["test_only"] = 1 },
	["75Alchemy"] = { ["name"] = "Alchemy", ["lvl"] = 75 },
	["150Alchemy"] = { ["name"] = "Alchemy", ["lvl"] = 150 },
	["225Alchemy"] = { ["name"] = "Alchemy", ["lvl"] = 225 },
	["300Alchemy"] = { ["name"] = "Alchemy", ["lvl"] = 300 },
	["1Engineering"] = { ["name"] = "Engineering", ["lvl"] = 2, ["test_only"] = 1 },
	["75Engineering"] = { ["name"] = "Engineering", ["lvl"] = 75 },
	["150Engineering"] = { ["name"] = "Engineering", ["lvl"] = 150 },
	["225Engineering"] = { ["name"] = "Engineering", ["lvl"] = 225 },
	["300Engineering"] = { ["name"] = "Engineering", ["lvl"] = 300 },
	["1Leatherworking"] = { ["name"] = "Leatherworking", ["lvl"] = 2, ["test_only"] = 1 },
	["75Leatherworking"] = { ["name"] = "Leatherworking", ["lvl"] = 75 },
	["150Leatherworking"] = { ["name"] = "Leatherworking", ["lvl"] = 150 },
	["225Leatherworking"] = { ["name"] = "Leatherworking", ["lvl"] = 225 },
	["300Leatherworking"] = { ["name"] = "Leatherworking", ["lvl"] = 300 },
}

ns.profession_menu_order = {
	"75Blacksmithing",
	"150Blacksmithing",
	"225Blacksmithing",
	"300Blacksmithing",
	"75Skinning",
	"150Skinning",
	"225Skinning",
	"300Skinning",
	"75Lockpicking",
	"150Lockpicking",
	"225Lockpicking",
	"300Lockpicking",
	"75Enchanting",
	"150Enchanting",
	"225Enchanting",
	"300Enchanting",
	"75Tailoring",
	"150Tailoring",
	"225Tailoring",
	"300Tailoring",
	"75Mining",
	"150Mining",
	"225Mining",
	"300Mining",
	"75Herbalism",
	"150Herbalism",
	"225Herbalism",
	"300Herbalism",
	"75Fishing",
	"150Fishing",
	"225Fishing",
	"300Fishing",
	"75Cooking",
	"150Cooking",
	"225Cooking",
	"300Cooking",
	"75FirstAid",
	"150FirstAid",
	"225FirstAid",
	"300FirstAid",
	"75Alchemy",
	"150Alchemy",
	"225Alchemy",
	"300Alchemy",
	"75Engineering",
	"150Engineering",
	"225Engineering",
	"300Engineering",
	"75Leatherworking",
	"150Leatherworking",
	"225Leatherworking",
	"300Leatherworking",
}

local professions_ex = {}

local function loadProfessionEvent(name, metadata)
	local _event = CreateFrame("Frame")
	ns.event[name] = _event

	-- General info
	_event.name = name
	_event.type = "Achievement"
	_event.title = "Reach " .. metadata.lvl .. " " .. metadata.name
	_event.profession_name = metadata.name
	_event.pts = 3
	_event.test_only = metadata.test_only
	_event.lvl = metadata.lvl
	_event.subtype = "Profession"
	_event.ex_string = ERR_SKILL_UP_SI:gsub("%%s", _event.profession_name)
	_event.ex_string = _event.ex_string:gsub("%%d", _event.lvl)
	_event.description = "|cffddddddReach "
		.. metadata.lvl
		.. " |r|cffFFA500["
		.. _event.profession_name
		.. "]|r |cffdddddd.|r"

	-- Aggregation
	_event.aggregrate = function(distributed_log, event_log)
		local race_name = ns.id_race[event_log[2]]
		distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
	end

	-- Register Definitions
	local sent = false

	professions_ex[_event.ex_string] = function()
		if sent == true then
			return
		end
		ns.triggerEvent(_event.name)
		sent = true
	end
end

for k, v in pairs(profs) do
	loadProfessionEvent(k, v)
end

local _prof_event_handler = CreateFrame("Frame")
_prof_event_handler:RegisterEvent("CHAT_MSG_SKILL")
_prof_event_handler:SetScript("OnEvent", function(self, e, _text)
	if professions_ex[_text] then
		professions_ex[_text]()
	end
end)
