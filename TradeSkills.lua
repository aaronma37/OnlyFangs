local tradeSkillFrame = CreateFrame("Frame")

local function OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        isLogin, isReload = ...
        if isLogin or isReload then
            C_TradeSkillUI.IsGuildTradeSkillsEnabled = function() return true end
            hooksecurefunc(CommunitiesMemberListEntryMixin, "RefreshExpandedColumns", function(self) 
                local memberInfo = self:GetMemberInfo()
                local professionID = self:GetProfessionId()
                if memberInfo and professionID then
                    if professionID == memberInfo.profession1ID then
                        self.GuildInfo:SetText(tostring(memberInfo.profession1Rank))
                    elseif professionID == memberInfo.profession2ID then
                        self.GuildInfo:SetText(tostring(memberInfo.profession2Rank))
                    end
                end
            end)
        end
    end
end

tradeSkillFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
tradeSkillFrame:SetScript("OnEvent", OnEvent)