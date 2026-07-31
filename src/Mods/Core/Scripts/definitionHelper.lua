local function loadSetting(schema)

    local setting = {}

    for _, source in ipairs(schema) do

        local targetDefType = source.targetDefType
        local defName = source.defName

        for definitionParam, info in pairs(source.params) do

            local resultParam = info.result or definitionParam

            local value, exists = Definition.TryGetPayload(
                    targetDefType, defName, { definitionParam })

            if not exists then

                if info.defaultValue ~= nil then
                    value = info.defaultValue
                else
                    error(Localize(
                        "definitionHelper.lua.missingSettingParam",
                        targetDefType, defName, definitionParam))
                end

            end

            setting[resultParam] = value
        end
    end

    return setting
end

local function tryParseAspectRatio(input)

    local ratioString = input.ratioString

    if type(ratioString) ~= "string" then
        print(Localize("definitionHelper.lua.aspectRatioNotString",
            tostring(ratioString)))
        return { success = false, }
    end

    local aspectWidth, aspectHeight = ratioString:match("^(%d+):(%d+)$")

    if aspectWidth == nil or aspectHeight == nil then
        print(Localize("definitionHelper.lua.invalidAspectRatioFormat",
            ratioString))
        return { success = false, }
    end

    aspectWidth = tonumber(aspectWidth)
    aspectHeight = tonumber(aspectHeight)

    if aspectWidth <= 0 or aspectHeight <= 0 then
        print(Localize("definitionHelper.lua.invalidAspectRatioValue",
            ratioString))
        return { success = false, }
    end

    return {
        success = true,
        aspectWidth = aspectWidth,
        aspectHeight = aspectHeight,
    }

end

DefinitionHelper = DefinitionHelper or {}

DefinitionHelper.LoadSetting = loadSetting
DefinitionHelper.TryParseAspectRatio = tryParseAspectRatio
