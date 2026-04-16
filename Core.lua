local NEWBIE_ICON_PATH = [[Interface\AddOns\MeetingStone\Media\Locomotive\Newbie]]
local NEWBIE_ICON_STR = [[|TInterface\AddOns\MeetingStone\Media\Locomotive\Newbie:16:64|t]]

local function GetLocomotiveData(fullName)
    local db = MEETINGSTONE_UI_DB and MEETINGSTONE_UI_DB.global and MEETINGSTONE_UI_DB.global.LocomotiveData
    if not db then return false, false, 0 end
    local data = db[fullName]
    if not data then return false, false, 0 end
    local isNewbie = false
    if data.isNewbie and data.newbieExpireTime and time() < data.newbieExpireTime then
        isNewbie = true
    end
    local checkTime = data.medalTime or (data.newbieExpireTime and data.newbieExpireTime - 18000) or 0
    local elapsedMins = 0
    if checkTime > 0 then
        elapsedMins = math.max(0, math.floor((time() - checkTime) / 60))
    end
    return true, isNewbie, elapsedMins
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    local MS = LibStub("AceAddon-3.0"):GetAddon("MeetingStone", true)
    if not MS then return end
    local MainPanel = MS:GetModule("MainPanel", true)
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
                    local hasData, isNewbie = GetLocomotiveData(leaderName)
                    if hasData and isNewbie then
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

        local hasData, isNewbie, elapsedMins = GetLocomotiveData(leaderName)
        if hasData then
            if tooltip.AddSepatator then tooltip:AddSepatator() else tooltip:AddLine(" ") end
            if isNewbie then
                tooltip:AddLine("|cff00ff00队长是|r" .. NEWBIE_ICON_STR .. "(" .. elapsedMins .. "分钟前检测)")
            else
                tooltip:AddLine("|cff888888队长为S1赛季老兵|r" )
            end
            tooltip:Show()
        end
    end)

    if TooltipDataProcessor then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
            if tooltip ~= GameTooltip then return end
            local _, unit = tooltip:GetUnit()
            if not unit or type(unit) ~= "string" then return end

            local ok1, isPlayer = pcall(UnitIsPlayer, unit)
            if not ok1 or not isPlayer then return end

            local ok2, name, realm = pcall(UnitName, unit)
            if not ok2 or not name then return end
            if not realm or realm == "" then realm = GetRealmName() end
            
            local fullName = name .. "-" .. realm
            local hasData, isNewbie, elapsedMins = GetLocomotiveData(fullName)
            if hasData then
                tooltip:AddLine(" ")
                if isNewbie then
                    tooltip:AddLine(NEWBIE_ICON_STR .. "(" .. elapsedMins .. "分钟前检测)")
                else
                    tooltip:AddLine("|cff888888S1赛季老兵认证|r" )
                end
            end
        end)
    end
end)