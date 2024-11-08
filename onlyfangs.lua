--[[
Copyright 2023 Yazpad
The Deathlog AddOn is distributed under the terms of the GNU General Public License (or the Lesser GPL).
This file is part of Deathlog.

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
local addonName, ns = ...

-- Entry: (event_id, player, time, faction)
ns.recent_level_up = nil -- KEEP GLOBAL
local last_attack_source = nil
local recent_msg = nil

deathlog_data = deathlog_data or {}

local onlyfangs_minimap_button_stub = nil
local onlyfangs_minimap_button_info = {}
local onlyfangs_minimap_button = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
	type = "data source",
	text = addonName,
	icon = "Interface\\TARGETINGFRAME\\UI-TargetingFrame-Skull",
	OnClick = function(self, btn)
		if btn == "LeftButton" then
			ns.showMenu()
		else
			InterfaceAddOnsList_Update()
			InterfaceOptionsFrame_OpenToCategory(addonName)
		end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:AddLine(addonName)
		tooltip:AddLine(Deathlog_L.minimap_btn_left_click)
		tooltip:AddLine(Deathlog_L.minimap_btn_right_click .. GAMEOPTIONS_MENU)
	end,
})
local function initMinimapButton()
	onlyfangs_minimap_button_stub = LibStub("LibDBIcon-1.0", true)
	if onlyfangs_minimap_button_stub:IsRegistered("OnlyFangs") then
		return
	end
	onlyfangs_minimap_button_stub:Register("OnlyFangs", onlyfangs_minimap_button, onlyfangs_minimap_button_info)
end

local function handleEvent(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		initMinimapButton()
	elseif event == "PLAYER_LEVEL_UP" then
		ns.recent_level_up = 1
		C_Timer.After(3, function()
			ns.recent_level_up = nil
		end)
	elseif event == "ADDON_LOADED" then
		print(OnlyFangsDistributedLog)
		OnlyFangsDistributedLog = OnlyFangsDistributedLog or {}
		ns.distributed_log = OnlyFangsDistributedLog
		ns.loadDistributedLog()
		ns.fakeEntries()
	end
end

local deathlog_event_handler = CreateFrame("Frame", "OnlyFangs", nil, "BackdropTemplate")
deathlog_event_handler:RegisterEvent("PLAYER_ENTERING_WORLD")
deathlog_event_handler:RegisterEvent("PLAYER_LEVEL_UP")
deathlog_event_handler:RegisterEvent("ADDON_LOADED")

deathlog_event_handler:SetScript("OnEvent", handleEvent)

local LSM30 = LibStub("LibSharedMedia-3.0", true)
local options = {
	name = "OnlyFangs",
	handler = OnlyFangs,
	type = "group",
	args = {},
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("OnlyFangs", options)
optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("OnlyFangs", "OnlyFangs", nil)

ns.checkEvents()
