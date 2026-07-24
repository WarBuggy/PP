local cachedScreenCenterX = nil
local cachedScreenCenterY = nil
local cachedDrawRequest = nil

local function loadSetting()
    return DefinitionHelper.LoadSetting(
    {
        {
            targetDefType = "worldViewSetting",
            defName = "base",
            params =
            {
                worldXRatio = {},
                worldYRatio = {},
                worldWidthRatio = {},
                worldHeightRatio = {},
            }
        }
    })
end

local function calculateScreenBounds(worldBounds, setting)

    local width =
        worldBounds.width * setting.worldWidthRatio

    local height =
        worldBounds.height * setting.worldHeightRatio

    local centerX =
        worldBounds.left +
        worldBounds.width * setting.worldXRatio

    local centerY =
        worldBounds.top +
        worldBounds.height * setting.worldYRatio

    local left = centerX - width / 2
    local top = centerY - height / 2

    local right = left + width
    local bottom = top + height

    return
    {
        left = left,
        top = top,
        right = right,
        bottom = bottom,

        centerX = centerX,
        centerY = centerY,

        width = width,
        height = height,
    }
end

local function buildDrawRequest(bounds)

    return BasicShape.CreateRectDrawRequest(
    {
        x = bounds.left,
        y = bounds.top,

        width = bounds.width,
        height = bounds.height,

        r = 255,
        g = 0,
        b = 255,
        a = 255,

        layer = "ui",
    })
end

local function init()

    local setting = loadSetting()

    local worldScreenBounds = World.GetScreenBounds()

    local screenBounds = calculateScreenBounds(worldScreenBounds, setting)

    cachedScreenCenterX = screenBounds.centerX
    cachedScreenCenterY = screenBounds.centerY

    cachedDrawRequest = buildDrawRequest(screenBounds)
end

local function draw(deltaTime, totalTime)

    if cachedDrawRequest then
        DrawQueue.AddToQueue(cachedDrawRequest)
    end
end

local function getScreenCenter()

    if not cachedScreenCenterX or not cachedScreenCenterY then
        error(Localize("base.lua.notInitialized"))
    end

    return
    {
        x = cachedScreenCenterX,
        y = cachedScreenCenterY,
    }
end

Events.OnUpdate.Add(draw)

Base = Base or {}
Base.Init = init
Base.GetScreenCenter = getScreenCenter