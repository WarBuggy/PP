local ZOOM_LEVEL_ACCEPTED = {
    viewRadius = "number",
    multiplier = "number",
}

local targetDefType = "zoomLevel"

local function buildAcceptedFieldsString(input)

    local acceptedFields = input.acceptedFields

    local names = {}

    for field in pairs(acceptedFields) do
        table.insert(names, "'" .. field .. "'")
    end

    table.sort(names)

    local acceptedFieldsString = table.concat(names, " or ")

    return {
        acceptedFieldsString = acceptedFieldsString
    }
end

local function validateAcceptedFields(input)
    local modId = input.modId
    local defName = input.defName
    local acceptedFields = input.acceptedFields

    local values = {}

    for field, expectedType in pairs(acceptedFields) do

        local value, exists = Definition.TryGetPayload(
            targetDefType, defName, { field }, modId)

        if exists and value ~= nil then

            if type(value) ~= expectedType then

                print(Localize("zoomLevelValidation.lua.invalidPropertyType",
                    modId, defName, field, expectedType, type(value)))

            else
                values[field] = value
            end
        end
    end

    if next(values) == nil then
        local acceptedFieldsString = buildAcceptedFieldsString({ 
            acceptedFields = acceptedFields, 
        }).acceptedFieldsString

        print(Localize("zoomLevelValidation.lua.missingRequiredProperty",
            modId, defName, acceptedFieldsString))

        return {
            validated = false, 
            values = nil,
        }
    end

    return {
        validated = true, 
        values = values,
    }
end

local function onZoomLevelCreated(modId, defType, defName, _)
    
    if defType ~= targetDefType then
        return
    end

    local result = validateAcceptedFields({
        modId = modId,
        defName = defName,
        acceptedFields = ZOOM_LEVEL_ACCEPTED,
    })

    if not result.validated then
        return
    end

    local zoomLevelArray, exists = GameData.TryGet("zoomLevel.list", "Core")

    if not exists or not zoomLevelArray then
        print(Localize("zoomLevelValidation.lua.noZoomLevelListFound", defName))
        return
    end

    LedgerArray.InsertFirst(zoomLevelArray, { 
        name = defName, 
        modId = modId, 
    })
end

Events.OnDefinitionCreated.Add(onZoomLevelCreated)