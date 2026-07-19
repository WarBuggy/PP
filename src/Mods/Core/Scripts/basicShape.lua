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

local function resolveLayerOrder(params)

    local layerOrder = 0 -- can default to 0 and fail silently

    if params.layer ~= nil then
        local resolvedOrder, exists = DrawLayers.TryGetLayerOrder(params.layer)

        if exists then
            layerOrder = resolvedOrder
        end
    end

    return layerOrder
end


local function applyCommonRequestProperties(params, request)

    for _, propertyName in ipairs(COMMON_DRAW_PROPERTIES) do
        if params[propertyName] ~= nil then
            request[propertyName] = params[propertyName]
        end
    end
end

local function createRectDrawRequest(params)
    
    if type(params) ~= "table" then
        error(Localize("basicShape.lua.requestMustBeTable"))
    end

    if params.width == nil or params.height == nil then
        error(Localize("basicShape.lua.rectSizeRequired"))
    end

    local request =
    {
        type = "rectangle",

        x = params.x or 0,
        y = params.y or 0,

        width = params.width,
        height = params.height,

        layerOrder = resolveLayerOrder(params),
    }

    applyCommonRequestProperties(params, request)

    return request
end

local function createLineDrawRequest(params)

    if type(params) ~= "table" then
        error(Localize("basicShape.lua.requestMustBeTable"))
    end

    if params.endX == nil or params.endY == nil then
        error(Localize("basicShape.lua.lineEndPointRequired"))
    end

    local request =
    {
        type = "line",

        x = params.x or 0,
        y = params.y or 0,

        layerOrder = resolveLayerOrder(params),

        endX = params.endX,
        endY = params.endY,
        thickness = params.thickness or 1,
    }

    applyCommonRequestProperties(params, request)

    return request
end


BasicShape = BasicShape or {}

BasicShape.CreateRectDrawRequest = createRectDrawRequest
BasicShape.CreateLineDrawRequest = createLineDrawRequest