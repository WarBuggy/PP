local cachedScreenBounds = nil
local cachedDrawRequests = nil
local cachedBackgroundDrawRequest = nil
local cachedOriginX = nil
local cachedOriginY = nil

local function loadSetting()
    return DefinitionHelper.LoadSetting(
    {
        {
            targetDefType = "worldViewSetting",
            defName = "world",

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
                worldCutoutWidth = {},
                worldCutoutHeight = {}
            }
        }
    })
end

local function calculateSize(screenWidth, screenHeight, setting)
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

local function calculateScreenBounds(screenWidth, screenHeight, setting,
    screenWorldWidth, screenWorldHeight)

    local left
    local top

    -- Horizontal alignment

    if setting.horizontalAlign == "left" then
        left = 0

    elseif setting.horizontalAlign == "center" then
        left = (screenWidth - screenWorldWidth) / 2

    elseif setting.horizontalAlign == "right" then
        left = screenWidth - screenWorldWidth

    else
        error(Localize(
            "world.lua.invalidHorizontalAlign",
            tostring(setting.horizontalAlign)
        ))
    end

    -- Vertical alignment

    if setting.verticalAlign == "top" then
        top = 0

    elseif setting.verticalAlign == "center" then
        top = (screenHeight - screenWorldHeight) / 2

    elseif setting.verticalAlign == "bottom" then
        top = screenHeight - screenWorldHeight

    else
        error(Localize(
            "world.lua.invalidVerticalAlign",
            tostring(setting.verticalAlign)
        ))
    end

    local right = left + screenWorldWidth
    local bottom = top + screenWorldHeight

    return
    {
        left = left,
        top = top,
        right = right,
        bottom = bottom,

        width = screenWorldWidth,
        height = screenWorldHeight,
    }
end

local function buildDrawRequests(screenBounds)

    cachedDrawRequests =
    {
        BasicShape.CreateLineDrawRequest(
        {
            x = screenBounds.left,
            y = screenBounds.top,

            endX = screenBounds.right,
            endY = screenBounds.top,

            thickness = 2,

            r = 255,
            g = 0,
            b = 255,
            a = 255,

            layer = "ui",
        }),

        BasicShape.CreateLineDrawRequest(
        {
            x = screenBounds.left,
            y = screenBounds.bottom,

            endX = screenBounds.right,
            endY = screenBounds.bottom,

            thickness = 2,

            r = 255,
            g = 0,
            b = 255,
            a = 255,

            layer = "ui",
        }),

        BasicShape.CreateLineDrawRequest(
        {
            x = screenBounds.left,
            y = screenBounds.top,

            endX = screenBounds.left,
            endY = screenBounds.bottom,

            thickness = 2,

            r = 255,
            g = 0,
            b = 255,
            a = 255,

            layer = "ui",
        }),

        BasicShape.CreateLineDrawRequest(
        {
            x = screenBounds.right,
            y = screenBounds.top,

            endX = screenBounds.right,
            endY = screenBounds.bottom,

            thickness = 2,

            r = 255,
            g = 0,
            b = 255,
            a = 255,

            layer = "ui",
        }),
    }
end

local function calculateBackgroundScale(screenBoundsWidth, screenBoundsHeight, setting)

    local scaleX = screenBoundsWidth / setting.worldCutoutWidth
    local scaleY = screenBoundsHeight / setting.worldCutoutHeight

    return scaleX, scaleY
end

local function buildBackgroundDrawRequest(screenWidth, screenHeight, screenBounds, setting)

    local scaleX, scaleY = calculateBackgroundScale(
        screenBounds.width, screenBounds.height, setting)

    cachedBackgroundDrawRequest = Sprite.CreateDrawRequest(
    {
        defName = "background",

        x = screenWidth / 2,
        y = screenHeight / 2,

        scaleX = scaleX,
        scaleY = scaleY,

        pivotX = 1050,
        pivotY = 1050,

        layer = "background",
    })
end

local function init()

    local setting = loadSetting()

    local screenWidth = Screen.Width()
    local screenHeight = Screen.Height()

    local screenWorldWidth, screenWorldHeight =
        calculateSize(screenWidth, screenHeight, setting)

    cachedScreenBounds = calculateScreenBounds(screenWidth, screenHeight, 
        setting, screenWorldWidth, screenWorldHeight)

    buildDrawRequests(cachedScreenBounds)

    buildBackgroundDrawRequest(screenWidth, screenHeight, 
        cachedScreenBounds, setting)
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

local function getScreenBounds()

    if not cachedScreenBounds then
        error(Localize("world.lua.notInitialized"))
    end

    return 
    {
        left = cachedScreenBounds.left,
        top = cachedScreenBounds.top,
        right = cachedScreenBounds.right,
        bottom = cachedScreenBounds.bottom,

        width = cachedScreenBounds.width,
        height = cachedScreenBounds.height,
    }
end

local function setScreenOrigin(screenX, screenY)

    cachedOriginX = screenX
    cachedOriginY = screenY
end

local function getScreenOrigin()

    if not cachedOriginX or not cachedOriginY then
        error(Localize("world.lua.originNotInitialized"))
    end

    return
    {
        x = cachedOriginX,
        y = cachedOriginY,
    }
end

Events.OnUpdate.Add(draw)

World = World or {}
World.Init = init
World.GetScreenBounds = getScreenBounds
World.SetScreenOrigin = setScreenOrigin
World.GetScreenOrigin = getScreenOrigin