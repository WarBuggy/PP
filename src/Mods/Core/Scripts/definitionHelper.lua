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
                error(Localize("definitionHelper.lua.missingSettingParam",
                    targetDefType, defName, definitionParam))
            end

            setting[resultParam] = value
        end
    end

    return setting
end

DefinitionHelper = DefinitionHelper or {}
DefinitionHelper.LoadSetting = loadSetting