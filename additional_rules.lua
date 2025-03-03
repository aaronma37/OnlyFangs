local addonName, ns = ...
local rule_event_handler = nil
rule_event_handler = CreateFrame("frame")

local REALM_NAME = GetRealmName()
REALM_NAME = REALM_NAME:gsub("%s+", "")

local mail_button = {}

local in_guild = function(_n)
	if OnlyFangsStreamerMap[_n .. "-" .. REALM_NAME] ~= nil then
		return true
	end
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
	if CanEditOfficerNote() == false then
		C_Timer.NewTicker(0.2, function(self)
			if _G["MailFrame"]:IsVisible() == false then
				self:Cancel()
			end
			for i = 1, 7 do
				local _, _, _name = GetInboxHeaderInfo(i)
				if _name == nil or in_guild(_name) or _name == "Horde Auction House" or _name == "Alliance Auction House" then
					_G["MailItem" .. tostring(i)]:SetAlpha(1.0)
					_G["MailItem" .. tostring(i)]:EnableMouse(1)
					_G["MailItem" .. tostring(i) .. "Button"]:Enable()
				else
					-- print("Returning mail from: ", _name)
					ReturnInboxItem(i)
					return
				end
			end
		end)
	else
		print("Officer's mail is not blocked.")
	end
end

rule_event_handler:RegisterEvent("MAIL_SHOW")
rule_event_handler:RegisterEvent("MAIL_INBOX_UPDATE")
rule_event_handler:RegisterEvent("AUCTION_HOUSE_SHOW")

local function canBuyItem()
	if CanEditOfficerNote() == true then
		return true
	end


    local index = GetSelectedAuctionItem(AuctionFrame.type)
    local name, texture, count, quality, canUse, level, levelColHeader,
          minBid, minIncrement, buyoutPrice, bidAmount, highBidder,
          bidderFullName, owner, ownerFullName, saleStatus, itemId, hasAllInfo =
          GetAuctionItemInfo(AuctionFrame.type, index)

    if not hasAllInfo then
        return false
    end

    local classID = select(6, GetItemInfoInstant(itemId))
    -- disallow Flask of Petrification
    if itemId == 13506 then
        print("|cFFFF0000[OnlyFangs] BLOCKED:|r Flask of Petrification can't be bought from the auction house.")
        return false
    end
    -- allow Potions, Tradegoods and Reagents
    if classID == Enum.ItemClass.Consumable then
        return true
    end
    if classID == Enum.ItemClass.Tradegoods then
        return true
    end
    if classID == Enum.ItemClass.Reagent then
        return true
    end

    -- everything else is disallowed
    print("|cFFFF0000[OnlyFangs] BLOCKED:|r Only Consumables, Reagents and Tradegoods may be purchased from the auction house.")
    return false
end

local function CloseAH(reason)
	print("|cFFFF0000[OnlyFangs] BLOCKED:|r You must disable the " .. reason .. " addon to use the Auction House")

	-- For whatever reason, when opening the AH after installing the addon for the first time,
	-- the first CloseAuctionHouse call doesn't work ~50% of the time
	--
	-- running CloseAuctionHouse in C_Timer seems to work reliably in all cases
	C_Timer.After(0.1, function ()
		CloseAuctionHouse()
	end)
	C_Timer.After(0.25, function ()
		CloseAuctionHouse()
	end)
	C_Timer.After(0.75, function ()
		CloseAuctionHouse()
	end)
end

local common_auction_addons = {
    ["preserveauctionatorahscan"]=1,
    ["sorted_auctionator"]=1,
    ["auctioneer"]=1,
    ["tdauction"]=1,
    ["tradeskillmaster"]=1,
    ["alatrade"]=1,
    ["auctionator"]=1,
    ["auctionbuddy"]=1,
    ["auctionfaster"]=1,
    ["auctionlite-classic"]=1,
    ["auctionwatch"]=1,
    ["auctipus"]=1,
    ["autionerfast"]=1,
    ["autoauction"]=1,
    ["aux-addon"]=1,
    ["auc-stat-stddev"]=1,
    ["auc-util-fixah"]=1,
    ["beancounter"]=1,
    ["auc-advanced"]=1,
    ["auc-filter-basic"]=1,
    ["auc-scandata"]=1,
    ["auc-stat-histogram"]=1,
    ["auc-stat-ilevel"]=1,
    ["auc-stat-purchased"]=1,
    ["auc-stat-simple"]=1,
}

-- Hooks into the existing AH Buyout and Bid buttons,
-- disabling the buttons' functionality when a non-potion item is selected
--
-- all other AuctionHouse functionality work as normal, so you can still sell, cancel, etc
--
-- there are some auction addons that also have bid/buyout buttons. So we require them to be disable to use the AH
OF_DID_HOOK_AH = false
rule_event_handler:SetScript("OnEvent", function(self, event, ...)
	if event == "MAIL_SHOW" or event == "MAIL_INBOX_UPDATE" then
		on_mail_show()
	elseif event == "AUCTION_HOUSE_SHOW" then
		-- disallow AH if auction addons are installed, since they could bypass the security checks

        for i = 1, GetNumAddOns() do
            local otherAddonName, _, _, isLoadable = GetAddOnInfo(i)
            local canLoad = isLoadable or select(1, IsAddOnLoaded(i))
            if canLoad and common_auction_addons[otherAddonName:lower()] then
                CloseAH(otherAddonName)
                return
            end
        end
        if not OF_DID_HOOK_AH then
            OF_DID_HOOK_AH = true

            local originalBuyoutOnClick = BrowseBuyoutButton:GetScript("OnClick")
            local originalBidOnClick = BrowseBidButton:GetScript("OnClick")

            BrowseBuyoutButton:SetScript("OnClick", function(self, button, down)
                if canBuyItem() then
                    originalBuyoutOnClick(self, button, down)
                end
            end)

            BrowseBidButton:SetScript("OnClick", function(self, button, down)
                if canBuyItem() then
                    originalBidOnClick(self, button, down)
                end
            end)
		end
	end
end)

local function notReceivingItems()
	local _money = GetTargetTradeMoney()
	if _money ~= 0 then
		print("|cFFFF0000[OnlyFangs] BLOCKED:|r You may not receive gold from outside of the guild.")
		return false
	end
	for i = 1, 6 do
		local _item_name, texture, quantity, quality, isUsable, enchant = GetTradeTargetItemInfo(i)
		if _item_name then
			print("|cFFFF0000[OnlyFangs] BLOCKED:|r You may not receive items from outside of the guild.")
			return false
		end
	end

	local _item_name, texture, quantity, quality, isUsable, enchant = GetTradePlayerItemInfo(7)
	if _item_name then
		print("|cFFFF0000[OnlyFangs] BLOCKED:|r You may not receive enchants from outside of the guild.")
		return false
	end
	return true
end

TradeFrameTradeButton:SetScript("OnClick", function()
	local target_trader = TradeFrameRecipientNameText:GetText()
	if in_guild(target_trader) or notReceivingItems() or CanEditOfficerNote() then
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

C_Timer.NewTicker(60, function(self)
	for i = 1, 40 do
		local buff_name, _, _, _, _, _, _, _, _, _, _ = UnitBuff("player", i)
		if buff_name == nil then
			return
		end
		if buff_name == "Spirit of Zandalar" then
			CancelUnitBuff("player", i)
			print("OnlyFangs: Removing buff " .. buff_name .. ".")
		end
	end
end)
