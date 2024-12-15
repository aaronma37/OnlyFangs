local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.Get40Mount = _event

-- General info
_event.name = "Get40Mount"
_event.type = "Achievement"
_event.title = "Obtain 40 Mount"
_event.subtype = "GeneralAchievement"
_event.icon_path = "Interface\\ICONS\\INV_BannerPVP_01"
_event.pts = 1
_event.description = "Obtain a level 40 mount."

-- Aggregation
_event.aggregrate = function(distributed_log, event_log)
	local race_name = ns.id_race[event_log[2]]
	distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
end

local spell_list = {
	[6654] = 1,
	[6653] = 1,
	[580] = 1,
	[17463] = 1,
	[17464] = 1,
	[18990] = 1,
	[18990] = 1,
	[18989] = 1,
	[10796] = 1,
	[10799] = 1,
	[13819] = 1,
	[5784] = 1,
}

-- Registers

-- Register Definitions
local sent = false
local _event_handler = CreateFrame("Frame")
_event_handler:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
_event_handler:SetScript("OnEvent", function(self, e, _, _, spell_id)
	if sent == true then
		return
	end
	if spell_list[spell_id] ~= nil then
		ns.triggerEvent(_event.name)
		sent = true
	end
end)
