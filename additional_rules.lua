local addonName, ns = ...
local rule_event_handler = nil
rule_event_handler = CreateFrame("frame")

local mail_button = {}

local in_guild = function(_n)
	for g_idx = 1, GetNumGuildMembers() do
		member_name, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ = GetGuildRosterInfo(g_idx)
		local player_name_short = string.split("-", member_name)
		if player_name_short == _n then
			return true
		end
	end
	return false
end

local on_mail_show = function()
	C_Timer.NewTicker(0.2, function(self)
		if _G["MailFrame"]:IsVisible() == false then
			self:Cancel()
		end
		for i = 1, 7 do
			local _name = _G["MailItem" .. tostring(i) .. "Sender"]:GetText()
			-- local _name = _G["MailItem" .. tostring(i) .. "Subject"]:GetText()

			if _name == nil or in_guild(_name) then
				_G["MailItem" .. tostring(i)]:SetAlpha(1.0)
				_G["MailItem" .. tostring(i)]:EnableMouse(1)
				_G["MailItem" .. tostring(i) .. "Button"]:Enable()
			else
				print("Returning mail from: ", _name)
				ReturnInboxItem(i)
				return
			end
		end
	end)
end

rule_event_handler:RegisterEvent("MAIL_SHOW")
rule_event_handler:RegisterEvent("MAIL_INBOX_UPDATE")
rule_event_handler:RegisterEvent("AUCTION_HOUSE_SHOW")

rule_event_handler:SetScript("OnEvent", function(self, event, ...)
	if event == "MAIL_SHOW" or event == "MAIL_INBOX_UPDATE" then
		on_mail_show()
	elseif event == "AUCTION_HOUSE_SHOW" then
		CloseAuctionHouse()
		print("|cFFFF0000[OnlyFangs] BLOCKED:|r You may not trade outside of the guild.")
	end
end)

TradeFrameTradeButton:SetScript("OnClick", function()
	local target_trader = TradeFrameRecipientNameText:GetText()
	if in_guild(target_trader) or CanEditOfficerNote() then
		AcceptTrade()
	else
		print("|cFFFF0000[OnlyFangs] BLOCKED:|r You may not trade outside of the guild.")
	end
end)

-- local handler = CreateFrame("frame")
-- handler:RegisterEvent("UNIT_TARGET")
--
-- handler:SetScript("OnEvent", function(self, event, ...)
-- 	print(in_guild(UnitName("target")))
-- end)
