local SPRITE_REQUIRED = {
    file = "string",
    width = "number",
    height = "number"
}

local SPRITE_RUNTIME = {
    "textureId"
}

local SPRITE_DEFAULTS = {
    folder = "",
    sourceMod = "",
}

local targetDefType = "sprite"

local function validateRequiredFields(modId, defName, requiredFields)

    local values = {}
    local missing = {}
    local invalid = {}

    for requiredField, expectedType in pairs(requiredFields) do

        local value, exists = Definition.TryGetPayload(
            targetDefType,
            defName,
            { requiredField },
            modId)

        if not exists or value == nil then

            table.insert(missing, requiredField)

        elseif type(value) ~= expectedType then

            table.insert(invalid,
            {
                field = requiredField,
                expected = expectedType,
                actual = type(value)
            })

        else
            values[requiredField] = value
        end
    end

    if #missing > 0 or #invalid > 0 then
        return false, nil, missing, invalid
    end

    return true, values, nil, nil
end

local function resolvePivotFields(modId, defName, width, height)

    local pivotX, existsPivotX = Definition.TryGetPayload(
            targetDefType, defName, { "pivotX" }, modId)

    local pivotY, existsPivotY = Definition.TryGetPayload(
            targetDefType, defName, { "pivotY" }, modId)

    if not existsPivotX or pivotX == nil then

        pivotX = width * 0.5

        local created = Definition.TryCreatePayload(
                targetDefType, defName, { "pivotX" }, pivotX, modId)

        if not created then 
            error(Localize("spriteValidation.lua.failedToCreateOptionalField",
                modId, defName, "pivotX"))
        end
    end

    if not existsPivotY or pivotY == nil then

        pivotY = height * 0.5

        local created = Definition.TryCreatePayload(
                targetDefType, defName, { "pivotY" }, pivotY, modId)

        if not created then
            error(Localize("spriteValidation.lua.failedToCreateOptionalField",
                modId, defName, "pivotY")) 
        end
    end

    return pivotX, pivotY
end

local function applyDefaultFields(modId, defName, optionalFields)

    local values = {}

    for field, defaultValue in pairs(optionalFields) do

        local value, exists = Definition.TryGetPayload(
                targetDefType, defName, { field }, modId)

        if not exists or value == nil then

            local created = Definition.TryCreatePayload(
                    targetDefType, defName, { field }, defaultValue, modId)

            if not created then
                error(Localize("spriteValidation.lua.failedToCreateOptionalField",
                    modId, defName, field)) 
            end

            value = defaultValue
        end

        values[field] = value
    end

    return values
end

local function createRuntimeFields(modId, defName, runtimeFields)

    for _, field in ipairs(runtimeFields) do

        local created = Definition.TryCreatePayload(
                targetDefType, defName, { field }, nil, modId)

        if not created then

            local value, exists = Definition.TryGetPayload(
                    targetDefType, defName, { field }, modId)

            if not exists then
                print(Localize("spriteValidation.lua.failedToCreateRuntimeField",
                    modId, defName, field))
            end
        end
    end
end

local function registerTexture(modId, defName, folder, file, sourceMod)

    if sourceMod == "" then
        sourceMod = modId
    end

    local registered, textureId = 
        Texture.TryRegister(folder, file, sourceMod, modId)

    if not registered then
        return false
    end

    Definition.SetPayload(
        targetDefType, defName, { "textureId" }, textureId, modId)

    return true
end

local function onSpriteCreated(modId, defType, defName, _)
    if defType ~= targetDefType then
        return
    end

    local ok, values, missing, invalidType = 
        validateRequiredFields(modId, defName, SPRITE_REQUIRED)

    if not ok then

        for _, field in ipairs(missing) do
            print(Localize(
                "spriteValidation.lua.missingProperty",
                modId, defName, field)) 
        end

        for _, invalid in ipairs(invalidType) do
            print(Localize(
                "spriteValidation.lua.invalidPropertyType",
                modId, defName, invalid.field, invalid.expected, invalid.actual))
        end

        return false
    end

    resolvePivotFields(modId, defName, values.width, values.height)

    createRuntimeFields(modId, defName, SPRITE_RUNTIME)

    local optionalValues = applyDefaultFields(modId, defName, SPRITE_DEFAULTS)

    local registered = registerTexture(
        modId, defName, optionalValues.folder, values.file, optionalValues.sourceMod)

    if not registered then
        return false
    end

    return true
end

Events.OnDefinitionCreated.Add(onSpriteCreated)

