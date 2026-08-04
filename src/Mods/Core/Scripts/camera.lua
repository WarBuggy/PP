local defaultMaxScreenWidthRatio = 1
local defaultMaxScreenHeightRatio = 1
local defaultHorizontalAlignment = "center"
local defaultVerticalAlignment = "center"
local defaultAspectRatio = "full"
local _viewport = nil
local _worldInPixel = nil
local _position = nil

local function loadSetting(input)
    return DefinitionHelper.LoadSetting(
    {
        {
            targetDefType = "camera",
            defName = "viewport",

            params =
            {
                maxScreenWidthRatio = {
                    defaultValue = defaultMaxScreenWidthRatio,
                },
                maxScreenHeightRatio = {
                    defaultValue = defaultMaxScreenHeightRatio,
                },
                aspectRatio = {
                    defaultValue = defaultAspectRatio,
                },
                horizontalAlignment = {
                    defaultValue = defaultHorizontalAlignment,
                },
                verticalAlignment = {
                    defaultValue = defaultVerticalAlignment,
                },
                worldPrimaryDimensionInPixel = {},
            }
        },
        {
            targetDefType = "world",
            defName = "setting",

            params =
            {
                primaryDimension = {},
            }
        },
        {
            targetDefType = "camera",
            defName = "view",

            params =
            {
                initialOffsetWorldOriginXInMeter = {},
                initialOffsetWorldOriginYInMeter = {},
            }
        },
    })
end

local function calculateViewportSize(input)

    local screenWidth = input.screenWidth
    local screenHeight = input.screenHeight
    local setting = input.setting
    local maxScreenWidthRatio = setting.maxScreenWidthRatio
    local maxScreenHeightRatio = setting.maxScreenHeightRatio
    local aspectRatio = setting.aspectRatio

    if maxScreenWidthRatio <= 0 or maxScreenWidthRatio > 1 then
        print(Localize("camera.lua.invalidMaxScreenWidthRatio", 
            maxScreenWidthRatio, defaultMaxScreenWidthRatio))
        maxScreenWidthRatio = defaultMaxScreenWidthRatio
    end

    if maxScreenHeightRatio <= 0 or maxScreenHeightRatio > 1 then
        print(Localize("camera.lua.invalidMaxScreenHeightRatio", 
            maxScreenHeightRatio, defaultMaxScreenHeightRatio))
        maxScreenHeightRatio = defaultMaxScreenHeightRatio
    end

    local maxWidth = screenWidth * maxScreenWidthRatio
    local maxHeight = screenHeight * maxScreenHeightRatio

    if aspectRatio == defaultAspectRatio then
        return {
            width = maxWidth,
            height = maxHeight,
        }
    end

    local result = DefinitionHelper.TryParseAspectRatio({
        ratioString = aspectRatio,
    })

    if not result.success then

        print(Localize("camera.lua.invalidAspectRatioFallback"))

        return {
            width = maxWidth,
            height = maxHeight,
        }
    end

    local aspectWidth = result.aspectWidth
    local aspectHeight = result.aspectHeight

    local width
    local height

    if maxWidth / maxHeight >= aspectWidth / aspectHeight then
        -- Limited by height
        height = maxHeight
        width = height * aspectWidth / aspectHeight
    else
        -- Limited by width
        width = maxWidth
        height = width * aspectHeight / aspectWidth
    end

    return {
        width = width,
        height = height,
    }

end

local function calculateViewportPosition(input)

    local screenWidth = input.screenWidth
    local screenHeight = input.screenHeight
    local viewportWidth = input.viewportWidth
    local viewportHeight = input.viewportHeight
    local setting = input.setting

    local horizontalAlignment = setting.horizontalAlignment
    local verticalAlignment = setting.verticalAlignment

    if horizontalAlignment ~= "left"
        and horizontalAlignment ~= "center"
        and horizontalAlignment ~= "right" then

        print(Localize("camera.lua.invalidHorizontalAlignment",
            horizontalAlignment,
            defaultHorizontalAlignment))

        horizontalAlignment = defaultHorizontalAlignment
    end

    if verticalAlignment ~= "top"
        and verticalAlignment ~= "center"
        and verticalAlignment ~= "bottom" then

        print(Localize("camera.lua.invalidVerticalAlignment",
            verticalAlignment, defaultVerticalAlignment))

        verticalAlignment = defaultVerticalAlignment
    end

    local x

    if horizontalAlignment == "left" then
        x = 0
    elseif horizontalAlignment == "center" then
        x = (screenWidth - viewportWidth) / 2
    else -- "right"
        x = screenWidth - viewportWidth
    end

    local y

    if verticalAlignment == "top" then
        y = 0
    elseif verticalAlignment == "center" then
        y = (screenHeight - viewportHeight) / 2
    else -- "bottom"
        y = screenHeight - viewportHeight
    end

    return {
        x = x,
        y = y,
    }

end

local function calculateViewport(input)

    local screenWidth = input.screenWidth
    local screenHeight = input.screenHeight
    local setting = input.setting
    
    local size = calculateViewportSize({
        screenWidth = screenWidth,
        screenHeight = screenHeight,
        setting = setting,
    })

    local position = calculateViewportPosition({
        screenWidth = screenWidth,
        screenHeight = screenHeight,
        viewportWidth = size.width,
        viewportHeight = size.height,
        setting = setting,
    })

    local viewport = {
        x = position.x,
        y = position.y,

        width = size.width,
        height = size.height,
    }

    viewport.halfWidth = viewport.width / 2
    viewport.halfHeight = viewport.height / 2

    viewport.left = viewport.x
    viewport.top = viewport.y
    viewport.right = viewport.x + viewport.width
    viewport.bottom = viewport.y + viewport.height

    viewport.centerX = viewport.left + viewport.width / 2
    viewport.centerY = viewport.top + viewport.height / 2

    return viewport

end

local function calculateWorldInPixel(input)

    local setting = input.setting

    local worldSize = World.GetSize()

    local worlAspectRatio = worldSize.width / worldSize.height
    local worldWidth
    local worldHeight

    if setting.primaryDimension == "width" then

        worldWidth = setting.worldPrimaryDimensionInPixel
        worldHeight = worldWidth / worlAspectRatio

    elseif setting.primaryDimension == "height" then

        worldHeight = setting.worldPrimaryDimensionInPixel
        worldWidth = worldHeight * worlAspectRatio

    else

        error(Localize("camera.lua.invalidPrimaryDimension",
            tostring(setting.primaryDimension)))

    end

    local worldOriginOffsetInMeter = World.GetOriginOffset()
    local pixelsPerMeter = worldWidth / worldSize.width
    local originOffsetX = worldOriginOffsetInMeter.offsetX * pixelsPerMeter
    local originOffsetY = worldOriginOffsetInMeter.offsetY * pixelsPerMeter

    return
    {
        width = worldWidth,
        height = worldHeight,

        originOffsetX = originOffsetX,
        originOffsetY = originOffsetY,

        pixelsPerMeter = pixelsPerMeter,
    }

end

local function calculateInitialPosition(input)

    local setting = input.setting
    local worldOriginOffset = input.worldOriginOffset

    return
    {
        x = worldOriginOffset.offsetX
            + setting.initialOffsetWorldOriginXInMeter,

        y = worldOriginOffset.offsetY
            + setting.initialOffsetWorldOriginYInMeter,
    }

end

local function init(input)
    
    local setting = loadSetting()

    local screenWidth = Screen.Width()
    local screenHeight = Screen.Height()
    local worldOriginOffset = World.GetOriginOffset()
    
    _viewport = calculateViewport({
        screenWidth = screenWidth,
        screenHeight = screenHeight,
        setting = setting,
    })

    _worldInPixel = calculateWorldInPixel({
        setting = setting,
    })

    _position = calculateInitialPosition({
        setting = setting,
        worldOriginOffset = worldOriginOffset,
    })

end

local function transform(input)

    local engineDrawRequest = input.engineDrawRequest

    local zoomLevel = ZoomLevel.GetCurrent().zoomLevel
    local cameraX = _position.x *
        _worldInPixel.pixelsPerMeter * zoomLevel.multiplier

    local cameraY = _position.y *
        _worldInPixel.pixelsPerMeter * zoomLevel.multiplier

    local cameraLeft = cameraX - _viewport.halfWidth

    local cameraTop = cameraY - _viewport.halfHeight

    engineDrawRequest.x = engineDrawRequest.x - 
        cameraLeft + _viewport.left

    engineDrawRequest.y = engineDrawRequest.y - 
        cameraTop + _viewport.top

end

local function getWorldInPixel()

    if _worldInPixel == nil then
        error(Localize("camera.lua.worldNotInitialized"))
    end

    return _worldInPixel
end

local function getViewport()

    if _viewport == nil then
        error(Localize("camera.lua.viewportNotInitialized"))
    end

    return _viewport
end

local function getPosition()

    if _position == nil then
        error(Localize("cameraView.lua.positionNotInitialized"))
    end

    return _position

end

Camera = Camera or {}

Camera.Init = init
Camera.GetWorldInPixel = getWorldInPixel
Camera.GetViewport = getViewport
Camera.Transform = transform