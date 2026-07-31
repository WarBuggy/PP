local targetDefType = "zoomLevel"

local function buildZoomLevel(input)

    local viewRadius = input.viewRadius
    local multiplier = input.multiplier
    local worldInPixel = input.worldInPixel
    local viewport = input.viewport

    local zoomLevel = {}

    if viewRadius ~= nil then

        local viewportSize = 
            math.min(viewport.width, viewport.height)

        zoomLevel.pixelPerMeter = viewportSize / (viewRadius * 2)

        zoomLevel.multiplier =
            zoomLevel.pixelPerMeter / worldInPixel.pixelsPerMeter

    else

        zoomLevel.multiplier = multiplier

        zoomLevel.pixelPerMeter =
            worldInPixel.pixelsPerMeter * zoomLevel.multiplier

    end

    zoomLevel.worldInPixel =
    {
        width =
            worldInPixel.width * zoomLevel.multiplier,

        height =
            worldInPixel.height * zoomLevel.multiplier,

        originOffsetX =
            worldInPixel.originOffsetX * zoomLevel.multiplier,

        originOffsetY =
            worldInPixel.originOffsetY * zoomLevel.multiplier,
    }

    return zoomLevel

end

local function buildZoomLevelList(input)

    local worldInPixel = Camera.GetWorldInPixel()
    local viewport = Camera.GetViewport()
    local zoomLevelArray = input.zoomLevelArray

    local zoomLevels = {}

    for zoomLevelInfo in LedgerArray.Iterator(zoomLevelArray) do

        local name = zoomLevelInfo.name
        local modId = zoomLevelInfo.modId
        
        local viewRadius, _ = Definition.TryGetPayload(
            targetDefType, name, { "viewRadius" }, modId)

        local multiplier, _ = Definition.TryGetPayload(
            targetDefType, name, { "multiplier" }, modId)

        local zoomLevel = buildZoomLevel({
            viewRadius = viewRadius,
            multiplier = multiplier,
            worldInPixel = worldInPixel,
            viewport = viewport,
        })

        zoomLevel.name = name
        zoomLevel.modId = modId

        table.insert(zoomLevels, zoomLevel)

    end

    return {
        zoomLevels = zoomLevels,
    }

end

local function sortZoomLevels(input)

    local zoomLevels = input.zoomLevels

    table.sort(zoomLevels,
        function(a, b)
            return a.multiplier < b.multiplier
        end)

end

local function replaceZoomLevelList(input)

    local zoomLevels = input.zoomLevels
    local zoomLevelArray = input.zoomLevelArray 

    LedgerArray.Clear(zoomLevelArray)

    for _, zoomLevel in ipairs(zoomLevels) do
        LedgerArray.InsertLast(zoomLevelArray, zoomLevel)
    end

end

local function init()

     local zoomLevelArray, exists =
        GameData.TryGet("zoomLevel.list", "Core")

    if not exists or not zoomLevelArray then

        error(Localize("zoomLevel.lua.zoomLevelListNotFound"))

    end

    local zoomLevels = buildZoomLevelList({
        zoomLevelArray = zoomLevelArray,
    }).zoomLevels

    sortZoomLevels({
        zoomLevels = zoomLevels,
    })

    replaceZoomLevelList({
        zoomLevels = zoomLevels,
        zoomLevelArray = zoomLevelArray,
    })

end

ZoomLevel = ZoomLevel or {}

ZoomLevel.Init = init