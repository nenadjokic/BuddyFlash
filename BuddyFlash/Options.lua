-- BuddyFlash Options GUI
-- ======================

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
    -- Always ensure "default" is present
    local hasDefault = false
    for _, name in ipairs(avatars) do
        if name == "default" then
            hasDefault = true
            break
        end
    end
    if not hasDefault then
        table.insert(avatars, 1, "default")
    end
    return avatars
end

-- ============================================================
-- MAIN OPTIONS FRAME
-- ============================================================

local optionsFrame = CreateFrame("Frame", "BuddyFlashOptionsFrame", UIParent, "BackdropTemplate")
optionsFrame:SetSize(520, 650)
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

-- Close on Escape
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

-- Close button
local closeBtn = CreateFrame("Button", nil, optionsFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -2, -2)

-- ============================================================
-- CONTENT SCROLL FRAME
-- ============================================================

local contentScroll = CreateFrame("ScrollFrame", "BuddyFlashOptionsScroll", optionsFrame, "UIPanelScrollFrameTemplate")
contentScroll:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 10, -40)
contentScroll:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -30, 10)

local content = CreateFrame("Frame", nil, contentScroll)
content:SetSize(460, 2400)
contentScroll:SetScrollChild(content)

-- ============================================================
-- SECTION 1: GENERAL SETTINGS
-- ============================================================

local yOffset = -10
CreateSectionHeader(content, "General Settings", 10, yOffset)
yOffset = yOffset - 30

local cbFlash = CreateCheckbox(content, "Enable Screen Flash", 20, yOffset,
    function() return ns.GetDB().flashEnabled end,
    function(v) ns.GetDB().flashEnabled = v end
)
yOffset = yOffset - 30

local cbSound = CreateCheckbox(content, "Enable Login Sound", 20, yOffset,
    function() return ns.GetDB().soundEnabled end,
    function(v) ns.GetDB().soundEnabled = v end
)
yOffset = yOffset - 30

local cbLock = CreateCheckbox(content, "Lock Window Position", 20, yOffset,
    function() return ns.GetDB().windowLocked end,
    function(v) ns.GetDB().windowLocked = v end
)
yOffset = yOffset - 30

local cbCharFriends = CreateCheckbox(content, "Show Character Friends", 20, yOffset,
    function() return ns.GetDB().showCharFriends end,
    function(v) ns.GetDB().showCharFriends = v; if ns.UpdateListUI then ns.UpdateListUI() end end
)
yOffset = yOffset - 30

local cbBNetFriends = CreateCheckbox(content, "Show Battle.net Friends", 20, yOffset,
    function() return ns.GetDB().showBNetFriends end,
    function(v) ns.GetDB().showBNetFriends = v; if ns.UpdateListUI then ns.UpdateListUI() end end
)
yOffset = yOffset - 40

-- ============================================================
-- SECTION 2: FLASH COLOR
-- ============================================================

CreateSectionHeader(content, "Flash Color", 10, yOffset)
yOffset = yOffset - 30

-- Color preview swatch
local colorPreview = content:CreateTexture(nil, "ARTWORK")
colorPreview:SetSize(40, 40)
colorPreview:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)

local function UpdateColorPreview()
    local db = ns.GetDB()
    colorPreview:SetColorTexture(db.flashColor.r, db.flashColor.g, db.flashColor.b, 1)
end

local sliderR = CreateSlider(content, "Red", 80, yOffset, 0, 1, 0.05,
    function() return ns.GetDB().flashColor.r end,
    function(v) ns.GetDB().flashColor.r = v; UpdateColorPreview() end
)
yOffset = yOffset - 45

local sliderG = CreateSlider(content, "Green", 80, yOffset, 0, 1, 0.05,
    function() return ns.GetDB().flashColor.g end,
    function(v) ns.GetDB().flashColor.g = v; UpdateColorPreview() end
)
yOffset = yOffset - 45

local sliderB = CreateSlider(content, "Blue", 80, yOffset, 0, 1, 0.05,
    function() return ns.GetDB().flashColor.b end,
    function(v) ns.GetDB().flashColor.b = v; UpdateColorPreview() end
)
yOffset = yOffset - 20

local testFlashBtn = CreateButton(content, "Test Flash", 20, yOffset, 100, 24, function()
    if ns.DoFlash then ns.DoFlash() end
    if ns.ShowBanner then ns.ShowBanner("TestPlayer", true, "TestPlayer") end
end)
yOffset = yOffset - 40

-- ============================================================
-- SECTION 2.5: BANNER SETTINGS (avatar size & position)
-- ============================================================

CreateSectionHeader(content, "Banner Notification", 10, yOffset)
yOffset = yOffset - 30

-- Avatar size slider
local sliderAvatarSize = CreateSlider(content, "Avatar Size", 80, yOffset, 24, 512, 4,
    function() return ns.GetDB().bannerAvatarSize end,
    function(v)
        ns.GetDB().bannerAvatarSize = v
        if ns.ApplyBannerLayout then ns.ApplyBannerLayout() end
    end
)
yOffset = yOffset - 50

-- Banner X position slider
local sliderBannerX = CreateSlider(content, "Position X", 80, yOffset, -600, 600, 10,
    function() return ns.GetDB().bannerPosX end,
    function(v)
        ns.GetDB().bannerPosX = v
        if ns.ApplyBannerLayout then ns.ApplyBannerLayout() end
    end
)
yOffset = yOffset - 50

-- Banner Y position slider
local sliderBannerY = CreateSlider(content, "Position Y", 80, yOffset, -600, 600, 10,
    function() return ns.GetDB().bannerPosY end,
    function(v)
        ns.GetDB().bannerPosY = v
        if ns.ApplyBannerLayout then ns.ApplyBannerLayout() end
    end
)
yOffset = yOffset - 30

-- Anchor dropdown
local anchorLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
anchorLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
anchorLabel:SetText("Screen Anchor:")

local ANCHOR_OPTIONS = { "TOP", "TOPLEFT", "TOPRIGHT", "CENTER", "BOTTOM", "BOTTOMLEFT", "BOTTOMRIGHT", "LEFT", "RIGHT" }

local anchorDropdown = CreateFrame("Frame", "BuddyFlashAnchorDropdown", content, "UIDropDownMenuTemplate")
anchorDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", 120, yOffset + 5)

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

yOffset = yOffset - 35

-- Test banner button
local testBannerBtn = CreateButton(content, "Test Banner", 20, yOffset, 120, 24, function()
    if ns.ShowBanner then ns.ShowBanner("TestPlayer", true, "TestPlayer") end
end)

-- Reset banner position button
local resetBannerBtn = CreateButton(content, "Reset Position", 155, yOffset, 120, 24, function()
    local db = ns.GetDB()
    db.bannerAvatarSize = 48
    db.bannerPosX = 0
    db.bannerPosY = -100
    db.bannerAnchor = "TOP"
    sliderAvatarSize:Refresh()
    sliderBannerX:Refresh()
    sliderBannerY:Refresh()
    UIDropDownMenu_SetText(anchorDropdown, "TOP")
    if ns.ApplyBannerLayout then ns.ApplyBannerLayout() end
    print("|cFF69CCF0BuddyFlash:|r Banner reset to defaults.")
end)

yOffset = yOffset - 40

-- ============================================================
-- SECTION 3: SOUND SETTINGS
-- ============================================================

CreateSectionHeader(content, "Login Sound", 10, yOffset)
yOffset = yOffset - 30

-- Sound dropdown
local soundLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
soundLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
soundLabel:SetText("Notification Sound:")
yOffset = yOffset - 5

local soundDropdown = CreateFrame("Frame", "BuddyFlashSoundDropdown", content, "UIDropDownMenuTemplate")
soundDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", 5, yOffset)

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

yOffset = yOffset - 35

local testSoundBtn = CreateButton(content, "Preview Sound", 20, yOffset, 120, 24, function()
    local db = ns.GetDB()
    local snd = ns.SOUND_OPTIONS[db.soundChoice] or ns.SOUND_OPTIONS[1]
    ns.PlayAlertSound(snd)
end)
yOffset = yOffset - 45

-- ============================================================
-- SECTION 4: AVATAR MANAGEMENT
-- ============================================================

CreateSectionHeader(content, "Avatar Management", 10, yOffset)
yOffset = yOffset - 10

local avatarInfoText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
avatarInfoText:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
avatarInfoText:SetTextColor(0.6, 0.6, 0.6)
avatarInfoText:SetText("Assign avatars by Character Name or BattleTag.\nBattleTag applies to all characters of that friend.")
avatarInfoText:SetJustifyH("LEFT")
yOffset = yOffset - 35

-- Character name input
local nameLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
nameLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
nameLabel:SetText("Character Name:")

local nameInput = CreateFrame("EditBox", "BuddyFlashNameInput", content, "InputBoxTemplate")
nameInput:SetPoint("TOPLEFT", content, "TOPLEFT", 130, yOffset)
nameInput:SetSize(150, 25)
nameInput:SetAutoFocus(false)
nameInput:SetMaxLetters(50)
nameInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
nameInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
yOffset = yOffset - 28

-- BattleTag input
local bnetLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
bnetLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
bnetLabel:SetText("BattleTag:")

local bnetInput = CreateFrame("EditBox", "BuddyFlashBNetInput", content, "InputBoxTemplate")
bnetInput:SetPoint("TOPLEFT", content, "TOPLEFT", 130, yOffset)
bnetInput:SetSize(150, 25)
bnetInput:SetAutoFocus(false)
bnetInput:SetMaxLetters(50)
bnetInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
bnetInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

-- Hint text
local orLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
orLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 290, yOffset)
orLabel:SetTextColor(0.5, 0.5, 0.5)
orLabel:SetText("(fill one or both)")

yOffset = yOffset - 30

-- Avatar dropdown
local avatarDropdownLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
avatarDropdownLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset + 5)
avatarDropdownLabel:SetText("Avatar:")

local avatarDropdown = CreateFrame("Frame", "BuddyFlashAvatarDropdown", content, "UIDropDownMenuTemplate")
avatarDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", 205, yOffset)

local selectedAvatar = "default"

local function AvatarDropdown_Initialize(self, level)
    local avatars = GetAvailableAvatars()
    for _, avatarName in ipairs(avatars) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = avatarName
        info.value = avatarName
        info.checked = (avatarName == selectedAvatar)
        info.func = function(self)
            selectedAvatar = self.value
            UIDropDownMenu_SetText(avatarDropdown, self.value)
            -- Update preview
            if avatarPreviewTexture then
                avatarPreviewTexture:SetTexture(ns.AVATAR_PATH .. self.value)
            end
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

UIDropDownMenu_SetWidth(avatarDropdown, 140)
UIDropDownMenu_Initialize(avatarDropdown, AvatarDropdown_Initialize)
UIDropDownMenu_SetText(avatarDropdown, selectedAvatar)

yOffset = yOffset - 35

-- Avatar preview
local previewLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
previewLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
previewLabel:SetText("Preview:")

avatarPreviewTexture = content:CreateTexture(nil, "ARTWORK")
avatarPreviewTexture:SetSize(48, 48)
avatarPreviewTexture:SetPoint("TOPLEFT", content, "TOPLEFT", 80, yOffset + 8)
avatarPreviewTexture:SetTexture(ns.DEFAULT_AVATAR)
avatarPreviewTexture:SetTexCoord(0, 1, 0, 1)

-- Helper: format character name (capitalize) but leave BattleTags as-is
local function FormatName(text)
    if text:find("#") then
        return text -- BattleTag, don't change case
    end
    return text:sub(1,1):upper() .. text:sub(2):lower()
end

-- Assign button
local assignBtn = CreateButton(content, "Assign Avatar", 150, yOffset - 5, 130, 28, function()
    local charName = nameInput:GetText():trim()
    local bnetTag = bnetInput:GetText():trim()
    local db = ns.GetDB()
    local assigned = false

    if charName ~= "" then
        charName = FormatName(charName)
        db.avatars[charName] = selectedAvatar
        print("|cFF69CCF0BuddyFlash:|r Avatar for |cFFFFFF00" .. charName .. "|r set to |cFF00FF00" .. selectedAvatar .. "|r")
        assigned = true
    end

    if bnetTag ~= "" then
        db.avatars[bnetTag] = selectedAvatar
        print("|cFF69CCF0BuddyFlash:|r Avatar for BattleTag |cFFFFFF00" .. bnetTag .. "|r set to |cFF00FF00" .. selectedAvatar .. "|r")
        assigned = true
    end

    if not assigned then
        print("|cFF69CCF0BuddyFlash:|r Enter a Character Name or BattleTag!")
        return
    end

    nameInput:SetText("")
    bnetInput:SetText("")
    nameInput:ClearFocus()
    bnetInput:ClearFocus()
    if ns.UpdateListUI then ns.UpdateListUI() end
    RefreshAssignmentList()
end)

-- Remove button
local removeBtn = CreateButton(content, "Remove Avatar", 290, yOffset - 5, 130, 28, function()
    local charName = nameInput:GetText():trim()
    local bnetTag = bnetInput:GetText():trim()
    local db = ns.GetDB()
    local removed = false

    if charName ~= "" then
        charName = FormatName(charName)
        if db.avatars[charName] then
            db.avatars[charName] = nil
            print("|cFF69CCF0BuddyFlash:|r Avatar removed for |cFFFFFF00" .. charName .. "|r")
            removed = true
        end
    end

    if bnetTag ~= "" then
        if db.avatars[bnetTag] then
            db.avatars[bnetTag] = nil
            print("|cFF69CCF0BuddyFlash:|r Avatar removed for BattleTag |cFFFFFF00" .. bnetTag .. "|r")
            removed = true
        end
    end

    if not removed then
        print("|cFF69CCF0BuddyFlash:|r No avatar found for that name/tag.")
        return
    end

    nameInput:SetText("")
    bnetInput:SetText("")
    nameInput:ClearFocus()
    bnetInput:ClearFocus()
    if ns.UpdateListUI then ns.UpdateListUI() end
    RefreshAssignmentList()
end)

yOffset = yOffset - 55

-- ============================================================
-- SECTION 5: CURRENT AVATAR ASSIGNMENTS LIST
-- ============================================================

CreateSectionHeader(content, "Current Avatar Assignments", 10, yOffset)
yOffset = yOffset - 25

-- Scrollable list of current assignments
local assignListFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
assignListFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 15, yOffset)
assignListFrame:SetSize(430, 200)
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
assignScrollChild:SetSize(400, 1)
assignScrollChild:EnableMouse(true)
assignScroll:SetScrollChild(assignScrollChild)

local assignmentRows = {}

local function CreateAssignmentRow(index)
    local row = CreateFrame("Frame", nil, assignScrollChild)
    row:SetHeight(36)
    row:SetPoint("TOPLEFT", assignScrollChild, "TOPLEFT", 0, -(index - 1) * 36)
    row:SetPoint("RIGHT", assignScrollChild, "RIGHT", 0, 0)
    row:EnableMouse(true)

    -- Row highlight
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    if index % 2 == 0 then
        bg:SetColorTexture(1, 1, 1, 0.03)
    else
        bg:SetColorTexture(0, 0, 0, 0)
    end

    -- Avatar preview
    local avatar = row:CreateTexture(nil, "ARTWORK")
    avatar:SetSize(28, 28)
    avatar:SetPoint("LEFT", row, "LEFT", 5, 0)
    avatar:SetTexCoord(0, 1, 0, 1)
    row.avatar = avatar

    -- Character name
    local charText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charText:SetPoint("LEFT", avatar, "RIGHT", 8, 4)
    charText:SetJustifyH("LEFT")
    row.charText = charText

    -- Avatar filename
    local fileText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fileText:SetPoint("LEFT", avatar, "RIGHT", 8, -8)
    fileText:SetJustifyH("LEFT")
    fileText:SetTextColor(0.5, 0.5, 0.5)
    row.fileText = fileText

    -- Edit button (fills input with this character's name)
    local editBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    editBtn:SetSize(50, 22)
    editBtn:SetPoint("RIGHT", row, "RIGHT", -60, 0)
    editBtn:SetText("Edit")
    editBtn:SetFrameLevel(row:GetFrameLevel() + 5)
    row.editBtn = editBtn

    -- Remove button
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

    -- Collect and sort assignments
    local assignments = {}
    for charName, fileName in pairs(db.avatars) do
        table.insert(assignments, { charName = charName, fileName = fileName })
    end
    table.sort(assignments, function(a, b) return a.charName < b.charName end)

    -- Create/update rows
    for i, entry in ipairs(assignments) do
        local row = assignmentRows[i] or CreateAssignmentRow(i)
        row.avatar:SetTexture(ns.AVATAR_PATH .. entry.fileName)
        local typeTag = entry.charName:find("#") and "|cFF69CCF0[BTag]|r " or ""
        row.charText:SetText(typeTag .. "|cFFFFFF00" .. entry.charName .. "|r")
        row.fileText:SetText(entry.fileName)

        row.editBtn:SetScript("OnClick", function()
            -- Detect if this is a BattleTag or character name
            if entry.charName:find("#") then
                bnetInput:SetText(entry.charName)
                nameInput:SetText("")
            else
                nameInput:SetText(entry.charName)
                bnetInput:SetText("")
            end
            selectedAvatar = entry.fileName
            UIDropDownMenu_SetText(avatarDropdown, entry.fileName)
            avatarPreviewTexture:SetTexture(ns.AVATAR_PATH .. entry.fileName)
            nameInput:SetFocus()
        end)

        row.delBtn:SetScript("OnClick", function()
            db.avatars[entry.charName] = nil
            print("|cFF69CCF0BuddyFlash:|r Avatar removed for |cFFFFFF00" .. entry.charName .. "|r")
            if ns.UpdateListUI then ns.UpdateListUI() end
            RefreshAssignmentList()
        end)

        row:Show()
    end

    -- Hide unused rows
    for i = #assignments + 1, #assignmentRows do
        if assignmentRows[i] then assignmentRows[i]:Hide() end
    end

    -- Empty state
    if #assignments == 0 then
        local row = assignmentRows[1] or CreateAssignmentRow(1)
        row.avatar:SetTexture(ns.DEFAULT_AVATAR)
        row.charText:SetText("|cFF666666No avatars assigned yet|r")
        row.fileText:SetText("Use the controls above to assign avatars")
        row.editBtn:Hide()
        row.delBtn:Hide()
        row:Show()
        assignScrollChild:SetHeight(36)
    else
        assignScrollChild:SetHeight(#assignments * 36)
        -- Re-show buttons that might have been hidden
        for i = 1, #assignments do
            assignmentRows[i].editBtn:Show()
            assignmentRows[i].delBtn:Show()
        end
    end
end

yOffset = yOffset - 210

-- ============================================================
-- SECTION 6: QUICK ADD FROM FRIENDS LIST
-- ============================================================

CreateSectionHeader(content, "Quick Add from Online Friends", 10, yOffset)
yOffset = yOffset - 10

local quickAddInfo = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
quickAddInfo:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
quickAddInfo:SetTextColor(0.6, 0.6, 0.6)
quickAddInfo:SetText("Click a friend below to fill their name in the input above.")
yOffset = yOffset - 20

local quickFriendListFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
quickFriendListFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 15, yOffset)
quickFriendListFrame:SetSize(430, 150)
quickFriendListFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
quickFriendListFrame:SetBackdropColor(0, 0, 0, 0.4)
quickFriendListFrame:SetBackdropBorderColor(0.2, 0.3, 0.5, 0.6)

local quickScroll = CreateFrame("ScrollFrame", "BuddyFlashQuickScroll", quickFriendListFrame, "UIPanelScrollFrameTemplate")
quickScroll:SetPoint("TOPLEFT", quickFriendListFrame, "TOPLEFT", 6, -6)
quickScroll:SetPoint("BOTTOMRIGHT", quickFriendListFrame, "BOTTOMRIGHT", -24, 6)

local quickScrollChild = CreateFrame("Frame", nil, quickScroll)
quickScrollChild:SetSize(400, 1)
quickScroll:SetScrollChild(quickScrollChild)

local quickRows = {}

local function CreateQuickRow(index)
    local row = CreateFrame("Button", nil, quickScrollChild)
    row:SetHeight(28)
    row:SetPoint("TOPLEFT", quickScrollChild, "TOPLEFT", 0, -(index - 1) * 28)
    row:SetPoint("RIGHT", quickScrollChild, "RIGHT", 0, 0)

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(row)
    hl:SetColorTexture(0.2, 0.4, 0.6, 0.3)

    local avatar = row:CreateTexture(nil, "ARTWORK")
    avatar:SetSize(22, 22)
    avatar:SetPoint("LEFT", row, "LEFT", 4, 0)
    avatar:SetTexCoord(0, 1, 0, 1)
    row.avatar = avatar

    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", avatar, "RIGHT", 6, 0)
    nameText:SetJustifyH("LEFT")
    row.nameText = nameText

    local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    statusText:SetJustifyH("RIGHT")
    row.statusText = statusText

    quickRows[index] = row
    return row
end

local function RefreshQuickFriendList()
    if not ns.CollectOnlineFriends then return end
    local onlineFriends = ns.CollectOnlineFriends()
    local db = ns.GetDB()

    for i, friend in ipairs(onlineFriends) do
        local row = quickRows[i] or CreateQuickRow(i)
        row.avatar:SetTexture(ns.GetAvatarTexture(friend.charName, friend.bnetTag))
        row.nameText:SetText(friend.charName or friend.name)

        -- Show current avatar assignment status
        local assignedAvatar = friend.charName and db.avatars[friend.charName]
        if assignedAvatar then
            row.statusText:SetText("|cFF00FF00" .. assignedAvatar .. "|r")
        else
            row.statusText:SetText("|cFF888888(no avatar)|r")
        end

        row:SetScript("OnClick", function()
            local cn = friend.charName or friend.name
            nameInput:SetText(cn)
            -- Auto-fill BattleTag if available
            if friend.bnetTag then
                bnetInput:SetText(friend.bnetTag)
            else
                bnetInput:SetText("")
            end
            nameInput:SetFocus()
            -- If they already have an avatar, select it in dropdown
            if assignedAvatar then
                selectedAvatar = assignedAvatar
                UIDropDownMenu_SetText(avatarDropdown, assignedAvatar)
                avatarPreviewTexture:SetTexture(ns.AVATAR_PATH .. assignedAvatar)
            end
        end)
        row:Show()
    end

    -- Hide extra rows
    for i = #onlineFriends + 1, #quickRows do
        if quickRows[i] then quickRows[i]:Hide() end
    end

    if #onlineFriends == 0 then
        local row = quickRows[1] or CreateQuickRow(1)
        row.avatar:SetTexture(ns.DEFAULT_AVATAR)
        row.nameText:SetText("|cFF666666No friends online|r")
        row.statusText:SetText("")
        row:SetScript("OnClick", nil)
        row:Show()
        quickScrollChild:SetHeight(28)
    else
        quickScrollChild:SetHeight(#onlineFriends * 28)
    end
end

yOffset = yOffset - 170  -- space after quick add list

-- ============================================================
-- SECTION 7: PER-FRIEND SOUND
-- ============================================================

CreateSectionHeader(content, "Per-Friend Login Sounds", 10, yOffset)
yOffset = yOffset - 10

local fsInfoText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
fsInfoText:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
fsInfoText:SetTextColor(0.6, 0.6, 0.6)
fsInfoText:SetText("Override the global login sound for specific friends.")
yOffset = yOffset - 20

-- Friend sound target input
local fsTargetLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fsTargetLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
fsTargetLabel:SetText("Friend:")

local fsTargetInput = CreateFrame("EditBox", "BuddyFlashFSTarget", content, "InputBoxTemplate")
fsTargetInput:SetPoint("TOPLEFT", content, "TOPLEFT", 80, yOffset)
fsTargetInput:SetSize(180, 25)
fsTargetInput:SetAutoFocus(false)
fsTargetInput:SetMaxLetters(50)
fsTargetInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
fsTargetInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
yOffset = yOffset - 28

-- Sound dropdown for per-friend
local fsSoundLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fsSoundLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
fsSoundLabel:SetText("Sound:")

local fsSoundDropdown = CreateFrame("Frame", "BuddyFlashFSSoundDropdown", content, "UIDropDownMenuTemplate")
fsSoundDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", 60, yOffset + 5)

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

yOffset = yOffset - 35

-- Set / Remove friend sound buttons
local setFSBtn = CreateButton(content, "Set Sound", 20, yOffset, 110, 24, function()
    local target = fsTargetInput:GetText():trim()
    if target == "" then
        print("|cFF69CCF0BuddyFlash:|r Enter a friend name!")
        return
    end
    local db = ns.GetDB()
    db.friendSounds[target] = selectedFriendSound
    local sndName = ns.SOUND_OPTIONS[selectedFriendSound] and ns.SOUND_OPTIONS[selectedFriendSound].name or "?"
    print("|cFF69CCF0BuddyFlash:|r Sound for |cFFFFFF00" .. target .. "|r set to: " .. sndName)
    fsTargetInput:SetText("")
    fsTargetInput:ClearFocus()
    RefreshFriendSoundList()
end)

local removeFSBtn = CreateButton(content, "Remove Sound", 145, yOffset, 120, 24, function()
    local target = fsTargetInput:GetText():trim()
    if target == "" then
        print("|cFF69CCF0BuddyFlash:|r Enter a friend name!")
        return
    end
    local db = ns.GetDB()
    if db.friendSounds[target] then
        db.friendSounds[target] = nil
        print("|cFF69CCF0BuddyFlash:|r Custom sound removed for |cFFFFFF00" .. target .. "|r")
    else
        print("|cFF69CCF0BuddyFlash:|r No custom sound for |cFFFFFF00" .. target .. "|r")
    end
    fsTargetInput:SetText("")
    fsTargetInput:ClearFocus()
    RefreshFriendSoundList()
end)

local previewFSBtn = CreateButton(content, "Preview", 280, yOffset, 80, 24, function()
    if ns.SOUND_OPTIONS[selectedFriendSound] then
        ns.PlayAlertSound(ns.SOUND_OPTIONS[selectedFriendSound])
    end
end)
yOffset = yOffset - 35

-- Friend sound assignments list
local fsListFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
fsListFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 15, yOffset)
fsListFrame:SetSize(430, 100)
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
fsScrollChild:SetSize(400, 1)
fsScroll:SetScrollChild(fsScrollChild)

local fsRows = {}

local function CreateFSRow(index)
    local row = CreateFrame("Frame", nil, fsScrollChild)
    row:SetHeight(26)
    row:SetPoint("TOPLEFT", fsScrollChild, "TOPLEFT", 0, -(index - 1) * 26)
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
    sndText:SetWidth(150)
    sndText:SetJustifyH("LEFT")
    sndText:SetTextColor(0.7, 0.7, 0.7)
    row.sndText = sndText

    local editBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    editBtn:SetSize(28, 20)
    editBtn:SetPoint("RIGHT", row, "RIGHT", -35, 0)
    editBtn:SetText("E")
    editBtn:SetFrameLevel(row:GetFrameLevel() + 5)
    row.editBtn = editBtn

    local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    delBtn:SetSize(28, 20)
    delBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    delBtn:SetText("X")
    delBtn:SetFrameLevel(row:GetFrameLevel() + 5)
    row.delBtn = delBtn

    fsRows[index] = row
    return row
end

function RefreshFriendSoundList()
    local db = ns.GetDB()
    local entries = {}
    for target, idx in pairs(db.friendSounds) do
        local sndName = ns.SOUND_OPTIONS[idx] and ns.SOUND_OPTIONS[idx].name or "Unknown #" .. idx
        table.insert(entries, { target = target, soundIdx = idx, soundName = sndName })
    end
    table.sort(entries, function(a, b) return a.target < b.target end)

    for i, entry in ipairs(entries) do
        local row = fsRows[i] or CreateFSRow(i)
        row.nameText:SetText("|cFFFFFF00" .. entry.target .. "|r")
        row.sndText:SetText(entry.soundName)
        row.editBtn:SetScript("OnClick", function()
            fsTargetInput:SetText(entry.target)
            selectedFriendSound = entry.soundIdx
            UIDropDownMenu_SetText(fsSoundDropdown, entry.soundName)
            fsTargetInput:SetFocus()
        end)
        row.delBtn:SetScript("OnClick", function()
            db.friendSounds[entry.target] = nil
            print("|cFF69CCF0BuddyFlash:|r Custom sound removed for |cFFFFFF00" .. entry.target .. "|r")
            RefreshFriendSoundList()
        end)
        row:Show()
    end

    for i = #entries + 1, #fsRows do
        if fsRows[i] then fsRows[i]:Hide() end
    end

    if #entries == 0 then
        local row = fsRows[1] or CreateFSRow(1)
        row.nameText:SetText("|cFF666666No per-friend sounds set|r")
        row.sndText:SetText("All friends use global sound")
        row.editBtn:Hide()
        row.delBtn:Hide()
        row:Show()
        fsScrollChild:SetHeight(26)
    else
        fsScrollChild:SetHeight(#entries * 26)
        for i = 1, #entries do
            fsRows[i].editBtn:Show()
            fsRows[i].delBtn:Show()
        end
    end
end

yOffset = yOffset - 110

-- ============================================================
-- SECTION 9: LOGIN HISTORY
-- ============================================================

CreateSectionHeader(content, "Login History", 10, yOffset)
yOffset = yOffset - 10

local histInfoText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
histInfoText:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
histInfoText:SetTextColor(0.6, 0.6, 0.6)
histInfoText:SetText("Recent login/logout activity of tracked friends.")
yOffset = yOffset - 20

local histListFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
histListFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 15, yOffset)
histListFrame:SetSize(430, 180)
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
histScrollChild:SetSize(400, 1)
histScroll:SetScrollChild(histScrollChild)

local histRows = {}

local function CreateHistRow(index)
    local row = CreateFrame("Frame", nil, histScrollChild)
    row:SetHeight(20)
    row:SetPoint("TOPLEFT", histScrollChild, "TOPLEFT", 0, -(index - 1) * 20)
    row:SetPoint("RIGHT", histScrollChild, "RIGHT", 0, 0)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetColorTexture(index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.3 or 0)

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
        row:Show()
    end

    for i = math.min(maxShow, #db.loginHistory) + 1, #histRows do
        if histRows[i] then histRows[i]:Hide() end
    end

    if #db.loginHistory == 0 then
        local row = histRows[1] or CreateHistRow(1)
        row.text:SetText("|cFF666666No history yet. Activity will appear here.|r")
        row:Show()
        histScrollChild:SetHeight(20)
    else
        histScrollChild:SetHeight(math.min(maxShow, #db.loginHistory) * 20)
    end
end

-- Clear history button
local clearHistBtn = CreateButton(content, "Clear History", 335, yOffset + 12, 110, 22, function()
    local db = ns.GetDB()
    db.loginHistory = {}
    print("|cFF69CCF0BuddyFlash:|r Login history cleared.")
    RefreshHistoryList()
end)

yOffset = yOffset - 190

-- ============================================================
-- SECTION 10: LAST SEEN
-- ============================================================

CreateSectionHeader(content, "Last Seen", 10, yOffset)
yOffset = yOffset - 10

local lsInfoText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
lsInfoText:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
lsInfoText:SetTextColor(0.6, 0.6, 0.6)
lsInfoText:SetText("When tracked friends were last seen going offline.")
yOffset = yOffset - 20

local lsListFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
lsListFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 15, yOffset)
lsListFrame:SetSize(430, 140)
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
lsScrollChild:SetSize(400, 1)
lsScroll:SetScrollChild(lsScrollChild)

local lsRows = {}

local function CreateLSRow(index)
    local row = CreateFrame("Frame", nil, lsScrollChild)
    row:SetHeight(22)
    row:SetPoint("TOPLEFT", lsScrollChild, "TOPLEFT", 0, -(index - 1) * 22)
    row:SetPoint("RIGHT", lsScrollChild, "RIGHT", 0, 0)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetColorTexture(index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.3 or 0)

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
    for key, ts in pairs(db.lastSeen) do
        table.insert(entries, { key = key, time = ts })
    end
    table.sort(entries, function(a, b) return a.time > b.time end)

    for i, entry in ipairs(entries) do
        local row = lsRows[i] or CreateLSRow(i)
        row.nameText:SetText("|cFFFFFF00" .. entry.key .. "|r")
        local elapsed = time() - entry.time
        local agoStr
        if elapsed < 60 then agoStr = elapsed .. "s ago"
        elseif elapsed < 3600 then agoStr = math.floor(elapsed / 60) .. "m ago"
        elseif elapsed < 86400 then agoStr = math.floor(elapsed / 3600) .. "h ago"
        else agoStr = math.floor(elapsed / 86400) .. "d ago" end
        row.timeText:SetText(agoStr .. "  (" .. date("%m/%d %H:%M", entry.time) .. ")")
        row:Show()
    end

    for i = #entries + 1, #lsRows do
        if lsRows[i] then lsRows[i]:Hide() end
    end

    if #entries == 0 then
        local row = lsRows[1] or CreateLSRow(1)
        row.nameText:SetText("|cFF666666No last seen data yet|r")
        row.timeText:SetText("")
        row:Show()
        lsScrollChild:SetHeight(22)
    else
        lsScrollChild:SetHeight(#entries * 22)
    end
end

-- Clear last seen button
local clearLSBtn = CreateButton(content, "Clear Last Seen", 325, yOffset + 12, 120, 22, function()
    local db = ns.GetDB()
    db.lastSeen = {}
    print("|cFF69CCF0BuddyFlash:|r Last seen data cleared.")
    RefreshLastSeenList()
end)

yOffset = yOffset - 150

-- ============================================================
-- SECTION 11: KNOWN ALTS
-- ============================================================

CreateSectionHeader(content, "Known Characters (Alts)", 10, yOffset)
yOffset = yOffset - 10

local altsInfoText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
altsInfoText:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
altsInfoText:SetTextColor(0.6, 0.6, 0.6)
altsInfoText:SetText("Characters seen per BattleTag. Discovered automatically over time.")
yOffset = yOffset - 20

local altsListFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
altsListFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 15, yOffset)
altsListFrame:SetSize(430, 150)
altsListFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
altsListFrame:SetBackdropColor(0, 0, 0, 0.4)
altsListFrame:SetBackdropBorderColor(0.2, 0.3, 0.5, 0.6)

local altsScroll = CreateFrame("ScrollFrame", "BuddyFlashAltsScroll", altsListFrame, "UIPanelScrollFrameTemplate")
altsScroll:SetPoint("TOPLEFT", altsListFrame, "TOPLEFT", 6, -6)
altsScroll:SetPoint("BOTTOMRIGHT", altsListFrame, "BOTTOMRIGHT", -24, 6)

local altsScrollChild = CreateFrame("Frame", nil, altsScroll)
altsScrollChild:SetSize(400, 1)
altsScroll:SetScrollChild(altsScrollChild)

local altsRows = {}

local function CreateAltsRow(index)
    local row = CreateFrame("Frame", nil, altsScrollChild)
    row:SetHeight(24)
    row:SetPoint("TOPLEFT", altsScrollChild, "TOPLEFT", 0, -(index - 1) * 24)
    row:SetPoint("RIGHT", altsScrollChild, "RIGHT", 0, 0)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetColorTexture(index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.05 or 0, index % 2 == 0 and 0.3 or 0)

    local tagText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tagText:SetPoint("LEFT", row, "LEFT", 5, 0)
    tagText:SetWidth(130)
    tagText:SetJustifyH("LEFT")
    row.tagText = tagText

    local charsText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    charsText:SetPoint("LEFT", tagText, "RIGHT", 5, 0)
    charsText:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    charsText:SetJustifyH("LEFT")
    charsText:SetTextColor(0.8, 0.8, 0.8)
    row.charsText = charsText

    altsRows[index] = row
    return row
end

local function RefreshAltsList()
    local db = ns.GetDB()
    local entries = {}
    for tag, alts in pairs(db.knownAlts) do
        table.insert(entries, { tag = tag, alts = alts })
    end
    table.sort(entries, function(a, b) return a.tag < b.tag end)

    local idx = 0
    for _, entry in ipairs(entries) do
        if #entry.alts > 0 then
            idx = idx + 1
            local row = altsRows[idx] or CreateAltsRow(idx)
            row.tagText:SetText("|cFFFFFF00" .. entry.tag .. "|r")
            row.charsText:SetText(table.concat(entry.alts, ", "))
            row:Show()
        end
    end

    for i = idx + 1, #altsRows do
        if altsRows[i] then altsRows[i]:Hide() end
    end

    if idx == 0 then
        local row = altsRows[1] or CreateAltsRow(1)
        row.tagText:SetText("|cFF666666No alt data yet|r")
        row.charsText:SetText("Play more to discover characters")
        row:Show()
        altsScrollChild:SetHeight(24)
    else
        altsScrollChild:SetHeight(idx * 24)
    end
end

-- Clear alts button
local clearAltsBtn = CreateButton(content, "Clear Alts Data", 325, yOffset + 12, 120, 22, function()
    local db = ns.GetDB()
    db.knownAlts = {}
    print("|cFF69CCF0BuddyFlash:|r Known alts data cleared.")
    RefreshAltsList()
end)

yOffset = yOffset - 165

-- ============================================================
-- REFRESH ALL ON SHOW
-- ============================================================

local function RefreshAll()
    local db = ns.GetDB()

    -- Refresh checkboxes
    cbFlash:Refresh()
    cbSound:Refresh()
    cbLock:Refresh()
    cbCharFriends:Refresh()
    cbBNetFriends:Refresh()

    -- Refresh sliders
    sliderR:Refresh()
    sliderG:Refresh()
    sliderB:Refresh()
    UpdateColorPreview()

    -- Refresh banner settings
    sliderAvatarSize:Refresh()
    sliderBannerX:Refresh()
    sliderBannerY:Refresh()
    UIDropDownMenu_SetText(anchorDropdown, db.bannerAnchor or "TOP")

    -- Refresh sound dropdown
    local currentSound = ns.SOUND_OPTIONS[db.soundChoice] or ns.SOUND_OPTIONS[1]
    UIDropDownMenu_SetText(soundDropdown, currentSound.name)

    -- Refresh avatar dropdown
    UIDropDownMenu_Initialize(avatarDropdown, AvatarDropdown_Initialize)
    UIDropDownMenu_SetText(avatarDropdown, selectedAvatar)
    avatarPreviewTexture:SetTexture(ns.AVATAR_PATH .. selectedAvatar)

    -- Refresh assignment list
    RefreshAssignmentList()

    -- Refresh quick friend list
    RefreshQuickFriendList()

    -- Refresh new sections
    RefreshFriendSoundList()
    RefreshHistoryList()
    RefreshLastSeenList()
    RefreshAltsList()
end

optionsFrame:SetScript("OnShow", RefreshAll)

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
