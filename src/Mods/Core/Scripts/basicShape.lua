local COMMON_DRAW_PROPERTIES =
{
    "rotation",
    "scaleX",
    "scaleY",
    "pivotX",
    "pivotY",
    "r",
    "g",
    "b",
    "a"
}

local function resolveLayerOrder(input)

    local layer = input.layer

    local layerOrder = 0 -- Can default to 0 and fail silently.

    if layer ~= nil then
        local resolvedOrder, exists = DrawLayers.TryGetLayerOrder(layer)

        if exists then
            layerOrder = resolvedOrder
        end
    end

    return {
        layerOrder = layerOrder
    }
end


local function applyCommonRequestProperties(input)

    local params = input.params
    local request = input.request

    for _, propertyName in ipairs(COMMON_DRAW_PROPERTIES) do
        if params[propertyName] ~= nil then
            request[propertyName] = params[propertyName]
        end
    end

    return {
        request = request
    }
end

local function createRectDrawRequest(input)

    if type(input) ~= "table" then
        error(Localize("basicShape.lua.requestMustBeTable"))
    end

    if input.width == nil or input.height == nil then
        error(Localize("basicShape.lua.rectSizeRequired"))
    end

    local layerResult = resolveLayerOrder({
        layer = input.layer
    })

    local request =
    {
        type = "rectangle",

        x = input.x or 0,
        y = input.y or 0,

        width = input.width,
        height = input.height,

        layerOrder = layerResult.layerOrder,
    }

    local result = applyCommonRequestProperties({
        params = input,
        request = request
    })

    return request
end

local function createLineDrawRequest(input)

    if type(input) ~= "table" then
        error(Localize("basicShape.lua.requestMustBeTable"))
    end

    if input.endX == nil or input.endY == nil then
        error(Localize("basicShape.lua.lineEndPointRequired"))
    end

    local layerResult = resolveLayerOrder({
        layer = input.layer
    })

    local request =
    {
        type = "line",

        x = input.x or 0,
        y = input.y or 0,

        layerOrder = layerResult.layerOrder,

        endX = input.endX,
        endY = input.endY,
        thickness = input.thickness or 1,
    }

    local result = applyCommonRequestProperties({
        params = input,
        request = request
    })

    return request
end


BasicShape = BasicShape or {}

BasicShape.CreateRectDrawRequest = createRectDrawRequest
BasicShape.CreateLineDrawRequest = createLineDrawRequest