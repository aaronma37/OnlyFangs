local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.Obtain40Mount = _event

-- General info
_event.name = "Obtain40Mount"
_event.type = "Achievement"
_event.title = "Obtain 40 Mount"
_event.subtype = "GeneralAchievement"
_event.icon_path = "Interface\\ICONS\\INV_BannerPVP_01"
_event.pts = 1
_event.description = "Obtain a level 40 mount.  Mount up to get this achievement."

-- Aggregation
_event.aggregrate = function(distributed_log, event_log)
	local race_name = ns.id_race[event_log[2]]
	distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
end

local spell_list = {
	[6654] = 1, -- brown wolf
	[6653] = 1, -- dire wolf
	[580] = 1, -- timber wolf
	[23250] = 1, -- swift brown wolf
	[23252] = 1, -- swift gray wolf
	[23251] = 1, -- swift timber wolf
	[17463] = 1, --  blue skeletal horse
	[17464] = 1, -- brown skeletal horse
	[17462] = 1, -- red skeletal horse
	[17465] = 1, -- green skeletal warhorse
	[23246] = 1, -- purple skeletal warhorse
	[18992] = 1, -- teal kodo
	[18991] = 1, -- green kodo
	[18990] = 1, -- brown kodo
	[18989] = 1, -- gray kodo
	[23249] = 1, -- great brown kodo
	[23248] = 1, -- great gray kodo
	[23247] = 1, -- great white kodo
	[10796] = 1, -- turquise raptor
	[8395] = 1, -- emerald raptor
	[10799] = 1, -- violet raptor
	[23241] = 1, -- swift blue raptor
	[23242] = 1, -- swift olive raptor
	[23243] = 1, -- swift orange raptor
	[13819] = 1, -- Warhorse
	[5784] = 1, -- felsteed
}

-- Registers

-- Register Definitions
local sent = false
local _event_handler = CreateFrame("Frame")
_event_handler:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
_event_handler:SetScript("OnEvent", function(self, e, _target, _, spell_id)
	if sent == true then
		return
	end
	if spell_list[spell_id] ~= nil and _target == "player" then
		C_Timer.After(5, function()
			ns.triggerEvent(_event.name)
			sent = true
		end)
	end
end)
