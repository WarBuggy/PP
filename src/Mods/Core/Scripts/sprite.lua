local SPRITE_REQUEST_REQUIRED = {
    spriteName = "string",
    pX = "number",
    pY = "number",
    pWidth = "number",
    pHeight = "number",
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

local function getSpriteProperty(input)

    local defName = input.defName
    local property = input.property
    local modId = input.modId

    local value, exists = Definition.TryGetPayload(
        targetDefType, defName, { property }, modId)

    if not exists or value == nil then
        error(Localize("sprite.lua.missingProperty",
            modId, defName, property))
    end

    return {
        value = value,
    }
end

local function getSpriteData(input)

    local defName = input.defName
    local modId = input.modId

    local sprite = {}

    for _, field in ipairs(SPRITE_DATA_FIELDS) do
        sprite[field] = getSpriteProperty({
            defName = defName,
            property = field,
            modId = modId,
        }).value
            
    end

    return {
        sprite = sprite,
    }
end

local function validateRequestFields(input)

    local request = input.request
    local requiredFields = input.requiredFields

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
        return {
            success = false,
            missing = missing,
            invalid = invalid,
        }
    end

    return {
        success = true, 
        values = values,
    }
end

local function applyDefaultRequestFields(input)
    local request = input.request
    local defaultFields = input.defaultFields
    local drawRequest = input.drawRequest

    for field, defaultValue in pairs(defaultFields) do

        local value = request[field]

        if value == nil then
            value = defaultValue
        end

        drawRequest[field] = value
    end
end

local function calculateScale(input)

    local request = input.request
    local pWidth = request.pWidth
    local pHeight = request.pHeight
    local spriteWidth = input.spriteWidth
    local spriteHeight = input.spriteHeight

    return {
        scaleX = pWidth / spriteWidth,
        scaleY = pHeight / spriteHeight,
    }
end

local function createDrawRequest(input)

    local request = input.request

    local validateResult = validateRequestFields({
        request = request, 
        requiredFields = SPRITE_REQUEST_REQUIRED,
    })

    if not validateResult.success then
        
        local missing = validateResult.missing
        for _, field in ipairs(missing) do
            print(Localize("sprite.lua.requestMissingProperty", request.spriteName, request.spriteModId, field))
        end

        local invalid = validateResult.invalid
        for _, invalidField in ipairs(invalid) do
            print(Localize("sprite.lua.requestInvalidPropertyType",
                invalidField.field, invalidField.expected, invalidField.actual))
        end

        return {
            success = false,
        }
    end

    local requiredInputs = validateResult.values
    local spriteModId = request.spriteModId or Mods.CurrentId()
    local spriteData = getSpriteData({
        defName = requiredInputs.spriteName, 
        modId = spriteModId,
    }).sprite

    local scale = calculateScale({
        request = request,
        spriteWidth = spriteData.width,
        spriteHeight = spriteData.height,
    })

    local resolvedOrder, existsLayer = 
        DrawLayers.TryGetLayerOrder(requiredInputs.layer)

    if not existsLayer then
        print(Localize("sprite.lua.invalidLayer", requiredInputs.layer))
        return {
            success = false,
        }
    end

    local drawRequest =
    {
        type = "sprite",

        textureId = spriteData.textureId,

        x = requiredInputs.pX,
        y = requiredInputs.pY,

        layerOrder = resolvedOrder,

        width = spriteData.width,
        height = spriteData.height,

        pivotX = request.pivotX or spriteData.pivotX,
        pivotY = request.pivotY or spriteData.pivotY,

        scaleX = scale.scaleX,
        scaleY = scale.scaleY,
    }

    applyDefaultRequestFields({
        request = request,
        defaultFields = DRAW_REQUEST_DEFAULTS,
        drawRequest = drawRequest,
    })

    return {
        success = true,
        drawRequest = drawRequest
    }
end

Sprite = Sprite or {}

Sprite.CreateEngineDrawRequest = createDrawRequest