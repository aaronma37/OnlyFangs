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

local off_race_sel = nil
local off_pt_num = nil
local off_char_name = nil
local ticker_handler = nil
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

local REALM_NAME = GetRealmName()
REALM_NAME = REALM_NAME:gsub("%s+", "")

local main_font = Deathlog_L.main_font

local onlyfangs_tab_container = nil

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

	local function blockUser() end

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
		"Streamer Name",
		120,
		function(_entry, _server_name)
			if _entry["name"] == nil then
				return " "
			end
			return ns.streamer_map[_entry["name"] .. "-" .. REALM_NAME] or ""
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
		100,
		function(_entry, _server_name)
			return _entry["guild"] or ""
		end,
	},
	{
		"Type",
		120,
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
		if _event_name then
			local _char_name, _ = string.split("-", _event["Name"])
			font_strings[i]["Name"]:SetText(_char_name)

			local _streamer_name = ""
			if _char_name ~= nil then
				_streamer_name = ns.streamer_map[_char_name .. "-" .. REALM_NAME] or ""
			end
			font_strings[i]["Streamer Name"]:SetText(_streamer_name)
			font_strings[i]["Date"]:SetText(date("%m/%d/%y, %H:%M", _event["Date"] + 1730639674))
			font_strings[i]["Race"]:SetText(ns.id_race[_event["Race"]])
			font_strings[i]["Class"]:SetText(ns.id_class[_event["Class"]] or "")
			font_strings[i]["Event"]:SetText(ns.event[_event_name].title or "")
			font_strings[i]["Type"]:SetText(ns.event[_event_name].type or "")
			local pt_str = ""
			if ns.event[_event_name].pts > 0 then
				pt_str = "|cff00FF00+" .. ns.event[_event_name].pts .. "|r"
			elseif ns.event[_event_name].pts < 0 then
				pt_str = "|cffFF0000-" .. ns.event[_event_name].pts .. "|r"
			end
			if ns.event[_event_name].type == "Milestone" and ns.claimed_milestones[_event_name] ~= _event["Name"] then
				pt_str = "|cff808080already claimed|r"
			end
			if _event_name == "AdjustPoints" then
				local str = "return " .. _event["AdditionalArgs"]
				local func = assert(loadstring(str))
				local args = func()
				pt_str = args["pts"]
				local _parsed_name = args["char_name"]
				font_strings[i]["Name"]:SetText(font_strings[i]["Name"]:GetText() .. "->" .. (_parsed_name or ""))
				if pt_str > 0 then
					pt_str = "|cff00FF00+" .. pt_str .. "|r"
				elseif pt_str < 0 then
					pt_str = "|cffFF0000-" .. pt_str .. "|r"
				end
			end
			font_strings[i]["Points"]:SetText(pt_str)
		end
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
	onlyfangs_tab_container:AddChild(scroll_container)

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

	local _header = AceGUI:Create("Heading")
	_header:SetFullWidth(true)
	_header:SetText("Summary")
	header_frame:AddChild(_header)

	local space1 = AceGUI:Create("Label")
	space1:SetWidth(140)
	space1:SetHeight(60)
	space1:SetText(
		"Orc: "
			.. ns.getScore("Orc")
			.. "\nTroll: "
			.. ns.getScore("Troll")
			.. "\nTauren: "
			.. ns.getScore("Tauren")
			.. "\nUndead: "
			.. ns.getScore("Undead")
	)
	header_frame:AddChild(space1)

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

	local reset_button = AceGUI:Create("Button")
	reset_button:SetText("Refresh")
	reset_button:SetHeight(25)
	reset_button:SetWidth(120)
	reset_button.frame:SetPoint("CENTER", font_container.page_str, "CENTER", -400, 0)
	reset_button:SetCallback("OnClick", function(self)
		container:ReleaseChildren()
		ns.refreshGuildList(true)
		ns.aggregateLog()
		drawLogTab(container)
		clearDeathlogMenuLogData()
		font_container.page_str:SetText("Page " .. page_number)
		setLogData()
	end)
	scroll_frame:AddChild(reset_button)

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

local alt = 0
local alt2 = 1
local function makeMilestoneLabel(_v)
	local __f = AceGUI:Create("InlineGroup")
	__f:SetLayout("Flow")
	__f:SetHeight(100)
	__f:SetWidth(800)
	local _title = AceGUI:Create("Label")
	_title:SetText(_v.title)
	_title:SetHeight(30)
	_title:SetWidth(690)
	_title:SetJustifyH("LEFT")
	_title:SetFont(main_font, 16, "")
	__f:AddChild(_title)

	local _pts = AceGUI:Create("Label")
	_pts:SetText(_v.pts .. " pts.")
	_pts:SetColor(0, 255 / 255, 0, 1)
	_pts:SetHeight(30)
	_pts:SetWidth(75)
	_pts:SetJustifyH("RIGHT")
	_pts:SetFont(main_font, 12, "")
	__f:AddChild(_pts)

	local _gap = AceGUI:Create("Label")
	_gap:SetHeight(0)
	_gap:SetFullWidth(true)
	__f:AddChild(_gap)

	local _desc = AceGUI:Create("Label")
	_desc:SetText(_v.description)
	_desc:SetHeight(30)
	_desc:SetWidth(800)
	_desc:SetJustifyH("LEFT")
	__f:AddChild(_desc)

	local _claimed_by = AceGUI:Create("Label")
	_claimed_by:SetColor(128 / 255, 128 / 255, 128 / 255, 1)
	if ns.claimed_milestones[_v.name] == nil then
		_claimed_by:SetText("Unclaimed")
	else
		local _short_n, _ = string.split("-", ns.claimed_milestones[_v.name])
		_claimed_by:SetText("Claimed by: " .. _short_n)
	end
	_claimed_by:SetHeight(140)
	_claimed_by:SetWidth(800)
	_claimed_by:SetJustifyH("LEFT")
	__f:AddChild(_claimed_by)
	return __f
end

local function makeAchievementLabel2(_v)
	local __f = AceGUI:Create("SimpleGroupOF")
	__f:SetLayout("Flow")
	__f:SetHeight(100)
	__f:SetWidth(390)

	-- __f.frame2 = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	__f.frame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	__f.frame:SetBackdropColor(1, 1, 1, alt)
	__f.frame:SetBackdropBorderColor(1, 1, 1, 0)
	if alt2 == 1 then
		if alt == 0 then
			alt = 0.1
			alt2 = 0
		else
			alt = 0
			alt2 = 0
		end
	else
		alt2 = 1
	end

	local _title = AceGUI:Create("Label")
	_title:SetText(_v.title)
	_title:SetHeight(30)
	_title:SetWidth(280)
	_title:SetJustifyH("LEFT")
	_title:SetFont(main_font, 12, "")
	__f:AddChild(_title)

	local _pts = AceGUI:Create("Label")
	_pts:SetText(_v.pts .. " pts.")
	_pts:SetColor(0, 255 / 255, 0, 1)
	_pts:SetHeight(30)
	_pts:SetWidth(75)
	_pts:SetJustifyH("RIGHT")
	_pts:SetFont(main_font, 12, "")
	__f:AddChild(_pts)

	local _desc = AceGUI:Create("Label")
	_desc:SetText(_v.description)
	_desc:SetHeight(30)
	_desc:SetWidth(400)
	_desc:SetJustifyH("LEFT")
	__f:AddChild(_desc)

	local _claimed_by = AceGUI:Create("Label")
	_claimed_by:SetColor(128 / 255, 128 / 255, 128 / 255, 1)
	_claimed_by:SetText(_v.zone)
	_claimed_by:SetHeight(140)
	_claimed_by:SetWidth(400)
	_claimed_by:SetJustifyH("LEFT")
	__f:AddChild(_claimed_by)

	local _gap = AceGUI:Create("Label")
	_gap:SetHeight(30)
	_gap:SetText("")
	-- _gap:SetFullWidth(true)
	__f:AddChild(_gap)
	local _gap2 = AceGUI:Create("Label")
	_gap2:SetHeight(30)
	_gap2:SetText("")
	-- _gap2:SetFullWidth(true)
	__f:AddChild(_gap2)

	return __f
end

local function makeFirstToFindLabel(_v)
	local __f = AceGUI:Create("SimpleGroupOF")
	__f:SetLayout("Flow")
	__f:SetHeight(100)
	__f:SetWidth(390)

	-- __f.frame2 = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	__f.frame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	__f.frame:SetBackdropColor(1, 1, 1, alt)
	__f.frame:SetBackdropBorderColor(1, 1, 1, 0)
	if alt2 == 1 then
		if alt == 0 then
			alt = 0.1
			alt2 = 0
		else
			alt = 0
			alt2 = 0
		end
	else
		alt2 = 1
	end

	local _title = AceGUI:Create("Label")
	_title:SetText(_v.title)
	_title:SetHeight(30)
	_title:SetWidth(280)
	_title:SetJustifyH("LEFT")
	_title:SetFont(main_font, 12, "")
	__f:AddChild(_title)

	local _pts = AceGUI:Create("Label")
	_pts:SetText(_v.pts .. " pts.")
	_pts:SetColor(0, 255 / 255, 0, 1)
	_pts:SetHeight(30)
	_pts:SetWidth(75)
	_pts:SetJustifyH("RIGHT")
	_pts:SetFont(main_font, 12, "")
	__f:AddChild(_pts)

	local _desc = AceGUI:Create("Label")
	_desc:SetText(_v.description)
	_desc:SetHeight(30)
	_desc:SetWidth(400)
	_desc:SetJustifyH("LEFT")
	__f:AddChild(_desc)

	local _claimed_by = AceGUI:Create("Label")
	_claimed_by:SetColor(128 / 255, 128 / 255, 128 / 255, 1)
	if ns.claimed_milestones[_v.name] == nil then
		_claimed_by:SetText("Unclaimed")
	else
		local _short_n, _ = string.split("-", ns.claimed_milestones[_v.name])
		_claimed_by:SetText("Claimed by: " .. _short_n)
	end
	_claimed_by:SetHeight(140)
	_claimed_by:SetWidth(400)
	_claimed_by:SetJustifyH("LEFT")
	__f:AddChild(_claimed_by)

	local _gap = AceGUI:Create("Label")
	_gap:SetHeight(30)
	_gap:SetText("")
	-- _gap:SetFullWidth(true)
	__f:AddChild(_gap)
	local _gap2 = AceGUI:Create("Label")
	_gap2:SetHeight(30)
	_gap2:SetText("")
	-- _gap2:SetFullWidth(true)
	__f:AddChild(_gap2)

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
		local _short_n, _ = string.split("-", ns.claimed_milestones[_v.name])
		_claimed_by:SetText("Claimed by: " .. _short_n)
	end
	_claimed_by:SetHeight(140)
	_claimed_by:SetWidth(800)
	_claimed_by:SetJustifyH("LEFT")
	__f:AddChild(_claimed_by)
	return __f
end

local function makeFailureLabel(_v)
	local __f = AceGUI:Create("SimpleGroupOF")
	__f:SetLayout("Flow")
	__f:SetHeight(100)
	__f:SetWidth(390)

	-- __f.frame2 = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	__f.frame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	__f.frame:SetBackdropColor(1, 1, 1, alt)
	__f.frame:SetBackdropBorderColor(1, 1, 1, 0)
	if alt2 == 1 then
		if alt == 0 then
			alt = 0.1
			alt2 = 0
		else
			alt = 0
			alt2 = 0
		end
	else
		alt2 = 1
	end

	local _title = AceGUI:Create("Label")
	_title:SetText(_v.title)
	_title:SetHeight(30)
	_title:SetWidth(280)
	_title:SetJustifyH("LEFT")
	_title:SetFont(main_font, 12, "")
	__f:AddChild(_title)

	local _pts = AceGUI:Create("Label")
	_pts:SetText(_v.pts .. " pts.")
	_pts:SetColor(1, 0, 0, 1)
	_pts:SetHeight(30)
	_pts:SetWidth(75)
	_pts:SetJustifyH("RIGHT")
	_pts:SetFont(main_font, 12, "")
	__f:AddChild(_pts)

	local _desc = AceGUI:Create("Label")
	_desc:SetText(_v.description)
	_desc:SetHeight(30)
	_desc:SetWidth(400)
	_desc:SetJustifyH("LEFT")
	__f:AddChild(_desc)

	local _gap = AceGUI:Create("Label")
	_gap:SetHeight(30)
	_gap:SetText("")
	-- _gap:SetFullWidth(true)
	__f:AddChild(_gap)
	local _gap2 = AceGUI:Create("Label")
	_gap2:SetHeight(30)
	_gap2:SetText("")
	-- _gap2:SetFullWidth(true)
	__f:AddChild(_gap2)

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
	onlyfangs_tab_container:AddChild(scroll_container)

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
					value = "First to Kill",
					text = "First to Kill",
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
			children = {
				{
					value = "GeneralAchievement",
					text = "General",
				},
				{
					value = "Profession",
					text = "Profession",
				},
				{
					value = "Quest",
					text = "Quest",
				},
				{
					value = "Leveling",
					text = "Leveling",
				},
			},
		},
		{
			value = "Failure",
			text = "Failures",
		},
		{
			value = "OfficerCommand",
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
	scroll_frame:SetLayout("Flow")
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
		elseif group == "GeneralAchievement" then
			local _group_description = AceGUI:Create("Label")
			_group_description:SetText("Complete the specified achievement.")
			_group_description:SetHeight(140)
			_group_description:SetWidth(800)
			_group_description:SetJustifyH("LEFT")
			scroll_frame:AddChild(_group_description)
		elseif group == "First to Kill" then
			local _group_description = AceGUI:Create("Label")
			_group_description:SetText("Be the first to kill the specified target.")
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
			if CanEditOfficerNote() then
				off_race_sel = nil
				off_pt_num = nil
				off_char_name = nil
				local __f = AceGUI:Create("InlineGroup")
				__f:SetFullWidth(true)
				__f:SetLayout("Flow")
				__f:SetHeight(100)
				scroll_frame:AddChild(__f)

				local _commit_label = AceGUI:Create("Label")
				local _desc = AceGUI:Create("Label")
				_desc:SetText("Add/Subtract Points")
				_desc:SetHeight(25)
				_desc:SetWidth(150)
				__f:AddChild(_desc)
				local _addorsub = AceGUI:Create("Dropdown")
				_addorsub:SetLabel("Race")
				_addorsub:SetList({
					["Orc"] = "Orc",
					["Troll"] = "Troll",
					["Undead"] = "Undead",
					["Tauren"] = "Tauren",
				})
				_addorsub:SetHeight(25)
				_addorsub:SetWidth(100)
				_addorsub:SetCallback("OnValueChanged", function(self, val, race)
					off_race_sel = race
					_commit_label:SetText(
						(off_race_sel or "[Race]") .. ", " .. (off_char_name or "") .. ": " .. (off_pt_num or "[pts]")
					)
				end)
				__f:AddChild(_addorsub)

				local _num = AceGUI:Create("EditBox")
				_num:SetLabel("Pts")
				_num:SetHeight(45)
				_num:SetWidth(100)
				_num:SetCallback("OnEnterPressed", function(self, val, pts)
					off_pt_num = tonumber(pts)
					_commit_label:SetText(
						(off_race_sel or "[Race]") .. ", " .. (off_char_name or "") .. ": " .. (off_pt_num or "[pts]")
					)
				end)
				__f:AddChild(_num)

				local _char = AceGUI:Create("EditBox")
				_char:SetLabel("Character name [optional]")
				_char:SetHeight(45)
				_char:SetWidth(150)
				_char:SetCallback("OnEnterPressed", function(self, val, _name)
					off_char_name = _name
					_commit_label:SetText(
						(off_race_sel or "[Race]") .. ", " .. (off_char_name or "") .. ": " .. (off_pt_num or "[pts]")
					)
				end)
				__f:AddChild(_char)

				local _button = AceGUI:Create("Button")
				_button:SetText("Submit")
				_button:SetHeight(25)
				_button:SetWidth(120)
				_button:SetCallback("OnClick", function(self)
					if off_pt_num == nil then
						print("Enter number of points to add or subtract")
					end
					if off_race_sel == nil or ns.race_id[off_race_sel] == nil then
						print("Enter a valid race")
					end

					print("Adjusting points. " .. off_race_sel .. ": " .. off_pt_num)
					local char_string_name = "nil"
					if off_char_name then
						char_string_name = "'" .. off_char_name .. "'"
					end
					ns.sendOffEvent(
						"AdjustPoints",
						ns.race_id[off_race_sel],
						'{["pts"]=' .. tostring(off_pt_num) .. ', ["char_name"]=' .. char_string_name .. "}"
					)
				end)
				__f:AddChild(_button)
				_commit_label:SetText(
					(off_race_sel or "[Race]") .. ", " .. (off_char_name or "") .. ": " .. (off_pt_num or "[pts]")
				)
				_commit_label:SetHeight(25)
				_commit_label:SetWidth(150)
				__f:AddChild(_commit_label)
			end
		elseif group == "Profession" then
			local _group_description = AceGUI:Create("Label")
			_group_description:SetText("Reach specified profession level.")
			_group_description:SetHeight(140)
			_group_description:SetWidth(800)
			_group_description:SetJustifyH("LEFT")
			scroll_frame:AddChild(_group_description)
		elseif group == "Quest" then
			local _group_description = AceGUI:Create("Label")
			_group_description:SetText("Complete the quest by the specified level.")
			_group_description:SetHeight(140)
			_group_description:SetWidth(800)
			_group_description:SetJustifyH("LEFT")
			scroll_frame:AddChild(_group_description)
		elseif group == "Leveling" then
			local _group_description = AceGUI:Create("Label")
			_group_description:SetText("Reach the specified level.")
			_group_description:SetHeight(140)
			_group_description:SetWidth(800)
			_group_description:SetJustifyH("LEFT")
			scroll_frame:AddChild(_group_description)
		end
		for k, v in pairs(ns.event) do
			if v.test_only == nil then
				if v.type == group or v.subtype == group then
					if group == "General" then
						scroll_frame:AddChild(makeFirstToFindLabel(v))
					elseif group == "GeneralAchievement" then
						scroll_frame:AddChild(makeAchievementLabel2(v))
					elseif group == "First to Kill" then
						scroll_frame:AddChild(makeFirstToFindLabel(v))
					elseif group == "First to Complete" then
						scroll_frame:AddChild(makeFirstToFindLabel(v))
					elseif group == "First to Find" then
						scroll_frame:AddChild(makeFirstToFindLabel(v))
					elseif group == "Profession" then
						scroll_frame:AddChild(makeAchievementLabel2(v))
					elseif group == "Quest" then
						scroll_frame:AddChild(makeAchievementLabel2(v))
					elseif group == "Leveling" then
						scroll_frame:AddChild(makeAchievementLabel2(v))
					elseif group == "First to Max Profession" then
						scroll_frame:AddChild(makeFirstToFindLabel(v))
					elseif group == "Failure" then
						scroll_frame:AddChild(makeFailureLabel(v))
					elseif group == "OfficerCommand" then
						scroll_frame:AddChild(makeOfficerCommandLabel(v))
					end
				end
			end
		end
	end)

	tree_container:SelectByValue("Milestone")
end

local guild_member_subtitle_data = {
	{
		"Name",
		100,
		function(_player_name_short, _player_name_long)
			return _player_name_short or ""
		end,
	},
	{
		"Streamer Name",
		120,
		function(_player_name_short, _player_name_long)
			return ns.streamer_map[_player_name_long] or OnlyFangsStreamerMap[_player_name_long] or ""
		end,
	},
	{
		"Lvl",
		30,
		function(_player_name_short, _player_name_long)
			if ns.guild_online[_player_name_long] == nil then
				return ""
			end
			return ns.guild_online[_player_name_long].level or ""
		end,
	},
	{
		"Version",
		90,
		function(_player_name_short, _player_name_long)
			local version_text
			if
				(ns.guild_member_addon_info[_player_name_long] and ns.guild_online[_player_name_long])
				or _player_name_short == UnitName("player")
			then
				if _player_name_short == UnitName("player") then
					version_text = GetAddOnMetadata("OnlyFangs", "Version")
				else
					version_text = ns.guild_member_addon_info[_player_name_long]["version"]
				end

				if
					ns.guild_member_addon_info[_player_name_long]
					and ns.guild_member_addon_info[_player_name_long]["version_status"] ~= nil
					and ns.guild_member_addon_info[_player_name_long]["version_status"] == "updated"
				then
					version_text = "|c0000ff00" .. version_text .. "|r"
				else
					version_text = "|c00ffff00" .. version_text .. "|r"
				end
			else
				version_text = "|c00ff0000Not detected|r"
			end
			return version_text or ""
		end,
	},
}
local guild_member_font_container = CreateFrame("Frame")
guild_member_font_container:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
guild_member_font_container:Show()
local guild_member_entry_tbl = {}
local guild_member_font_strings = {} -- idx/columns
local guild_member_header_strings = {} -- columns
local guild_member_row_backgrounds = {} --idx
local guild_member_max_rows = 48 --idx
local guild_member_row_height = 10
local guild_member_Width = 850
for idx, v in ipairs(guild_member_subtitle_data) do
	guild_member_header_strings[v[1]] = guild_member_font_container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if idx == 1 then
		guild_member_header_strings[v[1]]:SetPoint("TOPLEFT", guild_member_font_container, "TOPLEFT", 0, 2)
	else
		guild_member_header_strings[v[1]]:SetPoint("LEFT", last_font_string, "RIGHT", 0, 0)
	end
	last_font_string = guild_member_header_strings[v[1]]
	guild_member_header_strings[v[1]]:SetJustifyH("LEFT")
	guild_member_header_strings[v[1]]:SetWordWrap(false)

	if idx + 1 <= #guild_member_subtitle_data then
		guild_member_header_strings[v[1]]:SetWidth(v[2])
	end
	guild_member_header_strings[v[1]]:SetTextColor(0.7, 0.7, 0.7)
	guild_member_header_strings[v[1]]:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
	guild_member_header_strings[v[1]]:SetText(v[1])
end
for i = 1, guild_member_max_rows do
	guild_member_font_strings[i] = {}
	local last_font_string = nil
	for idx, v in ipairs(guild_member_subtitle_data) do
		guild_member_font_strings[i][v[1]] =
			guild_member_font_container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		if idx == 1 then
			guild_member_font_strings[i][v[1]]:SetPoint(
				"TOPLEFT",
				guild_member_font_container,
				"TOPLEFT",
				0,
				-i * guild_member_row_height
			)
		else
			guild_member_font_strings[i][v[1]]:SetPoint("LEFT", last_font_string, "RIGHT", 0, 0)
		end
		last_font_string = guild_member_font_strings[i][v[1]]
		guild_member_font_strings[i][v[1]]:SetJustifyH("LEFT")
		guild_member_font_strings[i][v[1]]:SetWordWrap(false)

		if idx + 1 <= #guild_member_subtitle_data then
			guild_member_font_strings[i][v[1]]:SetWidth(v[2])
		end
		guild_member_font_strings[i][v[1]]:SetTextColor(1, 1, 1)
		guild_member_font_strings[i][v[1]]:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
	end

	guild_member_row_backgrounds[i] = guild_member_font_container:CreateTexture(nil, "OVERLAY")
	guild_member_row_backgrounds[i]:SetDrawLayer("OVERLAY", 2)
	guild_member_row_backgrounds[i]:SetVertexColor(0.5, 0.5, 0.5, (i % 2) / 10)
	guild_member_row_backgrounds[i]:SetHeight(guild_member_row_height)
	guild_member_row_backgrounds[i]:SetWidth(guild_member_Width)
	guild_member_row_backgrounds[i]:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	guild_member_row_backgrounds[i]:SetPoint(
		"TOPLEFT",
		guild_member_font_container,
		"TOPLEFT",
		0,
		-i * guild_member_row_height
	)
end

local function setGuildMemberData()
	local rows_used = 1
	for i = 1, GetNumGuildMembers() do
		if rows_used > guild_member_max_rows then
			break
		end
		local player_name_long, _, _, _, _, _, _, _, online, _, _ = GetGuildRosterInfo(i)
		if online then
			local player_name_short = string.split("-", player_name_long)
			for _, col in ipairs(guild_member_subtitle_data) do
				guild_member_font_strings[rows_used][col[1]]:SetText(col[3](player_name_short, player_name_long))
			end
			rows_used = rows_used + 1
		end
	end
	for k = rows_used, guild_member_max_rows do
		for _, col in ipairs(guild_member_subtitle_data) do
			guild_member_font_strings[rows_used][col[1]]:SetText("")
		end
	end
end

local function DrawAccountabilityTab(container)
	local function updateLabelData(_label_tbls, player_name_short)
		if ns.guild_member_addon_info[player_name_short] ~= nil then
			_label_tbls["party_mode_label"]:SetText(ns.guild_member_addon_info[player_name_short].party_mode)
			_label_tbls["first_recorded_label"]:SetText(
				date("%m/%d/%y", ns.guild_member_addon_info[player_name_short].first_recorded or 0)
			)

			if
				ns.guild_member_addon_info[player_name_short].achievements == nil
				or #ns.guild_member_addon_info[player_name_short].achievements > 0
				or #ns.guild_member_addon_info[player_name_short].passive_achievements > 0
			then
				local inline_text = ""
				for i, achievement_name in ipairs(ns.guild_member_addon_info[player_name_short].achievements) do
					if _G.achievements[achievement_name] then
						inline_text = inline_text
							.. "|T"
							.. _G.achievements[achievement_name].icon_path
							.. ":16:16:0:0:64:64:4:60:4:60|t"
					end
				end
				for i, achievement_name in ipairs(ns.guild_member_addon_info[player_name_short].passive_achievements) do
					if _G.passive_achievements[achievement_name] then
						inline_text = inline_text
							.. "|T"
							.. _G.passive_achievements[achievement_name].icon_path
							.. ":16:16:0:0:64:64:4:60:4:60|t"
					end
				end
				_label_tbls["achievement_label"]:SetText(inline_text)
				_label_tbls["achievement_label"]:SetCallback("OnEnter", function(widget)
					GameTooltip:SetOwner(WorldFrame, "ANCHOR_CURSOR")
					GameTooltip:AddLine("achievements")
					for i, achievement_name in ipairs(ns.guild_member_addon_info[player_name_short].achievements) do
						if _G.achievements[achievement_name] then
							GameTooltip:AddLine(_G.achievements[achievement_name].title)
						end
					end
					for i, achievement_name in
						ipairs(ns.guild_member_addon_info[player_name_short].passive_achievements)
					do
						if _G.passive_achievements[achievement_name] then
							GameTooltip:AddLine(_G.passive_achievements[achievement_name].title)
						end
					end
					GameTooltip:Show()
				end)
				_label_tbls["achievement_label"]:SetCallback("OnLeave", function(widget)
					GameTooltip:Hide()
				end)
			else
				_label_tbls["achievement_label"]:SetText("")
			end
			_label_tbls["hc_tag_label"]:SetText(
				ns.guild_member_addon_info[player_name_short].hardcore_player_name or ""
			)
		end

		local player_name_long = player_name_short .. "-" .. GetSpacelessRealmName()
		if ns.guild_online[player_name_long] ~= nil then
			local version_text
			if
				(ns.guild_member_addon_info[player_name_long] and ns.guild_online[player_name_long])
				or player_name_short == UnitName("player")
			then
				if player_name_short == UnitName("player") then
					version_text = GetAddOnMetadata("OnlyFangs", "Version")
				else
					version_text = ns.guild_member_addon_info[player_name_long]
				end

				if ns.guild_member_addon_info[player_name_long]["version_status"] == "updated" then
					version_text = "|c0000ff00" .. version_text .. "|r"
				else
					version_text = "|c00ffff00" .. version_text .. "|r"
				end
			else
				version_text = "|c00ff0000Not detected|r"
			end
			_label_tbls["version_label"]:SetText(version_text)

			_label_tbls["level_label"]:SetText(ns.guild_online[player_name_long].level)
		end
	end
	local function addEntry(_scroll_frame, player_name_short, _self_name)
		--local _player_name = player_name_short .. "-" .. GetSpacelessRealmName()
		local entry = AceGUI:Create("SimpleGroup")
		entry:SetLayout("Flow")
		entry:SetFullWidth(true)
		_scroll_frame:AddChild(entry)

		local name_label = AceGUI:Create("Label")
		name_label:SetWidth(110)
		name_label:SetText(player_name_short)
		name_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(name_label)
		guild_member_entry_tbl[player_name_short] = {}

		local level_label = AceGUI:Create("Label")
		level_label:SetWidth(50)
		level_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(level_label)
		guild_member_entry_tbl[player_name_short]["level_label"] = level_label

		local version_label = AceGUI:Create("Label")
		version_label:SetWidth(80)
		version_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(version_label)
		guild_member_entry_tbl[player_name_short]["version_label"] = version_label

		local party_mode_label = AceGUI:Create("Label")
		party_mode_label:SetWidth(75)
		party_mode_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(party_mode_label)
		guild_member_entry_tbl[player_name_short]["party_mode_label"] = party_mode_label

		local first_recorded_label = AceGUI:Create("Label")
		first_recorded_label:SetWidth(85)
		first_recorded_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(first_recorded_label)
		guild_member_entry_tbl[player_name_short]["first_recorded_label"] = first_recorded_label

		local achievement_label = AceGUI:Create("InteractiveLabel")
		achievement_label:SetWidth(320)
		achievement_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(achievement_label)
		guild_member_entry_tbl[player_name_short]["achievement_label"] = achievement_label

		local hc_tag_label = AceGUI:Create("Label")
		hc_tag_label:SetWidth(75)
		hc_tag_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(hc_tag_label)
		guild_member_entry_tbl[player_name_short]["hc_tag_label"] = hc_tag_label

		updateLabelData(guild_member_entry_tbl[player_name_short], player_name_short) -- , _player_name)
	end

	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("List")
	onlyfangs_tab_container:AddChild(scroll_container)

	local scroll_frame = AceGUI:Create("ScrollFrame")
	scroll_frame:SetLayout("List")
	scroll_container:AddChild(scroll_frame)
	guild_member_font_container:SetParent(scroll_container.frame)
	guild_member_font_container:SetPoint("TOPLEFT", scroll_container.frame, "TOPLEFT")
	guild_member_font_container:SetHeight(400)
	guild_member_font_container:SetWidth(200)
	setGuildMemberData()

	ticker_handler = C_Timer.NewTicker(1, function()
		setGuildMemberData()
	end)

	guild_member_font_container:Show()
	scroll_container.frame:HookScript("OnHide", function()
		guild_member_font_container:Hide()
	end)
end
local function drawTestTab(container)
	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("Fill")
	onlyfangs_tab_container:AddChild(scroll_container)

	local main_frame = AceGUI:Create("SimpleGroup")
	main_frame:SetLayout("Flow")
	main_frame:SetFullWidth(true)
	main_frame:SetFullHeight(true)
	scroll_container:AddChild(main_frame)

	for k, v in pairs(ns.event) do
		if v.test_only == 1 then
			if v.type == "Milestone" then
				main_frame:AddChild(makeFirstToFindLabel(v))
			else
				main_frame:AddChild(makeAchievementLabel2(v))
			end
		end
	end
end

local function drawLeaderboardTab(container)
	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("Fill")
	onlyfangs_tab_container:AddChild(scroll_container)

	local main_frame = AceGUI:Create("SimpleGroup")
	main_frame:SetLayout("Flow")
	main_frame:SetFullWidth(true)
	main_frame:SetFullHeight(true)
	scroll_container:AddChild(main_frame)

	local _frames = {}
	local top_scores = {}
	top_scores["Daily"], top_scores["Weekly"], top_scores["All Time"] = ns.getTopPlayers()
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
			if top_scores[_type][j] ~= nil then
				_line:SetText(j .. ". " .. top_scores[_type][j].streamer_name .. "(" .. top_scores[_type][j].pts .. ")")
			else
				_line:SetText(j .. ". ")
			end
			__f:AddChild(_line)
			local _pts = AceGUI:Create("Label")
			_pts:SetWidth(40)
			_pts:SetText("")
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

	local reset_button = AceGUI:Create("Button")
	reset_button:SetText("Refresh")
	reset_button:SetHeight(25)
	reset_button:SetWidth(120)
	reset_button:SetCallback("OnClick", function(self)
		container:ReleaseChildren()
		ns.refreshGuildList(true)
		ns.aggregateLog()
		drawLeaderboardTab(container)
	end)
	main_frame:AddChild(reset_button)
end

local function createMenu()
	local ace_deathlog_menu = AceGUI:Create("DeathlogMenu")
	_G["AceOnlyFangsMenu"] = ace_deathlog_menu.frame -- Close on <ESC>
	ace_deathlog_menu:SetCallback("OnClose", function(widget)
		if ticker_handler ~= nil then
			ticker_handler:Cancel()
			ticker_handler = nil
		end
		-- hardcore_modern_menu_state.entry_tbl = {}
		-- AceGUI:Release(widget)
	end)
	ace_deathlog_menu:SetCallback("OnHide", function(widget)
		if ticker_handler ~= nil then
			ticker_handler:Cancel()
			ticker_handler = nil
		end
		-- hardcore_modern_menu_state.entry_tbl = {}
		-- AceGUI:Release(widget)
	end)
	tinsert(UISpecialFrames, "AceOnlyFangsMenu")

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

	onlyfangs_tab_container = AceGUI:Create("DeathlogTabGroup") -- "InlineGroup" is also good
	local tab_table = {}
	for _, v in ipairs(Deathlog_L.tab_table) do
		if v["value"] == "TestingPoints" then
			if ns.enable_testing == true then
				tab_table[#tab_table + 1] = v
			end
		else
			tab_table[#tab_table + 1] = v
		end
	end
	onlyfangs_tab_container:SetTabs(tab_table)
	onlyfangs_tab_container:SetFullWidth(true)
	onlyfangs_tab_container:SetFullHeight(true)
	onlyfangs_tab_container:SetLayout("Flow")

	local function SelectGroup(container, event, group)
		container:ReleaseChildren()
		if group == "PointsTab" then
			drawEventTypeTab(container)
		elseif group == "LogTab" then
			drawLogTab(container)
		elseif group == "LeaderboardTab" then
			drawLeaderboardTab(container)
		elseif group == "GuildMembersTab" then
			DrawAccountabilityTab(container)
		elseif group == "TestingPoints" then
			drawTestTab(container)
		end
	end

	onlyfangs_tab_container:SetCallback("OnGroupSelected", SelectGroup)

	ace_deathlog_menu:AddChild(onlyfangs_tab_container)
	return ace_deathlog_menu
end

deathlog_menu = createMenu()

ns.showMenu = function()
	deathlog_menu:Show()
	onlyfangs_tab_container:SelectTab("LogTab")
	setLogData()
end
