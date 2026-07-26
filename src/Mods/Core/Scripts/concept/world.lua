local cachedScreenBounds = nil
local cachedDrawRequests = nil
local cachedBackgroundDrawRequest = nil
local pixelPerMeter = nil
local cachedWorldSize = nil
local cachedOriginX = nil
local cachedOriginY = nil

local function loadSetting(input)
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
                verticalAlign = {},
                longerDimensionInMeters = {},
                widthRatioOriginX = {},
                heightRatioOriginY = {}
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

local function calculateScreenSize(input)
    local screenWidth = input.screenWidth
    local screenHeight = input.screenHeight
    local setting = input.setting

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

    return {
        width = width, 
        height = height,
    }
end

local function calculateScreenBounds(input)

    local screen = input.screen
    local setting = input.setting
    local world = input.world

    local left
    local top

    -- Horizontal alignment

    if setting.horizontalAlign == "left" then
        left = 0

    elseif setting.horizontalAlign == "center" then
        left = (screen.width - world.screenWidth) / 2

    elseif setting.horizontalAlign == "right" then
        left = screen.width - world.screenWidth

    else
        error(Localize("world.lua.invalidHorizontalAlign",
            tostring(setting.horizontalAlign)
        ))
    end

    -- Vertical alignment

    if setting.verticalAlign == "top" then
        top = 0

    elseif setting.verticalAlign == "center" then
        top = (screen.height - world.screenHeight) / 2

    elseif setting.verticalAlign == "bottom" then
        top = screen.height - world.screenHeight

    else
        error(Localize("world.lua.invalidVerticalAlign",
            tostring(setting.verticalAlign)
        ))
    end

    return
    {
        left = left,
        top = top,
        right = left + world.screenWidth,
        bottom = top + world.screenHeight,

        width = world.screenWidth,
        height = world.screenHeight,
    }
end

local function buildDrawRequests(input)

    local screenBounds = input

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

local function calculateBackgroundScale(input)

    local screenBounds = input.screenBounds
    local setting = input.setting

    local scaleX = screenBounds.width / setting.worldCutoutWidth
    local scaleY = screenBounds.height / setting.worldCutoutHeight

    return {
        scaleX = scaleX,
        scaleY = scaleY,
    }
end

local function buildBackgroundDrawRequest(input)

    local screenWidth = input.screenWidth
    local screenHeight = input.screenHeight
    local screenBounds = input.screenBounds
    local setting = input.setting

    local backgroundScale = calculateBackgroundScale({
        screenBounds = screenBounds,
        setting = setting,
    })

    cachedBackgroundDrawRequest = Sprite.CreateDrawRequest(
    {
        defName = "background",

        x = screenWidth / 2,
        y = screenHeight / 2,

        scaleX = backgroundScale.scaleX,
        scaleY = backgroundScale.scaleY,

        pivotX = 1050,
        pivotY = 1050,

        layer = "background",
    })
end

local function calculatePixelsPerMeter(input)

    local screenWidth = input.screenWidth
    local screenHeight = input.screenHeight
    local longerDimensionInMeters = input.longerDimensionInMeters

    local longerDimensionPixels = math.max(screenWidth, screenHeight)

    return longerDimensionPixels / longerDimensionInMeters
end

local function calculateWorldSize(input)

    local worldScreenSize = input.worldScreenSize
    local setting = input.setting

    local width
    local height

    if worldScreenSize.width >= worldScreenSize.height then
        width = setting.longerDimensionInMeters
        height = width * worldScreenSize.height / worldScreenSize.width
    else
        height = setting.longerDimensionInMeters
        width = height * worldScreenSize.width / worldScreenSize.height
    end

    return {
        width = width,
        height = height,
    }
end

local function calculateScreenOrigin(input)

    local screenBounds = input.screenBounds
    local setting = input.setting

    local originX =
        screenBounds.left +
        screenBounds.width * setting.widthRatioOriginX

    local originY =
        screenBounds.top +
        screenBounds.height * setting.heightRatioOriginY

    return {
        originX = originX,
        originY = originY,
    }
end

local function init(input)

    local setting = loadSetting()

    local screenWidth = Screen.Width()
    local screenHeight = Screen.Height()

    local worldScreenSize = calculateScreenSize({
            screenWidth = screenWidth, 
            screenHeight = screenHeight, 
            setting = setting
        })

    cachedScreenBounds = calculateScreenBounds({
        screen = { 
            width = screenWidth,
            height = screenHeight,
        },
        setting = setting,
        world = {
            screenWidth = worldScreenSize.width,
            screenHeight = worldScreenSize.height,
        }
    })

    cachedWorldSize = calculateWorldSize({
        worldScreenSize = worldScreenSize,
        setting = setting,
    })
    
    pixelPerMeter = calculatePixelsPerMeter({
        screenWidth = worldScreenSize.width, 
        screenHeight = worldScreenSize.height,
        longerDimensionInMeters = setting.longerDimensionInMeters, 
    })

    local origin = calculateScreenOrigin({
        screenBounds = cachedScreenBounds,
        setting = setting,
    })

    cachedOriginX = origin.originX
    cachedOriginY = origin.originY

    buildDrawRequests(cachedScreenBounds)

    buildBackgroundDrawRequest({
        screenWidth = screenWidth, 
        screenHeight = screenHeight, 
        screenBounds = cachedScreenBounds,
        setting = setting,
    })
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

Events.OnUpdate.Add(draw)

local function getScreenBounds(input)

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

local function getPixelsPerMeter()
    return pixelPerMeter
end

local function worldToScreen(input)

    local posX = input.posX
    local posY = input.posY

    return {
        x = cachedOriginX + posX * pixelPerMeter,
        y = cachedOriginY + posY * pixelPerMeter,
    }
end

local function screenToWorld(input)

    local x = input.x
    local y = input.y

    return {
        posX = (x - cachedOriginX) / pixelPerMeter,
        posY = (y - cachedOriginY) / pixelPerMeter,
    }
end

local function meterToPixel(input)
    return { pixel = input.meter * pixelPerMeter, }
end

local function getSize(input)
    if not cachedWorldSize then
        error(Localize("world.lua.notInitialized"))
    end

    return cachedWorldSize
end


World = World or {}
World.Init = init
World.GetScreenBounds = getScreenBounds
World.GetPixelsPerMeter = getPixelsPerMeter
World.WorldToScreen = worldToScreen
World.ScreenToWorld = screenToWorld
World.MeterToPixel = meterToPixel
World.GetSize = getSize
