local targetDefType = "zoomLevel"
local BASE_ZOOM_MULTIPLIER = 1
local _zoomLevels = nil
local _currentZoomLevel = nil
local _currentZoomLevelIndex = nil

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

    return {
        zoomLevel = zoomLevel,
    } 

end

local function createFallbackZoomLevel(input)

    local worldInPixel = input.worldInPixel
    local viewport = input.viewport

    local fallbackZoomLevel = buildZoomLevel({
        multiplier = BASE_ZOOM_MULTIPLIER,
        worldInPixel = worldInPixel,
        viewport = viewport,
    }).zoomLevel

    fallbackZoomLevel.name = "__fallback__"
    fallbackZoomLevel.modId = "Core"

    return {
        fallbackZoomLevel = fallbackZoomLevel,
    }
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
        }).zoomLevel

        zoomLevel.name = name
        zoomLevel.modId = modId

        table.insert(zoomLevels, zoomLevel)

    end

    if #zoomLevels == 0 then
        local fallbackZoomLevel = createFallbackZoomLevel({
            worldInPixel = worldInPixel,
            viewport = viewport,
        }).fallbackZoomLevel
        table.insert(zoomLevels, fallbackZoomLevel)
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

local function findDefaultZoomLevel(input)

    local zoomLevels = input.zoomLevels

    local defaultZoomLevel = nil
    local defaultZoomLevelIndex = nil
    local smallestDifference = math.huge

    for index, zoomLevel in ipairs(zoomLevels) do

        local difference =
            math.abs(zoomLevel.multiplier - BASE_ZOOM_MULTIPLIER)

        if difference < smallestDifference then

            smallestDifference = difference
            defaultZoomLevel = zoomLevel
            defaultZoomLevelIndex = index

        end

    end

    return
    {
        zoomLevel = defaultZoomLevel,
        index = defaultZoomLevelIndex,
    }

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

    _zoomLevels = zoomLevels

    local findResult = findDefaultZoomLevel({
        zoomLevels = zoomLevels
    })

    _currentZoomLevel = findResult.zoomLevel
    _currentZoomLevelIndex = findResult.index

end


local function getZoomLevelList(input)
    if _zoomLevels == nil then
        error(Localize("zoomLevel.lua.notInitialized"))
    end

    return {
        list = _zoomLevels,
    }

end

local function getCurrent(input)

    if _currentZoomLevel == nil then
        error(Localize("zoomLevel.lua.notInitialized"))
    end

    return {
        zoomLevel = _currentZoomLevel,
        index = _currentZoomLevelIndex,
    }

end

local function zoomIn()

    if _zoomLevels == nil then
        error(Localize("zoomLevel.lua.notInitialized"))
    end
    
    if _currentZoomLevelIndex >= #_zoomLevels then
        return {
            changed = false,
            currentZoomLevel = _currentZoomLevel,
            currentZoomLevelIndex = _currentZoomLevelIndex,
        }
    end

    _currentZoomLevelIndex = _currentZoomLevelIndex + 1
    _currentZoomLevel = _zoomLevels[_currentZoomLevelIndex]

    return {
        changed = true,
        currentZoomLevel = _currentZoomLevel,
        currentZoomLevelIndex = _currentZoomLevelIndex,
    }

end

local function zoomOut()
    
    if _zoomLevels == nil then
        error(Localize("zoomLevel.lua.notInitialized"))
    end

    if _currentZoomLevelIndex <= 1 then
        return {
            changed = false,
            currentZoomLevel = _currentZoomLevel,
            currentZoomLevelIndex = _currentZoomLevelIndex,
        }
    end

    _currentZoomLevelIndex = _currentZoomLevelIndex - 1
    _currentZoomLevel = _zoomLevels[_currentZoomLevelIndex]

    return {
        changed = true,
        currentZoomLevel = _currentZoomLevel,
        currentZoomLevelIndex = _currentZoomLevelIndex,
    }

end

ZoomLevel = ZoomLevel or {}

ZoomLevel.Init = init
ZoomLevel.GetZoomLevelList = getZoomLevelList
ZoomLevel.GetCurrent = getCurrent
ZoomLevel.ZoomIn = zoomIn
ZoomLevel.ZoomOut = zoomOut