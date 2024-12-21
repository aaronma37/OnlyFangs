SLASH_GUILDFOUND1 = "/guildfound"
SLASH_GUILDFOUND2 = "/gf"

local AceComm = LibStub("AceComm-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")

local BROADCAST_INTERVAL = 30

local GuildFoundFrame = CreateFrame("Frame", "GuildFoundFrame")
local prefix = "GuildFound"
local lastTx = 0

local localPlayerNeeds = {}
local guildNeeds = {}

local debug = true

local function prettyPrint(msg)
    print("|cffffff00[GuildFound]|r " .. msg)
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
--    prettyPrint("Received message from " .. from)
    local success, deserialized = AceSerializer:Deserialize(msg)
    if success then
        if #deserialized == 0 then
            guildNeeds[from] = nil
        else
            guildNeeds[from] = deserialized
        end
--        DevTools_Dump(guildNeeds)
    else
--        prettyPrint("Couldn't deserialize message")
    end
end

local function getNeeders(itemName)
    local needers = {}
    for k, v in pairs(guildNeeds) do
        for _,s in pairs(v) do
            if string.upper(itemName) == string.upper(s) then
                needers[#needers + 1] = k
            end
        end
    end
    return needers
end

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
        end
    elseif event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "GuildFound" then
            if not GuildFound_Saved then
                GuildFound_Saved = {}
            end
            localPlayerNeeds = GuildFound_Saved.localPlayerNeeds or {}
        end
    elseif event == "PLAYER_LOGOUT" then
        if not GuildFound_Saved then
            GuildFound_Saved = {}
        end
        GuildFound_Saved.localPlayerNeeds = localPlayerNeeds
    end
end

local function OnUpdate()
    local t = GetTime()
    if t - lastTx > BROADCAST_INTERVAL then
        broadcast()
    end
end

GuildFoundFrame:RegisterEvent("CHAT_MSG_ADDON")
GuildFoundFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
GuildFoundFrame:RegisterEvent("ADDON_LOADED")
GuildFoundFrame:RegisterEvent("PLAYER_LOGOUT")
GuildFoundFrame:SetScript("OnEvent", OnEvent)
GuildFoundFrame:SetScript("OnUpdate", OnUpdate)

local function SlashCommandHandler(msg)
    if string.sub(msg, 1, 4) == "add " then
        local item = string.sub(msg, 5)
        if string.len(item) > 0 then
            localPlayerNeeds[#localPlayerNeeds+1] = item
            prettyPrint("Added '" .. item .. "' to needed items")
        end        
        broadcast()
    elseif string.sub(msg, 1, 7) == "remove " then
        local item = string.sub(msg, 8)
        if string.len(item) > 0 then
            for k, v in pairs(localPlayerNeeds) do
                if string.upper(v) == string.upper(item) then
                    localPlayerNeeds[k] = nil
                end
            end
        end
        broadcast()
        prettyPrint("Removed '" .. item .. "' from needed items")
    elseif string.sub(msg, 1, 5) == "clear" then
        localPlayerNeeds = {}
        broadcast()
        prettyPrint("Cleared your list of needed items")
    elseif string.sub(msg, 1, 4) == "list" then
        prettyPrint("Needed items:")
        for k, v in pairs(localPlayerNeeds) do
            print(" - " .. v)
        end
    elseif string.sub(msg, 1, 9) == "whoneeds " then
        local item = string.sub(msg, 10)
        if string.len(item) > 0 then
            prettyPrint("Needers for '" .. item .. "':")
            local needers = getNeeders(item)
            if #needers == 0 then
                print("No needers for '" .. item .. "'.")
            end
            for k, v in pairs(needers) do
                print(" - " .. v)
            end
        end
    elseif string.sub(msg, 1, 4) == "help" then
        prettyPrint("Available commands:")
        print("|cffffff00/gf help|r print this message")
        print("|cffffff00/gf add itemName|r add itemName to your list of needed items")
        print("|cffffff00/gf remove itemName|r remove itemName from your list of needed items")
        print("|cffffff00/gf clear|r remove all items from your list of needed items")
        print("|cffffff00/gf list|r print your list of needed items")
        print("|cffffff00/gf whoneeds itemName|r print a list of guild members that need itemName")
    else
        prettyPrint("Unrecognized command: " .. msg)
    end
end

GameTooltip:HookScript("OnTooltipSetItem", function(tooltip, ...)
    local name = tooltip:GetItem()
    --Add the name and path of the item's texture
    local needers = getNeeders(name)

    local max = 6
    if #needers >= 1 then
        tooltip:AddLine("|cffff4040<OF>|r |cffffff00Needed By:|r")
        for i, v in pairs(needers) do
            if i < max or #needers == max then
                tooltip:AddLine("  |cff3ce13f" .. v .. "|r")
            else
                local extra = #needers - max + 1
                tooltip:AddLine("  |cffbbbbbb+ " .. tostring(extra) .. " more|r")
                break
            end
        end
        --Repaint tooltip with newly added lines
        tooltip:Show()
    end
  end)

SlashCmdList["GUILDFOUND"] = SlashCommandHandler