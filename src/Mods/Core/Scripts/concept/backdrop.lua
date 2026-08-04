local _engineDrawRequests = nil

local function loadSetting(input)
    return DefinitionHelper.LoadSetting(
    {
        {
            targetDefType = "backdrop",
            defName = "default",

            params =
            {
                spriteName = {},
                spriteModId = {},
                widthInMeter = {},
                heightInMeter = {},
                worldOriginRatioX = {},
                worldOriginRatioY = {},
            },
        },
    })
end

local function calculateBackdropBounds(input)

    local worldOriginRatioX = input.worldOriginRatioX
    local worldOriginRatioY = input.worldOriginRatioY
    local backdropWidth = input.widthInMeter
    local backdropHeight = input.heightInMeter

    local worldOriginOffset = World.GetOriginOffset()

    local backdropOriginOffsetX = backdropWidth * worldOriginRatioX

    local backdropOriginOffsetY = backdropHeight * worldOriginRatioY

    return
    {
        x = worldOriginOffset.offsetX - backdropOriginOffsetX,
        y = worldOriginOffset.offsetY - backdropOriginOffsetY,

        originOffsetX = backdropOriginOffsetX,
        originOffsetY = backdropOriginOffsetY,

        width = backdropWidth,
        height = backdropHeight,
    }

end

local function createDrawRequest(input)

    local bounds = input.bounds
    local spriteName = input.spriteName
    local spriteModId = input.spriteModId

    return
    {
        success = true,

        drawRequest =
        {
            type = "sprite",

            spriteName = spriteName,
            spriteModId = spriteModId,

            x = bounds.x,
            y = bounds.y,

            width = bounds.width,
            height = bounds.height,

            layer = "backdrop",

            pivotX = 0,
            pivotY = 0,
        },
    }

end

local function init(input)

    local setting = loadSetting()

    local bounds = calculateBackdropBounds({
        worldOriginRatioX = setting.worldOriginRatioX,
        worldOriginRatioY = setting.worldOriginRatioY,

        widthInMeter = setting.widthInMeter,
        heightInMeter = setting.heightInMeter,
    })

    local result = createDrawRequest({
        bounds = bounds,

        spriteName = setting.spriteName,
        spriteModId = setting.spriteModId,
    })

    if not result.success then
        error(Localize("backdrop.lua.failedToCreateDrawRequest"))
    end

    local drawRequest = result.drawRequest

    local engineResult =
        WorldRenderer.CreateEngineSpriteDrawRequestForAllZoomLevels({
            drawRequest = drawRequest,
        })

    if not engineResult.success then
        error(Localize("backdrop.lua.failedToCreateEngineDrawRequests"))
    end

    _engineDrawRequests = engineResult.drawRequests

end

Backdrop = Backdrop or {}

Backdrop.Init = init

local function draw(deltaTime, totalTime)

    local currentZoom = ZoomLevel.GetCurrent()
    
    local engineDrawRequest =
        _engineDrawRequests[currentZoom.index]

    if engineDrawRequest == nil then
        error(Localize("backdrop.lua.engineDrawRequestNotFound", 
            currentZoom.index))
    end

    DrawQueue.ProcessAndQueue({
        engineDrawRequest = engineDrawRequest,
    })

end

Events.OnUpdate.Add(draw)

