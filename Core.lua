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

-- ==========================================
-- 队伍成员身份主动查询和通报
-- 来源：https://bbs.nga.cn/read.php?tid=47025650
-- 作者：Khanid
-- ==========================================
local announcedMembers = {} 
local pendingQueries = {}   
local isQuerying = false

local function GetPartyMemberNames()
    local members = {}
    if IsInGroup() and not IsInRaid() then
        local playerName, playerRealm = UnitName('player')
        if not playerRealm or playerRealm == '' then playerRealm = GetRealmName() end
        local playerFullName = playerName .. '-' .. playerRealm

        for i = 1, GetNumGroupMembers() do
            local name, realm = UnitName('party' .. i)
            if name then
                if not realm or realm == '' then realm = GetRealmName() end
                local fullName = name .. '-' .. realm
                if fullName ~= playerFullName then
                    table.insert(members, fullName)
                end
            end
        end
    end
    return members
end

local function ProcessQueryResults(logicModule, round)
    if #pendingQueries == 0 then
        isQuerying = false
        return
    end

    local stillPending = {}
    for _, fullName in ipairs(pendingQueries) do
        local shortName = strsplit("-", fullName)
        local hasData, isNewbie, elapsedMins = GetLocomotiveData(fullName)
        
        if hasData and elapsedMins < 120 then 
            if isNewbie then
                if MS_NEWBIE_ANNOUNCE_ENABLED ~= false then print(string.format("|cff00ff00[新兵增强]|r %s - %s|cffffff00(%d分钟前检测)|r", shortName, NEWBIE_ICON_STR, elapsedMins))
                    PlaySound(416, "Master")
                end
            else
                if MS_NEWBIE_ANNOUNCE_ENABLED ~= false then print(string.format("|cff00ff00[新兵增强]|r %s - |cff888888S1赛季老兵|r", shortName)) end
            end
            announcedMembers[fullName] = true
        else
            table.insert(stillPending, fullName)
        end
    end

    pendingQueries = stillPending

    if #pendingQueries > 0 then
        if round >= 45 then
            for _, fullName in ipairs(pendingQueries) do
                local shortName = strsplit("-", fullName)
                print(string.format("  |cffff0000[新兵增强]|r %s 查询超时|r", shortName))
            end
            isQuerying = false
            pendingQueries = {}
            return
        end

        if round % 10 == 0 then
            for _, fullName in ipairs(pendingQueries) do
                logicModule:InsertServerCQGLIB(fullName)
            end
            logicModule:SendServerCQGLIB()
        end
        C_Timer.After(1, function() ProcessQueryResults(logicModule, round + 1) end)
    else
        isQuerying = false
    end
end

local function CheckAndQueryParty()
    if not IsInGroup() or IsInRaid() then
        announcedMembers = {} 
        return
    end

    local members = GetPartyMemberNames()
    if #members == 0 then return end

    local MS = LibStub("AceAddon-3.0"):GetAddon("MeetingStone", true)
    if not MS then return end
    local logicModule = MS:GetModule("Logic", true)
    if not logicModule then return end

    local needsTriggerQuery = false

    for _, fullName in ipairs(members) do
        if not announcedMembers[fullName] then
            local hasData, isNewbie, elapsedMins = GetLocomotiveData(fullName)
            local shortName = strsplit("-", fullName)
            
            if not hasData or elapsedMins >= 120 then
                if MS_NEWBIE_ANNOUNCE_ENABLED ~= false then print(string.format("|cff00ff00[新兵增强]|r %s - |cffffff00状态未知，正在查询中...|r", shortName)) end
                table.insert(pendingQueries, fullName)
                needsTriggerQuery = true
                announcedMembers[fullName] = "querying" 
            else
                if isNewbie then
                    if MS_NEWBIE_ANNOUNCE_ENABLED ~= false then print(string.format("|cff00ff00[新兵增强]|r %s - %s|cffffff00(%d分钟前检测)|r", shortName, NEWBIE_ICON_STR, elapsedMins))
                        PlaySound(416, "Master")
                    end
                else
                    if MS_NEWBIE_ANNOUNCE_ENABLED ~= false then print(string.format("|cff00ff00[新兵增强]|r %s - |cff888888S1赛季老兵|r", shortName)) end
                end
                announcedMembers[fullName] = true
            end
        end
    end

    if needsTriggerQuery and not isQuerying then
        isQuerying = true
        for _, fullName in ipairs(pendingQueries) do
            logicModule:InsertServerCQGLIB(fullName)
        end
        logicModule:SendServerCQGLIB()
        C_Timer.After(1, function() ProcessQueryResults(logicModule, 1) end)
    end
end

local partyCheckFrame = CreateFrame("Frame")
partyCheckFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
partyCheckFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
local rosterUpdateTimer
partyCheckFrame:SetScript("OnEvent", function()
    if rosterUpdateTimer then rosterUpdateTimer:Cancel() end
    rosterUpdateTimer = C_Timer.NewTimer(1, CheckAndQueryParty)
end)

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
                tooltip:AddLine("|cff888888队长为S1赛季认证老兵|r" )
            end
            tooltip:Show()
        end
    end)

    if TooltipDataProcessor then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
            if tooltip ~= GameTooltip then return end
            
            local ok0, _, unit = pcall(function() return tooltip:GetUnit() end)
            if not ok0 or not unit or type(unit) ~= "string" then return end

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
                    tooltip:AddLine("|cff888888S1赛季认证老兵|r" )
                end
            end
        end)
    end

    print("|cff00ff00[新兵增强]|r模块已加载。现已支持进队自动查询队内新兵，使用|cffffff00/msd|r可查看集合石返回的原始信息、开关聊天框通报、手动查询特定角色的新兵状态。")

end)