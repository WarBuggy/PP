local SPRITE_REQUEST_REQUIRED = {
    defName = "string",
    x = "number",
    y = "number",
    layer = "string",
}

local SPRITE_DATA_FIELDS = {
    "textureId",
    "width",
    "height",
    "pivotX",
    "pivotY",
}

local DRAW_REQUEST_DEFAULTS = {
    scaleX = 1,
    scaleY = 1,

    rotation = 0,

    flipX = false,
    flipY = false,

    offsetX = 0,
    offsetY = 0,

    r = 255,
    g = 255,
    b = 255,
    a = 255,
}

local targetDefType = "sprite"

local function getSpriteProperty(defName, property, modId)

    local value, exists = Definition.TryGetPayload(
        targetDefType, defName, { property }, modId)

    if not exists or value == nil then
        error(Localize("sprite.lua.missingProperty",
            modId, defName, property))
    end

    return value
end

local function getSpriteData(defName, modId)

    local sprite = {}

    for _, field in ipairs(SPRITE_DATA_FIELDS) do
        sprite[field] = getSpriteProperty(
            defName, field, modId)
    end

    return sprite
end

local function validateRequestFields(request, requiredFields)

    local values = {}
    local missing = {}
    local invalid = {}

    for field, expectedType in pairs(requiredFields) do

        local value = request[field]

        if value == nil then

            table.insert(missing, field)

        elseif type(value) ~= expectedType then

            table.insert(invalid,
            {
                field = field,
                expected = expectedType,
                actual = type(value)
            })

        else
            values[field] = value
        end
    end

    if #missing > 0 or #invalid > 0 then
        return false, missing, invalid
    end

    return true, values
end

local function applyDefaultRequestFields(
    request, defaultFields, drawRequest)

    for field, defaultValue in pairs(defaultFields) do

        local value = request[field]

        if value == nil then
            value = defaultValue
        end

        drawRequest[field] = value
    end
end

local function createDrawRequest(request)

    local ok, requiredInputs, missing, invalid =
        validateRequestFields(request, SPRITE_REQUEST_REQUIRED)

    if not ok then
        for _, field in ipairs(missing) do
            print(Localize("sprite.lua.requestMissingProperty", field))
        end

        for _, invalidField in ipairs(invalid) do
            print(Localize("sprite.lua.requestInvalidPropertyType",
                invalidField.field, invalidField.expected, invalidField.actual))
        end

        return nil, false
    end

    local spriteModId = request.spriteModId or Mods.CurrentId()
    local spriteData = getSpriteData(requiredInputs.defName, spriteModId)

    local resolvedOrder, existsLayer = 
        DrawLayers.TryGetLayerOrder(requiredInputs.layer)

    if not existsLayer then
        print(Localize("sprite.lua.invalidLayer", requiredInputs.layer))
        return nil, false
    end

    local drawRequest =
    {
        type = "sprite",

        textureId = spriteData.textureId,

        x = requiredInputs.x,
        y = requiredInputs.y,

        layerOrder = resolvedOrder,

        width = request.width or spriteData.width,
        height = request.height or spriteData.height,

        pivotX = request.pivotX or spriteData.pivotX,
        pivotY = request.pivotY or spriteData.pivotY,
    }

    applyDefaultRequestFields(request, DRAW_REQUEST_DEFAULTS, drawRequest)

    return drawRequest, true
end

Sprite = Sprite or {}

Sprite.CreateDrawRequest = createDrawRequest