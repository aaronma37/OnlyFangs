local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.FirstEpicBOE = _event

-- General info
_event.name = "FirstEpicBOE"
_event.type = "Milestone"
_event.title = "1st Epic BoE"
_event.icon_path = "Interface\\ICONS\\INV_BannerPVP_01"
_event.pts = 100
_event.description = "First to obtain an epic BoE world drop gets this milestone!"
_event.subtype = "General"

-- Aggregation
_event.aggregrate = function(distributed_log, event_log)
	local race_name = ns.id_race[event_log[2]]
	distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
end

local world_epic_boes = {
	14551,
	873,
	871,
	18665,
	1168,
	810,
	1728,
	2244,
	1982,
	809,
	2291,
	2164,
	14555,
	2825,
	943,
	14554,
	942,
	870,
	2100,
	2243,
	2246,
	811,
	2099,
	1980,
	869,
	2824,
	2163,
	647,
	1204,
	20698,
	3075,
	14549,
	14553,
	812,
	944,
	940,
	14552,
	1315,
	3475,
	2801,
	867,
	1979,
	1263,
	2915,
	14557,
	16861,
	2245,
	833,
	868,
	16827,
	16857,
	1981,
	1169,
	1447,
	16806,
	16828,
	16799,
	16802,
	16850,
	16851,
	16838,
	16864,
	16819,
	16804,
	16825,
	16817,
	16858,
	17007,
	16840,
	16830,
	14558,
	1443,
}
-- Register Definitions
local sent = false
local function triggerCondition()
	if sent == true then
		return
	end
	if ns.claimed_milestones[_event.name] == nil then
		ns.triggerEvent(_event.name)
		sent = true
	end
end

for _, v in ipairs(world_epic_boes) do
	ns.item_id_epic_obs[v] = function()
		triggerCondition()
	end
end
