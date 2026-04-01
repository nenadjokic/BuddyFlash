-- BuddyFlash: Flash on friend login + persistent online friends list
-- =================================================================

local addonName, ns = ...

local BUDDYFLASH_VERSION = "1.0.6"
ns.VERSION = BUDDYFLASH_VERSION
ns.SUPPORT_PAYPAL = "paypal.me/nenadjokicRS"
ns.SUPPORT_COFFEE = "buymeacoffee.com/nenadjokic"

-- Saved settings (persisted between sessions)
BuddyFlashDB = BuddyFlashDB or {}

-- Available login sounds (verified via wowhead.com/sounds)
local SOUND_OPTIONS = {
    { id = 3332,  name = "Friend Login (Default)" },    -- FriendJoinGame
    { id = 11466, name = "You Are Not Prepared!" },      -- Illidan voice line
    { id = 888,   name = "Level Up" },                   -- LEVELUP (the classic "ding!")
    { id = 8960,  name = "Ready Check" },                -- ReadyCheck
    { id = 8959,  name = "Raid Warning" },               -- RaidWarning
    { id = 619,   name = "Quest Complete" },              -- QUESTCOMPLETED
    { id = 416,   name = "Murloc Aggro" },               -- MurlocAggro (mrrglglgl!)
    { id = 8174,  name = "PvP Flag Taken" },             -- PVPFlagTakenAlliance
    { id = 8454,  name = "PvP Victory" },                -- PVPVictoryHorde
    { id = 8458,  name = "PvP Queue Pop" },              -- PVPEnterQueue
    { id = 4574,  name = "PvP Warning" },                -- igPVPUpdate (PVPWARNING)
    { id = 6199,  name = "Peon: Work Complete" },        -- PeonBuildingComplete1
}

-- Custom sounds: place .ogg files in BuddyFlash/Sounds/
-- Files must be named custom1.ogg through custom5.ogg
local CUSTOM_SOUND_PATH = "Interface\\AddOns\\BuddyFlash\\Sounds\\"
for i = 1, 5 do
    table.insert(SOUND_OPTIONS, { file = CUSTOM_SOUND_PATH .. "custom" .. i .. ".ogg", name = "Custom Voice " .. i })
end

-- Avatar system paths
-- Users place .tga or .blp files in: BuddyFlash/Avatars/
-- Reference them by filename without extension (e.g., "myimage" for myimage.tga)
local AVATAR_PATH = "Interface\\AddOns\\BuddyFlash\\Avatars\\"
local DEFAULT_AVATAR = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
local CUSTOM_DEFAULT_AVATAR = AVATAR_PATH .. "default"

local defaults = {
    flashEnabled = true,
    soundEnabled = true,
    soundChoice = 1, -- index into SOUND_OPTIONS
    windowLocked = false,
    windowPoint = { "TOPRIGHT", nil, "TOPRIGHT", -20, -200 },
    windowWidth = 180,
    windowHeight = 220,
    flashColor = { r = 0.2, g = 0.6, b = 1.0 },
    showCharFriends = true,
    showBNetFriends = true,
    avatars = {}, -- { ["CharName"] or ["BattleTag#1234"] = "filename_without_ext" }
    bannerAvatarSize = 48, -- avatar size in banner (24-512)
    bannerPosX = 0,        -- banner X offset from anchor
    bannerPosY = -100,     -- banner Y offset from anchor
    bannerAnchor = "TOP",  -- anchor point on screen
    -- Last Seen: { ["bnet_123"] = timestamp, ["char_Name"] = timestamp }
    lastSeen = {},
    -- Login History: { { key="bnet_123", name="Tag (Char)", time=timestamp, isLogin=true }, ... }
    loginHistory = {},
    loginHistoryMax = 100, -- max entries to keep
    -- Auto-whisper: disabled by default (opt-in to comply with CurseForge rules)
    autoWhisperEnabled = false,
    autoWhisper = {}, -- { ["BattleTag#1234"] = "message", ["CharName"] = "message" }
    -- Per-friend sound: { ["BattleTag#1234"] = soundIndex, ["CharName"] = soundIndex }
    friendSounds = {},
    -- Known alts per BNet account: { ["BattleTag#1234"] = { "Char1", "Char2", ... } }
    knownAlts = {},
}

local function GetDB()
    for k, v in pairs(defaults) do
        if BuddyFlashDB[k] == nil then
            BuddyFlashDB[k] = v
        end
    end
    return BuddyFlashDB
end

-- Lookup helper: matches "MightyPotato" against both "MightyPotato" and "MightyPotato#12345" keys
local function LookupByTag(tbl, tag)
    if not tbl or not tag then return nil end
    if tbl[tag] then return tbl[tag] end
    -- API returns name without #, user may have saved with # — scan for prefix match
    for key, val in pairs(tbl) do
        local base = key:match("^(.+)#%d+$")
        if base and base == tag then return val end
    end
    return nil
end
ns.LookupByTag = LookupByTag

local function GetAvatarTexture(charName, bnetTag)
    local db = GetDB()
    if db.avatars then
        local found = LookupByTag(db.avatars, bnetTag)
        if found then return AVATAR_PATH .. found end
        if charName and db.avatars[charName] then
            return AVATAR_PATH .. db.avatars[charName]
        end
    end
    return CUSTOM_DEFAULT_AVATAR
end

-- Play a sound entry (handles both built-in IDs and custom .ogg files)
local function PlayAlertSound(soundEntry)
    if not soundEntry then return end
    if soundEntry.file then
        PlaySoundFile(soundEntry.file, "Master")
    elseif soundEntry.id then
        PlaySound(soundEntry.id)
    end
end
ns.PlayAlertSound = PlayAlertSound

-- Expose shared data to other files via namespace
ns.GetDB = GetDB
ns.GetAvatarTexture = GetAvatarTexture
ns.SOUND_OPTIONS = SOUND_OPTIONS
ns.AVATAR_PATH = AVATAR_PATH
ns.DEFAULT_AVATAR = DEFAULT_AVATAR

-- Track who was online last check (to detect new logins)
local previousOnline = {}

-- ============================================================
-- FLASH EFFECT
-- ============================================================

local flashFrame = CreateFrame("Frame", "BuddyFlashFlash", UIParent)
flashFrame:SetAllPoints(UIParent)
flashFrame:SetFrameStrata("FULLSCREEN_DIALOG")
flashFrame:Hide()

local flashTexture = flashFrame:CreateTexture(nil, "BACKGROUND")
flashTexture:SetAllPoints(flashFrame)
flashTexture:SetColorTexture(0.2, 0.6, 1.0, 0)

local flashGroup = flashTexture:CreateAnimationGroup()

local fadeIn = flashGroup:CreateAnimation("Alpha")
fadeIn:SetFromAlpha(0)
fadeIn:SetToAlpha(0.4)
fadeIn:SetDuration(0.15)
fadeIn:SetOrder(1)

local fadeOut = flashGroup:CreateAnimation("Alpha")
fadeOut:SetFromAlpha(0.4)
fadeOut:SetToAlpha(0)
fadeOut:SetDuration(0.5)
fadeOut:SetOrder(2)

flashGroup:SetScript("OnFinished", function()
    flashFrame:Hide()
    flashTexture:SetAlpha(0)
end)

local function DoFlash()
    if not GetDB().flashEnabled then return end
    local db = GetDB()
    flashTexture:SetColorTexture(db.flashColor.r, db.flashColor.g, db.flashColor.b, 1)
    flashTexture:SetAlpha(1)
    flashFrame:Show()
    flashGroup:Stop()
    flashGroup:Play()
end

-- ============================================================
-- NOTIFICATION BANNER (shows friend name on login)
-- ============================================================

local bannerFrame = CreateFrame("Frame", "BuddyFlashBanner", UIParent, "BackdropTemplate")
bannerFrame:SetSize(320, 70)
bannerFrame:SetPoint("TOP", UIParent, "TOP", 0, -100)
bannerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
bannerFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
bannerFrame:SetBackdropColor(0, 0, 0, 0.85)
bannerFrame:SetBackdropBorderColor(0.2, 0.6, 1.0, 0.9)
bannerFrame:Hide()

-- Avatar portrait in banner
local bannerAvatar = bannerFrame:CreateTexture(nil, "ARTWORK")
bannerAvatar:SetSize(48, 48)
bannerAvatar:SetPoint("LEFT", bannerFrame, "LEFT", 10, 0)
bannerAvatar:SetTexture(DEFAULT_AVATAR)
bannerAvatar:SetTexCoord(0, 1, 0, 1)

-- Online/offline status dot on the avatar
local bannerStatusIcon = bannerFrame:CreateTexture(nil, "OVERLAY")
bannerStatusIcon:SetSize(16, 16)
bannerStatusIcon:SetPoint("BOTTOMRIGHT", bannerAvatar, "BOTTOMRIGHT", 4, -4)

local bannerText = bannerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
bannerText:SetPoint("LEFT", bannerAvatar, "RIGHT", 10, 0)
bannerText:SetPoint("RIGHT", bannerFrame, "RIGHT", -10, 0)
bannerText:SetJustifyH("LEFT")

local bannerFadeGroup = bannerFrame:CreateAnimationGroup()

local bannerFadeIn = bannerFadeGroup:CreateAnimation("Alpha")
bannerFadeIn:SetFromAlpha(0)
bannerFadeIn:SetToAlpha(1)
bannerFadeIn:SetDuration(0.3)
bannerFadeIn:SetOrder(1)

local bannerHold = bannerFadeGroup:CreateAnimation("Alpha")
bannerHold:SetFromAlpha(1)
bannerHold:SetToAlpha(1)
bannerHold:SetDuration(3)
bannerHold:SetOrder(2)

local bannerFadeOut = bannerFadeGroup:CreateAnimation("Alpha")
bannerFadeOut:SetFromAlpha(1)
bannerFadeOut:SetToAlpha(0)
bannerFadeOut:SetDuration(0.5)
bannerFadeOut:SetOrder(3)

bannerFadeGroup:SetScript("OnPlay", function()
    bannerFrame:Show()
end)

bannerFadeGroup:SetScript("OnFinished", function()
    bannerFrame:Hide()
    bannerFrame:SetAlpha(0)
end)

local function ApplyBannerLayout()
    local db = GetDB()
    local size = db.bannerAvatarSize

    -- Resize avatar + status dot
    bannerAvatar:SetSize(size, size)
    local dotSize = math.max(10, size * 0.3)
    bannerStatusIcon:SetSize(dotSize, dotSize)

    -- Resize banner frame to fit avatar
    local frameHeight = math.max(70, size + 22)
    local frameWidth = math.max(320, size + 230)
    bannerFrame:SetSize(frameWidth, frameHeight)

    -- Reposition banner
    bannerFrame:ClearAllPoints()
    bannerFrame:SetPoint(db.bannerAnchor, UIParent, db.bannerAnchor, db.bannerPosX, db.bannerPosY)
end

local function ShowBanner(name, isLogin, charName, bnetTag)
    -- Apply size & position settings
    ApplyBannerLayout()

    -- Reset alpha for re-play
    bannerFrame:SetAlpha(1)

    -- Set avatar (checks BattleTag first, then character name)
    local avatarTex = GetAvatarTexture(charName, bnetTag)
    bannerAvatar:SetTexture(avatarTex)

    if isLogin then
        bannerText:SetText("|cFF33FF33+|r " .. name .. " je online!")
        bannerFrame:SetBackdropBorderColor(0.2, 0.6, 1.0, 0.9)
        bannerStatusIcon:SetTexture("Interface\\COMMON\\Indicator-Green")
    else
        bannerText:SetText("|cFFFF3333-|r " .. name .. " je offline.")
        bannerFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.9)
        bannerStatusIcon:SetTexture("Interface\\COMMON\\Indicator-Red")
    end
    bannerFadeGroup:Stop()
    bannerFadeGroup:Play()
end

-- ============================================================
-- PERSISTENT FRIENDS WINDOW
-- ============================================================

local listFrame = CreateFrame("Frame", "BuddyFlashList", UIParent, "BackdropTemplate")
listFrame:SetSize(180, 220)
listFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -200)
listFrame:SetFrameStrata("MEDIUM")
listFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
listFrame:SetBackdropColor(0, 0, 0, 0.75)
listFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
listFrame:SetClampedToScreen(true)
listFrame:EnableMouse(true)
listFrame:SetMovable(true)
listFrame:Hide()
listFrame:RegisterForDrag("LeftButton")

listFrame:SetScript("OnDragStart", function(self)
    if not GetDB().windowLocked then
        self:StartMoving()
    end
end)

listFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local db = GetDB()
    local point, _, relPoint, x, y = self:GetPoint()
    db.windowPoint = { point, nil, relPoint, x, y }
end)

-- Title bar
local titleBar = CreateFrame("Frame", nil, listFrame)
titleBar:SetHeight(22)
titleBar:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 4, -4)
titleBar:SetPoint("TOPRIGHT", listFrame, "TOPRIGHT", -4, -4)

local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("LEFT", titleBar, "LEFT", 4, 0)
titleText:SetText("|cFF69CCF0Friends Online|r")

-- Count badge
local countText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
countText:SetPoint("RIGHT", titleBar, "RIGHT", -22, 0)
countText:SetTextColor(0.6, 0.8, 1.0)

-- Minimize button
local minimizeBtn = CreateFrame("Button", nil, titleBar)
minimizeBtn:SetSize(16, 16)
minimizeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -2, 0)
minimizeBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
minimizeBtn:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
minimizeBtn:SetHighlightTexture("Interface\\Buttons\\UI-MinusButton-Highlight", "ADD")

local isMinimized = false

-- Scroll frame for the friend list
local scrollFrame = CreateFrame("ScrollFrame", "BuddyFlashScrollFrame", listFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 2, -4)
scrollFrame:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", -24, 6)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(1, 1)
scrollFrame:SetScrollChild(scrollChild)

-- Pool of row frames for friend entries
local rowPool = {}

-- ============================================================
-- RIGHT-CLICK CONTEXT MENU
-- ============================================================

local contextMenu = CreateFrame("Frame", "BuddyFlashContextMenu", UIParent, "UIDropDownMenuTemplate")

local function ShowContextMenu(row, friendData)
    local menuList = {
        {
            text = friendData.name,
            isTitle = true,
            notCheckable = true,
        },
        {
            text = " ",
            isTitle = true,
            notCheckable = true,
            disabled = true,
        },
    }

    -- Invite to party
    if friendData.charName then
        table.insert(menuList, {
            text = "Invite to Party",
            notCheckable = true,
            func = function()
                if friendData.isBNet and friendData.bnetAccountID then
                    BNInviteFriend(friendData.bnetAccountID)
                else
                    C_PartyInfo.InviteUnit(friendData.charName)
                end
                print("|cFF69CCF0BuddyFlash:|r Party invite sent to " .. friendData.charName)
            end,
        })
    end

    -- Inspect (only works if the player is nearby)
    if friendData.charName then
        table.insert(menuList, {
            text = "Inspect",
            notCheckable = true,
            func = function()
                InspectUnit(friendData.charName)
            end,
        })
    end

    -- Whisper
    if friendData.isBNet and friendData.bnetAccountID then
        table.insert(menuList, {
            text = "Whisper (BNet)",
            notCheckable = true,
            func = function()
                ChatFrame_SendBNetTell(friendData.name:match("^(.-)%s*%(") or friendData.name)
            end,
        })
    elseif friendData.charName then
        table.insert(menuList, {
            text = "Whisper",
            notCheckable = true,
            func = function()
                ChatFrame_SendTell(friendData.charName)
            end,
        })
    end

    -- Target (only works if nearby)
    if friendData.charName then
        table.insert(menuList, {
            text = "Target",
            notCheckable = true,
            func = function()
                TargetUnit(friendData.charName)
            end,
        })
    end

    -- Avatar info
    if friendData.charName then
        local db = GetDB()
        local currentAvatar = db.avatars and db.avatars[friendData.charName]
        if currentAvatar then
            table.insert(menuList, {
                text = "Avatar: " .. currentAvatar,
                isTitle = true,
                notCheckable = true,
            })
            table.insert(menuList, {
                text = "Remove Avatar",
                notCheckable = true,
                func = function()
                    db.avatars[friendData.charName] = nil
                    print("|cFF69CCF0BuddyFlash:|r Avatar removed for " .. friendData.charName)
                    if initialized then UpdateListUI() end
                end,
            })
        else
            table.insert(menuList, {
                text = "Set Avatar: /bf avatar " .. friendData.charName .. " <file>",
                isTitle = true,
                notCheckable = true,
            })
        end
    end

    -- Configure... (opens GUI popup)
    table.insert(menuList, {
        text = "|cFF69CCF0Configure...|r",
        notCheckable = true,
        func = function()
            if ns.ShowFriendConfig then
                ns.ShowFriendConfig(friendData.charName, friendData.bnetTag, friendData.name)
            end
        end,
    })

    -- Separator
    table.insert(menuList, {
        text = " ",
        isTitle = true,
        notCheckable = true,
        disabled = true,
    })

    -- Cancel
    table.insert(menuList, {
        text = "Cancel",
        notCheckable = true,
        func = function() CloseDropDownMenus() end,
    })

    EasyMenu(menuList, contextMenu, "cursor", 0, 0, "MENU")
end

-- ============================================================
-- ROW CREATION
-- ============================================================

local ROW_HEIGHT = 22

local function GetRow(index)
    if rowPool[index] then return rowPool[index] end

    local row = CreateFrame("Button", nil, scrollChild)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
    row:RegisterForClicks("RightButtonUp")
    row:EnableMouse(true)

    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(row)
    highlight:SetColorTexture(1, 1, 1, 0.1)

    -- Mini avatar in the list
    local avatar = row:CreateTexture(nil, "ARTWORK")
    avatar:SetSize(18, 18)
    avatar:SetPoint("LEFT", row, "LEFT", 2, 0)
    avatar:SetTexture(DEFAULT_AVATAR)
    avatar:SetTexCoord(0, 1, 0, 1)
    row.avatar = avatar

    local statusDot = row:CreateTexture(nil, "OVERLAY")
    statusDot:SetSize(8, 8)
    statusDot:SetPoint("BOTTOMRIGHT", avatar, "BOTTOMRIGHT", 2, -2)
    statusDot:SetTexture("Interface\\COMMON\\Indicator-Green")
    row.statusDot = statusDot

    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", avatar, "RIGHT", 4, 0)
    nameText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    nameText:SetJustifyH("LEFT")
    row.nameText = nameText

    local classIcon = row:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(14, 14)
    classIcon:SetPoint("LEFT", avatar, "RIGHT", 2, 0)
    row.classIcon = classIcon

    -- Right-click handler (set dynamically via row.friendData)
    row:SetScript("OnClick", function(self, button)
        if button == "RightButton" and self.friendData then
            ShowContextMenu(self, self.friendData)
        end
    end)

    -- Tooltip on hover
    row:SetScript("OnEnter", function(self)
        if self.friendData then
            local fd = self.friendData
            local db = GetDB()
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine(fd.name, 0.4, 0.8, 1.0)

            -- Last seen (show for currently online friends too - their previous offline time)
            if fd.key and db.lastSeen[fd.key] then
                local lsData = db.lastSeen[fd.key]
                local lsTime = type(lsData) == "table" and lsData.time or lsData
                local elapsed = time() - lsTime
                local timeStr
                if elapsed < 60 then timeStr = elapsed .. "s ago"
                elseif elapsed < 3600 then timeStr = math.floor(elapsed / 60) .. "m ago"
                elseif elapsed < 86400 then timeStr = math.floor(elapsed / 3600) .. "h ago"
                else timeStr = math.floor(elapsed / 86400) .. "d ago" end
                GameTooltip:AddLine("Last offline: " .. timeStr, 0.6, 0.6, 0.6)
            end

            -- Auto-whisper status
            if db.autoWhisperEnabled then
                local whisperMsg = LookupByTag(db.autoWhisper, fd.bnetTag)
                if not whisperMsg and fd.charName then
                    whisperMsg = db.autoWhisper[fd.charName]
                end
                if whisperMsg then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Auto-whisper: \"" .. whisperMsg .. "\"", 0.4, 1.0, 0.4)
                end
            end

            -- Per-friend sound
            local friendSoundIdx = nil
            if fd.bnetTag and db.friendSounds[fd.bnetTag] then
                friendSoundIdx = db.friendSounds[fd.bnetTag]
            elseif fd.charName and db.friendSounds[fd.charName] then
                friendSoundIdx = db.friendSounds[fd.charName]
            end
            if friendSoundIdx and SOUND_OPTIONS[friendSoundIdx] then
                GameTooltip:AddLine("Sound: " .. SOUND_OPTIONS[friendSoundIdx].name, 0.6, 0.8, 1.0)
            end

            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Right-click for options", 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    rowPool[index] = row
    return row
end

-- Minimize toggle
minimizeBtn:SetScript("OnClick", function()
    isMinimized = not isMinimized
    if isMinimized then
        scrollFrame:Hide()
        listFrame:SetHeight(30)
        minimizeBtn:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
        minimizeBtn:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
        minimizeBtn:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Highlight", "ADD")
    else
        scrollFrame:Show()
        local db = GetDB()
        listFrame:SetHeight(db.windowHeight)
        minimizeBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
        minimizeBtn:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
        minimizeBtn:SetHighlightTexture("Interface\\Buttons\\UI-MinusButton-Highlight", "ADD")
    end
end)

-- Resize handle
local resizeHandle = CreateFrame("Button", nil, listFrame)
resizeHandle:SetSize(16, 16)
resizeHandle:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", 0, 0)
resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

listFrame:SetResizable(true)
listFrame:SetResizeBounds(140, 80, 300, 500)

resizeHandle:SetScript("OnMouseDown", function()
    if not GetDB().windowLocked then
        listFrame:StartSizing("BOTTOMRIGHT")
    end
end)

resizeHandle:SetScript("OnMouseUp", function()
    listFrame:StopMovingOrSizing()
    local db = GetDB()
    db.windowWidth = listFrame:GetWidth()
    db.windowHeight = listFrame:GetHeight()
end)

-- ============================================================
-- FRIEND DATA COLLECTION
-- ============================================================

local CLASS_COLORS = {
    WARRIOR     = "C79C6E",
    PALADIN     = "F58CBA",
    HUNTER      = "ABD473",
    ROGUE       = "FFF569",
    PRIEST      = "FFFFFF",
    DEATHKNIGHT = "C41F3B",
    SHAMAN      = "0070DE",
    MAGE        = "69CCF0",
    WARLOCK     = "9482C9",
    MONK        = "00FF96",
    DRUID       = "FF7D0A",
    DEMONHUNTER = "A330C9",
    EVOKER      = "33937F",
}

local function GetClassColor(classFile)
    return CLASS_COLORS[classFile] or "AAAAAA"
end

local function CollectOnlineFriends()
    local online = {}

    -- Battle.net friends
    local db = GetDB()
    if db.showBNetFriends then
        local numBNet = BNGetNumFriends()
        for i = 1, numBNet do
            local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
            if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
                local gameInfo = accountInfo.gameAccountInfo
                -- Use battleTag (stable "Name#1234") instead of accountName (unstable KString)
                local bnetTag = accountInfo.battleTag or accountInfo.accountName or "?"
                local displayTag = bnetTag:match("^(.+)#%d+$") or bnetTag
                local charName = gameInfo.characterName
                local classFile = gameInfo.className and gameInfo.classFile
                local level = gameInfo.characterLevel
                local clientProgram = gameInfo.clientProgram

                -- Only show WoW players with character info
                if clientProgram == "WoW" and charName then
                    local colorHex = GetClassColor(classFile)
                    table.insert(online, {
                        sortName = displayTag,
                        display = string.format("|cFF%s%s|r |cFF888888(%s)|r", colorHex, charName, displayTag),
                        key = "bnet_" .. (accountInfo.bnetAccountID or i),
                        name = displayTag .. " (" .. charName .. ")",
                        charName = charName,
                        bnetTag = bnetTag,
                        bnetAccountID = accountInfo.bnetAccountID,
                        bnetIndex = i,
                        isBNet = true,
                    })
                elseif clientProgram == "WoW" then
                    table.insert(online, {
                        sortName = displayTag,
                        display = "|cFFAAAAFF" .. displayTag .. "|r",
                        key = "bnet_" .. (accountInfo.bnetAccountID or i),
                        name = displayTag,
                        charName = nil,
                        bnetTag = bnetTag,
                        bnetAccountID = accountInfo.bnetAccountID,
                        bnetIndex = i,
                        isBNet = true,
                    })
                end
            end
        end
    end

    -- Character friends
    if db.showCharFriends then
        local numFriends = C_FriendList.GetNumFriends()
        for i = 1, numFriends do
            local info = C_FriendList.GetFriendInfoByIndex(i)
            if info and info.connected then
                local colorHex = GetClassColor(info.className and info.className:upper():gsub(" ", ""))
                local name = info.name or "?"
                local level = info.level or ""
                table.insert(online, {
                    sortName = name,
                    display = string.format("|cFF%s%s|r |cFF888888(Lv%s)|r", colorHex, name, level),
                    key = "char_" .. name,
                    name = name,
                    charName = name,
                    isBNet = false,
                })
            end
        end
    end

    table.sort(online, function(a, b) return a.sortName < b.sortName end)
    return online
end

-- ============================================================
-- UPDATE THE LIST UI
-- ============================================================

local function UpdateListUI()
    local onlineFriends = CollectOnlineFriends()

    -- Update count badge
    countText:SetText("|cFFFFFFFF" .. #onlineFriends .. "|r")

    -- Detect new logins
    local currentKeys = {}
    local db = GetDB()
    for _, friend in ipairs(onlineFriends) do
        currentKeys[friend.key] = { name = friend.name, charName = friend.charName, bnetTag = friend.bnetTag }

        if not previousOnline[friend.key] then
            -- New login detected - only notify if friend is in our avatar list
            local isTracked = false
            if db.avatars then
                if friend.charName and db.avatars[friend.charName] then
                    isTracked = true
                elseif LookupByTag(db.avatars, friend.bnetTag) then
                    isTracked = true
                end
            end

            if isTracked then
                DoFlash()
                ShowBanner(friend.name, true, friend.charName, friend.bnetTag)

                -- Per-friend sound or global sound
                if db.soundEnabled then
                    local friendSoundIdx = LookupByTag(db.friendSounds, friend.bnetTag)
                    if not friendSoundIdx and friend.charName then
                        friendSoundIdx = db.friendSounds[friend.charName]
                    end
                    local soundEntry
                    if friendSoundIdx then
                        soundEntry = SOUND_OPTIONS[friendSoundIdx] or SOUND_OPTIONS[1]
                    else
                        soundEntry = SOUND_OPTIONS[db.soundChoice] or SOUND_OPTIONS[1]
                    end
                    PlayAlertSound(soundEntry)
                end

                -- Login history
                table.insert(db.loginHistory, 1, {
                    key = friend.key,
                    name = friend.name,
                    charName = friend.charName,
                    bnetTag = friend.bnetTag,
                    time = time(),
                    isLogin = true,
                })
                if #db.loginHistory > db.loginHistoryMax then
                    table.remove(db.loginHistory)
                end

                -- Auto-whisper (only if globally enabled)
                if db.autoWhisperEnabled then
                    local whisperMsg = LookupByTag(db.autoWhisper, friend.bnetTag)
                    if not whisperMsg and friend.charName then
                        whisperMsg = db.autoWhisper[friend.charName]
                    end
                    if whisperMsg and friend.isBNet and friend.bnetAccountID then
                        C_Timer.After(2, function()
                            BNSendWhisper(friend.bnetAccountID, whisperMsg)
                            print("|cFF69CCF0BuddyFlash:|r Auto-whisper sent to |cFFFFFF00" .. friend.name .. "|r: " .. whisperMsg)
                        end)
                    elseif whisperMsg and friend.charName then
                        C_Timer.After(2, function()
                            SendChatMessage(whisperMsg, "WHISPER", nil, friend.charName)
                            print("|cFF69CCF0BuddyFlash:|r Auto-whisper sent to |cFFFFFF00" .. friend.charName .. "|r: " .. whisperMsg)
                        end)
                    end
                end
            end
        end
    end

    -- Detect logouts - only notify for tracked friends
    for key, data in pairs(previousOnline) do
        if not currentKeys[key] then
            local logoutName = type(data) == "table" and data.name or data
            local logoutChar = type(data) == "table" and data.charName or nil
            local logoutBnet = type(data) == "table" and data.bnetTag or nil

            local isTracked = false
            if db.avatars then
                if logoutChar and db.avatars[logoutChar] then isTracked = true end
                if not isTracked and LookupByTag(db.avatars, logoutBnet) then isTracked = true end
            end

            if isTracked then
                ShowBanner(logoutName, false, logoutChar, logoutBnet)

                -- Save last seen data
                db.lastSeen[key] = { time = time(), name = logoutName, charName = logoutChar, bnetTag = logoutBnet }

                -- Logout history
                table.insert(db.loginHistory, 1, {
                    key = key,
                    name = logoutName,
                    charName = logoutChar,
                    bnetTag = logoutBnet,
                    time = time(),
                    isLogin = false,
                })
                if #db.loginHistory > db.loginHistoryMax then
                    table.remove(db.loginHistory)
                end
            end
        end
    end

    previousOnline = currentKeys

    -- Update scroll child width
    scrollChild:SetWidth(scrollFrame:GetWidth())

    -- Show/hide rows
    for i, friend in ipairs(onlineFriends) do
        local row = GetRow(i)
        row.nameText:SetText(friend.display)
        row.statusDot:SetTexture("Interface\\COMMON\\Indicator-Green")
        row.avatar:SetTexture(GetAvatarTexture(friend.charName, friend.bnetTag))
        row.friendData = friend
        row:Show()
    end

    -- Hide extra rows
    for i = #onlineFriends + 1, #rowPool do
        if rowPool[i] then
            rowPool[i].friendData = nil
            rowPool[i]:Hide()
        end
    end

    -- Update scroll child height
    scrollChild:SetHeight(math.max(1, #onlineFriends * ROW_HEIGHT))

    -- Show empty message if no friends online
    if #onlineFriends == 0 then
        local row = GetRow(1)
        row.nameText:SetText("|cFF666666Niko nije online|r")
        row.statusDot:SetTexture("Interface\\COMMON\\Indicator-Gray")
        row.avatar:SetTexture(DEFAULT_AVATAR)
        row:Show()
        scrollChild:SetHeight(ROW_HEIGHT)
    end
end

-- Collect ALL Battle.net friends (online + offline) for Settings Friends tab
local function CollectAllBNetFriends()
    local all = {}
    local numBNet = BNGetNumFriends()
    for i = 1, numBNet do
        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo then
            local bnetTag = accountInfo.battleTag or accountInfo.accountName or "?"
            local isOnline = false
            local charName = nil
            local classFile = nil
            local isAFK = accountInfo.isAFK or false
            local isDND = accountInfo.isDND or false
            local isInWoW = false

            if accountInfo.gameAccountInfo then
                local gameInfo = accountInfo.gameAccountInfo
                isOnline = gameInfo.isOnline or false
                if gameInfo.isGameAFK then isAFK = true end
                if gameInfo.isGameBusy then isDND = true end
                if isOnline and gameInfo.clientProgram == "WoW" then
                    charName = gameInfo.characterName
                    classFile = gameInfo.classFile
                    isInWoW = true
                end
            end

            table.insert(all, {
                bnetTag = bnetTag,
                charName = charName,
                classFile = classFile,
                isOnline = isOnline,
                isAFK = isAFK,
                isDND = isDND,
                isInWoW = isInWoW,
                bnetAccountID = accountInfo.bnetAccountID,
                bnetIndex = i,
            })
        end
    end
    table.sort(all, function(a, b)
        if a.isOnline ~= b.isOnline then return a.isOnline end
        return a.bnetTag < b.bnetTag
    end)
    return all
end

-- Expose more functions to namespace
ns.UpdateListUI = UpdateListUI
ns.DoFlash = DoFlash
ns.ShowBanner = ShowBanner
ns.ApplyBannerLayout = ApplyBannerLayout
ns.CollectOnlineFriends = CollectOnlineFriends
ns.CollectAllBNetFriends = CollectAllBNetFriends

-- ============================================================
-- EVENT HANDLING
-- ============================================================

local eventFrame = CreateFrame("Frame")
local initialized = false
local updateTimer = nil

-- Debounce updates (events can fire in rapid succession)
local function ScheduleUpdate()
    if updateTimer then return end
    updateTimer = C_Timer.After(0.5, function()
        updateTimer = nil
        UpdateListUI()
    end)
end

eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("BN_FRIEND_INFO_CHANGED")
eventFrame:RegisterEvent("FRIENDLIST_UPDATE")
eventFrame:RegisterEvent("BN_CONNECTED")
eventFrame:RegisterEvent("BN_DISCONNECTED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        local db = GetDB()

        -- Restore window position
        local p = db.windowPoint
        if p then
            listFrame:ClearAllPoints()
            listFrame:SetPoint(p[1], UIParent, p[3], p[4], p[5])
        end
        listFrame:SetSize(db.windowWidth, db.windowHeight)

        -- Welcome / update popup
        local isFirstRun = not db.lastSeenVersion
        local isUpdate = db.lastSeenVersion and db.lastSeenVersion ~= BUDDYFLASH_VERSION
        if isFirstRun or isUpdate then
            db.lastSeenVersion = BUDDYFLASH_VERSION
            C_Timer.After(5, function()
                if ns.ShowWelcomePopup then
                    ns.ShowWelcomePopup(isFirstRun)
                end
            end)
        end

        -- Chat message on login
        print("|cFF69CCF0BuddyFlash v" .. BUDDYFLASH_VERSION .. "|r loaded! Type |cFFFFFF00/bf|r for commands.")
        print("  |cFF888888Support development: /bf support|r")

        -- Request friend list data
        C_FriendList.ShowFriends()
        if BNConnected() then
            -- Build initial state (don't flash for people already online at login)
            C_Timer.After(3, function()
                -- Migrate KString keys to stable battleTag keys
                local function MigrateKStringKeys()
                    -- Build mapping: KString accountName -> battleTag
                    local ksMap = {}
                    local numBNet = BNGetNumFriends()
                    for fi = 1, numBNet do
                        local acctInfo = C_BattleNet.GetFriendAccountInfo(fi)
                        if acctInfo and acctInfo.accountName and acctInfo.battleTag then
                            local accName = acctInfo.accountName
                            if accName:find("|K") then
                                ksMap[accName] = acctInfo.battleTag
                            end
                        end
                    end
                    -- Re-key tables that had KString keys
                    local function migrateTable(tbl)
                        if not tbl then return end
                        local toMigrate = {}
                        for key, val in pairs(tbl) do
                            if key:find("|K") and ksMap[key] then
                                toMigrate[key] = ksMap[key]
                            end
                        end
                        for oldKey, newKey in pairs(toMigrate) do
                            if not tbl[newKey] then
                                tbl[newKey] = tbl[oldKey]
                            end
                            tbl[oldKey] = nil
                        end
                    end
                    migrateTable(db.avatars)
                    migrateTable(db.friendSounds)
                    migrateTable(db.autoWhisper)
                    migrateTable(db.knownAlts)
                    -- Also clean up lastSeen and loginHistory bnetTag fields
                    for key, data in pairs(db.lastSeen) do
                        if type(data) == "table" and data.bnetTag and data.bnetTag:find("|K") and ksMap[data.bnetTag] then
                            local newTag = ksMap[data.bnetTag]
                            local displayTag = newTag:match("^(.+)#%d+$") or newTag
                            data.bnetTag = newTag
                            if data.charName then
                                data.name = displayTag .. " (" .. data.charName .. ")"
                            else
                                data.name = displayTag
                            end
                        end
                    end
                    for _, entry in ipairs(db.loginHistory) do
                        if entry.bnetTag and entry.bnetTag:find("|K") and ksMap[entry.bnetTag] then
                            local newTag = ksMap[entry.bnetTag]
                            local displayTag = newTag:match("^(.+)#%d+$") or newTag
                            entry.bnetTag = newTag
                            if entry.charName then
                                entry.name = displayTag .. " (" .. entry.charName .. ")"
                            else
                                entry.name = displayTag
                            end
                        end
                    end
                end
                MigrateKStringKeys()

                local onlineFriends = CollectOnlineFriends()
                for _, friend in ipairs(onlineFriends) do
                    previousOnline[friend.key] = { name = friend.name, charName = friend.charName, bnetTag = friend.bnetTag }
                end
                initialized = true
                UpdateListUI()
            end)
        end
    elseif event == "BN_FRIEND_INFO_CHANGED" or event == "FRIENDLIST_UPDATE" then
        if initialized then
            ScheduleUpdate()
        end
    elseif event == "BN_CONNECTED" then
        C_Timer.After(2, function()
            local onlineFriends = CollectOnlineFriends()
            for _, friend in ipairs(onlineFriends) do
                previousOnline[friend.key] = { name = friend.name, charName = friend.charName, bnetTag = friend.bnetTag }
            end
            initialized = true
            UpdateListUI()
        end)
    end
end)

-- Periodic refresh every 30 seconds (catch edge cases)
C_Timer.NewTicker(30, function()
    if initialized then
        UpdateListUI()
    end
end)

-- ============================================================
-- SLASH COMMANDS
-- ============================================================

SLASH_BUDDYFLASH1 = "/bf"
SLASH_BUDDYFLASH2 = "/buddyflash"

SlashCmdList["BUDDYFLASH"] = function(msg)
    local cmd = msg:lower():trim()

    if cmd == "options" or cmd == "config" or cmd == "settings" then
        if ns.ToggleOptions then
            ns.ToggleOptions()
        else
            print("|cFF69CCF0BuddyFlash:|r Options panel not loaded.")
        end

    elseif cmd == "toggle" then
        if listFrame:IsShown() then
            listFrame:Hide()
        else
            listFrame:Show()
        end
        print("|cFF69CCF0BuddyFlash:|r Window " .. (listFrame:IsShown() and "shown" or "hidden"))

    elseif cmd == "flash" then
        local db = GetDB()
        db.flashEnabled = not db.flashEnabled
        print("|cFF69CCF0BuddyFlash:|r Flash " .. (db.flashEnabled and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))

    elseif cmd == "sound" then
        local db = GetDB()
        db.soundEnabled = not db.soundEnabled
        print("|cFF69CCF0BuddyFlash:|r Sound " .. (db.soundEnabled and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))

    elseif cmd:match("^sound%s+%d+$") then
        local num = tonumber(cmd:match("^sound%s+(%d+)$"))
        if num and num >= 1 and num <= #SOUND_OPTIONS then
            local db = GetDB()
            db.soundChoice = num
            local chosen = SOUND_OPTIONS[num]
            PlayAlertSound(chosen)
            print("|cFF69CCF0BuddyFlash:|r Sound set to: |cFFFFFF00" .. chosen.name .. "|r")
        else
            print("|cFF69CCF0BuddyFlash:|r Invalid sound number. Use 1-" .. #SOUND_OPTIONS)
        end

    elseif cmd == "sounds" then
        print("|cFF69CCF0BuddyFlash - Available sounds:|r")
        local db = GetDB()
        for i, s in ipairs(SOUND_OPTIONS) do
            local marker = (i == db.soundChoice) and " |cFF00FF00<< current|r" or ""
            print(string.format("  |cFFFFFF00%d|r - %s%s", i, s.name, marker))
        end
        print("Use |cFFFFFF00/bf sound <number>|r to change.")

    elseif cmd == "soundtest" then
        local db = GetDB()
        local chosen = SOUND_OPTIONS[db.soundChoice] or SOUND_OPTIONS[1]
        PlayAlertSound(chosen)
        print("|cFF69CCF0BuddyFlash:|r Playing: " .. chosen.name)

    elseif cmd == "lock" then
        local db = GetDB()
        db.windowLocked = not db.windowLocked
        print("|cFF69CCF0BuddyFlash:|r Window " .. (db.windowLocked and "|cFFFF0000locked|r" or "|cFF00FF00unlocked|r"))

    elseif cmd:match("^avatar%s+%S+%s+%S+$") then
        local charName, fileName = cmd:match("^avatar%s+(%S+)%s+(%S+)$")
        -- Capitalize first letter of charName for consistency
        charName = charName:sub(1,1):upper() .. charName:sub(2):lower()
        local db = GetDB()
        db.avatars[charName] = fileName
        print("|cFF69CCF0BuddyFlash:|r Avatar for |cFFFFFF00" .. charName .. "|r set to: |cFF00FF00" .. fileName .. "|r")
        print("  File should be at: |cFF888888Interface/AddOns/BuddyFlash/Avatars/" .. fileName .. ".tga|r")
        if initialized then UpdateListUI() end

    elseif cmd:match("^avatar%s+%S+$") then
        local charName = cmd:match("^avatar%s+(%S+)$")
        charName = charName:sub(1,1):upper() .. charName:sub(2):lower()
        local db = GetDB()
        if db.avatars[charName] then
            print("|cFF69CCF0BuddyFlash:|r Avatar for |cFFFFFF00" .. charName .. "|r: " .. db.avatars[charName])
        else
            print("|cFF69CCF0BuddyFlash:|r No custom avatar for |cFFFFFF00" .. charName .. "|r (using default)")
        end

    elseif cmd:match("^avatar%-remove%s+%S+$") then
        local charName = cmd:match("^avatar%-remove%s+(%S+)$")
        charName = charName:sub(1,1):upper() .. charName:sub(2):lower()
        local db = GetDB()
        if db.avatars[charName] then
            db.avatars[charName] = nil
            print("|cFF69CCF0BuddyFlash:|r Avatar removed for |cFFFFFF00" .. charName .. "|r (back to default)")
            if initialized then UpdateListUI() end
        else
            print("|cFF69CCF0BuddyFlash:|r No custom avatar found for |cFFFFFF00" .. charName .. "|r")
        end

    -- /bf history [count]
    elseif cmd == "history" or cmd:match("^history%s+%d+$") then
        local count = tonumber(cmd:match("^history%s+(%d+)$")) or 20
        local db = GetDB()
        if #db.loginHistory == 0 then
            print("|cFF69CCF0BuddyFlash:|r No login history yet.")
        else
            print("|cFF69CCF0BuddyFlash - Login History:|r")
            for i = 1, math.min(count, #db.loginHistory) do
                local entry = db.loginHistory[i]
                local timeStr = date("%m/%d %H:%M", entry.time)
                local arrow = entry.isLogin and "|cFF00FF00+|r" or "|cFFFF3333-|r"
                local action = entry.isLogin and "logged in" or "went offline"
                print(string.format("  %s |cFF888888[%s]|r %s %s", arrow, timeStr, entry.name, action))
            end
        end

    -- /bf lastseen <name>
    elseif cmd:match("^lastseen%s+.+$") then
        local searchName = cmd:match("^lastseen%s+(.+)$"):trim()
        local db = GetDB()
        local found = false
        for key, ts in pairs(db.lastSeen) do
            if key:lower():find(searchName:lower()) then
                local elapsed = time() - ts
                local timeStr
                if elapsed < 3600 then timeStr = math.floor(elapsed / 60) .. " min ago"
                elseif elapsed < 86400 then timeStr = math.floor(elapsed / 3600) .. " hours ago"
                else timeStr = math.floor(elapsed / 86400) .. " days ago" end
                print("|cFF69CCF0BuddyFlash:|r |cFFFFFF00" .. key .. "|r last seen: " .. timeStr .. " (" .. date("%m/%d %H:%M", ts) .. ")")
                found = true
            end
        end
        if not found then
            print("|cFF69CCF0BuddyFlash:|r No last seen data for '" .. searchName .. "'")
        end

    -- /bf lastseen (no args - show all)
    elseif cmd == "lastseen" then
        local db = GetDB()
        local entries = {}
        for key, ts in pairs(db.lastSeen) do
            table.insert(entries, { key = key, time = ts })
        end
        if #entries == 0 then
            print("|cFF69CCF0BuddyFlash:|r No last seen data yet.")
        else
            table.sort(entries, function(a, b) return a.time > b.time end)
            print("|cFF69CCF0BuddyFlash - Last Seen:|r")
            for _, e in ipairs(entries) do
                local elapsed = time() - e.time
                local timeStr
                if elapsed < 3600 then timeStr = math.floor(elapsed / 60) .. "m ago"
                elseif elapsed < 86400 then timeStr = math.floor(elapsed / 3600) .. "h ago"
                else timeStr = math.floor(elapsed / 86400) .. "d ago" end
                print(string.format("  |cFFFFFF00%s|r - %s |cFF888888(%s)|r", e.key, timeStr, date("%m/%d %H:%M", e.time)))
            end
        end

    -- /bf whisper <name> <message>
    elseif cmd:match("^whisper%s+%S+%s+.+$") then
        local target, message = cmd:match("^whisper%s+(%S+)%s+(.+)$")
        local db = GetDB()
        db.autoWhisper[target] = message
        print("|cFF69CCF0BuddyFlash:|r Auto-whisper set for |cFFFFFF00" .. target .. "|r: \"" .. message .. "\"")

    -- /bf whisper-remove <name>
    elseif cmd:match("^whisper%-remove%s+%S+$") then
        local target = cmd:match("^whisper%-remove%s+(%S+)$")
        local db = GetDB()
        if db.autoWhisper[target] then
            db.autoWhisper[target] = nil
            print("|cFF69CCF0BuddyFlash:|r Auto-whisper removed for |cFFFFFF00" .. target .. "|r")
        else
            print("|cFF69CCF0BuddyFlash:|r No auto-whisper set for |cFFFFFF00" .. target .. "|r")
        end

    -- /bf whispers (list all)
    elseif cmd == "whispers" then
        local db = GetDB()
        local count = 0
        print("|cFF69CCF0BuddyFlash - Auto-whispers:|r")
        for target, message in pairs(db.autoWhisper) do
            print(string.format("  |cFFFFFF00%s|r -> \"%s\"", target, message))
            count = count + 1
        end
        if count == 0 then
            print("  |cFF888888No auto-whispers configured.|r")
        end

    -- /bf friendsound <name> <number>
    elseif cmd:match("^friendsound%s+%S+%s+%d+$") then
        local target, num = cmd:match("^friendsound%s+(%S+)%s+(%d+)$")
        num = tonumber(num)
        if num and num >= 1 and num <= #SOUND_OPTIONS then
            local db = GetDB()
            db.friendSounds[target] = num
            local chosen = SOUND_OPTIONS[num]
            PlayAlertSound(chosen)
            print("|cFF69CCF0BuddyFlash:|r Sound for |cFFFFFF00" .. target .. "|r set to: |cFFFFFF00" .. chosen.name .. "|r")
        else
            print("|cFF69CCF0BuddyFlash:|r Invalid sound number. Use 1-" .. #SOUND_OPTIONS)
        end

    -- /bf friendsound-remove <name>
    elseif cmd:match("^friendsound%-remove%s+%S+$") then
        local target = cmd:match("^friendsound%-remove%s+(%S+)$")
        local db = GetDB()
        if db.friendSounds[target] then
            db.friendSounds[target] = nil
            print("|cFF69CCF0BuddyFlash:|r Custom sound removed for |cFFFFFF00" .. target .. "|r (using global)")
        else
            print("|cFF69CCF0BuddyFlash:|r No custom sound set for |cFFFFFF00" .. target .. "|r")
        end

    -- /bf friendsounds (list all)
    elseif cmd == "friendsounds" then
        local db = GetDB()
        local count = 0
        print("|cFF69CCF0BuddyFlash - Per-friend sounds:|r")
        for target, idx in pairs(db.friendSounds) do
            local sndName = SOUND_OPTIONS[idx] and SOUND_OPTIONS[idx].name or "Unknown"
            print(string.format("  |cFFFFFF00%s|r -> %s (#%d)", target, sndName, idx))
            count = count + 1
        end
        if count == 0 then
            print("  |cFF888888No per-friend sounds configured.|r")
        end

    elseif cmd == "avatars" then
        local db = GetDB()
        local count = 0
        print("|cFF69CCF0BuddyFlash - Custom Avatars:|r")
        for charName, fileName in pairs(db.avatars) do
            print(string.format("  |cFFFFFF00%s|r -> %s", charName, fileName))
            count = count + 1
        end
        if count == 0 then
            print("  |cFF888888No custom avatars set.|r")
        end
        print(" ")
        print("Place |cFF00FF00.tga|r or |cFF00FF00.blp|r files in:")
        print("  |cFF888888Interface/AddOns/BuddyFlash/Avatars/|r")
        print("Then assign: |cFFFFFF00/bf avatar CharName filename|r")
        print("  (filename without extension)")

    elseif cmd == "test" then
        DoFlash()
        ShowBanner("TestPlayer", true, "TestPlayer")
        print("|cFF69CCF0BuddyFlash:|r Test flash triggered!")

    elseif cmd == "reset" then
        listFrame:ClearAllPoints()
        listFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -200)
        listFrame:SetSize(180, 220)
        local db = GetDB()
        db.windowPoint = { "TOPRIGHT", nil, "TOPRIGHT", -20, -200 }
        db.windowWidth = 180
        db.windowHeight = 220
        print("|cFF69CCF0BuddyFlash:|r Window position reset.")

    elseif cmd == "support" then
        print("|cFF69CCF0BuddyFlash - Support Development:|r")
        print("  |cFFFFCC00PayPal:|r " .. ns.SUPPORT_PAYPAL)
        print("  |cFFFFCC00Buy Me a Coffee:|r " .. ns.SUPPORT_COFFEE)
        print(" ")
        print("  Thank you for using BuddyFlash! <3")

    elseif cmd == "welcome" then
        if ns.ShowWelcomePopup then ns.ShowWelcomePopup(false) end

    else
        print("|cFF69CCF0BuddyFlash v" .. BUDDYFLASH_VERSION .. " commands:|r")
        print("  /bf options             - Open settings GUI")
        print("  /bf toggle              - Show/hide friend list")
        print("  /bf flash               - Toggle flash effect")
        print("  /bf sound               - Toggle login sound on/off")
        print("  /bf sounds              - List all available sounds")
        print("  /bf sound <num>         - Set login sound (1-" .. #SOUND_OPTIONS .. ")")
        print("  /bf soundtest           - Preview current sound")
        print("  /bf lock                - Lock/unlock window position")
        print("  /bf test                - Test the flash effect")
        print("  /bf reset               - Reset window position")
        print("  /bf support             - Show support links")
        print(" ")
        print("|cFF69CCF0Avatar commands:|r")
        print("  /bf avatar <name> <img> - Set avatar for character")
        print("  /bf avatar <name>       - Check current avatar")
        print("  /bf avatar-remove <name> - Remove custom avatar")
        print("  /bf avatars             - List all custom avatars")
        print(" ")
        print("|cFF69CCF0History & Tracking:|r")
        print("  /bf history [count]     - Show login/logout history")
        print("  /bf lastseen            - Show last seen times for all")
        print("  /bf lastseen <name>     - Last seen for specific friend")
        print("  /bf alts                - Show known alts per BNet account")
        print("  /bf alts <BattleTag>    - Show alts for specific friend")
        print(" ")
        print("|cFF69CCF0Auto-whisper:|r")
        print("  /bf whisper <name> <msg> - Set auto-whisper on login")
        print("  /bf whisper-remove <name> - Remove auto-whisper")
        print("  /bf whispers            - List all auto-whispers")
        print(" ")
        print("|cFF69CCF0Per-friend sounds:|r")
        print("  /bf friendsound <name> <num> - Set sound for friend")
        print("  /bf friendsound-remove <name> - Remove (use global)")
        print("  /bf friendsounds        - List per-friend sounds")
        print(" ")
        print("|cFF69CCF0Custom sounds:|r")
        print("  Place .ogg files in: |cFF888888AddOns/BuddyFlash/Sounds/|r")
        print("  Name them: |cFFFFFF00custom1.ogg|r through |cFFFFFF00custom5.ogg|r")
        print(" ")
        print("  |cFF888888Put .tga/.blp files in: AddOns/BuddyFlash/Avatars/|r")
        print("  |cFF888888Right-click a friend for: Invite, Inspect, Whisper, Target|r")
    end
end
