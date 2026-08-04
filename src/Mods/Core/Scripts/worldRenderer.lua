local function mergeRemainingFields(input)

    local source = input.source
    local target = input.target
    local ignoredFields = input.ignoredFields or {}

    for key, value in pairs(source) do

        if not ignoredFields[key] and target[key] == nil then
            target[key] = value
        end

    end

end

local function convertToBasePixel(input)

    local x = input.x
    local y = input.y
    local width = input.width
    local height = input.height

    local pixelsPerMeter = 
        Camera.GetWorldInPixel().pixelsPerMeter

    return
    {
        pX = x * pixelsPerMeter,
        pY = y * pixelsPerMeter,

        pWidth = width * pixelsPerMeter,
        pHeight = height * pixelsPerMeter,
    }

end

local function applyZoom(input)

    local pX = input.pX
    local pY = input.pY
    local pWidth = input.pWidth
    local pHeight = input.pHeight
    local multiplier = input.multiplier

    return
    {
        pX = pX * multiplier,
        pY = pY * multiplier,

        pWidth = pWidth * multiplier,
        pHeight = pHeight * multiplier,
    }

end

local function createEngineSpriteDrawRequest(input)

    local drawRequest = input.drawRequest
    local zoomLevel = input.zoomLevel

    local basePixel = convertToBasePixel({
        x = drawRequest.x,
        y = drawRequest.y,

        width = drawRequest.width,
        height = drawRequest.height,
    })

    local zoomedPixel = applyZoom({
        pX = basePixel.pX,
        pY = basePixel.pY,

        pWidth = basePixel.pWidth,
        pHeight = basePixel.pHeight,

        multiplier = zoomLevel.multiplier,
    })

    local request =
    {
        pX = zoomedPixel.pX,
        pY = zoomedPixel.pY,

        pWidth = zoomedPixel.pWidth,
        pHeight = zoomedPixel.pHeight,
    }

    mergeRemainingFields({
        source = drawRequest,
        target = request,

        ignoredFields = 
        {
            x = true,
            y = true,
            width = true,
            height = true,
        },
    })

    return Sprite.CreateEngineDrawRequest({
        request = request,
    })

end

local function createEngineSpriteDrawRequestForAllZoomLevels(input)

    local drawRequest = input.drawRequest

    local zoomLevels = ZoomLevel.GetZoomLevelList().list

    local engineDrawRequests = {}

     for index, zoomLevel in ipairs(zoomLevels) do

        local result = createEngineSpriteDrawRequest({
            drawRequest = drawRequest,
            zoomLevel = zoomLevel,
        })

        if not result.success then
            return {
                success = false,
            }
        end

        engineDrawRequests[index] = result.drawRequest

    end

    return
    {
        success = true,
        drawRequests = engineDrawRequests,
    }

end

local function copyDrawRequest(input)

    local drawRequest = input.source

    local copy = {}

    for key, value in pairs(drawRequest) do
        copy[key] = value
    end

    return
    {
        drawRequest = copy,
    }

end

local function transform(input)

    local engineDrawRequest = input.engineDrawRequest

    local request = copyDrawRequest({
        source = engineDrawRequest,
    }).drawRequest

    Camera.Transform({
        engineDrawRequest = request,
    })

    return {
        transformedRequest = request,
    }

end
WorldRenderer = WorldRenderer or {}

WorldRenderer.CreateEngineSpriteDrawRequestForAllZoomLevels = createEngineSpriteDrawRequestForAllZoomLevels
WorldRenderer.CreateEngineSpriteDrawRequest = createEngineSpriteDrawRequest

WorldRenderer.CreateRectDrawRequest = createRectDrawRequest
WorldRenderer.Transform = transform