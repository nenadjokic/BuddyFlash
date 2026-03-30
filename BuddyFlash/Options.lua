-- BuddyFlash Options GUI (Tab-based)
-- ====================================
local addonName, ns = ...

-- ============================================================
-- HELPER: Create standard UI elements
-- ============================================================

local function CreateCheckbox(parent, label, x, y, getter, setter)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb.text:SetText(label)
    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked())
    end)
    cb.Refresh = function(self)
        self:SetChecked(getter())
    end
    cb:Refresh()
    return cb
end

local function CreateSlider(parent, label, x, y, minVal, maxVal, step, getter, setter)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetSize(180, 17)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider.Text:SetText(label)
    slider.Low:SetText(minVal)
    slider.High:SetText(maxVal)

    local valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valueText:SetPoint("TOP", slider, "BOTTOM", 0, -2)
    slider.valueText = valueText

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        self.valueText:SetText(string.format("%.2f", value))
        setter(value)
    end)
    slider.Refresh = function(self)
        self:SetValue(getter())
    end
    slider:Refresh()
    return slider
end

local function CreateSectionHeader(parent, text, x, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    header:SetText("|cFF69CCF0" .. text .. "|r")

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    line:SetPoint("RIGHT", parent, "RIGHT", -20, 0)
    line:SetColorTexture(0.3, 0.5, 0.7, 0.5)

    return header
end

local function CreateButton(parent, text, x, y, width, height, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:SetSize(width, height)
    btn:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- ============================================================
-- AVATAR MANIFEST HELPERS
-- ============================================================

local function GetAvailableAvatars()
    local avatars = {}
    if BuddyFlashAvatarManifest then
        for _, name in ipairs(BuddyFlashAvatarManifest) do
            table.insert(avatars, name)
        end
    end
    local hasDefault = false
    for _, name in ipairs(avatars) do
        if name == "default" then hasDefault = true; break end
    end
    if not hasDefault then table.insert(avatars, 1, "default") end
    return avatars
end

-- Helper: format character name
local function FormatName(text)
    if text:find("#") then return text end
    return text:sub(1,1):upper() .. text:sub(2):lower()
end

-- ============================================================
-- INLINE EDIT POPUP (reusable for Avatar / Sound / Whisper)
-- ============================================================

local editPopup = CreateFrame("Frame", "BuddyFlashEditPopup", UIParent, "BackdropTemplate")
editPopup:SetSize(320, 140)
editPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
editPopup:SetFrameStrata("FULLSCREEN_DIALOG")
editPopup:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
editPopup:SetBackdropColor(0.05, 0.05, 0.15, 0.97)
editPopup:SetBackdropBorderColor(0.4, 0.6, 1.0, 0.9)
editPopup:SetMovable(true)
editPopup:EnableMouse(true)
editPopup:RegisterForDrag("LeftButton")
editPopup:SetScript("OnDragStart", editPopup.StartMoving)
editPopup:SetScript("OnDragStop", editPopup.StopMovingOrSizing)
editPopup:SetClampedToScreen(true)
editPopup:Hide()
tinsert(UISpecialFrames, "BuddyFlashEditPopup")

local editTitle = editPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
editTitle:SetPoint("TOP", editPopup, "TOP", 0, -12)

local editCloseBtn = CreateFrame("Button", nil, editPopup, "UIPanelCloseButton")
editCloseBtn:SetPoint("TOPRIGHT", editPopup, "TOPRIGHT", -2, -2)

-- Avatar dropdown (hidden by default)
local editAvatarDropdown = CreateFrame("Frame", "BuddyFlashEditAvatarDD", editPopup, "UIDropDownMenuTemplate")
editAvatarDropdown:SetPoint("TOPLEFT", editPopup, "TOPLEFT", 20, -40)
editAvatarDropdown:Hide()

local editAvatarPreview = editPopup:CreateTexture(nil, "ARTWORK")
editAvatarPreview:SetSize(36, 36)
editAvatarPreview:SetPoint("LEFT", editPopup, "TOPLEFT", 25, -42)
editAvatarPreview:SetTexCoord(0, 1, 0, 1)
editAvatarPreview:Hide()

-- Sound dropdown (hidden by default)
local editSoundDropdown = CreateFrame("Frame", "BuddyFlashEditSoundDD", editPopup, "UIDropDownMenuTemplate")
editSoundDropdown:SetPoint("TOPLEFT", editPopup, "TOPLEFT", 20, -40)
editSoundDropdown:Hide()

-- Whisper text input (hidden by default)
local editWhisperInput = CreateFrame("EditBox", "BuddyFlashEditWspInput", editPopup, "InputBoxTemplate")
editWhisperInput:SetPoint("TOPLEFT", editPopup, "TOPLEFT", 30, -48)
editWhisperInput:SetSize(260, 25)
editWhisperInput:SetAutoFocus(false)
editWhisperInput:SetMaxLetters(255)
editWhisperInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
editWhisperInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
editWhisperInput:Hide()

-- Save button
local editSaveBtn = CreateFrame("Button", nil, editPopup, "UIPanelButtonTemplate")
editSaveBtn:SetSize(100, 26)
editSaveBtn:SetPoint("BOTTOMLEFT", editPopup, "BOTTOMLEFT", 20, 12)
editSaveBtn:SetText("Save")

-- Preview button (sounds only)
local editPreviewBtn = CreateFrame("Button", nil, editPopup, "UIPanelButtonTemplate")
editPreviewBtn:SetSize(80, 26)
editPreviewBtn:SetPoint("BOTTOM", editPopup, "BOTTOM", 0, 12)
editPreviewBtn:SetText("Preview")
editPreviewBtn:Hide()

-- Cancel button
local editCancelBtn = CreateFrame("Button", nil, editPopup, "UIPanelButtonTemplate")
editCancelBtn:SetSize(80, 26)
editCancelBtn:SetPoint("BOTTOMRIGHT", editPopup, "BOTTOMRIGHT", -20, 12)
editCancelBtn:SetText("Cancel")
editCancelBtn:SetScript("OnClick", function() editPopup:Hide() end)

local editSelectedAvatar, editSelectedSound

local function ShowEditPopup_Avatar(name, currentFile, onSave)
    editTitle:SetText("|cFFFFFF00" .. name .. "|r - Avatar")
    editAvatarDropdown:Show(); editAvatarPreview:Show()
    editSoundDropdown:Hide(); editWhisperInput:Hide(); editPreviewBtn:Hide()
    editAvatarPreview:SetPoint("LEFT", editPopup, "TOPLEFT", 25, -58)
    editAvatarDropdown:SetPoint("TOPLEFT", editPopup, "TOPLEFT", 65, -44)
    editSelectedAvatar = currentFile or "default"
    editAvatarPreview:SetTexture(ns.AVATAR_PATH .. editSelectedAvatar)
    UIDropDownMenu_SetWidth(editAvatarDropdown, 170)
    UIDropDownMenu_Initialize(editAvatarDropdown, function(self, level)
        for _, avName in ipairs(GetAvailableAvatars()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = avName
            info.value = avName
            info.checked = (avName == editSelectedAvatar)
            info.func = function(btn)
                editSelectedAvatar = btn.value
                UIDropDownMenu_SetText(editAvatarDropdown, btn.value)
                editAvatarPreview:SetTexture(ns.AVATAR_PATH .. btn.value)
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetText(editAvatarDropdown, editSelectedAvatar)
    editSaveBtn:SetScript("OnClick", function()
        onSave(editSelectedAvatar)
        editPopup:Hide()
    end)
    editPopup:Show()
end

local function ShowEditPopup_Sound(name, currentIdx, onSave)
    editTitle:SetText("|cFFFFFF00" .. name .. "|r - Sound")
    editSoundDropdown:Show(); editPreviewBtn:Show()
    editAvatarDropdown:Hide(); editAvatarPreview:Hide(); editWhisperInput:Hide()
    editSoundDropdown:SetPoint("TOPLEFT", editPopup, "TOPLEFT", 20, -40)
    editSelectedSound = currentIdx or 1
    UIDropDownMenu_SetWidth(editSoundDropdown, 220)
    UIDropDownMenu_Initialize(editSoundDropdown, function(self, level)
        for i, snd in ipairs(ns.SOUND_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = snd.name
            info.value = i
            info.checked = (i == editSelectedSound)
            info.func = function(btn)
                editSelectedSound = btn.value
                UIDropDownMenu_SetText(editSoundDropdown, ns.SOUND_OPTIONS[btn.value].name)
                ns.PlayAlertSound(ns.SOUND_OPTIONS[btn.value])
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetText(editSoundDropdown, (ns.SOUND_OPTIONS[editSelectedSound] or ns.SOUND_OPTIONS[1]).name)
    editPreviewBtn:SetScript("OnClick", function()
        if ns.SOUND_OPTIONS[editSelectedSound] then ns.PlayAlertSound(ns.SOUND_OPTIONS[editSelectedSound]) end
    end)
    editSaveBtn:SetScript("OnClick", function()
        onSave(editSelectedSound)
        editPopup:Hide()
    end)
    editPopup:Show()
end

local function ShowEditPopup_Whisper(name, currentMsg, onSave)
    editTitle:SetText("|cFFFFFF00" .. name .. "|r - Whisper")
    editWhisperInput:Show()
    editAvatarDropdown:Hide(); editAvatarPreview:Hide(); editSoundDropdown:Hide(); editPreviewBtn:Hide()
    editWhisperInput:SetText(currentMsg or "")
    editWhisperInput:SetFocus()
    editSaveBtn:SetScript("OnClick", function()
        local msg = editWhisperInput:GetText():trim()
        if msg ~= "" then
            onSave(msg)
        end
        editPopup:Hide()
    end)
    editPopup:Show()
end

-- ============================================================
-- MAIN OPTIONS FRAME
-- ============================================================

local optionsFrame = CreateFrame("Frame", "BuddyFlashOptionsFrame", UIParent, "BackdropTemplate")
optionsFrame:SetSize(540, 680)
optionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
optionsFrame:SetFrameStrata("DIALOG")
optionsFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
optionsFrame:SetBackdropColor(0.05, 0.05, 0.1, 0.95)
optionsFrame:SetBackdropBorderColor(0.3, 0.5, 0.8, 0.8)
optionsFrame:SetMovable(true)
optionsFrame:EnableMouse(true)
optionsFrame:RegisterForDrag("LeftButton")
optionsFrame:SetScript("OnDragStart", optionsFrame.StartMoving)
optionsFrame:SetScript("OnDragStop", optionsFrame.StopMovingOrSizing)
optionsFrame:SetClampedToScreen(true)
optionsFrame:Hide()

tinsert(UISpecialFrames, "BuddyFlashOptionsFrame")

-- Title
local titleBg = optionsFrame:CreateTexture(nil, "ARTWORK")
titleBg:SetHeight(30)
titleBg:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 4, -4)
titleBg:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -4, -4)
titleBg:SetColorTexture(0.1, 0.2, 0.4, 0.6)

local titleText = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOP", optionsFrame, "TOP", 0, -10)
titleText:SetText("|cFF69CCF0BuddyFlash|r Settings")

local closeBtn = CreateFrame("Button", nil, optionsFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -2, -2)

-- ============================================================
-- TAB SYSTEM
-- ============================================================

local TAB_NAMES = { "General", "Friends", "Avatars", "Sounds", "Whisper", "History" }
local tabButtons = {}
local tabPanels = {}
local activeTab = 1

local function SelectTab(index)
    activeTab = index
    for i, btn in ipairs(tabButtons) do
        if i == index then
            btn:SetNormalFontObject("GameFontHighlight")
            btn:GetFontString():SetTextColor(1, 1, 1)
            btn.bg:SetColorTexture(0.15, 0.3, 0.5, 0.8)
        else
            btn:SetNormalFontObject("GameFontNormal")
            btn:GetFontString():SetTextColor(0.6, 0.6, 0.6)
            btn.bg:SetColorTexture(0.1, 0.1, 0.15, 0.6)
        end
    end
    for i, panel in ipairs(tabPanels) do
        if i == index then panel.scroll:Show() else panel.scroll:Hide() end
    end
    -- Trigger refresh for visible tab
    if tabPanels[index] and tabPanels[index].refresh then
        tabPanels[index].refresh()
    end
end

for i, name in ipairs(TAB_NAMES) do
    local tab = CreateFrame("Button", "BuddyFlashTab" .. i, optionsFrame)
    tab:SetSize(80, 24)
    tab:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 8 + (i - 1) * 86, -38)

    local bg = tab:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(tab)
    bg:SetColorTexture(0.1, 0.1, 0.15, 0.6)
    tab.bg = bg

    local text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", tab, "CENTER", 0, 0)
    text:SetText(name)
    tab:SetFontString(text)

    local hl = tab:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(tab)
    hl:SetColorTexture(0.2, 0.4, 0.6, 0.3)

    tab:SetScript("OnClick", function() SelectTab(i) end)
    tabButtons[i] = tab

    -- Create scroll panel for this tab
    local scroll = CreateFrame("ScrollFrame", "BuddyFlashTabScroll" .. i, optionsFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 10, -66)
    scroll:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -30, 10)
    scroll:Hide()

    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(480)
    child:SetHeight(1) -- will be set after content is built
    scroll:SetScrollChild(child)

    tabPanels[i] = { scroll = scroll, child = child }
end

-- ============================================================
-- TAB 1: GENERAL SETTINGS
-- ============================================================

local t1 = tabPanels[1].child
local y1 = -10

CreateSectionHeader(t1, "Notifications", 10, y1)
y1 = y1 - 30

local cbFlash = CreateCheckbox(t1, "Enable Screen Flash", 20, y1,
    function() return ns.GetDB().flashEnabled end,
    function(v) ns.GetDB().flashEnabled = v end
)
y1 = y1 - 30

local cbSound = CreateCheckbox(t1, "Enable Login Sound", 20, y1,
    function() return ns.GetDB().soundEnabled end,
    function(v) ns.GetDB().soundEnabled = v end
)
y1 = y1 - 30

local cbLock = CreateCheckbox(t1, "Lock Window Position", 20, y1,
    function() return ns.GetDB().windowLocked end,
    function(v) ns.GetDB().windowLocked = v end
)
y1 = y1 - 30

local cbCharFriends = CreateCheckbox(t1, "Show Character Friends", 20, y1,
    function() return ns.GetDB().showCharFriends end,
    function(v) ns.GetDB().showCharFriends = v; if ns.UpdateListUI then ns.UpdateListUI() end end
)
y1 = y1 - 30

local cbBNetFriends = CreateCheckbox(t1, "Show Battle.net Friends", 20, y1,
    function() return ns.GetDB().showBNetFriends end,
    function(v) ns.GetDB().showBNetFriends = v; if ns.UpdateListUI then ns.UpdateListUI() end end
)
y1 = y1 - 40

-- Auto-Whisper toggle
CreateSectionHeader(t1, "Auto-Whisper", 10, y1)
y1 = y1 - 30

local cbAutoWhisper = CreateCheckbox(t1, "Enable Auto-Whisper on Friend Login", 20, y1,
    function() return ns.GetDB().autoWhisperEnabled end,
    function(v) ns.GetDB().autoWhisperEnabled = v end
)
y1 = y1 - 20

local whisperWarning = t1:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
whisperWarning:SetPoint("TOPLEFT", t1, "TOPLEFT", 50, y1)
whisperWarning:SetTextColor(1, 0.4, 0.4)
whisperWarning:SetText("When enabled, sends a message to friends when they log in.\nConfigure per-friend messages in the Friends tab.")
whisperWarning:SetJustifyH("LEFT")
y1 = y1 - 40

-- Flash Color
CreateSectionHeader(t1, "Flash Color", 10, y1)
y1 = y1 - 30

local colorPreview = t1:CreateTexture(nil, "ARTWORK")
colorPreview:SetSize(40, 40)
colorPreview:SetPoint("TOPLEFT", t1, "TOPLEFT", 20, y1)

local function UpdateColorPreview()
    local db = ns.GetDB()
    colorPreview:SetColorTexture(db.flashColor.r, db.flashColor.g, db.flashColor.b, 1)
end

local sliderR = CreateSlider(t1, "Red", 80, y1, 0, 1, 0.05,
    function() return ns.GetDB().flashColor.r end,
    function(v) ns.GetDB().flashColor.r = v; UpdateColorPreview() end
)
y1 = y1 - 45

local sliderG = CreateSlider(t1, "Green", 80, y1, 0, 1, 0.05,
    function() return ns.GetDB().flashColor.g end,
    function(v) ns.GetDB().flashColor.g = v; UpdateColorPreview() end
)
y1 = y1 - 45

local sliderB = CreateSlider(t1, "Blue", 80, y1, 0, 1, 0.05,
    function() return ns.GetDB().flashColor.b end,
    function(v) ns.GetDB().flashColor.b = v; UpdateColorPreview() end
)
y1 = y1 - 20

local testFlashBtn = CreateButton(t1, "Test Flash", 20, y1, 100, 24, function()
    if ns.DoFlash then ns.DoFlash() end
    if ns.ShowBanner then ns.ShowBanner("TestPlayer", true, "TestPlayer") end
end)
y1 = y1 - 40

-- Banner Settings
CreateSectionHeader(t1, "Banner Notification", 10, y1)
y1 = y1 - 30

local sliderAvatarSize = CreateSlider(t1, "Avatar Size", 80, y1, 24, 512, 4,
    function() return ns.GetDB().bannerAvatarSize end,
    function(v) ns.GetDB().bannerAvatarSize = v; if ns.ApplyBannerLayout then ns.ApplyBannerLayout() end end
)
y1 = y1 - 50

local sliderBannerX = CreateSlider(t1, "Position X", 80, y1, -600, 600, 10,
    function() return ns.GetDB().bannerPosX end,
    function(v) ns.GetDB().bannerPosX = v; if ns.ApplyBannerLayout then ns.ApplyBannerLayout() end end
)
y1 = y1 - 50

local sliderBannerY = CreateSlider(t1, "Position Y", 80, y1, -600, 600, 10,
    function() return ns.GetDB().bannerPosY end,
    function(v) ns.GetDB().bannerPosY = v; if ns.ApplyBannerLayout then ns.ApplyBannerLayout() end end
)
y1 = y1 - 30

local anchorLabel = t1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
anchorLabel:SetPoint("TOPLEFT", t1, "TOPLEFT", 20, y1)
anchorLabel:SetText("Screen Anchor:")

local ANCHOR_OPTIONS = { "TOP", "TOPLEFT", "TOPRIGHT", "CENTER", "BOTTOM", "BOTTOMLEFT", "BOTTOMRIGHT", "LEFT", "RIGHT" }

local anchorDropdown = CreateFrame("Frame", "BuddyFlashAnchorDropdown", t1, "UIDropDownMenuTemplate")
anchorDropdown:SetPoint("TOPLEFT", t1, "TOPLEFT", 120, y1 + 5)

local function AnchorDropdown_Initialize(self, level)
    local db = ns.GetDB()
    for _, anchor in ipairs(ANCHOR_OPTIONS) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = anchor
        info.value = anchor
        info.checked = (anchor == db.bannerAnchor)
        info.func = function(self)
            db.bannerAnchor = self.value
            UIDropDownMenu_SetText(anchorDropdown, self.value)
            if ns.ApplyBannerLayout then ns.ApplyBannerLayout() end
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

UIDropDownMenu_SetWidth(anchorDropdown, 120)
UIDropDownMenu_Initialize(anchorDropdown, AnchorDropdown_Initialize)

y1 = y1 - 35

local testBannerBtn = CreateButton(t1, "Test Banner", 20, y1, 120, 24, function()
    if ns.ShowBanner then ns.ShowBanner("TestPlayer", true, "TestPlayer") end
end)
local resetBannerBtn = CreateButton(t1, "Reset Position", 155, y1, 120, 24, function()
    local db = ns.GetDB()
    db.bannerAvatarSize = 48; db.bannerPosX = 0; db.bannerPosY = -100; db.bannerAnchor = "TOP"
    sliderAvatarSize:Refresh(); sliderBannerX:Refresh(); sliderBannerY:Refresh()
    UIDropDownMenu_SetText(anchorDropdown, "TOP")
    if ns.ApplyBannerLayout then ns.ApplyBannerLayout() end
end)
y1 = y1 - 40

-- Login Sound
CreateSectionHeader(t1, "Login Sound", 10, y1)
y1 = y1 - 30

local soundLabel = t1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
soundLabel:SetPoint("TOPLEFT", t1, "TOPLEFT", 20, y1)
soundLabel:SetText("Notification Sound:")
y1 = y1 - 22

local soundDropdown = CreateFrame("Frame", "BuddyFlashSoundDropdown", t1, "UIDropDownMenuTemplate")
soundDropdown:SetPoint("TOPLEFT", t1, "TOPLEFT", 5, y1)

local function SoundDropdown_Initialize(self, level)
    local db = ns.GetDB()
    for i, snd in ipairs(ns.SOUND_OPTIONS) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = snd.name
        info.value = i
        info.checked = (i == db.soundChoice)
        info.func = function(self)
            db.soundChoice = self.value
            UIDropDownMenu_SetText(soundDropdown, ns.SOUND_OPTIONS[self.value].name)
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

UIDropDownMenu_SetWidth(soundDropdown, 200)
UIDropDownMenu_Initialize(soundDropdown, SoundDropdown_Initialize)

y1 = y1 - 35
local testSoundBtn = CreateButton(t1, "Preview Sound", 20, y1, 120, 24, function()
    local db = ns.GetDB()
    local snd = ns.SOUND_OPTIONS[db.soundChoice] or ns.SOUND_OPTIONS[1]
    ns.PlayAlertSound(snd)
end)
y1 = y1 - 30

t1:SetHeight(-y1 + 20)

-- Tab 1 refresh
tabPanels[1].refresh = function()
    cbFlash:Refresh(); cbSound:Refresh(); cbLock:Refresh()
    cbCharFriends:Refresh(); cbBNetFriends:Refresh(); cbAutoWhisper:Refresh()
    sliderR:Refresh(); sliderG:Refresh(); sliderB:Refresh(); UpdateColorPreview()
    sliderAvatarSize:Refresh(); sliderBannerX:Refresh(); sliderBannerY:Refresh()
    local db = ns.GetDB()
    UIDropDownMenu_SetText(anchorDropdown, db.bannerAnchor or "TOP")
    UIDropDownMenu_SetText(soundDropdown, (ns.SOUND_OPTIONS[db.soundChoice] or ns.SOUND_OPTIONS[1]).name)
end

-- ============================================================
-- FRIEND CONFIG POPUP (modal, used by Tab 2 and right-click menu)
-- ============================================================

local fcPopup = CreateFrame("Frame", "BuddyFlashFriendConfig", UIParent, "BackdropTemplate")
fcPopup:SetSize(420, 400)
fcPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
fcPopup:SetFrameStrata("FULLSCREEN_DIALOG")
fcPopup:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
fcPopup:SetBackdropColor(0.05, 0.08, 0.15, 0.98)
fcPopup:SetBackdropBorderColor(0.4, 0.6, 1.0, 0.9)
fcPopup:SetMovable(true)
fcPopup:EnableMouse(true)
fcPopup:RegisterForDrag("LeftButton")
fcPopup:SetScript("OnDragStart", fcPopup.StartMoving)
fcPopup:SetScript("OnDragStop", fcPopup.StopMovingOrSizing)
fcPopup:SetClampedToScreen(true)
fcPopup:Hide()

tinsert(UISpecialFrames, "BuddyFlashFriendConfig")

-- Popup title
local fcTitleBg = fcPopup:CreateTexture(nil, "ARTWORK")
fcTitleBg:SetHeight(28)
fcTitleBg:SetPoint("TOPLEFT", fcPopup, "TOPLEFT", 4, -4)
fcTitleBg:SetPoint("TOPRIGHT", fcPopup, "TOPRIGHT", -4, -4)
fcTitleBg:SetColorTexture(0.1, 0.2, 0.4, 0.7)

local fcTitle = fcPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
fcTitle:SetPoint("TOP", fcPopup, "TOP", 0, -9)
fcTitle:SetText("Configure Friend")

local fcCloseBtn = CreateFrame("Button", nil, fcPopup, "UIPanelCloseButton")
fcCloseBtn:SetPoint("TOPRIGHT", fcPopup, "TOPRIGHT", -2, -2)

-- Internal state
local fcCharName, fcBnetTag = nil, nil

-- == AVATAR SECTION ==
local fcY = -40
CreateSectionHeader(fcPopup, "Avatar", 15, fcY)
fcY = fcY - 28

local fcAvatarPreview = fcPopup:CreateTexture(nil, "ARTWORK")
fcAvatarPreview:SetSize(48, 48)
fcAvatarPreview:SetPoint("TOPLEFT", fcPopup, "TOPLEFT", 20, fcY)
fcAvatarPreview:SetTexCoord(0, 1, 0, 1)

local fcSelectedAvatar = "default"

local fcAvatarDropdown = CreateFrame("Frame", "BuddyFlashFCAvatar", fcPopup, "UIDropDownMenuTemplate")
fcAvatarDropdown:SetPoint("TOPLEFT", fcPopup, "TOPLEFT", 70, fcY + 15)

local function FCAvatarDropdown_Init(self, level)
    local avatars = GetAvailableAvatars()
    for _, av in ipairs(avatars) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = av
        info.value = av
        info.checked = (av == fcSelectedAvatar)
        info.func = function(self)
            fcSelectedAvatar = self.value
            UIDropDownMenu_SetText(fcAvatarDropdown, self.value)
            fcAvatarPreview:SetTexture(ns.AVATAR_PATH .. self.value)
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end
UIDropDownMenu_SetWidth(fcAvatarDropdown, 130)
UIDropDownMenu_Initialize(fcAvatarDropdown, FCAvatarDropdown_Init)

local fcAssignAvatarBtn = CreateFrame("Button", nil, fcPopup, "UIPanelButtonTemplate")
fcAssignAvatarBtn:SetSize(80, 24)
fcAssignAvatarBtn:SetPoint("TOPLEFT", fcPopup, "TOPLEFT", 240, fcY - 2)
fcAssignAvatarBtn:SetText("Assign")
fcAssignAvatarBtn:SetScript("OnClick", function()
    local db = ns.GetDB()
    local key = fcBnetTag or fcCharName
    if key then
        db.avatars[key] = fcSelectedAvatar
        print("|cFF69CCF0BuddyFlash:|r Avatar set for |cFFFFFF00" .. key .. "|r: " .. fcSelectedAvatar)
        if ns.UpdateListUI then ns.UpdateListUI() end
    end
end)

local fcRemoveAvatarBtn = CreateFrame("Button", nil, fcPopup, "UIPanelButtonTemplate")
fcRemoveAvatarBtn:SetSize(80, 24)
fcRemoveAvatarBtn:SetPoint("LEFT", fcAssignAvatarBtn, "RIGHT", 5, 0)
fcRemoveAvatarBtn:SetText("Remove")
fcRemoveAvatarBtn:SetScript("OnClick", function()
    local db = ns.GetDB()
    if fcCharName and db.avatars[fcCharName] then db.avatars[fcCharName] = nil end
    if fcBnetTag and db.avatars[fcBnetTag] then db.avatars[fcBnetTag] = nil end
    print("|cFF69CCF0BuddyFlash:|r Avatar removed.")
    fcAvatarPreview:SetTexture(ns.DEFAULT_AVATAR)
    if ns.UpdateListUI then ns.UpdateListUI() end
end)

fcY = fcY - 60

-- == SOUND SECTION ==
CreateSectionHeader(fcPopup, "Login Sound", 15, fcY)
fcY = fcY - 28

local fcSoundLabel = fcPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
fcSoundLabel:SetPoint("TOPLEFT", fcPopup, "TOPLEFT", 20, fcY)
fcSoundLabel:SetTextColor(0.7, 0.7, 0.7)
fcSoundLabel:SetText("Override global sound for this friend:")
fcY = fcY - 18

local fcSelectedSound = 1
local fcSoundDropdown = CreateFrame("Frame", "BuddyFlashFCSound", fcPopup, "UIDropDownMenuTemplate")
fcSoundDropdown:SetPoint("TOPLEFT", fcPopup, "TOPLEFT", 5, fcY + 5)

local function FCSoundDropdown_Init(self, level)
    for i, snd in ipairs(ns.SOUND_OPTIONS) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = snd.name
        info.value = i
        info.checked = (i == fcSelectedSound)
        info.func = function(self)
            fcSelectedSound = self.value
            UIDropDownMenu_SetText(fcSoundDropdown, ns.SOUND_OPTIONS[self.value].name)
            ns.PlayAlertSound(ns.SOUND_OPTIONS[self.value])
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end
UIDropDownMenu_SetWidth(fcSoundDropdown, 200)
UIDropDownMenu_Initialize(fcSoundDropdown, FCSoundDropdown_Init)

fcY = fcY - 30

local fcSetSoundBtn = CreateFrame("Button", nil, fcPopup, "UIPanelButtonTemplate")
fcSetSoundBtn:SetSize(90, 24)
fcSetSoundBtn:SetPoint("TOPLEFT", fcPopup, "TOPLEFT", 20, fcY)
fcSetSoundBtn:SetText("Set Sound")
fcSetSoundBtn:SetScript("OnClick", function()
    local db = ns.GetDB()
    local key = fcBnetTag or fcCharName
    if key then
        db.friendSounds[key] = fcSelectedSound
        print("|cFF69CCF0BuddyFlash:|r Sound for |cFFFFFF00" .. key .. "|r set to: " .. (ns.SOUND_OPTIONS[fcSelectedSound] or {}).name)
    end
end)

local fcRemoveSoundBtn = CreateFrame("Button", nil, fcPopup, "UIPanelButtonTemplate")
fcRemoveSoundBtn:SetSize(100, 24)
fcRemoveSoundBtn:SetPoint("LEFT", fcSetSoundBtn, "RIGHT", 5, 0)
fcRemoveSoundBtn:SetText("Use Global")
fcRemoveSoundBtn:SetScript("OnClick", function()
    local db = ns.GetDB()
    if fcCharName then db.friendSounds[fcCharName] = nil end
    if fcBnetTag then db.friendSounds[fcBnetTag] = nil end
    print("|cFF69CCF0BuddyFlash:|r Custom sound removed (using global).")
end)

local fcPreviewSoundBtn = CreateFrame("Button", nil, fcPopup, "UIPanelButtonTemplate")
fcPreviewSoundBtn:SetSize(80, 24)
fcPreviewSoundBtn:SetPoint("LEFT", fcRemoveSoundBtn, "RIGHT", 5, 0)
fcPreviewSoundBtn:SetText("Preview")
fcPreviewSoundBtn:SetScript("OnClick", function()
    if ns.SOUND_OPTIONS[fcSelectedSound] then ns.PlayAlertSound(ns.SOUND_OPTIONS[fcSelectedSound]) end
end)

fcY = fcY - 45

-- == WHISPER SECTION ==
CreateSectionHeader(fcPopup, "Auto-Whisper", 15, fcY)
fcY = fcY - 28

local fcWhisperInfo = fcPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
fcWhisperInfo:SetPoint("TOPLEFT", fcPopup, "TOPLEFT", 20, fcY)
fcWhisperInfo:SetTextColor(0.7, 0.7, 0.7)
fcWhisperInfo:SetText("Message sent when this friend logs in (requires global toggle ON):")
fcY = fcY - 20

local fcWhisperInput = CreateFrame("EditBox", "BuddyFlashFCWhisper", fcPopup, "InputBoxTemplate")
fcWhisperInput:SetPoint("TOPLEFT", fcPopup, "TOPLEFT", 20, fcY)
fcWhisperInput:SetSize(370, 25)
fcWhisperInput:SetAutoFocus(false)
fcWhisperInput:SetMaxLetters(200)
fcWhisperInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
fcWhisperInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
fcY = fcY - 30

local fcSetWhisperBtn = CreateFrame("Button", nil, fcPopup, "UIPanelButtonTemplate")
fcSetWhisperBtn:SetSize(110, 24)
fcSetWhisperBtn:SetPoint("TOPLEFT", fcPopup, "TOPLEFT", 20, fcY)
fcSetWhisperBtn:SetText("Save Whisper")
fcSetWhisperBtn:SetScript("OnClick", function()
    local msg = fcWhisperInput:GetText():trim()
    if msg == "" then
        print("|cFF69CCF0BuddyFlash:|r Enter a message!")
        return
    end
    local db = ns.GetDB()
    local key = fcBnetTag or fcCharName
    if key then
        db.autoWhisper[key] = msg
        print("|cFF69CCF0BuddyFlash:|r Auto-whisper for |cFFFFFF00" .. key .. "|r: \"" .. msg .. "\"")
    end
end)

local fcRemoveWhisperBtn = CreateFrame("Button", nil, fcPopup, "UIPanelButtonTemplate")
fcRemoveWhisperBtn:SetSize(120, 24)
fcRemoveWhisperBtn:SetPoint("LEFT", fcSetWhisperBtn, "RIGHT", 5, 0)
fcRemoveWhisperBtn:SetText("Remove Whisper")
fcRemoveWhisperBtn:SetScript("OnClick", function()
    local db = ns.GetDB()
    if fcCharName then db.autoWhisper[fcCharName] = nil end
    if fcBnetTag then db.autoWhisper[fcBnetTag] = nil end
    fcWhisperInput:SetText("")
    print("|cFF69CCF0BuddyFlash:|r Auto-whisper removed.")
end)

-- Show Friend Config popup
function ns.ShowFriendConfig(charName, bnetTag, displayName)
    fcCharName = charName
    fcBnetTag = bnetTag
    fcTitle:SetText("Configure: |cFFFFFF00" .. (displayName or charName or bnetTag or "?") .. "|r")

    local db = ns.GetDB()
    local key = bnetTag or charName

    local Lookup = ns.LookupByTag

    -- Load avatar
    local currentAvatar = Lookup(db.avatars, bnetTag)
    if not currentAvatar and charName then currentAvatar = db.avatars[charName] end
    fcSelectedAvatar = currentAvatar or "default"
    UIDropDownMenu_SetText(fcAvatarDropdown, fcSelectedAvatar)
    fcAvatarPreview:SetTexture(ns.AVATAR_PATH .. fcSelectedAvatar)

    -- Load sound
    local currentSound = Lookup(db.friendSounds, bnetTag)
    if not currentSound and charName then currentSound = db.friendSounds[charName] end
    fcSelectedSound = currentSound or db.soundChoice or 1
    UIDropDownMenu_SetText(fcSoundDropdown, (ns.SOUND_OPTIONS[fcSelectedSound] or ns.SOUND_OPTIONS[1]).name)

    -- Load whisper
    local currentWhisper = Lookup(db.autoWhisper, bnetTag)
    if not currentWhisper and charName then currentWhisper = db.autoWhisper[charName] end
    fcWhisperInput:SetText(currentWhisper or "")

    fcPopup:Show()
end

-- ============================================================
-- TAB 2: FRIENDS (click-to-configure friend list)
-- ============================================================

local t2 = tabPanels[2].child
local y2 = -10

CreateSectionHeader(t2, "Battle.net Friends", 10, y2)
y2 = y2 - 26

local friendsInfo = t2:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
friendsInfo:SetPoint("TOPLEFT", t2, "TOPLEFT", 20, y2)
friendsInfo:SetTextColor(0.6, 0.6, 0.6)
friendsInfo:SetText("Click a friend to configure their avatar, sound, and whisper.")
y2 = y2 - 22

local friendListFrame = CreateFrame("Frame", nil, t2, "BackdropTemplate")
friendListFrame:SetPoint("TOPLEFT", t2, "TOPLEFT", 10, y2)
friendListFrame:SetSize(460, 500)
friendListFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
friendListFrame:SetBackdropColor(0, 0, 0, 0.4)
friendListFrame:SetBackdropBorderColor(0.2, 0.3, 0.5, 0.6)

local friendScroll = CreateFrame("ScrollFrame", "BuddyFlashFriendTabScroll", friendListFrame, "UIPanelScrollFrameTemplate")
friendScroll:SetPoint("TOPLEFT", friendListFrame, "TOPLEFT", 6, -6)
friendScroll:SetPoint("BOTTOMRIGHT", friendListFrame, "BOTTOMRIGHT", -24, 6)

local friendScrollChild = CreateFrame("Frame", nil, friendScroll)
friendScrollChild:SetSize(430, 1)
friendScroll:SetScrollChild(friendScrollChild)

local friendRows = {}

local function CreateFriendRow(index)
    local row = CreateFrame("Button", nil, friendScrollChild)
    row:SetHeight(36)
    row:SetPoint("TOPLEFT", friendScrollChild, "TOPLEFT", 0, -(index - 1) * 36)
    row:SetPoint("RIGHT", friendScrollChild, "RIGHT", 0, 0)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    row.bg = bg

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(row)
    hl:SetColorTexture(0.2, 0.4, 0.6, 0.3)

    -- Online/offline indicator dot
    local statusDot = row:CreateTexture(nil, "ARTWORK")
    statusDot:SetSize(10, 10)
    statusDot:SetPoint("LEFT", row, "LEFT", 6, 0)
    statusDot:SetTexture("Interface\\COMMON\\Indicator-Green")
    row.statusDot = statusDot

    local avatar = row:CreateTexture(nil, "ARTWORK")
    avatar:SetSize(28, 28)
    avatar:SetPoint("LEFT", statusDot, "RIGHT", 4, 0)
    avatar:SetTexCoord(0, 1, 0, 1)
    row.avatar = avatar

    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", avatar, "RIGHT", 8, 0)
    nameText:SetWidth(200)
    nameText:SetJustifyH("LEFT")
    row.nameText = nameText

    -- Status icons (small text badges)
    local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    statusText:SetJustifyH("RIGHT")
    row.statusText = statusText

    friendRows[index] = row
    return row
end

local function RefreshFriendList()
    if not ns.CollectAllBNetFriends then return end
    local allFriends = ns.CollectAllBNetFriends()
    local db = ns.GetDB()

    for i, friend in ipairs(allFriends) do
        local row = friendRows[i] or CreateFriendRow(i)

        -- Alternate row background
        if i % 2 == 0 then
            row.bg:SetColorTexture(0.08, 0.08, 0.12, 0.4)
        else
            row.bg:SetColorTexture(0, 0, 0, 0)
        end

        -- Online/offline/AFK/DND indicator
        if friend.isDND then
            row.statusDot:SetTexture("Interface\\COMMON\\Indicator-Red")
        elseif friend.isAFK then
            row.statusDot:SetTexture("Interface\\COMMON\\Indicator-Yellow")
        elseif friend.isOnline then
            row.statusDot:SetTexture("Interface\\COMMON\\Indicator-Green")
        else
            row.statusDot:SetTexture("Interface\\COMMON\\Indicator-Gray")
        end

        -- Avatar
        row.avatar:SetTexture(ns.GetAvatarTexture(friend.charName, friend.bnetTag))
        if friend.isOnline then
            row.avatar:SetDesaturated(false)
            row.avatar:SetAlpha(1)
        else
            row.avatar:SetDesaturated(true)
            row.avatar:SetAlpha(0.6)
        end

        -- Name display
        local displayName
        local statusTag = ""
        if friend.isAFK then statusTag = " |cFFFFCC00[Away]|r"
        elseif friend.isDND then statusTag = " |cFFFF4444[Busy]|r" end

        if friend.isOnline and friend.charName then
            displayName = friend.charName .. " |cFF888888(" .. friend.bnetTag .. ")|r" .. statusTag
        elseif friend.isOnline then
            displayName = "|cFFFFFFAA" .. friend.bnetTag .. "|r" .. statusTag
        else
            displayName = "|cFF777777" .. friend.bnetTag .. "|r"
        end
        row.nameText:SetText(displayName)

        -- Build status badges
        local badges = {}
        local key = friend.bnetTag
        local Lookup = ns.LookupByTag
        if key then
            if Lookup(db.avatars, key) or (friend.charName and db.avatars[friend.charName]) then
                table.insert(badges, "|cFF00FF00av|r")
            end
            if Lookup(db.friendSounds, key) or (friend.charName and db.friendSounds[friend.charName]) then
                table.insert(badges, "|cFF69CCF0snd|r")
            end
            if Lookup(db.autoWhisper, key) or (friend.charName and db.autoWhisper[friend.charName]) then
                table.insert(badges, "|cFFFFCC00wsp|r")
            end
        end
        row.statusText:SetText(#badges > 0 and table.concat(badges, " ") or "|cFF666666configure|r")

        row:SetScript("OnClick", function()
            local name = friend.bnetTag
            if friend.charName then
                name = friend.bnetTag .. " (" .. friend.charName .. ")"
            end
            ns.ShowFriendConfig(friend.charName, friend.bnetTag, name)
        end)
        row:Show()
    end

    for i = #allFriends + 1, #friendRows do
        if friendRows[i] then friendRows[i]:Hide() end
    end

    if #allFriends == 0 then
        local row = friendRows[1] or CreateFriendRow(1)
        row.statusDot:SetTexture("Interface\\COMMON\\Indicator-Gray")
        row.avatar:SetTexture(ns.DEFAULT_AVATAR)
        row.avatar:SetDesaturated(false)
        row.avatar:SetAlpha(1)
        row.bg:SetColorTexture(0, 0, 0, 0)
        row.nameText:SetText("|cFF666666No Battle.net friends found|r")
        row.statusText:SetText("")
        row:SetScript("OnClick", nil)
        row:Show()
        friendScrollChild:SetHeight(36)
    else
        friendScrollChild:SetHeight(#allFriends * 36)
    end
end

y2 = y2 - 510
t2:SetHeight(-y2 + 20)
tabPanels[2].refresh = RefreshFriendList

-- ============================================================
-- TAB 3: AVATARS
-- ============================================================

local t3 = tabPanels[3].child
local y3 = -10

CreateSectionHeader(t3, "Assign Avatar", 10, y3)
y3 = y3 - 26

local avInfoText = t3:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
avInfoText:SetPoint("TOPLEFT", t3, "TOPLEFT", 20, y3)
avInfoText:SetTextColor(0.6, 0.6, 0.6)
avInfoText:SetText("Assign avatars by Character Name or BattleTag.\nOr use the Friends tab to click-assign.")
avInfoText:SetJustifyH("LEFT")
y3 = y3 - 35

local nameLabel = t3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
nameLabel:SetPoint("TOPLEFT", t3, "TOPLEFT", 20, y3)
nameLabel:SetText("Name / BattleTag:")

local nameInput = CreateFrame("EditBox", "BuddyFlashNameInput", t3, "InputBoxTemplate")
nameInput:SetPoint("TOPLEFT", t3, "TOPLEFT", 140, y3)
nameInput:SetSize(180, 25)
nameInput:SetAutoFocus(false)
nameInput:SetMaxLetters(50)
nameInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
nameInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
y3 = y3 - 30

local avatarDropdownLabel = t3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
avatarDropdownLabel:SetPoint("TOPLEFT", t3, "TOPLEFT", 20, y3 + 5)
avatarDropdownLabel:SetText("Avatar:")

local avatarDropdown = CreateFrame("Frame", "BuddyFlashAvatarDropdown", t3, "UIDropDownMenuTemplate")
avatarDropdown:SetPoint("TOPLEFT", t3, "TOPLEFT", 205, y3)

local selectedAvatar = "default"

local avatarPreviewTexture = t3:CreateTexture(nil, "ARTWORK")
avatarPreviewTexture:SetSize(48, 48)
avatarPreviewTexture:SetPoint("TOPLEFT", t3, "TOPLEFT", 140, y3 + 8)
avatarPreviewTexture:SetTexture(ns.DEFAULT_AVATAR)
avatarPreviewTexture:SetTexCoord(0, 1, 0, 1)

local function AvatarDropdown_Initialize(self, level)
    local avatars = GetAvailableAvatars()
    for _, av in ipairs(avatars) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = av
        info.value = av
        info.checked = (av == selectedAvatar)
        info.func = function(self)
            selectedAvatar = self.value
            UIDropDownMenu_SetText(avatarDropdown, self.value)
            avatarPreviewTexture:SetTexture(ns.AVATAR_PATH .. self.value)
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end
UIDropDownMenu_SetWidth(avatarDropdown, 130)
UIDropDownMenu_Initialize(avatarDropdown, AvatarDropdown_Initialize)
UIDropDownMenu_SetText(avatarDropdown, selectedAvatar)

y3 = y3 - 35

local assignBtn = CreateButton(t3, "Assign Avatar", 20, y3, 130, 28, function()
    local name = nameInput:GetText():trim()
    if name == "" then print("|cFF69CCF0BuddyFlash:|r Enter a name!"); return end
    local db = ns.GetDB()
    name = FormatName(name)
    db.avatars[name] = selectedAvatar
    print("|cFF69CCF0BuddyFlash:|r Avatar for |cFFFFFF00" .. name .. "|r set to |cFF00FF00" .. selectedAvatar .. "|r")
    nameInput:SetText(""); nameInput:ClearFocus()
    if ns.UpdateListUI then ns.UpdateListUI() end
    RefreshAssignmentList()
end)

local removeBtn = CreateButton(t3, "Remove Avatar", 165, y3, 130, 28, function()
    local name = nameInput:GetText():trim()
    if name == "" then print("|cFF69CCF0BuddyFlash:|r Enter a name!"); return end
    local db = ns.GetDB()
    name = FormatName(name)
    if db.avatars[name] then
        db.avatars[name] = nil
        print("|cFF69CCF0BuddyFlash:|r Avatar removed for |cFFFFFF00" .. name .. "|r")
    end
    nameInput:SetText(""); nameInput:ClearFocus()
    if ns.UpdateListUI then ns.UpdateListUI() end
    RefreshAssignmentList()
end)

y3 = y3 - 45

-- Current assignments
CreateSectionHeader(t3, "Current Assignments", 10, y3)
y3 = y3 - 25

local assignListFrame = CreateFrame("Frame", nil, t3, "BackdropTemplate")
assignListFrame:SetPoint("TOPLEFT", t3, "TOPLEFT", 10, y3)
assignListFrame:SetSize(460, 360)
assignListFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
assignListFrame:SetBackdropColor(0, 0, 0, 0.4)
assignListFrame:SetBackdropBorderColor(0.2, 0.3, 0.5, 0.6)

local assignScroll = CreateFrame("ScrollFrame", "BuddyFlashAssignScroll", assignListFrame, "UIPanelScrollFrameTemplate")
assignScroll:SetPoint("TOPLEFT", assignListFrame, "TOPLEFT", 6, -6)
assignScroll:SetPoint("BOTTOMRIGHT", assignListFrame, "BOTTOMRIGHT", -24, 6)

local assignScrollChild = CreateFrame("Frame", nil, assignScroll)
assignScrollChild:SetSize(430, 1)
assignScroll:SetScrollChild(assignScrollChild)

local assignmentRows = {}

local function CreateAssignmentRow(index)
    local row = CreateFrame("Frame", nil, assignScrollChild)
    row:SetHeight(36)
    row:SetPoint("TOPLEFT", assignScrollChild, "TOPLEFT", 0, -(index - 1) * 36)
    row:SetPoint("RIGHT", assignScrollChild, "RIGHT", 0, 0)
    row:EnableMouse(true)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetColorTexture(index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.3 or 0)

    local avatar = row:CreateTexture(nil, "ARTWORK")
    avatar:SetSize(28, 28)
    avatar:SetPoint("LEFT", row, "LEFT", 5, 0)
    avatar:SetTexCoord(0, 1, 0, 1)
    row.avatar = avatar

    local charText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charText:SetPoint("LEFT", avatar, "RIGHT", 8, 4)
    charText:SetJustifyH("LEFT")
    row.charText = charText

    local fileText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fileText:SetPoint("LEFT", avatar, "RIGHT", 8, -8)
    fileText:SetJustifyH("LEFT")
    fileText:SetTextColor(0.5, 0.5, 0.5)
    row.fileText = fileText

    local editBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    editBtn:SetSize(50, 22)
    editBtn:SetPoint("RIGHT", row, "RIGHT", -60, 0)
    editBtn:SetText("Edit")
    editBtn:SetFrameLevel(row:GetFrameLevel() + 5)
    row.editBtn = editBtn

    local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    delBtn:SetSize(55, 22)
    delBtn:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    delBtn:SetText("Remove")
    delBtn:SetFrameLevel(row:GetFrameLevel() + 5)
    row.delBtn = delBtn

    assignmentRows[index] = row
    return row
end

function RefreshAssignmentList()
    local db = ns.GetDB()
    local assignments = {}
    for charName, fileName in pairs(db.avatars) do
        table.insert(assignments, { charName = charName, fileName = fileName })
    end
    table.sort(assignments, function(a, b) return a.charName < b.charName end)

    for i, entry in ipairs(assignments) do
        local row = assignmentRows[i] or CreateAssignmentRow(i)
        row.avatar:SetTexture(ns.AVATAR_PATH .. entry.fileName)
        local typeTag = entry.charName:find("#") and "|cFF69CCF0[BTag]|r " or ""
        row.charText:SetText(typeTag .. "|cFFFFFF00" .. entry.charName .. "|r")
        row.fileText:SetText(entry.fileName)

        row.editBtn:SetScript("OnClick", function()
            ShowEditPopup_Avatar(entry.charName, entry.fileName, function(newFile)
                db.avatars[entry.charName] = newFile
                if ns.UpdateListUI then ns.UpdateListUI() end
                RefreshAssignmentList()
            end)
        end)

        row.delBtn:SetScript("OnClick", function()
            db.avatars[entry.charName] = nil
            if ns.UpdateListUI then ns.UpdateListUI() end
            RefreshAssignmentList()
        end)
        row:Show()
    end

    for i = #assignments + 1, #assignmentRows do
        if assignmentRows[i] then assignmentRows[i]:Hide() end
    end

    if #assignments == 0 then
        local row = assignmentRows[1] or CreateAssignmentRow(1)
        row.avatar:SetTexture(ns.DEFAULT_AVATAR)
        row.charText:SetText("|cFF666666No avatars assigned yet|r")
        row.fileText:SetText("Use controls above or Friends tab")
        row.editBtn:Hide(); row.delBtn:Hide()
        row:Show()
        assignScrollChild:SetHeight(36)
    else
        assignScrollChild:SetHeight(#assignments * 36)
        for i = 1, #assignments do
            assignmentRows[i].editBtn:Show()
            assignmentRows[i].delBtn:Show()
        end
    end
end

y3 = y3 - 370
t3:SetHeight(-y3 + 20)

tabPanels[3].refresh = function()
    UIDropDownMenu_Initialize(avatarDropdown, AvatarDropdown_Initialize)
    UIDropDownMenu_SetText(avatarDropdown, selectedAvatar)
    avatarPreviewTexture:SetTexture(ns.AVATAR_PATH .. selectedAvatar)
    RefreshAssignmentList()
end

-- ============================================================
-- TAB 4: SOUNDS (per-friend)
-- ============================================================

local t4 = tabPanels[4].child
local y4 = -10

CreateSectionHeader(t4, "Per-Friend Login Sounds", 10, y4)
y4 = y4 - 26

local fsInfo = t4:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
fsInfo:SetPoint("TOPLEFT", t4, "TOPLEFT", 20, y4)
fsInfo:SetTextColor(0.6, 0.6, 0.6)
fsInfo:SetText("Override the global login sound for specific friends.\nOr use the Friends tab to click-configure.")
fsInfo:SetJustifyH("LEFT")
y4 = y4 - 35

local fsTargetLabel = t4:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fsTargetLabel:SetPoint("TOPLEFT", t4, "TOPLEFT", 20, y4)
fsTargetLabel:SetText("Friend:")

local fsTargetInput = CreateFrame("EditBox", "BuddyFlashFSTarget", t4, "InputBoxTemplate")
fsTargetInput:SetPoint("TOPLEFT", t4, "TOPLEFT", 80, y4)
fsTargetInput:SetSize(180, 25)
fsTargetInput:SetAutoFocus(false)
fsTargetInput:SetMaxLetters(50)
fsTargetInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
fsTargetInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
y4 = y4 - 28

local fsSoundLabel = t4:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fsSoundLabel:SetPoint("TOPLEFT", t4, "TOPLEFT", 20, y4)
fsSoundLabel:SetText("Sound:")

local fsSoundDropdown = CreateFrame("Frame", "BuddyFlashFSSoundDropdown", t4, "UIDropDownMenuTemplate")
fsSoundDropdown:SetPoint("TOPLEFT", t4, "TOPLEFT", 60, y4 + 5)

local selectedFriendSound = 1

local function FSSoundDropdown_Initialize(self, level)
    for i, snd in ipairs(ns.SOUND_OPTIONS) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = snd.name
        info.value = i
        info.checked = (i == selectedFriendSound)
        info.func = function(self)
            selectedFriendSound = self.value
            UIDropDownMenu_SetText(fsSoundDropdown, ns.SOUND_OPTIONS[self.value].name)
            ns.PlayAlertSound(ns.SOUND_OPTIONS[self.value])
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end
UIDropDownMenu_SetWidth(fsSoundDropdown, 180)
UIDropDownMenu_Initialize(fsSoundDropdown, FSSoundDropdown_Initialize)
UIDropDownMenu_SetText(fsSoundDropdown, ns.SOUND_OPTIONS[1].name)

y4 = y4 - 35

local setFSBtn = CreateButton(t4, "Set Sound", 20, y4, 110, 24, function()
    local target = fsTargetInput:GetText():trim()
    if target == "" then print("|cFF69CCF0BuddyFlash:|r Enter a friend name!"); return end
    local db = ns.GetDB()
    db.friendSounds[target] = selectedFriendSound
    print("|cFF69CCF0BuddyFlash:|r Sound for |cFFFFFF00" .. target .. "|r set to: " .. (ns.SOUND_OPTIONS[selectedFriendSound] or {}).name)
    fsTargetInput:SetText(""); fsTargetInput:ClearFocus()
    RefreshFriendSoundList()
end)

local removeFSBtn = CreateButton(t4, "Remove Sound", 145, y4, 120, 24, function()
    local target = fsTargetInput:GetText():trim()
    if target == "" then print("|cFF69CCF0BuddyFlash:|r Enter a friend name!"); return end
    local db = ns.GetDB()
    if db.friendSounds[target] then db.friendSounds[target] = nil end
    fsTargetInput:SetText(""); fsTargetInput:ClearFocus()
    RefreshFriendSoundList()
end)

local previewFSBtn = CreateButton(t4, "Preview", 280, y4, 80, 24, function()
    if ns.SOUND_OPTIONS[selectedFriendSound] then ns.PlayAlertSound(ns.SOUND_OPTIONS[selectedFriendSound]) end
end)
y4 = y4 - 40

-- Sound assignments list
CreateSectionHeader(t4, "Current Assignments", 10, y4)
y4 = y4 - 25

local fsListFrame = CreateFrame("Frame", nil, t4, "BackdropTemplate")
fsListFrame:SetPoint("TOPLEFT", t4, "TOPLEFT", 10, y4)
fsListFrame:SetSize(460, 360)
fsListFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
fsListFrame:SetBackdropColor(0, 0, 0, 0.4)
fsListFrame:SetBackdropBorderColor(0.2, 0.3, 0.5, 0.6)

local fsScroll = CreateFrame("ScrollFrame", "BuddyFlashFSScroll", fsListFrame, "UIPanelScrollFrameTemplate")
fsScroll:SetPoint("TOPLEFT", fsListFrame, "TOPLEFT", 6, -6)
fsScroll:SetPoint("BOTTOMRIGHT", fsListFrame, "BOTTOMRIGHT", -24, 6)

local fsScrollChild = CreateFrame("Frame", nil, fsScroll)
fsScrollChild:SetSize(430, 1)
fsScroll:SetScrollChild(fsScrollChild)

local fsRows = {}

local function CreateFSRow(index)
    local row = CreateFrame("Frame", nil, fsScrollChild)
    row:SetHeight(30)
    row:SetPoint("TOPLEFT", fsScrollChild, "TOPLEFT", 0, -(index - 1) * 30)
    row:SetPoint("RIGHT", fsScrollChild, "RIGHT", 0, 0)
    row:EnableMouse(true)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetColorTexture(index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.3 or 0)

    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", row, "LEFT", 5, 0)
    nameText:SetWidth(150)
    nameText:SetJustifyH("LEFT")
    row.nameText = nameText

    local sndText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sndText:SetPoint("LEFT", nameText, "RIGHT", 5, 0)
    sndText:SetWidth(180)
    sndText:SetJustifyH("LEFT")
    sndText:SetTextColor(0.7, 0.7, 0.7)
    row.sndText = sndText

    local editBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    editBtn:SetSize(50, 22)
    editBtn:SetPoint("RIGHT", row, "RIGHT", -60, 0)
    editBtn:SetText("Edit")
    editBtn:SetFrameLevel(row:GetFrameLevel() + 5)
    row.editBtn = editBtn

    local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    delBtn:SetSize(55, 22)
    delBtn:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    delBtn:SetText("Remove")
    delBtn:SetFrameLevel(row:GetFrameLevel() + 5)
    row.delBtn = delBtn

    fsRows[index] = row
    return row
end

function RefreshFriendSoundList()
    local db = ns.GetDB()
    local entries = {}
    for target, idx in pairs(db.friendSounds) do
        table.insert(entries, { target = target, soundIdx = idx, soundName = (ns.SOUND_OPTIONS[idx] or {}).name or "?" })
    end
    table.sort(entries, function(a, b) return a.target < b.target end)

    for i, entry in ipairs(entries) do
        local row = fsRows[i] or CreateFSRow(i)
        row.nameText:SetText("|cFFFFFF00" .. entry.target .. "|r")
        row.sndText:SetText(entry.soundName)
        row.editBtn:SetScript("OnClick", function()
            ShowEditPopup_Sound(entry.target, entry.soundIdx, function(newIdx)
                db.friendSounds[entry.target] = newIdx
                RefreshFriendSoundList()
            end)
        end)
        row.delBtn:SetScript("OnClick", function()
            db.friendSounds[entry.target] = nil
            RefreshFriendSoundList()
        end)
        row:Show()
    end

    for i = #entries + 1, #fsRows do
        if fsRows[i] then fsRows[i]:Hide() end
    end

    if #entries == 0 then
        local row = fsRows[1] or CreateFSRow(1)
        row.nameText:SetText("|cFF666666No per-friend sounds|r")
        row.sndText:SetText("All friends use global sound")
        row.editBtn:Hide(); row.delBtn:Hide()
        row:Show()
        fsScrollChild:SetHeight(30)
    else
        fsScrollChild:SetHeight(#entries * 30)
        for i = 1, #entries do fsRows[i].editBtn:Show(); fsRows[i].delBtn:Show() end
    end
end

y4 = y4 - 370
t4:SetHeight(-y4 + 20)
tabPanels[4].refresh = RefreshFriendSoundList

-- ============================================================
-- TAB 5: WHISPER (per-friend auto-whisper messages)
-- ============================================================

local t5w = tabPanels[5].child
local y5w = -10

CreateSectionHeader(t5w, "Per-Friend Auto-Whisper", 10, y5w)
y5w = y5w - 26

local wspInfo = t5w:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
wspInfo:SetPoint("TOPLEFT", t5w, "TOPLEFT", 20, y5w)
wspInfo:SetTextColor(0.6, 0.6, 0.6)
wspInfo:SetText("Set a message to automatically send when a friend logs in.\nRequires 'Enable Auto-Whisper' in the General tab.")
wspInfo:SetJustifyH("LEFT")
y5w = y5w - 40

local wspTargetLabel = t5w:CreateFontString(nil, "OVERLAY", "GameFontNormal")
wspTargetLabel:SetPoint("TOPLEFT", t5w, "TOPLEFT", 20, y5w)
wspTargetLabel:SetText("Friend:")

local wspTargetInput = CreateFrame("EditBox", "BuddyFlashWspTarget", t5w, "InputBoxTemplate")
wspTargetInput:SetPoint("TOPLEFT", t5w, "TOPLEFT", 80, y5w)
wspTargetInput:SetSize(180, 25)
wspTargetInput:SetAutoFocus(false)
wspTargetInput:SetMaxLetters(50)
wspTargetInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
wspTargetInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
y5w = y5w - 28

local wspMsgLabel = t5w:CreateFontString(nil, "OVERLAY", "GameFontNormal")
wspMsgLabel:SetPoint("TOPLEFT", t5w, "TOPLEFT", 20, y5w)
wspMsgLabel:SetText("Message:")

local wspMsgInput = CreateFrame("EditBox", "BuddyFlashWspMsg", t5w, "InputBoxTemplate")
wspMsgInput:SetPoint("TOPLEFT", t5w, "TOPLEFT", 90, y5w)
wspMsgInput:SetSize(350, 25)
wspMsgInput:SetAutoFocus(false)
wspMsgInput:SetMaxLetters(255)
wspMsgInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
wspMsgInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
y5w = y5w - 35

local setWspBtn = CreateButton(t5w, "Set Whisper", 20, y5w, 120, 24, function()
    local target = wspTargetInput:GetText():trim()
    local msg = wspMsgInput:GetText():trim()
    if target == "" then print("|cFF69CCF0BuddyFlash:|r Enter a friend name!"); return end
    if msg == "" then print("|cFF69CCF0BuddyFlash:|r Enter a message!"); return end
    local db = ns.GetDB()
    db.autoWhisper[target] = msg
    print("|cFF69CCF0BuddyFlash:|r Whisper for |cFFFFFF00" .. target .. "|r set to: " .. msg)
    wspTargetInput:SetText(""); wspMsgInput:SetText("")
    wspTargetInput:ClearFocus(); wspMsgInput:ClearFocus()
    RefreshWhisperList()
end)

local removeWspBtn = CreateButton(t5w, "Remove Whisper", 155, y5w, 130, 24, function()
    local target = wspTargetInput:GetText():trim()
    if target == "" then print("|cFF69CCF0BuddyFlash:|r Enter a friend name!"); return end
    local db = ns.GetDB()
    if db.autoWhisper[target] then
        db.autoWhisper[target] = nil
        print("|cFF69CCF0BuddyFlash:|r Whisper removed for |cFFFFFF00" .. target .. "|r")
    end
    wspTargetInput:SetText(""); wspMsgInput:SetText("")
    wspTargetInput:ClearFocus(); wspMsgInput:ClearFocus()
    RefreshWhisperList()
end)
y5w = y5w - 40

-- Whisper assignments list
CreateSectionHeader(t5w, "Current Assignments", 10, y5w)
y5w = y5w - 25

local wspListFrame = CreateFrame("Frame", nil, t5w, "BackdropTemplate")
wspListFrame:SetPoint("TOPLEFT", t5w, "TOPLEFT", 10, y5w)
wspListFrame:SetSize(460, 360)
wspListFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
wspListFrame:SetBackdropColor(0, 0, 0, 0.4)
wspListFrame:SetBackdropBorderColor(0.2, 0.3, 0.5, 0.6)

local wspScroll = CreateFrame("ScrollFrame", "BuddyFlashWspScroll", wspListFrame, "UIPanelScrollFrameTemplate")
wspScroll:SetPoint("TOPLEFT", wspListFrame, "TOPLEFT", 6, -6)
wspScroll:SetPoint("BOTTOMRIGHT", wspListFrame, "BOTTOMRIGHT", -24, 6)

local wspScrollChild = CreateFrame("Frame", nil, wspScroll)
wspScrollChild:SetSize(430, 1)
wspScroll:SetScrollChild(wspScrollChild)

local wspRows = {}

local function CreateWspRow(index)
    local row = CreateFrame("Frame", nil, wspScrollChild)
    row:SetHeight(30)
    row:SetPoint("TOPLEFT", wspScrollChild, "TOPLEFT", 0, -(index - 1) * 30)
    row:SetPoint("RIGHT", wspScrollChild, "RIGHT", 0, 0)
    row:EnableMouse(true)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetColorTexture(index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.3 or 0)

    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", row, "LEFT", 5, 0)
    nameText:SetWidth(120)
    nameText:SetJustifyH("LEFT")
    row.nameText = nameText

    local msgText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msgText:SetPoint("LEFT", nameText, "RIGHT", 5, 0)
    msgText:SetWidth(230)
    msgText:SetJustifyH("LEFT")
    msgText:SetTextColor(0.7, 0.7, 0.7)
    row.msgText = msgText

    local editBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    editBtn:SetSize(50, 22)
    editBtn:SetPoint("RIGHT", row, "RIGHT", -60, 0)
    editBtn:SetText("Edit")
    editBtn:SetFrameLevel(row:GetFrameLevel() + 5)
    row.editBtn = editBtn

    local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    delBtn:SetSize(55, 22)
    delBtn:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    delBtn:SetText("Remove")
    delBtn:SetFrameLevel(row:GetFrameLevel() + 5)
    row.delBtn = delBtn

    wspRows[index] = row
    return row
end

function RefreshWhisperList()
    local db = ns.GetDB()
    local entries = {}
    for target, msg in pairs(db.autoWhisper) do
        table.insert(entries, { target = target, msg = msg })
    end
    table.sort(entries, function(a, b) return a.target < b.target end)

    for i, entry in ipairs(entries) do
        local row = wspRows[i] or CreateWspRow(i)
        row.nameText:SetText("|cFFFFFF00" .. entry.target .. "|r")
        row.msgText:SetText(entry.msg)
        row.editBtn:SetScript("OnClick", function()
            ShowEditPopup_Whisper(entry.target, entry.msg, function(newMsg)
                db.autoWhisper[entry.target] = newMsg
                RefreshWhisperList()
            end)
        end)
        row.delBtn:SetScript("OnClick", function()
            db.autoWhisper[entry.target] = nil
            RefreshWhisperList()
        end)
        row:Show()
    end

    for i = #entries + 1, #wspRows do
        if wspRows[i] then wspRows[i]:Hide() end
    end

    if #entries == 0 then
        local row = wspRows[1] or CreateWspRow(1)
        row.nameText:SetText("|cFF666666No auto-whispers|r")
        row.msgText:SetText("Set messages above or via Friends tab")
        row.editBtn:Hide(); row.delBtn:Hide()
        row:Show()
        wspScrollChild:SetHeight(30)
    else
        wspScrollChild:SetHeight(#entries * 30)
        for i = 1, #entries do wspRows[i].editBtn:Show(); wspRows[i].delBtn:Show() end
    end
end

y5w = y5w - 370
t5w:SetHeight(-y5w + 20)
tabPanels[5].refresh = RefreshWhisperList

-- ============================================================
-- TAB 6: HISTORY (login history + last seen)
-- ============================================================

local t5 = tabPanels[6].child
local y5 = -10

-- Login History
CreateSectionHeader(t5, "Login History", 10, y5)
y5 = y5 - 25

local histListFrame = CreateFrame("Frame", nil, t5, "BackdropTemplate")
histListFrame:SetPoint("TOPLEFT", t5, "TOPLEFT", 10, y5)
histListFrame:SetSize(460, 170)
histListFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
histListFrame:SetBackdropColor(0, 0, 0, 0.4)
histListFrame:SetBackdropBorderColor(0.2, 0.3, 0.5, 0.6)

local histScroll = CreateFrame("ScrollFrame", "BuddyFlashHistScroll", histListFrame, "UIPanelScrollFrameTemplate")
histScroll:SetPoint("TOPLEFT", histListFrame, "TOPLEFT", 6, -6)
histScroll:SetPoint("BOTTOMRIGHT", histListFrame, "BOTTOMRIGHT", -24, 6)

local histScrollChild = CreateFrame("Frame", nil, histScroll)
histScrollChild:SetSize(430, 1)
histScroll:SetScrollChild(histScrollChild)

local histRows = {}

local function CreateHistRow(index)
    local row = CreateFrame("Button", nil, histScrollChild)
    row:SetHeight(20)
    row:SetPoint("TOPLEFT", histScrollChild, "TOPLEFT", 0, -(index - 1) * 20)
    row:SetPoint("RIGHT", histScrollChild, "RIGHT", 0, 0)

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(row)
    hl:SetColorTexture(0.2, 0.4, 0.6, 0.3)

    local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", row, "LEFT", 5, 0)
    text:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    text:SetJustifyH("LEFT")
    row.text = text

    histRows[index] = row
    return row
end

local function RefreshHistoryList()
    local db = ns.GetDB()
    local maxShow = 30

    for i = 1, math.min(maxShow, #db.loginHistory) do
        local entry = db.loginHistory[i]
        local row = histRows[i] or CreateHistRow(i)
        local timeStr = date("%m/%d %H:%M", entry.time)
        local arrow = entry.isLogin and "|cFF00FF00+|r" or "|cFFFF3333-|r"
        local action = entry.isLogin and "logged in" or "went offline"
        row.text:SetText(string.format("%s |cFF888888[%s]|r %s %s", arrow, timeStr, entry.name, action))
        if entry.bnetTag or entry.charName then
            row:SetScript("OnClick", function()
                ns.ShowFriendConfig(entry.charName, entry.bnetTag, entry.name)
            end)
        else
            row:SetScript("OnClick", nil)
        end
        row:Show()
    end

    for i = math.min(maxShow, #db.loginHistory) + 1, #histRows do
        if histRows[i] then histRows[i]:Hide() end
    end

    if #db.loginHistory == 0 then
        local row = histRows[1] or CreateHistRow(1)
        row.text:SetText("|cFF666666No history yet.|r")
        row:SetScript("OnClick", nil)
        row:Show()
        histScrollChild:SetHeight(20)
    else
        histScrollChild:SetHeight(math.min(maxShow, #db.loginHistory) * 20)
    end
end

local clearHistBtn = CreateButton(t5, "Clear History", 360, y5 + 22, 110, 22, function()
    ns.GetDB().loginHistory = {}
    RefreshHistoryList()
end)

y5 = y5 - 180

-- Last Seen
CreateSectionHeader(t5, "Last Seen", 10, y5)
y5 = y5 - 25

local lsListFrame = CreateFrame("Frame", nil, t5, "BackdropTemplate")
lsListFrame:SetPoint("TOPLEFT", t5, "TOPLEFT", 10, y5)
lsListFrame:SetSize(460, 140)
lsListFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
lsListFrame:SetBackdropColor(0, 0, 0, 0.4)
lsListFrame:SetBackdropBorderColor(0.2, 0.3, 0.5, 0.6)

local lsScroll = CreateFrame("ScrollFrame", "BuddyFlashLSScroll", lsListFrame, "UIPanelScrollFrameTemplate")
lsScroll:SetPoint("TOPLEFT", lsListFrame, "TOPLEFT", 6, -6)
lsScroll:SetPoint("BOTTOMRIGHT", lsListFrame, "BOTTOMRIGHT", -24, 6)

local lsScrollChild = CreateFrame("Frame", nil, lsScroll)
lsScrollChild:SetSize(430, 1)
lsScroll:SetScrollChild(lsScrollChild)

local lsRows = {}

local function CreateLSRow(index)
    local row = CreateFrame("Button", nil, lsScrollChild)
    row:SetHeight(22)
    row:SetPoint("TOPLEFT", lsScrollChild, "TOPLEFT", 0, -(index - 1) * 22)
    row:SetPoint("RIGHT", lsScrollChild, "RIGHT", 0, 0)

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(row)
    hl:SetColorTexture(0.2, 0.4, 0.6, 0.3)

    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", row, "LEFT", 5, 0)
    nameText:SetWidth(180)
    nameText:SetJustifyH("LEFT")
    row.nameText = nameText

    local timeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeText:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    timeText:SetJustifyH("RIGHT")
    timeText:SetTextColor(0.6, 0.6, 0.6)
    row.timeText = timeText

    lsRows[index] = row
    return row
end

local function RefreshLastSeenList()
    local db = ns.GetDB()
    local entries = {}
    for key, data in pairs(db.lastSeen) do
        local ts = type(data) == "table" and data.time or data
        local name = type(data) == "table" and data.name or key
        local charName = type(data) == "table" and data.charName or nil
        local bnetTag = type(data) == "table" and data.bnetTag or nil
        table.insert(entries, { key = key, time = ts, name = name, charName = charName, bnetTag = bnetTag })
    end
    table.sort(entries, function(a, b) return a.time > b.time end)

    for i, entry in ipairs(entries) do
        local row = lsRows[i] or CreateLSRow(i)
        row.nameText:SetText("|cFFFFFF00" .. entry.name .. "|r")
        local elapsed = time() - entry.time
        local agoStr
        if elapsed < 60 then agoStr = elapsed .. "s ago"
        elseif elapsed < 3600 then agoStr = math.floor(elapsed / 60) .. "m ago"
        elseif elapsed < 86400 then agoStr = math.floor(elapsed / 3600) .. "h ago"
        else agoStr = math.floor(elapsed / 86400) .. "d ago" end
        row.timeText:SetText(agoStr .. "  (" .. date("%m/%d %H:%M", entry.time) .. ")")
        row:SetScript("OnClick", function()
            ns.ShowFriendConfig(entry.charName, entry.bnetTag, entry.name)
        end)
        row:Show()
    end

    for i = #entries + 1, #lsRows do
        if lsRows[i] then lsRows[i]:Hide() end
    end

    if #entries == 0 then
        local row = lsRows[1] or CreateLSRow(1)
        row.nameText:SetText("|cFF666666No last seen data yet|r")
        row.timeText:SetText("")
        row:SetScript("OnClick", nil)
        row:Show()
        lsScrollChild:SetHeight(22)
    else
        lsScrollChild:SetHeight(#entries * 22)
    end
end

local clearLSBtn = CreateButton(t5, "Clear Last Seen", 350, y5 + 22, 120, 22, function()
    ns.GetDB().lastSeen = {}
    RefreshLastSeenList()
end)

y5 = y5 - 150
t5:SetHeight(-y5 + 20)

tabPanels[6].refresh = function()
    RefreshHistoryList()
    RefreshLastSeenList()
end

-- ============================================================
-- INIT: Select first tab, refresh on show
-- ============================================================

optionsFrame:SetScript("OnShow", function()
    SelectTab(activeTab)
end)

SelectTab(1)

-- ============================================================
-- TOGGLE FUNCTION (exposed via namespace)
-- ============================================================

ns.ToggleOptions = function()
    if optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        optionsFrame:Show()
    end
end

-- ============================================================
-- WELCOME / UPDATE POPUP
-- ============================================================

local welcomeFrame = CreateFrame("Frame", "BuddyFlashWelcome", UIParent, "BackdropTemplate")
welcomeFrame:SetSize(460, 420)
welcomeFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
welcomeFrame:SetFrameStrata("FULLSCREEN_DIALOG")
welcomeFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
welcomeFrame:SetBackdropColor(0.05, 0.08, 0.15, 0.98)
welcomeFrame:SetBackdropBorderColor(0.4, 0.6, 1.0, 0.9)
welcomeFrame:SetMovable(true)
welcomeFrame:EnableMouse(true)
welcomeFrame:RegisterForDrag("LeftButton")
welcomeFrame:SetScript("OnDragStart", welcomeFrame.StartMoving)
welcomeFrame:SetScript("OnDragStop", welcomeFrame.StopMovingOrSizing)
welcomeFrame:SetClampedToScreen(true)
welcomeFrame:Hide()

tinsert(UISpecialFrames, "BuddyFlashWelcome")

local wTitleBg = welcomeFrame:CreateTexture(nil, "ARTWORK")
wTitleBg:SetHeight(28)
wTitleBg:SetPoint("TOPLEFT", welcomeFrame, "TOPLEFT", 4, -4)
wTitleBg:SetPoint("TOPRIGHT", welcomeFrame, "TOPRIGHT", -4, -4)
wTitleBg:SetColorTexture(0.1, 0.2, 0.4, 0.7)

local wTitle = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
wTitle:SetPoint("TOP", welcomeFrame, "TOP", 0, -9)

local wCloseBtn = CreateFrame("Button", nil, welcomeFrame, "UIPanelCloseButton")
wCloseBtn:SetPoint("TOPRIGHT", welcomeFrame, "TOPRIGHT", -2, -2)

local wBody = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
wBody:SetPoint("TOPLEFT", welcomeFrame, "TOPLEFT", 20, -42)
wBody:SetPoint("RIGHT", welcomeFrame, "RIGHT", -20, 0)
wBody:SetJustifyH("LEFT")
wBody:SetSpacing(3)

-- Support section - anchored BELOW body text
local wSupportHeader = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
wSupportHeader:SetPoint("TOPLEFT", wBody, "BOTTOMLEFT", 0, -16)
wSupportHeader:SetText("|cFF69CCF0Support Development|r")

local wSupportLine = welcomeFrame:CreateTexture(nil, "ARTWORK")
wSupportLine:SetHeight(1)
wSupportLine:SetPoint("TOPLEFT", wSupportHeader, "BOTTOMLEFT", 0, -4)
wSupportLine:SetPoint("RIGHT", welcomeFrame, "RIGHT", -20, 0)
wSupportLine:SetColorTexture(0.3, 0.5, 0.7, 0.5)

local wSupportText = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
wSupportText:SetPoint("TOPLEFT", wSupportLine, "BOTTOMLEFT", 0, -8)
wSupportText:SetPoint("RIGHT", welcomeFrame, "RIGHT", -20, 0)
wSupportText:SetJustifyH("LEFT")
wSupportText:SetTextColor(0.8, 0.8, 0.8)
wSupportText:SetText("If you enjoy BuddyFlash, consider supporting development!\nCopy a link below and paste it in your browser:")

-- Copyable URL boxes
local wCoffeeLabel = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
wCoffeeLabel:SetPoint("TOPLEFT", wSupportText, "BOTTOMLEFT", 0, -10)
wCoffeeLabel:SetTextColor(1, 0.82, 0)
wCoffeeLabel:SetText("Buy Me a Coffee:")

local wCoffeeBox = CreateFrame("EditBox", "BuddyFlashCoffeeURL", welcomeFrame, "InputBoxTemplate")
wCoffeeBox:SetPoint("LEFT", wCoffeeLabel, "RIGHT", 8, 0)
wCoffeeBox:SetSize(260, 20)
wCoffeeBox:SetAutoFocus(false)
wCoffeeBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
wCoffeeBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

local wPaypalLabel = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
wPaypalLabel:SetPoint("TOPLEFT", wCoffeeLabel, "BOTTOMLEFT", 0, -10)
wPaypalLabel:SetTextColor(0.4, 0.7, 1)
wPaypalLabel:SetText("PayPal:")

local wPaypalBox = CreateFrame("EditBox", "BuddyFlashPaypalURL", welcomeFrame, "InputBoxTemplate")
wPaypalBox:SetPoint("LEFT", wPaypalLabel, "RIGHT", 8, 0)
wPaypalBox:SetPoint("RIGHT", wCoffeeBox, "RIGHT", 0, 0)
wPaypalBox:SetHeight(20)
wPaypalBox:SetAutoFocus(false)
wPaypalBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
wPaypalBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

-- Buttons
local wSettingsBtn = CreateFrame("Button", nil, welcomeFrame, "UIPanelButtonTemplate")
wSettingsBtn:SetSize(130, 26)
wSettingsBtn:SetPoint("BOTTOMLEFT", welcomeFrame, "BOTTOMLEFT", 20, 15)
wSettingsBtn:SetText("Open Settings")
wSettingsBtn:SetScript("OnClick", function()
    welcomeFrame:Hide()
    if ns.ToggleOptions then ns.ToggleOptions() end
end)

local wDismissBtn = CreateFrame("Button", nil, welcomeFrame, "UIPanelButtonTemplate")
wDismissBtn:SetSize(100, 26)
wDismissBtn:SetPoint("BOTTOMRIGHT", welcomeFrame, "BOTTOMRIGHT", -20, 15)
wDismissBtn:SetText("Got it!")
wDismissBtn:SetScript("OnClick", function() welcomeFrame:Hide() end)

ns.ShowWelcomePopup = function(isFirstRun)
    if isFirstRun then
        wTitle:SetText("|cFF69CCF0BuddyFlash|r - Welcome!")
        wBody:SetText(
            "|cFFFFFFFFThank you for installing BuddyFlash!|r\n\n" ..
            "  |cFF00FF00*|r Screen flash & sound when friends log in\n" ..
            "  |cFF00FF00*|r Custom avatars & per-friend sounds\n" ..
            "  |cFF00FF00*|r Auto-whisper on friend login\n" ..
            "  |cFF00FF00*|r Login history & friend tracking\n\n" ..
            "Type |cFFFFFF00/bf options|r to open settings.\n" ..
            "Type |cFFFFFF00/bf|r for all commands.\n\n" ..
            "|cFF888888Custom sounds: place custom1.ogg - custom5.ogg|r\n" ..
            "|cFF888888in Interface/AddOns/BuddyFlash/Sounds/|r"
        )
    else
        wTitle:SetText("|cFF69CCF0BuddyFlash|r v" .. (ns.VERSION or "?") .. " - Updated!")
        wBody:SetText(
            "|cFFFFFFFFWhat's new:|r\n\n" ..
            "  |cFF00FF00*|r Friends tab: ALL Battle.net friends (online + offline)\n" ..
            "  |cFF00FF00*|r AFK/DND status indicators\n" ..
            "  |cFF00FF00*|r Sound names fixed (verified via Wowhead)\n" ..
            "  |cFF00FF00*|r Clickable history & alts entries\n" ..
            "  |cFF00FF00*|r Custom Voice 1-5 sound slots\n" ..
            "  |cFF00FF00*|r UI spacing & overflow fixes\n\n" ..
            "|cFF888888Custom sounds: place custom1.ogg - custom5.ogg|r\n" ..
            "|cFF888888in Interface/AddOns/BuddyFlash/Sounds/|r"
        )
    end
    wCoffeeBox:SetText(ns.SUPPORT_COFFEE or "")
    wPaypalBox:SetText(ns.SUPPORT_PAYPAL or "")
    welcomeFrame:Show()
end
