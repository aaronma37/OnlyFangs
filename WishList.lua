SLASH_WISHLIST1 = "/wishlist"
SLASH_WISHLIST2 = "/wl"

local AceComm = LibStub("AceComm-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")

local BROADCAST_INTERVAL = 30

local WishListFrame = CreateFrame("Frame", "WishListFrame")
local prefix = "WishList"
local lastTx = 0

local localPlayerNeeds = {}
local guildNeeds = {}
local needersByItem = {}

local debug = true

local function prettyPrint(msg)
    print("|cffffff00[WishList]|r " .. msg)
end

local function debugPrint(msg)
    if debug then
        prettyPrint("|cff40ff40[Debug]|r " .. msg)
    end
end

local function sendAddonMessage(msg)
    if prefix then
        local msgChannel = "GUILD"
        lastTx = GetTime()
        AceComm:SendCommMessage(prefix, msg, msgChannel)
    end
end

local function broadcast() 
    local serialized = AceSerializer:Serialize(localPlayerNeeds)
    sendAddonMessage(serialized)
end

local function processMessage(msg, from)
    -- prettyPrint("Received message from " .. from)
    local success, deserialized = AceSerializer:Deserialize(msg)
    if success then

        local priorNeeds = guildNeeds[from]

        if deserialized == {} then
            guildNeeds[from] = nil
        else
            guildNeeds[from] = deserialized
        end

        -- Populate needersByItem
        for k, v in pairs(deserialized) do
            local needers = needersByItem[string.upper(k)] or {}
            needers[from] = true
            needersByItem[string.upper(k)] = needers
        end

        -- check for removed items from wishlist
        if priorNeeds then
            for k, v in pairs(priorNeeds) do
                if not deserialized[k] then
                    local needers = needersByItem[string.upper(k)] or {}
                    needers[from] = nil
                    needersByItem[string.upper(k)] = needers
                end
            end
        end
    else
--        prettyPrint("Couldn't deserialize message")
    end
end

local function getNeeders(itemName)
    return needersByItem[string.upper(itemName)] or {}
end

local function addItem(itemName)
    localPlayerNeeds[string.upper(itemName)] = {itemName = itemName}
end

local function removeItem(itemName)
    localPlayerNeeds[string.upper(itemName)] = nil
end

local function clearItems()
    localPlayerNeeds = {}
end

local ticker
local function OnEvent(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local pf, msg, channel, _, from = ...
        if pf ~= prefix then return end
        if channel == "GUILD" then
            processMessage(msg, from)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isLogin, isReload = ...
        if isLogin or isReload then
            C_ChatInfo.RegisterAddonMessagePrefix(prefix)
            broadcast()
            ticker = C_Timer.NewTicker(BROADCAST_INTERVAL, function() 
                broadcast()
            end)
        end
    elseif event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "OnlyFangs" then
            if not WishList_Saved then
                WishList_Saved = {}
            end
            localPlayerNeeds = WishList_Saved.localPlayerNeeds or {}
            guildNeeds = WishList_Saved.guildNeeds or {}
            needersByItem = WishList_Saved.needersByItem or {}
        end
    elseif event == "PLAYER_LOGOUT" then
        if not WishList_Saved then
            WishList_Saved = {}
        end
        WishList_Saved.localPlayerNeeds = localPlayerNeeds
        WishList_Saved.guildNeeds = guildNeeds
        WishList_Saved.needersByItem = needersByItem
    end
end



WishListFrame:RegisterEvent("CHAT_MSG_ADDON")
WishListFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
WishListFrame:RegisterEvent("ADDON_LOADED")
WishListFrame:RegisterEvent("PLAYER_LOGOUT")
WishListFrame:SetScript("OnEvent", OnEvent)
WishListFrame:SetScript("OnUpdate", OnUpdate)



local function SlashCommandHandler(msg)
    if string.sub(msg, 1, 4) == "add " then
        local item = string.sub(msg, 5)
        if string.len(item) > 0 then
            addItem(item)
            prettyPrint("Added '" .. item .. "' to needed items")
        end        
        broadcast()
    elseif string.sub(msg, 1, 7) == "remove " then
        local item = string.sub(msg, 8)
        if string.len(item) > 0 then
            removeItem(item)
            prettyPrint("Removed '" .. item .. "' from needed items")
        end
        broadcast()
    elseif string.sub(msg, 1, 5) == "clear" then
        clearItems()
        broadcast()
        prettyPrint("Cleared your list of needed items")
    elseif string.sub(msg, 1, 4) == "list" then
        prettyPrint("Needed items:")
        for k, v in pairs(localPlayerNeeds) do
            print(" - " .. v.itemName)
        end
    elseif string.sub(msg, 1, 9) == "whoneeds " then
        local item = string.sub(msg, 10)
        if string.len(item) > 0 then
            prettyPrint("Needers for '" .. item .. "':")
            local needers = getNeeders(item)
            local i = 0
            for k, v in pairs(needers) do
                i = i + 1
                print(" - " .. k)
            end

            if i == 0 then
                print("No needers for '" .. item .. "'.")
            end
        end
    elseif string.sub(msg, 1, 4) == "help" then
        prettyPrint("Available commands:")
        print("|cffffff00/wl help|r print this message")
        print("|cffffff00/wl add itemName|r add itemName to your list of needed items")
        print("|cffffff00/wl remove itemName|r remove itemName from your list of needed items")
        print("|cffffff00/wl clear|r remove all items from your list of needed items")
        print("|cffffff00/wl list|r print your list of needed items")
        print("|cffffff00/wl whoneeds itemName|r print a list of guild members that need itemName")
    else
        prettyPrint("Unrecognized command: " .. msg)
    end
end

GameTooltip:HookScript("OnTooltipSetItem", function(tooltip, ...)
    local name = tooltip:GetItem()
    --Add the name and path of the item's texture
    local needers = getNeeders(name)
    local count = 0
    for k,v in pairs(needers) do count = count + 1 end

    local max = 5
    if count >= 1 then
        tooltip:AddLine("|cffff4040<OF>|r |cffffff00Needed By:|r")
        local i = 0
        for k, v in pairs(needers) do
            i = i + 1
            if i < max or count == max then
                tooltip:AddLine("  |cff3ce13f" .. k .. "|r")
            else
                local extra = count - max + 1
                tooltip:AddLine("  |cffbbbbbb+ " .. tostring(extra) .. " more|r")
                break
            end
        end
        --Repaint tooltip with newly added lines
        tooltip:Show()
    end
  end)

WishList = {}
function WishList:SetFromText(text)
    clearItems()
    for token in string.gmatch(text, "[^\r\n]+") do
        if string.len(token) > 0 then
            addItem(token)
        end
    end
    broadcast()
end

function WishList:GetText()
    local text = ""
    for k, v in pairs(localPlayerNeeds) do
        text = text .. v.itemName .. "\n"
    end
    return text
end

function WishList:WhoNeeds(text)
    return getNeeders(text)
end

SlashCmdList["WISHLIST"] = SlashCommandHandler