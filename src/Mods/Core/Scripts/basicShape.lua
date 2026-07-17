local function createRectDrawRequest(params)
    
    if type(params) ~= "table" then
        error(Localize("basicShape.lua.requestMustBeTable"))
    end

    if params.width == nil or params.height == nil then
        error(Localize("basicShape.lua.rectSizeRequired"))
    end
    
    local layerOrder = 0 -- can default to 0 and fail silently
    if params.layer ~= nil then
        local resolvedOrder, exists = DrawLayers.TryGetLayerOrder(params.layer)

        if exists then
            layerOrder = resolvedOrder
        end
    end

    
    local request =
    {
        type = "rectangle",

        x = params.x or 0,
        y = params.y or 0,

        width = params.width,
        height = params.height,

        layerOrder = layerOrder,
    }

    -- Common draw properties
    local properties =
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

    for _, propertyName in ipairs(properties) do
        if params[propertyName] ~= nil then
            request[propertyName] = params[propertyName]
        end
    end

    return request
end

BasicShape = BasicShape or {}

BasicShape.CreateRectDrawRequest = createRectDrawRequest