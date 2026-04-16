local NEWBIE_ICON_PATH = [[Interface\AddOns\MeetingStone\Media\Locomotive\Newbie]]
local NEWBIE_ICON_STR = [[|TInterface\AddOns\MeetingStone\Media\Locomotive\Newbie:16:64|t]]

local function GetNewbieElapsedMins(fullName)
    local db = MEETINGSTONE_UI_DB and MEETINGSTONE_UI_DB.global and MEETINGSTONE_UI_DB.global.LocomotiveData
    if not db then return nil end

    local data = db[fullName]
    if data and data.isNewbie and data.newbieExpireTime and time() < data.newbieExpireTime then
        local checkTime = data.medalTime or (data.newbieExpireTime - 18000)
        local elapsedMins = math.floor((time() - checkTime) / 60)
        return math.max(0, elapsedMins)
    end
    return nil
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    local MS = LibStub("AceAddon-3.0"):GetAddon("MeetingStone", true)
    if not MS then return end
    
    local MainPanel = MS:GetModule("MainPanel", true)
    if not MainPanel or not MainPanel.OnInitialize then return end

    local MSEnv = getfenv(MainPanel.OnInitialize)
    local MemberDisplay = MSEnv.MemberDisplay

    if MemberDisplay and MemberDisplay.SetActivity then
        hooksecurefunc(MemberDisplay, "SetActivity", function(self, activity)
            if not self.DataDisplay then return end

            if not self.msNewbieIcon then
                self.msNewbieIcon = self.DataDisplay:CreateTexture(nil, "OVERLAY", nil, 7)
                self.msNewbieIcon:SetSize(64, 16)
                self.msNewbieIcon:SetTexture(NEWBIE_ICON_PATH)
                self.msNewbieIcon:SetPoint("RIGHT", self.DataDisplay, "LEFT", 600, 0)
            end

            if activity then
                local leaderName = activity:GetLeader()
                if leaderName then
                    if not string.find(leaderName, "-") then
                        leaderName = leaderName .. "-" .. GetRealmName()
                    end
                    
                    if GetNewbieElapsedMins(leaderName) then
                        self.msNewbieIcon:Show()
                    else
                        self.msNewbieIcon:Hide()
                    end
                else
                    self.msNewbieIcon:Hide()
                end
            else
                self.msNewbieIcon:Hide()
            end
        end)
    end

    hooksecurefunc(MainPanel, "OpenActivityTooltip", function(self, activity, tooltip)
        tooltip = tooltip or self.GameTooltip
        if not tooltip or not activity then return end

        local leaderName = activity:GetLeader()
        if not leaderName then return end

        if not string.find(leaderName, "-") then
            leaderName = leaderName .. "-" .. GetRealmName()
        end

        local elapsedMins = GetNewbieElapsedMins(leaderName)
        if elapsedMins then
            if tooltip.AddSepatator then tooltip:AddSepatator() end
            tooltip:AddLine("|cff00ff00队长是|r" .. NEWBIE_ICON_STR .. "(" .. elapsedMins .. "分钟前检测)")
            tooltip:Show()
        end
    end)

    if TooltipDataProcessor then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
            if tooltip ~= GameTooltip then return end
            local _, unit = tooltip:GetUnit()
            if not unit or not UnitIsPlayer(unit) then return end

            local name, realm = UnitName(unit)
            if not name then return end
            if not realm or realm == "" then realm = GetRealmName() end
            
            local fullName = name .. "-" .. realm
            local elapsedMins = GetNewbieElapsedMins(fullName)

            if elapsedMins then
                tooltip:AddLine(" ")
                tooltip:AddLine(NEWBIE_ICON_STR .. "(" .. elapsedMins .. "分钟前检测)")
            end
        end)
    end
    
    print("|cff00ff00[集合石新兵增强已加载]|r 插件所有信息来自网易集合石的缓存数据，晚间时段流量较大，新兵信息可能并不完整，还请谨慎判断。使用|cFF00FFFF/msd|r可进入调试页面，查看网易集合石返回的原始信息")
end)