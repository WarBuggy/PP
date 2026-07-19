local function getPlayableBoxSetting()
    local targetDefType = "worldViewSetting"
    local defName = "playableBox"

    local primaryRatio, existsPrimaryRatio =
        Definition.TryGetPayload(targetDefType, defName, {"primaryRatio"})

    local remainingRatio, existsRemainingRatio =
        Definition.TryGetPayload(targetDefType, defName, {"remainingRatio"})

    local minPrimary, existsMinPrimary =
        Definition.TryGetPayload(targetDefType, defName, {"minPrimary"})

    local primaryDimension, existsPrimaryDimension =
        Definition.TryGetPayload(targetDefType, defName, {"primaryDimension"})

    local horizontalAlign, existsHorizontalAlign =
        Definition.TryGetPayload(targetDefType, defName, {"horizontalAlign"})

    local verticalAlign, existsVerticalAlign =
        Definition.TryGetPayload(targetDefType, defName, {"verticalAlign"})

    local fitToScreen, existsFitToScreen =
        Definition.TryGetPayload(targetDefType, defName, {"fitToScreen"})

    if not existsPrimaryRatio
        or not existsRemainingRatio
        or not existsMinPrimary
        or not existsPrimaryDimension
        or not existsHorizontalAlign
        or not existsVerticalAlign
        or not existsFitToScreen then

        error(Localize("playableBox.lua.missingSettingParam", targetDefType, defName))
    end

    return {
        primaryRatio = primaryRatio,
        remainingRatio = remainingRatio,
        minPrimary = minPrimary,
        primaryDimension = primaryDimension,
        horizontalAlign = horizontalAlign,
        verticalAlign = verticalAlign,
        fitToScreen = fitToScreen
    }
end

local function calculatePlayableBox(screenWidth, screenHeight, setting)
    local screenPrimary
    local screenRemaining

    if setting.primaryDimension == "height" then
        screenPrimary = screenHeight
        screenRemaining = screenWidth
    elseif setting.primaryDimension == "width" then
        screenPrimary = screenWidth
        screenRemaining = screenHeight
    else
        error(Localize("playableBox.lua.invalidPrimaryDimension", 
            tostring(setting.primaryDimension)))
    end

    -- Generic algorithm from here on
    local ratio = setting.remainingRatio / setting.primaryRatio
    local minRemaining = setting.minPrimary * ratio
    local primary = math.max(screenPrimary, setting.minPrimary)
    local remaining = primary * ratio

    if remaining < minRemaining then
        remaining = minRemaining
        primary = remaining / ratio
    end

    -- Map back once

    local playableBoxWidth
    local playableBoxHeight

    if setting.primaryDimension == "height" then
        playableBoxHeight = primary
        playableBoxWidth = remaining
    else
        playableBoxWidth = primary
        playableBoxHeight = remaining
    end

    return playableBoxWidth, playableBoxHeight
end

local function calculatePlayableBoxCorners(
    screenWidth, screenHeight, setting, 
    playableBoxWidth, playableBoxHeight)

    local left
    local top

    -- Horizontal alignment

    if setting.horizontalAlign == "left" then
        left = 0

    elseif setting.horizontalAlign == "center" then
        left = (screenWidth - playableBoxWidth) / 2

    elseif setting.horizontalAlign == "right" then
        left = screenWidth - playableBoxWidth

    else
        error(Localize(
            "playableBox.lua.invalidHorizontalAlign",
            tostring(setting.horizontalAlign)
        ))
    end

    -- Vertical alignment

    if setting.verticalAlign == "top" then
        top = 0

    elseif setting.verticalAlign == "center" then
        top = (screenHeight - playableBoxHeight) / 2

    elseif setting.verticalAlign == "bottom" then
        top = screenHeight - playableBoxHeight

    else
        error(Localize(
            "playableBox.lua.invalidVerticalAlign",
            tostring(setting.verticalAlign)
        ))
    end

    local right = left + playableBoxWidth
    local bottom = top + playableBoxHeight

    return {
        left = left,
        top = top,
        right = right,
        bottom = bottom,
        width = playableBoxWidth,
        height = playableBoxHeight
    }
end

local cachedSetting = nil
local cachedBounds = nil
local cachedLines = nil
local cachedDrawRequests = nil

local function createCachedDrawRequests()

    cachedDrawRequests = {}

    for _, line in ipairs(cachedLines) do

        local request = BasicShape.CreateLineDrawRequest(
        {
            x = line.x,
            y = line.y,

            endX = line.endX,
            endY = line.endY,

            thickness = 2,

            r = 255,
            g = 0,
            b = 255,
            a = 255,

            layer = "ui",
        })

        table.insert(cachedDrawRequests, request)
    end
end

local function initializePlayableBox()

    cachedSetting = getPlayableBoxSetting()

    local screenWidth = Screen.Width()
    local screenHeight = Screen.Height()

    local playableBoxWidth, playableBoxHeight = calculatePlayableBox(
            screenWidth, screenHeight, cachedSetting)


    cachedBounds = calculatePlayableBoxCorners(
            screenWidth, screenHeight, cachedSetting, playableBoxWidth, playableBoxHeight)


    cachedLines =
    {
        {
            x = cachedBounds.left,
            y = cachedBounds.top,
            endX = cachedBounds.right,
            endY = cachedBounds.top,
        },

        {
            x = cachedBounds.left,
            y = cachedBounds.bottom,
            endX = cachedBounds.right,
            endY = cachedBounds.bottom,
        },

        {
            x = cachedBounds.left,
            y = cachedBounds.top,
            endX = cachedBounds.left,
            endY = cachedBounds.bottom,
        },

        {
            x = cachedBounds.right,
            y = cachedBounds.top,
            endX = cachedBounds.right,
            endY = cachedBounds.bottom,
        },
    }


    createCachedDrawRequests()
end

local function drawPlayableBox(deltaTime, totalTime)

    if not cachedDrawRequests then
        return
    end

    for _, request in ipairs(cachedDrawRequests) do
        DrawQueue.AddToQueue(request)
    end
end

Events.OnUpdate.Add(drawPlayableBox)

PlayableBox = PlayableBox or {}
PlayableBox.InitializePlayableBox = initializePlayableBox