local logBuffer = {} 

local DebugFrame = CreateFrame("Frame", "MeetingStoneNewbieDebugFrame", UIParent, "BasicFrameTemplateWithInset")
DebugFrame:SetSize(720, 450)
DebugFrame:SetPoint("CENTER")
DebugFrame:SetMovable(true)
DebugFrame:EnableMouse(true)
DebugFrame:RegisterForDrag("LeftButton")
DebugFrame:SetScript("OnDragStart", function() DebugFrame:StartMoving() end)
DebugFrame:SetScript("OnDragStop", function() DebugFrame:StopMovingOrSizing() end)
DebugFrame:Hide()

DebugFrame.title = DebugFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
DebugFrame.title:SetPoint("CENTER", DebugFrame.TitleBg, "CENTER", 0, 0)
DebugFrame.title:SetText("新兵增强 - 集合石原始数据")

DebugFrame:SetResizable(true)
if DebugFrame.SetResizeBounds then
    DebugFrame:SetResizeBounds(500, 300)
else
    DebugFrame:SetMinResize(500, 300)
end

local ResizeGrip = CreateFrame("Button", nil, DebugFrame)
ResizeGrip:SetPoint("BOTTOMRIGHT", -4, 4)
ResizeGrip:SetSize(16, 16)
ResizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
ResizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
ResizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
ResizeGrip:SetScript("OnMouseDown", function(self, btn) if btn == "LeftButton" then DebugFrame:StartSizing("BOTTOMRIGHT") end end)
ResizeGrip:SetScript("OnMouseUp", function() DebugFrame:StopMovingOrSizing() end)

local CopyFrame = CreateFrame("Frame", "MSNDebugCopyFrame", DebugFrame, "BasicFrameTemplateWithInset")
CopyFrame:SetSize(500, 350)
CopyFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -50)
CopyFrame:Hide()
CopyFrame:SetFrameStrata("DIALOG")
CopyFrame.title = CopyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
CopyFrame.title:SetPoint("CENTER", CopyFrame.TitleBg, "CENTER", 0, 0)
CopyFrame.title:SetText("文本已自动全选，请按 Ctrl+C 复制")

local CopyScroll = CreateFrame("ScrollFrame", nil, CopyFrame, "UIPanelScrollFrameTemplate")
CopyScroll:SetPoint("TOPLEFT", 10, -30)
CopyScroll:SetPoint("BOTTOMRIGHT", -30, 10)

local CopyEditBox = CreateFrame("EditBox", nil, CopyScroll)
CopyEditBox:SetMultiLine(true)
CopyEditBox:SetFontObject(ChatFontNormal)
CopyEditBox:SetWidth(440)
CopyEditBox:SetAutoFocus(true)
CopyEditBox:SetScript("OnEscapePressed", function() CopyFrame:Hide() end)
CopyScroll:SetScrollChild(CopyEditBox)

local function ShowCopyFrame(text)
    CopyFrame:Show()
    CopyEditBox:SetText(text)
    CopyEditBox:HighlightText()
    CopyEditBox:SetFocus()
end

local DbPage = CreateFrame("Frame", nil, DebugFrame)
DbPage:SetAllPoints()

local LogPage = CreateFrame("Frame", nil, DebugFrame)
LogPage:SetAllPoints()
LogPage:Hide() 

DebugFrame.DbPage = DbPage
DebugFrame.LogPage = LogPage

local function CreateTab(id, text)
    local tab = CreateFrame("Button", "$parentTab"..id, DebugFrame, "UIPanelButtonTemplate")
    tab:SetID(id)
    tab:SetSize(100, 26)
    tab:SetText(text)
    tab:SetScript("OnClick", function(self)
        DebugFrame.tab1:Enable()
        DebugFrame.tab2:Enable()
        self:Disable()
        if self:GetID() == 1 then
            DebugFrame.DbPage:Show()
            DebugFrame.LogPage:Hide()
            if DebugFrame.UpdateDB then DebugFrame:UpdateDB(true) end
        else
            DebugFrame.DbPage:Hide()
            DebugFrame.LogPage:Show()
        end
    end)
    return tab
end

DebugFrame.tab1 = CreateTab(1, "已缓存数据")
DebugFrame.tab2 = CreateTab(2, "实时日志")
DebugFrame.tab1:SetPoint("TOPLEFT", DebugFrame, "TOPLEFT", 15, -30)
DebugFrame.tab2:SetPoint("LEFT", DebugFrame.tab1, "RIGHT", 5, 0)
DebugFrame.tab1:Disable()

if MS_NEWBIE_ANNOUNCE_ENABLED == nil then
    MS_NEWBIE_ANNOUNCE_ENABLED = true
end

local AnnounceToggleCB = CreateFrame("CheckButton", "MSNDebugAnnounceToggle", DebugFrame, "UICheckButtonTemplate")
AnnounceToggleCB:SetSize(24, 24)
AnnounceToggleCB:SetPoint("BOTTOMLEFT", DebugFrame, "BOTTOMLEFT", 15, 15)
_G["MSNDebugAnnounceToggleText"]:SetText("在聊天框通报队伍成员身份（仅自己可见）")
_G["MSNDebugAnnounceToggleText"]:SetFontObject(GameFontNormalSmall)
AnnounceToggleCB:SetChecked(MS_NEWBIE_ANNOUNCE_ENABLED)

AnnounceToggleCB:SetScript("OnClick", function(self)
    MS_NEWBIE_ANNOUNCE_ENABLED = self:GetChecked()
    local stateText = MS_NEWBIE_ANNOUNCE_ENABLED and "|cff00ff00开启|r" or "|cffff0000关闭|r"
    print("|cff00ff00[新兵增强]|r 进队自动通报已" .. stateText)
end)

-- ==========================================
-- 队伍成员身份主动查询和通报
-- 来源：https://bbs.nga.cn/read.php?tid=47025650
-- 作者：Khanid
-- ==========================================
local ManualQueryLabel = DebugFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ManualQueryLabel:SetPoint("TOPRIGHT", DebugFrame, "TOPRIGHT", -215, -35)
ManualQueryLabel:SetText("手动查询:")

local ManualQueryBox = CreateFrame("EditBox", "MSNDebugManualQuery", DebugFrame, "InputBoxTemplate")
ManualQueryBox:SetSize(120, 20)
ManualQueryBox:SetPoint("LEFT", ManualQueryLabel, "RIGHT", 10, 0)
ManualQueryBox:SetAutoFocus(false)

local ManualQueryBtn = CreateFrame("Button", nil, DebugFrame, "UIPanelButtonTemplate")
ManualQueryBtn:SetSize(50, 22)
ManualQueryBtn:SetPoint("LEFT", ManualQueryBox, "RIGHT", 5, 0)
ManualQueryBtn:SetText("发送")

if not MS_PendingManualQueries then MS_PendingManualQueries = {} end

ManualQueryBtn:SetScript("OnClick", function()
    local name = ManualQueryBox:GetText()
    name = string.gsub(name, "%s+", "") 
    
    if name and name ~= "" then
        local MS = LibStub("AceAddon-3.0"):GetAddon("MeetingStone", true)
        if MS then
            local logicModule = MS:GetModule("Logic", true)
            if logicModule then
                if not string.find(name, "-") then
                    name = name .. "-" .. GetRealmName()
                    ManualQueryBox:SetText(name) 
                end
                
                MS_PendingManualQueries[name] = true 
                logicModule:InsertServerCQGLIB(name)
                logicModule:SendServerCQGLIB()
                
                print(string.format("|cff00ff00[新兵增强]|r 正在查询 %s，等待返回...", name))
                ManualQueryBox:ClearFocus()
            end
        end
    end
end)

ManualQueryBox:SetScript("OnEnterPressed", function(self)
    ManualQueryBtn:Click()
end)

local DbSearch = CreateFrame("EditBox", "MSNDebugDbSearch", DbPage, "SearchBoxTemplate")
DbSearch:SetPoint("TOPLEFT", 20, -65)
DbSearch:SetSize(150, 20)
DbSearch:SetAutoFocus(false)
DbSearch:SetScript("OnTextChanged", function() DebugFrame:UpdateDB(true) end)

local function CreateFilterCB(name, label, anchor, xOffset, defaultChecked, parent)
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("LEFT", anchor, "RIGHT", xOffset, 0)
    _G[name.."Text"]:SetText(label)
    _G[name.."Text"]:SetFontObject(GameFontNormalSmall)
    cb:SetChecked(defaultChecked)
    return cb
end

local cbDbNewbie = CreateFilterCB("MSNCBDbNewbie", "新兵", DbSearch, 10, true, DbPage)
local cbDbOldbie = CreateFilterCB("MSNCBDbOldbie", "老兵", cbDbNewbie, 40, true, DbPage)
cbDbNewbie:SetScript("OnClick", function() DebugFrame:UpdateDB(true) end)
cbDbOldbie:SetScript("OnClick", function() DebugFrame:UpdateDB(true) end)

local DbCopyBtn = CreateFrame("Button", nil, DbPage, "UIPanelButtonTemplate")
DbCopyBtn:SetSize(80, 22)
DbCopyBtn:SetPoint("TOPRIGHT", -30, -65)
DbCopyBtn:SetText("复制列表")

local DbScroll = CreateFrame("ScrollFrame", "MeetingStoneNewbieDBScroll", DbPage, "UIPanelScrollFrameTemplate")
DbScroll:SetPoint("TOPLEFT", 15, -95)
DbScroll:SetPoint("BOTTOMRIGHT", -35, 45)

local DbContent = CreateFrame("Frame", nil, DbScroll)
DbContent:SetSize(500, 1)
DbScroll:SetScrollChild(DbContent)

local currentSortedDb = {}
local dbRows = {}
local ROW_HEIGHT = 16
local VISIBLE_ROWS = 80

for i = 1, VISIBLE_ROWS do
    local row = DbContent:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
    row:SetJustifyH("LEFT")
    row:Hide()
    dbRows[i] = row
end

local function RefreshDbView()
    local offset = DbScroll:GetVerticalScroll()
    local startIndex = math.max(0, math.floor(offset / ROW_HEIGHT))
    
    for i = 1, VISIBLE_ROWS do
        local dataIndex = startIndex + i
        local item = currentSortedDb[dataIndex]
        local row = dbRows[i]
        
        if item then
            local statusColor = item.info.isNewbie and "|cff00ff00[新兵]|r" or "|cff888888[老兵]|r"
            local timeStr = item.time > 0 and date("%m-%d %H:%M:%S", item.time) or "未知时间"
            local expireText = ""
            if item.info.isNewbie and item.info.newbieExpireTime then
                expireText = string.format(" |cffffaa00(余%d分)|r", math.max(0, math.floor((item.info.newbieExpireTime - time())/60)))
            end
            
            row:SetPoint("TOPLEFT", 5, -(dataIndex - 1) * ROW_HEIGHT)
            row:SetText(string.format("|cff888888%2d. [%s]|r %s |cffffffff%s|r%s", dataIndex, timeStr, statusColor, item.name, expireText))
            row:Show()
        else
            row:Hide()
        end
    end
end

DbScroll:HookScript("OnVerticalScroll", function() RefreshDbView() end)

function DebugFrame:UpdateDB(forceScrollBottom)
    currentSortedDb = {}
    
    local data = MEETINGSTONE_UI_DB and MEETINGSTONE_UI_DB.global and MEETINGSTONE_UI_DB.global.LocomotiveData
    if not data then 
        DbContent:SetHeight(1)
        RefreshDbView()
        return 
    end
    
    local query = (DbSearch:GetText() or ""):lower()
    for name, info in pairs(data) do
        local matchFilter = (info.isNewbie and cbDbNewbie:GetChecked()) or (not info.isNewbie and cbDbOldbie:GetChecked())
        local matchSearch = (query == "" or name:lower():find(query, 1, true))
        
        if matchFilter and matchSearch then
            local sortTime = info.medalTime or (info.newbieExpireTime and (info.newbieExpireTime - 18000)) or 0
            table.insert(currentSortedDb, {name = name, time = sortTime, info = info})
        end
    end
    
    table.sort(currentSortedDb, function(a, b)
        if a.time == b.time then return a.name < b.name end
        return a.time < b.time 
    end)

    DbContent:SetHeight(math.max(1, #currentSortedDb * ROW_HEIGHT))
    
    if forceScrollBottom then
        C_Timer.After(0.01, function()
            local maxScroll = math.max(0, DbContent:GetHeight() - DbScroll:GetHeight())
            DbScroll:SetVerticalScroll(maxScroll)
            RefreshDbView()
        end)
    else
        RefreshDbView()
    end
end

DbCopyBtn:SetScript("OnClick", function()
    local lines = {}
    for i, item in ipairs(currentSortedDb) do
        local status = item.info.isNewbie and "[新兵]" or "[老兵]"
        local timeStr = item.time > 0 and date("%m-%d %H:%M:%S", item.time) or "未知时间"
        local expire = item.info.isNewbie and string.format(" (余%d分)", math.max(0, math.floor((item.info.newbieExpireTime - time())/60))) or ""
        table.insert(lines, string.format("%d. [%s] %s %s%s", i, timeStr, status, item.name, expire))
    end
    if #lines == 0 then table.insert(lines, "无匹配的数据库记录。") end
    ShowCopyFrame(table.concat(lines, "\n"))
end)

local LogSearch = CreateFrame("EditBox", "MSNDebugLogSearch", LogPage, "SearchBoxTemplate")
LogSearch:SetPoint("TOPLEFT", 20, -65)
LogSearch:SetSize(150, 20)
LogSearch:SetAutoFocus(false)

local cbQueue = CreateFilterCB("MSNCBQueue", "队列", LogSearch, 10, false, LogPage)
local cbSend  = CreateFilterCB("MSNCBSend", "发包", cbQueue, 40, true, LogPage)
local cbRecv  = CreateFilterCB("MSNCBRecv", "收包", cbSend, 40, true, LogPage)

local LogCopyBtn = CreateFrame("Button", nil, LogPage, "UIPanelButtonTemplate")
LogCopyBtn:SetSize(80, 22)
LogCopyBtn:SetPoint("TOPRIGHT", -30, -65)
LogCopyBtn:SetText("复制日志")

local LogClearBtn = CreateFrame("Button", nil, LogPage, "UIPanelButtonTemplate")
LogClearBtn:SetSize(60, 22)
LogClearBtn:SetPoint("RIGHT", LogCopyBtn, "LEFT", -5, 0)
LogClearBtn:SetText("清空")

local ScrollFrame = CreateFrame("ScrollingMessageFrame", nil, LogPage)
ScrollFrame.SetVerticalScroll = function() end 
ScrollFrame:SetPoint("TOPLEFT", 15, -95)
ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 45)
ScrollFrame:SetFontObject(ChatFontNormal)
ScrollFrame:SetJustifyH("LEFT")
ScrollFrame:SetMaxLines(2000)
ScrollFrame:SetFading(false)
ScrollFrame:EnableMouseWheel(true)

local ScrollBar = CreateFrame("Slider", nil, ScrollFrame, "UIPanelScrollBarTemplate")
ScrollBar:SetPoint("TOPLEFT", ScrollFrame, "TOPRIGHT", 6, -16)
ScrollBar:SetPoint("BOTTOMLEFT", ScrollFrame, "BOTTOMRIGHT", 6, 16)
ScrollBar:SetMinMaxValues(0, 0)
ScrollBar:SetValueStep(1)
ScrollBar:SetValue(0)
ScrollBar:SetWidth(16)

ScrollBar:SetScript("OnValueChanged", function(self, value)
    local minVal, maxVal = self:GetMinMaxValues()
    local val = math.floor(value + 0.5)
    ScrollFrame:SetScrollOffset(math.max(0, math.floor(maxVal - val)))
end)

ScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local target = ScrollBar:GetValue() - (delta * (IsShiftKeyDown() and 10 or 3))
    local minV, maxV = ScrollBar:GetMinMaxValues()
    ScrollBar:SetValue(math.max(minV, math.min(maxV, target)))
end)

local function IsLogMatch(logObj, query)
    if logObj.type == "queue" and not cbQueue:GetChecked() then return false end
    if logObj.type == "send" and not cbSend:GetChecked() then return false end
    if logObj.type == "recv" and not cbRecv:GetChecked() then return false end
    if query ~= "" and not logObj.search:find(query, 1, true) then return false end
    return true
end

local function RenderLogs()
    ScrollFrame:Clear()
    local query = (LogSearch:GetText() or ""):lower()
    for _, logObj in ipairs(logBuffer) do
        if IsLogMatch(logObj, query) then
            ScrollFrame:AddMessage(logObj.display, logObj.r, logObj.g, logObj.b)
        end
    end
    local maxScroll = math.max(0, ScrollFrame:GetNumMessages() - 1)
    ScrollBar:SetMinMaxValues(0, maxScroll)
    ScrollBar:SetValue(maxScroll)
end

LogSearch:SetScript("OnTextChanged", RenderLogs)
cbQueue:SetScript("OnClick", RenderLogs)
cbSend:SetScript("OnClick", RenderLogs)
cbRecv:SetScript("OnClick", RenderLogs)

local function Log(logType, msg, r, g, b, plainText)
    local t = date("%H:%M:%S")
    local displayMsg = string.format("[%s] %s", t, msg)
    local rawMsg = string.format("[%s] %s", t, plainText or msg)
    table.insert(logBuffer, {type=logType, display=displayMsg, search=rawMsg:lower(), raw=rawMsg, r=r or 1, g=g or 1, b=b or 1})
    RenderLogs()
end

LogCopyBtn:SetScript("OnClick", function()
    local lines = {}
    local query = (LogSearch:GetText() or ""):lower()
    for _, logObj in ipairs(logBuffer) do
        if IsLogMatch(logObj, query) then
            table.insert(lines, logObj.raw)
        end
    end
    if #lines == 0 then table.insert(lines, "无匹配的日志数据。") end
    ShowCopyFrame(table.concat(lines, "\n"))
end)

LogClearBtn:SetScript("OnClick", function()
    ScrollFrame:Clear()
    logBuffer = {}
    ScrollBar:SetMinMaxValues(0, 0)
    ScrollBar:SetValue(0)
end)

local function SetupHooks()
    local MS = LibStub("AceAddon-3.0"):GetAddon("MeetingStone", true)
    if not MS then return end
    local Logic = MS:GetModule("Logic", true)
    if not Logic then return end

    hooksecurefunc(Logic, "InsertServerCQGLIB", function(self, name)
        Log("queue", "队列加入: " .. tostring(name), 0.7, 0.7, 0.7)
    end)

    hooksecurefunc(Logic, "SendServer", function(self, cmd, ...)
        if cmd == "CQGLIB" then
            Log("send", ">> [发包] 请求数据: " .. tostring(...), 1, 1, 0)
        end
    end)

    local NEWBIE_ICON_STR = [[|TInterface\AddOns\MeetingStone\Media\Locomotive\Newbie:16:64|t]]

    hooksecurefunc(Logic, "SQGLIB", function(self, event, maps)
        Log("recv", "<< [收包] 收到服务器数据", 0, 1, 0)
        for name, d in pairs(maps) do
            if d.n == 1 then Log("recv", "   确认新兵: " .. name, 0, 1, 0) end
            
            if MS_PendingManualQueries and MS_PendingManualQueries[name] then
                local shortName = strsplit("-", name)
                if d.n == 1 then
                    print(string.format("|cff00ff00[查询结果]|r %s - %s", shortName, NEWBIE_ICON_STR))
                    PlaySound(416, "Master")
                else
                    print(string.format("|cff00ff00[查询结果]|r %s - |cff888888S1赛季老兵|r", shortName))
                end
                MS_PendingManualQueries[name] = nil 
            end
        end
        if DebugFrame.DbPage:IsShown() then DebugFrame:UpdateDB(true) end
    end)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", SetupHooks)

SLASH_MSD1 = "/msd"
SlashCmdList["MSD"] = function()
    if DebugFrame:IsShown() then 
        DebugFrame:Hide() 
    else 
        DebugFrame:Show()
        if DebugFrame.DbPage:IsShown() and DebugFrame.UpdateDB then
            DebugFrame:UpdateDB(true)
        end
    end
end