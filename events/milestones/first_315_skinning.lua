local addonName, ns = ...

local _event = CreateFrame("Frame")
ns.event.First315Skinning = _event

-- General info
_event.name = "First315Skinning"
_event.type = "Milestone"
_event.title = "1st 315 Skinning"
_event.icon_path = "Interface\\ICONS\\INV_BannerPVP_01"
_event.pts = 100
_event.description = "First to reach 315 skinning gets this milestone!"
_event.subtype = "General"

-- Aggregation
_event.aggregrate = function(distributed_log, event_log)
	local race_name = ns.id_race[event_log[2]]
	distributed_log.points[race_name] = distributed_log.points[race_name] + _event.pts
end

local sent = false
local function triggerCondition()
	ns.item_id_obs[_event.item_id] = function()
		if sent == true then
			return
		end
		if ns.claimed_milestones[_event.name] == nil then
			for bag = 0, 5 do
				for slot = 0, 16 do
					local item_id = C_Container.GetContainerItemID(bag, slot)
					if item_id == 12709 then
						local item_link = GetContainerItemLink(bag, slot)
						local _, ench_id, gem1, gem2, gem3, gem4 =
							item_link:match("item:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)")
						if ench_id == 865 then
							ns.triggerEvent(_event.name)
							sent = true
						end
					end
				end
			end
		end
	end
end

for _, v in ipairs({ 12709 }) do
	ns.item_id_obs[v] = function()
		triggerCondition()
	end
end
