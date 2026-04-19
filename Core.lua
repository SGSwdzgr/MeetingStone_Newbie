local EX_ADDON_NAME = "MeetingStoneEX"

StaticPopupDialogs["MS_NEWBIE_RADAR_CONFLICT"] = {
    text = "|cffff0000【新兵增强 - 严重冲突警告】|r\n\n检测到残留的修改版集合石核心，请手动删除魔兽目录 _retail_\\Interface\\AddOns 下的 |cffffff00MeetingStoneEX|r 文件夹。\n\n这是你之前（如开心集合石等）修改版集合石插件的补充模块，会导致网易官方集合石运行异常，列表页提示“未知目标”等问题。",
    button1 = "我知道了，忽略提醒",
    button2 = "我已删除，重载界面",
    OnAccept = function()
        print("|cff00ff00[新兵增强]|r 你选择了忽略提醒，请确保已手动处理冲突。")
    end,
    OnCancel = function()
        ReloadUI()
    end,
    showAlert = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
}

local conflictChecker = CreateFrame("Frame")
conflictChecker:RegisterEvent("PLAYER_LOGIN")
conflictChecker:SetScript("OnEvent", function()
    local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(EX_ADDON_NAME)
    
    if name and reason ~= "MISSING" then
        C_Timer.After(1.5, function()
            StaticPopup_Show("MS_NEWBIE_RADAR_CONFLICT")
            print("|cffff0000[新兵增强] 警告：检测到不兼容的 MeetingStoneEX 模块，请务必手动删除并重载界面！|r")
        end)
    end
end)

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
                tooltip:AddLine("|cff888888队长为集合石认证老兵|r" )
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
                    tooltip:AddLine("|cff88888集合石认证老兵|r" )
                end
            end
        end)
    end

    print("|cff00ff00[新兵增强]|r模块已加载。高峰时段（尤其是每日18~23点）看不到新兵标记是网易集合石数据延迟导致的正常情况，本插件无法解决此问题，此时网易集合石开组也是看不到新兵信息的。 如需确认，可 |cffffff00/msd|r 查看新兵信息的原始收发记录，有发包信息即为增强模块工作正常，等待网易服务器返回数据即可")

end)