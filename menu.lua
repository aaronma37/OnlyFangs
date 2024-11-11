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

local addonName, ns = ...

local _menu_width = 1100
local _inner_menu_width = 800
local _menu_height = 600
local current_map_id = nil
local max_rows = 25
local page_number = 1
local environment_damage = {
	[-2] = "Drowning",
	[-3] = "Falling",
	[-4] = "Fatigue",
	[-5] = "Fire",
	[-6] = "Lava",
	[-7] = "Slime",
}

local main_font = Deathlog_L.main_font

local deathlog_tabcontainer = nil

local class_tbl = ns.class_tbl
local race_tbl = ns.race_id
local zone_tbl = deathlog_zone_tbl
local instance_tbl = Deathlog_L.instance_map

local deathlog_menu = nil

local WorldMapButton = WorldMapFrame:GetCanvas()
local death_tomb_frame = CreateFrame("frame", nil, WorldMapButton)
death_tomb_frame:SetAllPoints()
death_tomb_frame:SetFrameLevel(15000)

local death_tomb_frame_tex = death_tomb_frame:CreateTexture(nil, "OVERLAY")
death_tomb_frame_tex:SetTexture("Interface\\TARGETINGFRAME\\UI-TargetingFrame-Skull")
death_tomb_frame_tex:SetDrawLayer("OVERLAY", 4)
death_tomb_frame_tex:SetHeight(25)
death_tomb_frame_tex:SetWidth(25)
death_tomb_frame_tex:Hide()

local death_tomb_frame_tex_glow = death_tomb_frame:CreateTexture(nil, "OVERLAY")
death_tomb_frame_tex_glow:SetTexture("Interface\\Glues/Models/UI_HUMAN/GenericGlow64")
death_tomb_frame_tex_glow:SetDrawLayer("OVERLAY", 3)
death_tomb_frame_tex_glow:SetHeight(55)
death_tomb_frame_tex_glow:SetWidth(55)
death_tomb_frame_tex_glow:Hide()

local function WPDropDownDemo_Menu(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()

	if death_tomb_frame.map_id and death_tomb_frame.coordinates then
	end

	local function openWorldMap()
		if not (death_tomb_frame.map_id and death_tomb_frame.coordinates) then
			return
		end
		if C_Map.GetMapInfo(death_tomb_frame["map_id"]) == nil then
			return
		end
		if tonumber(death_tomb_frame.coordinates[1]) == nil or tonumber(death_tomb_frame.coordinates[2]) == nil then
			return
		end

		WorldMapFrame:SetShown(not WorldMapFrame:IsShown())
		WorldMapFrame:SetMapID(death_tomb_frame.map_id)
		WorldMapFrame:GetCanvas()
		local mWidth, mHeight = WorldMapFrame:GetCanvas():GetSize()
		death_tomb_frame_tex:SetPoint(
			"CENTER",
			WorldMapButton,
			"TOPLEFT",
			mWidth * death_tomb_frame.coordinates[1],
			-mHeight * death_tomb_frame.coordinates[2]
		)
		death_tomb_frame_tex:Show()

		death_tomb_frame_tex_glow:SetPoint(
			"CENTER",
			WorldMapButton,
			"TOPLEFT",
			mWidth * death_tomb_frame.coordinates[1],
			-mHeight * death_tomb_frame.coordinates[2]
		)
		death_tomb_frame_tex_glow:Show()
		death_tomb_frame:Show()
		deathlog_menu:Hide()
	end

	local function blockUser()
		if death_tomb_frame.clicked_name then
			local added = C_FriendList.AddIgnore(death_tomb_frame.clicked_name)
		end
	end

	if level == 1 then
		info.text, info.hasArrow, info.func, info.disabled = "Show death location", false, openWorldMap, false
		UIDropDownMenu_AddButton(info)
		info.text, info.hasArrow, info.func, info.disabled = "Block user", false, blockUser, false
		UIDropDownMenu_AddButton(info)
	end
end

hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
	death_tomb_frame:Hide()
end)

local subtitle_data = {
	{
		"Date",
		105,
		function(_entry, _server_name)
			return date("%m/%d/%y, %H:%M", _entry["date"]) or ""
		end,
	},
	{
		"Name",
		90,
		function(_entry, _server_name)
			return _entry["name"] or ""
		end,
	},
	{
		"Class",
		60,
		function(_entry, _server_name)
			if _entry["class_id"] == nil then
				return ""
			end
			local class_id = _entry["class_id"]
			local class_str, _, _ = GetClassInfo(class_id)
			if class_id then
				if deathlog_id_to_class_tbl[class_id] then
					if RAID_CLASS_COLORS[deathlog_id_to_class_tbl[class_id]:upper()] then
						return "|c"
							.. RAID_CLASS_COLORS[deathlog_id_to_class_tbl[class_id]:upper()].colorStr
							.. class_str
							.. "|r"
					end
				end
			end
			return class_str or ""
		end,
	},
	{
		"Race",
		60,
		function(_entry, _server_name)
			if _entry["race_id"] == nil then
				return ""
			end
			local race_info = C_CreatureInfo.GetRaceInfo(_entry["race_id"])
			if race_info then
				return race_info.raceName or ""
			end
			return ""
		end,
	},
	{
		"Points",
		120,
		function(_entry, _server_name)
			return _entry["guild"] or ""
		end,
	},
	{
		"Type",
		200,
		function(_entry, _server_name)
			if _entry["map_id"] == nil then
				if _entry["instance_id"] ~= nil then
					return deathlog_id_to_instance_tbl[_entry["instance_id"]] or _entry["instance_id"]
				else
					return "-----------"
				end
			end
			local map_info = C_Map.GetMapInfo(_entry["map_id"])
			if map_info then
				return map_info.name
			end
			return "-----------"
		end,
	},
	{
		"Event",
		200,
		function(_entry, _server_name)
			if _entry["map_id"] == nil then
				if _entry["instance_id"] ~= nil then
					return deathlog_id_to_instance_tbl[_entry["instance_id"]] or _entry["instance_id"]
				else
					return "-----------"
				end
			end
			local map_info = C_Map.GetMapInfo(_entry["map_id"])
			if map_info then
				return map_info.name
			end
			return "-----------"
		end,
	},
}

local AceGUI = LibStub("AceGUI-3.0")

local font_container = CreateFrame("Frame")
font_container:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
font_container:SetSize(100, 100)
font_container:Show()
local row_entry = {}
local font_strings = {} -- idx/columns
local header_strings = {} -- columns
local row_backgrounds = {} --idx

for idx, v in ipairs(subtitle_data) do
	header_strings[v[1]] = font_container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if idx == 1 then
		header_strings[v[1]]:SetPoint("LEFT", font_container, "LEFT", 0, 0)
	else
		header_strings[v[1]]:SetPoint("LEFT", last_font_string, "RIGHT", 0, 0)
	end
	last_font_string = header_strings[v[1]]
	header_strings[v[1]]:SetJustifyH("LEFT")
	header_strings[v[1]]:SetWordWrap(false)

	if idx + 1 <= #subtitle_data then
		header_strings[v[1]]:SetWidth(v[2])
	end
	header_strings[v[1]]:SetTextColor(0.7, 0.7, 0.7)
	header_strings[v[1]]:SetFont(main_font, 12, "")
end

for i = 1, max_rows do
	font_strings[i] = {}
	local last_font_string = nil
	for idx, v in ipairs(subtitle_data) do
		font_strings[i][v[1]] = font_container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		if idx == 1 then
			font_strings[i][v[1]]:SetPoint("LEFT", font_container, "LEFT", 0, 0)
		else
			font_strings[i][v[1]]:SetPoint("LEFT", last_font_string, "RIGHT", 0, 0)
		end
		last_font_string = font_strings[i][v[1]]
		font_strings[i][v[1]]:SetJustifyH("LEFT")
		font_strings[i][v[1]]:SetWordWrap(false)

		if idx + 1 <= #subtitle_data then
			font_strings[i][v[1]]:SetWidth(v[2])
		end
		font_strings[i][v[1]]:SetTextColor(1, 1, 1)
		font_strings[i][v[1]]:SetFont(main_font, 10, "")
	end

	row_backgrounds[i] = font_container:CreateTexture(nil, "OVERLAY")
	row_backgrounds[i]:SetDrawLayer("OVERLAY", 2)
	row_backgrounds[i]:SetVertexColor(0.5, 0.5, 0.5, (i % 2) / 10)
	row_backgrounds[i]:SetHeight(16)
	row_backgrounds[i]:SetWidth(1600)
	row_backgrounds[i]:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
end

local function clearDeathlogMenuLogData()
	for i, v in ipairs(font_strings) do
		for _, col in ipairs(subtitle_data) do
			v[col[1]]:SetText("")
		end
	end
end

local function setLogData()
	local list = ns.logAsList()
	for i = 1, max_rows do
		local idx = (i + (page_number - 1) * max_rows)
		if idx > #list then
			break
		end

		local _event = list[idx]
		local _event_name = ns.eventName(_event["Event"])
		font_strings[i]["Name"]:SetText(_event["Name"])
		font_strings[i]["Date"]:SetText(_event["Date"])
		font_strings[i]["Race"]:SetText(_event["Race"])
		font_strings[i]["Class"]:SetText(_event["Class"])
		font_strings[i]["Event"]:SetText(_event_name)
		font_strings[i]["Type"]:SetText(ns.event[_event_name].type)
		font_strings[i]["Points"]:SetText(ns.event[_event_name].pts)
	end
end

local _stats = {}
local _log_normal_params = {}
local initialized = false

local function drawLogTab(container)
	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("Fill")
	deathlog_tabcontainer:AddChild(scroll_container)

	local name_filter = nil
	local guidl_filter = nil
	local class_filter = nil
	local race_filter = nil
	local zone_filter = nil
	local min_level_filter = nil
	local max_level_filter = nil
	local death_source_filter = nil
	local last_words_filter = nil
	local filter = function(server_name, _entry)
		if name_filter ~= nil then
			if name_filter(server_name, _entry) == false then
				return false
			end
		end
		if min_level_filter ~= nil then
			if min_level_filter(server_name, _entry) == false then
				return false
			end
		end
		if max_level_filter ~= nil then
			if max_level_filter(server_name, _entry) == false then
				return false
			end
		end
		if death_source_filter ~= nil then
			if death_source_filter(server_name, _entry) == false then
				return false
			end
		end
		if class_filter ~= nil then
			if class_filter(server_name, _entry) == false then
				return false
			end
		end
		if race_filter ~= nil then
			if race_filter(server_name, _entry) == false then
				return false
			end
		end
		if zone_filter ~= nil then
			if zone_filter(server_name, _entry) == false then
				return false
			end
		end
		if guild_filter ~= nil then
			if guild_filter(server_name, _entry) == false then
				return false
			end
		end
		if last_words_filter ~= nil then
			if last_words_filter(server_name, _entry) == false then
				return false
			end
		end
		return true
	end

	local scroll_frame = AceGUI:Create("ScrollFrame")
	scroll_frame:SetLayout("Flow")
	scroll_container:AddChild(scroll_frame)

	local header_frame = AceGUI:Create("InlineGroup")
	header_frame:SetLayout("Flow")
	header_frame:SetFullWidth(true)
	header_frame:SetHeight(100)
	scroll_frame:AddChild(header_frame)

	local score1 = AceGUI:Create("InteractiveLabel")
	score1:SetWidth(100)
	score1:SetHeight(60)
	score1:SetText("   " .. ns.getScore("Tauren") .. " pts")
	score1:SetImage("Interface\\Glues/CHARACTERCREATE\\UI-CHARACTERCREATE-RACES.PNG")
	score1.image:SetTexCoord(0, 0.25, 0.25, 0.5)
	score1:SetImageSize(50, 50)
	score1.label:SetFont(main_font, 14, "")
	header_frame:AddChild(score1)

	local space1 = AceGUI:Create("Label")
	space1:SetWidth(140)
	space1:SetHeight(60)
	header_frame:AddChild(space1)

	local score2 = AceGUI:Create("InteractiveLabel")
	score2:SetWidth(100)
	score2:SetHeight(60)
	score2:SetText("   " .. ns.getScore("Undead") .. " pts")
	score2:SetImage("Interface\\Glues/CHARACTERCREATE\\UI-CHARACTERCREATE-RACES.PNG")
	score2.image:SetTexCoord(0.25, 0.5, 0.25, 0.5)
	score2:SetImageSize(50, 50)
	score2.label:SetFont(main_font, 14, "")
	header_frame:AddChild(score2)

	local space2 = AceGUI:Create("Label")
	space2:SetWidth(140)
	space2:SetHeight(60)
	header_frame:AddChild(space2)

	local score3 = AceGUI:Create("InteractiveLabel")
	score3:SetWidth(100)
	score3:SetHeight(60)
	score3:SetText("   " .. ns.getScore("Troll") .. " pts")
	score3:SetImage("Interface\\Glues/CHARACTERCREATE\\UI-CHARACTERCREATE-RACES.PNG")
	score3.image:SetTexCoord(0.5, 0.75, 0.25, 0.5)
	score3:SetImageSize(50, 50)
	score3.label:SetFont(main_font, 14, "")
	header_frame:AddChild(score3)

	local space3 = AceGUI:Create("Label")
	space3:SetWidth(140)
	space3:SetHeight(60)
	header_frame:AddChild(space3)

	local score4 = AceGUI:Create("InteractiveLabel")
	score4:SetWidth(100)
	score4:SetHeight(60)
	score4:SetText("   " .. ns.getScore("Orc") .. " pts")
	score4:SetImage("Interface\\Glues/CHARACTERCREATE\\UI-CHARACTERCREATE-RACES.PNG")
	score4.image:SetTexCoord(0.75, 1, 0.25, 0.5)
	score4:SetImageSize(50, 50)
	score4.label:SetFont(main_font, 14, "")
	header_frame:AddChild(score4)

	local space4 = AceGUI:Create("Label")
	space4:SetWidth(140)
	space4:SetHeight(60)
	header_frame:AddChild(space4)

	local header_label = AceGUI:Create("InteractiveLabel")
	header_label:SetFullWidth(true)
	header_label:SetHeight(60)
	header_label.font_strings = {}

	header_strings[subtitle_data[1][1]]:SetPoint("LEFT", header_label.frame, "LEFT", 0, 0)
	header_strings[subtitle_data[1][1]]:Show()
	for _, v in ipairs(subtitle_data) do
		header_strings[v[1]]:SetParent(header_label.frame)
		header_strings[v[1]]:SetText(v[1])
	end

	header_label:SetFont(main_font, 16, "")
	header_label:SetColor(1, 1, 1)
	header_label:SetText(" ")
	scroll_frame:AddChild(header_label)

	local deathlog_group = AceGUI:Create("ScrollFrame")
	deathlog_group:SetFullWidth(true)
	deathlog_group:SetHeight(340)
	scroll_frame:AddChild(deathlog_group)
	-- deathlog_group.frame:SetPoint("TOP", scroll_container.frame, "TOP", 0, -100)
	font_container:SetParent(deathlog_group.frame)
	-- font_container:SetPoint("TOP", deathlog_group.frame, "TOP", 0, -100)
	font_container:SetHeight(400)
	font_container:Show()
	for i = 1, max_rows do
		local idx = 101 - i
		local _entry = AceGUI:Create("InteractiveLabel")
		_entry:SetHighlight("Interface\\Glues\\CharacterSelect\\Glues-CharacterSelect-Highlight")

		font_strings[i][subtitle_data[1][1]]:SetPoint("LEFT", _entry.frame, "LEFT", 0, 0)
		font_strings[i][subtitle_data[1][1]]:Show()
		for _, v in ipairs(subtitle_data) do
			font_strings[i][v[1]]:SetParent(_entry.frame)
		end

		row_backgrounds[i]:SetPoint("CENTER", _entry.frame, "CENTER", 0, 0)
		row_backgrounds[i]:SetParent(_entry.frame)

		_entry:SetHeight(40)
		_entry:SetFullWidth(true)
		_entry:SetFont(main_font, 16, "")
		_entry:SetColor(1, 1, 1)
		_entry:SetText(" ")

		function _entry:deselect()
			for _, v in pairs(_entry.font_strings) do
				v:SetTextColor(1, 1, 1)
			end
		end

		function _entry:select()
			selected = idx
			for _, v in pairs(_entry.font_strings) do
				v:SetTextColor(1, 1, 0)
			end
		end

		_entry:SetCallback("OnLeave", function(widget)
			GameTooltip:Hide()
		end)

		_entry:SetCallback("OnClick", function()
			local click_type = GetMouseButtonClicked()

			if click_type == "LeftButton" then
			elseif click_type == "RightButton" then
				local dropDown = CreateFrame("Frame", "WPDemoContextMenu", UIParent, "UIDropDownMenuTemplate")
				-- Bind an initializer function to the dropdown; see previous sections for initializer function examples.
				UIDropDownMenu_Initialize(dropDown, WPDropDownDemo_Menu, "MENU")
				ToggleDropDownMenu(1, nil, dropDown, "cursor", 3, -3)
				if font_strings[i] and font_strings[i].map_id and font_strings[i].map_id_coords_x then
					death_tomb_frame.map_id = font_strings[i].map_id
					death_tomb_frame.coordinates = { font_strings[i].map_id_coords_x, font_strings[i].map_id_coords_y }
					death_tomb_frame.clicked_name = font_strings[i].Name:GetText()
				end
			end
		end)

		_entry:SetCallback("OnEnter", function(widget)
			GameTooltip_SetDefaultAnchor(GameTooltip, WorldFrame)
			local _name = ""
			local _level = ""
			local _guild = ""
			local _race = ""
			local _class = ""
			local _source = ""
			local _zone = ""
			local _date = ""
			local _last_words = ""
			if font_strings[i] and font_strings[i]["Name"] then
				_name = font_strings[i]["Name"]:GetText() or ""
			end
			if font_strings[i] and font_strings[i]["Lvl"] then
				_level = font_strings[i]["Lvl"]:GetText() or ""
			end
			if font_strings[i] and font_strings[i]["Guild"] then
				_guild = font_strings[i]["Guild"]:GetText() or ""
			end
			if font_strings[i] and font_strings[i]["Race"] then
				_race = font_strings[i]["Race"]:GetText() or ""
			end
			if font_strings[i] and font_strings[i]["Class"] then
				_class = font_strings[i]["Class"]:GetText() or ""
			end
			if font_strings[i] and font_strings[i]["Death Source"] then
				_source = font_strings[i]["Death Source"]:GetText() or ""
			end
			if font_strings[i] and font_strings[i]["Zone/Instance"] then
				_zone = font_strings[i]["Zone/Instance"]:GetText() or ""
			end
			if font_strings[i] and font_strings[i]["Date"] then
				_date = font_strings[i]["Date"]:GetText() or ""
			end
			if font_strings[i] and font_strings[i]["Last Words"] then
				_last_words = font_strings[i]["Last Words"]:GetText() or ""
			end
			GameTooltip:Show()
		end)

		deathlog_group:SetScroll(0)
		deathlog_group.scrollbar:Hide()
		deathlog_group:AddChild(_entry)
	end
	scroll_frame.scrollbar:Hide()

	if font_container.page_str == nil then
		font_container.page_str = font_container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		font_container.page_str:SetText("Page " .. page_number)
		font_container.page_str:SetFont(Deathlog_L.menu_font, 14, "")
		font_container.page_str:SetJustifyV("BOTTOM")
		font_container.page_str:SetJustifyH("CENTER")
		font_container.page_str:SetTextColor(0.7, 0.7, 0.7)
		font_container.page_str:SetPoint("TOP", font_container, "TOP", 0, -444)
		font_container.page_str:Show()
	end

	if font_container.prev_button == nil then
		font_container.prev_button = CreateFrame("Button", nil, font_container)
		font_container.prev_button:SetPoint("CENTER", font_container.page_str, "CENTER", -50, 0)
		font_container.prev_button:SetWidth(25)
		font_container.prev_button:SetHeight(25)
		font_container.prev_button:SetNormalTexture("Interface/Buttons/UI-SpellbookIcon-PrevPage-Up.PNG")
		font_container.prev_button:SetHighlightTexture("Interface/Buttons/UI-SpellbookIcon-PrevPage-Up.PNG")
		font_container.prev_button:SetPushedTexture("Interface/Buttons/UI-SpellbookIcon-PrevPage-Down.PNG")
	end

	font_container.prev_button:SetScript("OnClick", function()
		page_number = page_number - 1
		if page_number < 1 then
			page_number = 1
		end
		clearDeathlogMenuLogData()
		font_container.page_str:SetText("Page " .. page_number)
		setLogData()
	end)

	if font_container.next_button == nil then
		font_container.next_button = CreateFrame("Button", nil, font_container)
		font_container.next_button:SetPoint("CENTER", font_container.page_str, "CENTER", 50, 0)
		font_container.next_button:SetWidth(25)
		font_container.next_button:SetHeight(25)
		font_container.next_button:SetNormalTexture("Interface/Buttons/UI-SpellbookIcon-NextPage-Up.PNG")
		font_container.next_button:SetHighlightTexture("Interface/Buttons/UI-SpellbookIcon-NextPage-Up.PNG")
		font_container.next_button:SetPushedTexture("Interface/Buttons/UI-SpellbookIcon-NextPage-Down.PNG")
	end

	font_container.next_button:SetScript("OnClick", function()
		page_number = page_number + 1
		clearDeathlogMenuLogData()
		font_container.page_str:SetText("Page " .. page_number)
		setLogData()
	end)

	deathlog_group.frame:HookScript("OnHide", function()
		font_container:Hide()
	end)
end

local function makeAchievementLabel(_v)
	local __f = AceGUI:Create("InlineGroup")
	__f:SetLayout("Flow")
	__f:SetHeight(200)
	__f:SetWidth(800)
	local _title = AceGUI:Create("Label")
	_title:SetText(_v.title)
	_title:SetHeight(100)
	_title:SetWidth(690)
	_title:SetJustifyH("LEFT")
	_title:SetFont(main_font, 16, "")
	__f:AddChild(_title)

	local _pts = AceGUI:Create("Label")
	_pts:SetText(_v.pts .. " pts.")
	_pts:SetColor(0, 255, 0, 1)
	_pts:SetHeight(50)
	_pts:SetWidth(75)
	_pts:SetJustifyH("RIGHT")
	_pts:SetFont(main_font, 12, "")
	__f:AddChild(_pts)

	local _gap = AceGUI:Create("Label")
	_gap:SetHeight(100)
	_gap:SetFullWidth(true)
	__f:AddChild(_gap)

	local _desc = AceGUI:Create("Label")
	_desc:SetText(_v.description)
	_desc:SetHeight(140)
	_desc:SetWidth(800)
	_desc:SetJustifyH("LEFT")
	__f:AddChild(_desc)

	local _gap2 = AceGUI:Create("Label")
	_gap2:SetHeight(100)
	_gap2:SetFullWidth(true)
	__f:AddChild(_gap2)

	local _zone = AceGUI:Create("Label")
	_zone:SetText(_v.zone)
	_zone:SetHeight(140)
	_zone:SetWidth(800)
	_zone:SetJustifyH("LEFT")
	_zone:SetColor(100 / 255, 100 / 255, 100 / 255, 1)
	__f:AddChild(_zone)
	return __f
end

local function makeMilestoneLabel(_v)
	local __f = AceGUI:Create("InlineGroup")
	__f:SetLayout("Flow")
	__f:SetHeight(200)
	__f:SetWidth(800)
	local _title = AceGUI:Create("Label")
	_title:SetText(_v.title)
	_title:SetHeight(100)
	_title:SetWidth(690)
	_title:SetJustifyH("LEFT")
	_title:SetFont(main_font, 16, "")
	__f:AddChild(_title)

	local _pts = AceGUI:Create("Label")
	_pts:SetText(_v.pts .. " pts.")
	_pts:SetColor(0, 255 / 255, 0, 1)
	_pts:SetHeight(50)
	_pts:SetWidth(75)
	_pts:SetJustifyH("RIGHT")
	_pts:SetFont(main_font, 12, "")
	__f:AddChild(_pts)

	local _gap = AceGUI:Create("Label")
	_gap:SetHeight(100)
	_gap:SetFullWidth(true)
	__f:AddChild(_gap)

	local _desc = AceGUI:Create("Label")
	_desc:SetText(_v.description)
	_desc:SetHeight(140)
	_desc:SetWidth(800)
	_desc:SetJustifyH("LEFT")
	__f:AddChild(_desc)

	local _claimed_by = AceGUI:Create("Label")
	_claimed_by:SetColor(128 / 255, 128 / 255, 128 / 255, 1)
	if ns.claimed_milestones[_v.name] == nil then
		_claimed_by:SetText("Unclaimed")
	else
		_claimed_by:SetText("Claimed by: " .. ns.claimed_milestones[_v.name])
	end
	_claimed_by:SetHeight(140)
	_claimed_by:SetWidth(800)
	_claimed_by:SetJustifyH("LEFT")
	__f:AddChild(_claimed_by)
	return __f
end

local function makeFirstToFindLabel(_v)
	local __f = AceGUI:Create("InlineGroup")
	__f:SetLayout("Flow")
	__f:SetHeight(200)
	__f:SetWidth(800)
	local _title = AceGUI:Create("Label")
	_title:SetText(_v.title)
	_title:SetHeight(100)
	_title:SetWidth(690)
	_title:SetJustifyH("LEFT")
	_title:SetFont(main_font, 16, "")
	__f:AddChild(_title)

	local _pts = AceGUI:Create("Label")
	_pts:SetText(_v.pts .. " pts.")
	_pts:SetColor(0, 255 / 255, 0, 1)
	_pts:SetHeight(50)
	_pts:SetWidth(75)
	_pts:SetJustifyH("RIGHT")
	_pts:SetFont(main_font, 12, "")
	__f:AddChild(_pts)

	local _gap = AceGUI:Create("Label")
	_gap:SetHeight(100)
	_gap:SetFullWidth(true)
	__f:AddChild(_gap)

	local _desc = AceGUI:Create("Label")
	_desc:SetText(_v.description)
	_desc:SetHeight(140)
	_desc:SetWidth(800)
	_desc:SetJustifyH("LEFT")
	__f:AddChild(_desc)

	local _claimed_by = AceGUI:Create("Label")
	_claimed_by:SetColor(128 / 255, 128 / 255, 128 / 255, 1)
	if ns.claimed_milestones[_v.name] == nil then
		_claimed_by:SetText("Unclaimed")
	else
		_claimed_by:SetText("Claimed by: " .. ns.claimed_milestones[_v.name])
	end
	_claimed_by:SetHeight(140)
	_claimed_by:SetWidth(800)
	_claimed_by:SetJustifyH("LEFT")
	__f:AddChild(_claimed_by)
	return __f
end

local function makeFirstToCompleteLabel(_v)
	local __f = AceGUI:Create("InlineGroup")
	__f:SetLayout("Flow")
	__f:SetHeight(200)
	__f:SetWidth(800)
	local _title = AceGUI:Create("Label")
	_title:SetText(_v.title)
	_title:SetHeight(100)
	_title:SetWidth(690)
	_title:SetJustifyH("LEFT")
	_title:SetFont(main_font, 16, "")
	__f:AddChild(_title)

	local _pts = AceGUI:Create("Label")
	_pts:SetText(_v.pts .. " pts.")
	_pts:SetColor(0, 255 / 255, 0, 1)
	_pts:SetHeight(50)
	_pts:SetWidth(75)
	_pts:SetJustifyH("RIGHT")
	_pts:SetFont(main_font, 12, "")
	__f:AddChild(_pts)

	local _gap = AceGUI:Create("Label")
	_gap:SetHeight(100)
	_gap:SetFullWidth(true)
	__f:AddChild(_gap)

	local _desc = AceGUI:Create("Label")
	_desc:SetText(_v.description)
	_desc:SetHeight(140)
	_desc:SetWidth(800)
	_desc:SetJustifyH("LEFT")
	__f:AddChild(_desc)

	local _claimed_by = AceGUI:Create("Label")
	_claimed_by:SetColor(128 / 255, 128 / 255, 128 / 255, 1)
	if ns.claimed_milestones[_v.name] == nil then
		_claimed_by:SetText("Unclaimed")
	else
		_claimed_by:SetText("Claimed by: " .. ns.claimed_milestones[_v.name])
	end
	_claimed_by:SetHeight(140)
	_claimed_by:SetWidth(800)
	_claimed_by:SetJustifyH("LEFT")
	__f:AddChild(_claimed_by)
	return __f
end

local function makeFailureLabel(_v)
	local __f = AceGUI:Create("InlineGroup")
	__f:SetLayout("Flow")
	__f:SetHeight(200)
	__f:SetWidth(800)
	local _title = AceGUI:Create("Label")
	_title:SetText(_v.title)
	_title:SetHeight(100)
	_title:SetWidth(690)
	_title:SetJustifyH("LEFT")
	_title:SetFont(main_font, 16, "")
	__f:AddChild(_title)

	local _pts = AceGUI:Create("Label")
	_pts:SetText(_v.pts .. " pts.")
	_pts:SetColor(255 / 255, 0, 0, 1)
	_pts:SetHeight(50)
	_pts:SetWidth(75)
	_pts:SetJustifyH("RIGHT")
	_pts:SetFont(main_font, 12, "")
	__f:AddChild(_pts)

	local _gap = AceGUI:Create("Label")
	_gap:SetHeight(100)
	_gap:SetFullWidth(true)
	__f:AddChild(_gap)

	local _desc = AceGUI:Create("Label")
	_desc:SetText(_v.description)
	_desc:SetHeight(140)
	_desc:SetWidth(800)
	_desc:SetJustifyH("LEFT")
	__f:AddChild(_desc)
	return __f
end

local function makeOfficerCommandLabel(_v)
	local __f = AceGUI:Create("InlineGroup")
	__f:SetLayout("Flow")
	__f:SetHeight(200)
	__f:SetWidth(800)
	local _title = AceGUI:Create("Label")
	_title:SetText(_v.title)
	_title:SetHeight(100)
	_title:SetWidth(690)
	_title:SetJustifyH("LEFT")
	_title:SetFont(main_font, 16, "")
	__f:AddChild(_title)

	local _gap = AceGUI:Create("Label")
	_gap:SetHeight(100)
	_gap:SetFullWidth(true)
	__f:AddChild(_gap)

	local _desc = AceGUI:Create("Label")
	_desc:SetText(_v.description)
	_desc:SetHeight(140)
	_desc:SetWidth(800)
	_desc:SetJustifyH("LEFT")
	__f:AddChild(_desc)
	return __f
end

local function drawEventTypeTab(container, _title, _frames)
	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("Flow")
	deathlog_tabcontainer:AddChild(scroll_container)

	local header_frame = AceGUI:Create("SimpleGroup")
	header_frame:SetLayout("Flow")
	header_frame:SetFullWidth(true)
	header_frame:SetHeight(100)
	scroll_container:AddChild(header_frame)

	local recently_selected_group = "Milestones"
	local tree = {
		{
			value = "Milestone",
			text = "Milestones",
			children = {
				{
					value = "General",
					text = "General",
				},
				{
					value = "First to Complete",
					text = "First to Complete",
				},
				{
					value = "First to Find",
					text = "First to Find",
				},
				{
					value = "First to Max Profession",
					text = "First to Max Profession",
				},
			},
		},
		{
			value = "Achievement",
			text = "Achievements",
		},
		{
			value = "Failure",
			text = "Failures",
		},
		{
			value = "OfficerCommands",
			text = "Officer Commands",
		},
	}

	local tree_container = AceGUI:Create("TreeGroup")

	tree_container:SetTree(tree)
	tree_container:EnableButtonTooltips(true)
	tree_container:SetFullWidth(true)
	tree_container:SetHeight(450)
	tree_container:SetLayout("Fill")
	scroll_container:AddChild(tree_container)

	local scroll_frame = AceGUI:Create("ScrollFrame")
	scroll_frame:SetLayout("List")
	tree_container:AddChild(scroll_frame)

	tree_container:SetCallback("OnGroupSelected", function(_container, events, group, other)
		local _, _subgroup = string.split(string.char(1), group)
		if _subgroup ~= nil then
			group = _subgroup
		end
		recently_selected_group = group

		scroll_frame:ReleaseChildren()

		if group == "Achievement" then
			local _group_description = AceGUI:Create("Label")
			_group_description:SetText(
				"Awarded when completing the quest by the specified level.  Limited to once per character."
			)
			_group_description:SetHeight(140)
			_group_description:SetWidth(800)
			_group_description:SetJustifyH("LEFT")
			scroll_frame:AddChild(_group_description)
		elseif group == "Milestone" then
			local _group_description = AceGUI:Create("Label")
			_group_description:SetText("Awarded to the first character that meets the requirements.")
			_group_description:SetHeight(140)
			_group_description:SetWidth(800)
			_group_description:SetJustifyH("LEFT")
			scroll_frame:AddChild(_group_description)
		elseif group == "General" then
			local _group_description = AceGUI:Create("Label")
			_group_description:SetText("Be the first to complete the specified achievement.")
			_group_description:SetHeight(140)
			_group_description:SetWidth(800)
			_group_description:SetJustifyH("LEFT")
			scroll_frame:AddChild(_group_description)
		elseif group == "First to Complete" then
			local _group_description = AceGUI:Create("Label")
			_group_description:SetText("Be the first to complete the specified quest.")
			_group_description:SetHeight(140)
			_group_description:SetWidth(800)
			_group_description:SetJustifyH("LEFT")
			scroll_frame:AddChild(_group_description)
		elseif group == "First to Find" then
			local _group_description = AceGUI:Create("Label")
			_group_description:SetText("Be the first to obtain the specified item.")
			_group_description:SetHeight(140)
			_group_description:SetWidth(800)
			_group_description:SetJustifyH("LEFT")
			scroll_frame:AddChild(_group_description)
		elseif group == "First to Max Profession" then
			local _group_description = AceGUI:Create("Label")
			_group_description:SetText("Be the first to reach 300 the specified profession.")
			_group_description:SetHeight(140)
			_group_description:SetWidth(800)
			_group_description:SetJustifyH("LEFT")
			scroll_frame:AddChild(_group_description)
		elseif group == "Failure" then
			local _group_description = AceGUI:Create("Label")
			_group_description:SetText("Points are taken away for these events.")
			_group_description:SetHeight(140)
			_group_description:SetWidth(800)
			_group_description:SetJustifyH("LEFT")
			scroll_frame:AddChild(_group_description)
		elseif group == "OfficerCommand" then
			local _group_description = AceGUI:Create("Label")
			_group_description:SetText("Special commands that only officers can use.")
			_group_description:SetHeight(140)
			_group_description:SetWidth(800)
			_group_description:SetJustifyH("LEFT")
			scroll_frame:AddChild(_group_description)
		end
		for k, v in pairs(ns.event) do
			if v.type == group or v.subtype == group then
				if group == "Achievement" then
					scroll_frame:AddChild(makeAchievementLabel(v))
				elseif group == "General" then
					scroll_frame:AddChild(makeFirstToCompleteLabel(v))
				elseif group == "First to Complete" then
					scroll_frame:AddChild(makeFirstToCompleteLabel(v))
				elseif group == "First to Find" then
					scroll_frame:AddChild(makeFirstToFindLabel(v))
				elseif group == "First to Max Profession" then
					scroll_frame:AddChild(makeFirstToFindLabel(v))
				elseif group == "Failure" then
					scroll_frame:AddChild(makeFailureLabel(v))
				elseif group == "OfficerCommand" then
					scroll_frame:AddChild(makeOfficerCommandLabel(v))
				end
			end
		end
	end)

	tree_container:SelectByValue("Milestone")
end

local function drawLeaderboardTab(container)
	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("Fill")
	deathlog_tabcontainer:AddChild(scroll_container)

	local main_frame = AceGUI:Create("SimpleGroup")
	main_frame:SetLayout("Flow")
	main_frame:SetFullWidth(true)
	main_frame:SetFullHeight(true)
	scroll_container:AddChild(main_frame)

	local _frames = {}
	for _, _type in ipairs({ "Daily", "Weekly", "All Time" }) do
		local __f = AceGUI:Create("InlineGroup")
		__f:SetLayout("Flow")
		__f:SetHeight(700)
		__f:SetWidth(330)
		main_frame:AddChild(__f)

		local _header = AceGUI:Create("Heading")
		_header:SetFullWidth(true)
		_header:SetText(_type .. " Leaderboard")
		__f:AddChild(_header)

		for j = 1, 30 do
			local _line = AceGUI:Create("Label")
			_line:SetWidth(250)
			_line:SetText("1. Yazpad")
			__f:AddChild(_line)
			local _pts = AceGUI:Create("Label")
			_pts:SetWidth(40)
			_pts:SetText("5 pts")
			__f:AddChild(_pts)
			_frames[#_frames + 1] = __f.frame
		end
	end

	local count = 0
	for _, v in ipairs(_frames) do
		v:SetPoint("TOPLEFT", scroll_container.frame, count * 11 - 300, -8)
		count = count + 1
		v:Show()
	end
end

local function createMenu()
	local ace_deathlog_menu = AceGUI:Create("DeathlogMenu")
	_G["AceDeathlogMenu"] = ace_deathlog_menu.frame -- Close on <ESC>
	tinsert(UISpecialFrames, "AceDeathlogMenu")

	ace_deathlog_menu:SetTitle("OnlyFangs")
	ace_deathlog_menu:SetVersion(GetAddOnMetadata("OnlyFangs", "Version"))
	ace_deathlog_menu:SetStatusText("")
	ace_deathlog_menu:SetLayout("Flow")
	ace_deathlog_menu:SetHeight(_menu_height)
	ace_deathlog_menu:SetWidth(_menu_width)

	if ace_deathlog_menu.exit_button == nil then
		ace_deathlog_menu.exit_button = CreateFrame("Button", nil, ace_deathlog_menu.frame)
		ace_deathlog_menu.exit_button:SetPoint("TOPRIGHT", ace_deathlog_menu.frame, "TOPRIGHT", -8, -8)
		ace_deathlog_menu.exit_button:SetWidth(25)
		ace_deathlog_menu.exit_button:SetHeight(25)
		ace_deathlog_menu.exit_button:SetNormalTexture("Interface/Buttons/UI-SquareButton-Disabled.PNG")
		ace_deathlog_menu.exit_button:SetHighlightTexture("Interface/Buttons/UI-SquareButton-Up.PNG")
		ace_deathlog_menu.exit_button:SetPushedTexture("Interface/Buttons/UI-SquareButton-Down.PNG")
	end

	ace_deathlog_menu.exit_button:SetScript("OnClick", function()
		deathlog_menu:Hide()
	end)

	if ace_deathlog_menu.exit_button_x == nil then
		ace_deathlog_menu.exit_button_x = death_tomb_frame:CreateTexture(nil, "OVERLAY")
		ace_deathlog_menu.exit_button_x:SetParent(ace_deathlog_menu.exit_button)
		ace_deathlog_menu.exit_button_x:SetPoint("CENTER", ace_deathlog_menu.exit_button, "CENTER", 0, 0)
		ace_deathlog_menu.exit_button_x:SetWidth(10)
		ace_deathlog_menu.exit_button_x:SetHeight(10)
		ace_deathlog_menu.exit_button_x:SetTexture("Interface/Buttons/UI-StopButton.PNG")
		ace_deathlog_menu.exit_button_x:SetVertexColor(1, 1, 1, 0.8)
	end

	deathlog_tabcontainer = AceGUI:Create("DeathlogTabGroup") -- "InlineGroup" is also good
	local tab_table = Deathlog_L.tab_table
	deathlog_tabcontainer:SetTabs(tab_table)
	deathlog_tabcontainer:SetFullWidth(true)
	deathlog_tabcontainer:SetFullHeight(true)
	deathlog_tabcontainer:SetLayout("Flow")

	local function SelectGroup(container, event, group)
		container:ReleaseChildren()
		if group == "PointsTab" then
			drawEventTypeTab(container)
		elseif group == "LogTab" then
			drawLogTab(container)
		elseif group == "LeaderboardTab" then
			drawLeaderboardTab(container)
		end
	end

	deathlog_tabcontainer:SetCallback("OnGroupSelected", SelectGroup)

	ace_deathlog_menu:AddChild(deathlog_tabcontainer)
	return ace_deathlog_menu
end

deathlog_menu = createMenu()

ns.showMenu = function()
	deathlog_menu:Show()
	deathlog_tabcontainer:SelectTab("LogTab")
	setLogData()
end
