local addonName, ns = ...
local profs = {
	["FirstAid"] = "First Aid",
	["Cooking"] = "Cooking",
	["Fishing"] = "Fishing",
	["Herbalism"] = "Herbalism",
	["Mining"] = "Mining",
	["Tailoring"] = "Tailoring",
	["Enchanting"] = "Enchanting",
	["Skinning"] = "Skinning",
	["Lockpicking"] = "Lockpicking",
	["Blacksmithing"] = "Blacksmithing",
}
local lvls = {
	75,
	150,
	225,
	300,
}

local function loadProfessionEvent(lvl, name, title)
	local _event = CreateFrame("Frame")
	ns.event[lvl .. name] = _event

	-- General info
	_event.name = lvl .. name
	_event.type = "Achievement"
	_event.title = "Reach " .. lvl .. " " .. title
	_event.profession_name = name
	_event.pts = 3
	_event.lvl = lvl
	_event.subtype = "Profession"
	_event.description = "|cffddddddReach " .. lvl .. " |r|cffFFA500[" .. _event.profession_name .. "]|r |cffdddddd.|r"

	-- Aggregation
	_event.aggregrate = function(distributed_log, event_log)
		local race_name = ns.id_race[event_log[2]]
		distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
	end

	-- Registers
	function _event:Register(succeed_function_executor)
		_event:RegisterEvent("SKILL_LINES_CHANGED")
	end

	function _event:Unregister()
		_event:UnregisterAllEvents()
	end

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
					if lvl == _event.lvl and ns.current_profession_levels == _event.lvl - 1 then
						ns.triggerEvent(_event.name)
						sent = true
					end
				end
				ns.current_profession_levels[arg] = lvl
			end
		end
	end)
end

for _, lvl in ipairs(lvls) do
	for name, title in pairs(profs) do
		loadProfessionEvent(lvl, name, title)
	end
end
