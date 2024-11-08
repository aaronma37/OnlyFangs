local addonName, ns = ...
local rule_event_handler = nil
rule_event_handler = CreateFrame("frame")

local on_mail_show = function()
	for i = 1, 7 do
		local _name = _G["MailItem" .. tostring(i) .. "Subject"]:GetText()
		local in_whitelist = function(_n)
			if
				ns.whitelist ~= nil
				and ns.whitelist ~= nil
				and ns.whitelist[_n] ~= nil
				and UnitLevel("player") <= ns.whitelist[_n]
			then
				return true
			end
			return false
		end

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

		if _name == nil or in_whitelist(_name) or in_guild(_name) then
			_G["MailItem" .. tostring(i)]:SetAlpha(1.0)
			_G["MailItem" .. tostring(i)]:EnableMouse(1)
			_G["MailItem" .. tostring(i) .. "Button"]:Enable()
		else
			print("Disabling mail from: ", _name)
			_G["MailItem" .. tostring(i)]:SetAlpha(0.5)
			_G["MailItem" .. tostring(i)]:EnableMouse(0)
			_G["MailItem" .. tostring(i) .. "Button"]:Disable()
		end
	end
end

rule_event_handler:RegisterEvent("MAIL_SHOW")
rule_event_handler:RegisterEvent("MAIL_INBOX_UPDATE")
rule_event_handler:RegisterEvent("AUCTION_HOUSE_SHOW")

rule_event_handler:SetScript("OnEvent", function(self, event, ...)
	if event == "MAIL_SHOW" or event == "MAIL_INBOX_UPDATE" then
		on_mail_show()
	elseif event == "AUCTION_HOUSE_SHOW" then
		CloseAuctionHouse()
	end
end)
