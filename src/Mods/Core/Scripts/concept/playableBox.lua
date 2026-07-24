local function loadSetting()
    return DefinitionHelper.LoadSetting(
    {
        {
            targetDefType = "worldViewSetting",
            defName = "playableBox",

            params =
            {
                widthRatio = {},
                heightRatio = {},
                maxWidth = {},
                maxHeight = {},
                horizontalAlign = {},
                verticalAlign = {}
            }
        },

        {
            targetDefType = "worldViewSetting",
            defName = "backgroundImage",

            params =
            {
                playableCutoutWidth = {},
                playableCutoutHeight = {}
            }
        }
    })
end

local function calculateDimension(screenWidth, screenHeight, setting)
    local width
    local height

    if screenWidth > screenHeight then
        -- Landscape: height determines the size
        height = math.min(screenHeight, setting.maxHeight)
        width = height * setting.widthRatio / setting.heightRatio
    else
        -- Portrait or square: width determines the size
        width = math.min(screenWidth, setting.maxWidth)
        height = width * setting.heightRatio / setting.widthRatio
    end

    return width, height
end

local function calculateBounds(screenWidth, screenHeight, setting, width, height)

    local left
    local top

    -- Horizontal alignment

    if setting.horizontalAlign == "left" then
        left = 0

    elseif setting.horizontalAlign == "center" then
        left = (screenWidth - width) / 2

    elseif setting.horizontalAlign == "right" then
        left = screenWidth - width

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
        top = (screenHeight - height) / 2

    elseif setting.verticalAlign == "bottom" then
        top = screenHeight - height

    else
        error(Localize(
            "playableBox.lua.invalidVerticalAlign",
            tostring(setting.verticalAlign)
        ))
    end

    local right = left + width
    local bottom = top + height

    return {
        left = left,
        top = top,
        right = right,
        bottom = bottom,
        width = width,
        height = height
    }
end

local cachedSetting = nil
local cachedBounds = nil
local cachedLines = nil
local cachedDrawRequests = nil
local cachedBackgroundDrawRequest = nil

local function buildDrawRequests()

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

local function calculateBackgroundScale(playableWidth, playableHeight, setting)

    local scaleX = playableWidth / setting.playableCutoutWidth
    local scaleY = playableHeight / setting.playableCutoutHeight

    return scaleX, scaleY
end

local function buildBackgroundDrawRequest(screenWidth, screenHeight, bounds, setting)

    local scaleX, scaleY = calculateBackgroundScale(
        bounds.width, bounds.height, setting)

    cachedBackgroundDrawRequest = Sprite.CreateDrawRequest(
    {
        defName = "background",

        x = screenWidth / 2,
        y = screenHeight / 2,

        scaleX = scaleX,
        scaleY = scaleY,

        pivotX = 1050,
        pivotY = 1050,

        layer = "background"
    })
end

local function init()

    cachedSetting = loadSetting()

    local screenWidth = Screen.Width()
    local screenHeight = Screen.Height()

    local width, height = calculateDimension(
            screenWidth, screenHeight, cachedSetting)


    cachedBounds = calculateBounds(
            screenWidth, screenHeight, cachedSetting, width, height)

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


    buildDrawRequests()

    buildBackgroundDrawRequest(
            screenWidth, screenHeight, cachedBounds, cachedSetting)
end

local function draw(deltaTime, totalTime)

    if not cachedDrawRequests then
        return
    end

    for _, request in ipairs(cachedDrawRequests) do
        DrawQueue.AddToQueue(request)
    end

     if cachedBackgroundDrawRequest then
        DrawQueue.AddToQueue(cachedBackgroundDrawRequest)
    end
end

local function getBounds()

    if not cachedBounds then
        error(Localize("playableBox.lua.notInitialized"))
    end

    return {
        left = cachedBounds.left,
        top = cachedBounds.top,
        right = cachedBounds.right,
        bottom = cachedBounds.bottom,

        width = cachedBounds.width,
        height = cachedBounds.height
    }
end

Events.OnUpdate.Add(draw)

PlayableBox = PlayableBox or {}
PlayableBox.Init = init
PlayableBox.GetBounds = getBounds