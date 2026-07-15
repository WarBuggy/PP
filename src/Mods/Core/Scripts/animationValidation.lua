local ANIMATION_REQUIRED = {
    "baseComponent",
}

local ANIMATION_RUNTIME = {
    "componentList"
}

local COMPONENT_REQUIRED = {
    "defaultState",
}

local COMPONENT_RUNTIME = {
    "currentState"
}

local STATE_REQUIRED = {
}

local STATE_RUNTIME = {
    "currentFrame",
    "frameList"
}

local FRAME_REQUIRED = {
    "index"
}

local FRAME_RUNTIME = {
    "textureId",
    "layerOrder"
}

local CASCADE_FIELDS = {
    layer         = { required = true, },
    width         = { required = true, },
    height        = { required = true, },
    folder        = { required = true, },
    file          = { required = true, },

    spriteOffsetX = { required = false, default = 0 },
    spriteOffsetY = { required = false, default = 0 },
    offsetX       = { required = false, default = 0 },
    offsetY       = { required = false, default = 0 },
    flipX         = { required = false, default = false, },
    flipY         = { required = false, default = false, },
    posX          = { required = false, default = 0 },
    posY          = { required = false, default = 0 },
    pivotX        = { required = false, default = 0 },
    pivotY        = { required = false, default = 0 },
}

local targetDefType = "animation"

local function ensurePayload(modId, defName, path, value)

    local _, exists = Definition.TryGetPayload(
        targetDefType, defName, path, modId)

    if not exists then
        local created = Definition.TryCreatePayload(
            targetDefType, defName, path, value, modId)

        if not created then
            print(Localize(
                "animationValidation.lua.failedToCreatePayload",
                modId, defName, table.concat(path, ".")))
            return false
        end
    end

    Definition.SetPayload(targetDefType, defName, path, value, modId)
    return true
end

local function resolveCascadeField(modId, defName, framePath, fieldName, cascadeFields)

    local rule = CASCADE_FIELDS[fieldName]

    if not rule then
        return nil, false
    end

    -- Frame-level value has highest priority.
    local value, exists = Definition.TryGetPayload(
        targetDefType, defName, framePath, modId)

    if exists and value ~= nil then
        return value, true
    end

    -- Use already resolved cascade value.
    if cascadeFields and cascadeFields[fieldName] ~= nil then
        return cascadeFields[fieldName], true
    end

    -- Optional fields fall back to default.
    if not rule.required then
        return rule.default, true
    end

    -- Required field missing.
    return nil, false
end

local function copyPath(path)
    local result = {}

    for _, part in ipairs(path) do
        table.insert(result, part)
    end

    return result
end

local function createRuntimeFields(modId, defName, basePath, fields)
    for _, field in ipairs(fields) do

        local path = copyPath(basePath)
        table.insert(path, field)

        local created = Definition.TryCreatePayload(
            targetDefType,
            defName,
            path,
            nil,
            modId)

        if not created then
            local v, exists = Definition.TryGetPayload(
                targetDefType,
                defName,
                path,
                modId)
            print("FOUND " .. table.concat(path, ".") .. " value:" .. v)

            if not exists then
                print(Localize(
                    "animationValidation.lua.failedToCreateRuntimeField",
                    modId,
                    defName,
                    table.concat(path, ".")))
            end
        end
    end
end

local function validateRequiredFields(modId, defName, basePath, fields)

    local values = {}
    local missing = {}

    for _, field in ipairs(fields) do

        local path = copyPath(basePath)
        table.insert(path, field)

        local value, exists = Definition.TryGetPayload(
            targetDefType, defName, path, modId)

        if not exists or value == nil then
            print("not payload " .. path.concat("."))
            table.insert(missing, field)
        else
            values[field] = value
        end
    end

    if #missing > 0 then
        return false, missing
    end

    return true, values
end

local function rememberFields(
    modId, defName, basePath, fieldsToRemember, destinationTable)

    local remembered = destinationTable or {}

    for field, _ in pairs(fieldsToRemember) do

        local path = copyPath(basePath)
        table.insert(path, field)

        local value, exists = Definition.TryGetPayload(
            targetDefType, defName, path, modId)

        if exists then
            remembered[field] = value
        end
    end

    return remembered
end

local function buildCascadeFields(modId, defName, basePath, inheritedFields)
    local cascadeFields = {}

    if inheritedFields then
        for key, value in pairs(inheritedFields) do
            cascadeFields[key] = value
        end
    end

    rememberFields(modId, defName, basePath, CASCADE_FIELDS, cascadeFields)

    return cascadeFields
end

local function validateAndReportRequired(
    modId, defName, basePath, fields, localizationKey, ...)

    local extraArgs = {...}

    local ok, result = validateRequiredFields(modId, defName, basePath, fields)

    if ok then
        return true, result
    end

    for _, field in ipairs(result) do

        local args = { modId, defName }

        for _, value in ipairs(extraArgs) do
            table.insert(args, value)
        end

        table.insert(args, field)

        print(Localize(localizationKey, table.unpack(args)))
    end

    return false, result
end

local function tryRegisterTexture(defName, comp, state, frameKey, folder, file, modId)
    local sourceModId, exists = Animation.TryGetFrameProperty(defName, comp, state, frameKey, "sourceMod", modId)
    if not exists or type(sourceModId) ~= "string" or sourceModId == "" then
        sourceModId = modId
    end

    local ok, texId = Texture.TryRegister(folder, file, sourceModId, modId)
    if ok and texId then
        Animation.SetFrameProperty(defName, comp, state, frameKey, "textureId", texId, modId)
        return true
    else
        return false
    end
end

local function processFrame(
    modId, defName, compName, stateName, frameKey, cascadeFields)

    local basePath = { "components", compName, "states", stateName, "frames", frameKey }

    local ok, requiredValues = validateAndReportRequired(
        modId, defName, basePath, FRAME_REQUIRED,
        "animationValidation.lua.frameMissingProperty",
        compName, stateName, frameKey)

    if not ok then
        return false, nil
    end

    -- Create runtime fields
    createRuntimeFields(modId, defName, basePath, FRAME_RUNTIME)

    local resolvedFields = {}

    -- Resolve cascade fields
    for fieldName, _ in pairs(CASCADE_FIELDS) do

        local fieldPath = copyPath(basePath)
        table.insert(fieldPath, fieldName)

        local value, exists = resolveCascadeField(modId, defName, fieldPath, fieldName, cascadeFields)

        if not exists then
            print(Localize(
                "animationValidation.lua.frameMissingCascadeProperty",
                modId, defName, compName, stateName, frameKey, fieldName))

            return false, nil
        end

        resolvedFields[fieldName] = value
        ensurePayload(modId, defName, fieldPath, value)
    end


    -- Register texture after folder/file are resolved
    local registered = tryRegisterTexture(defName, compName, stateName, frameKey, 
        resolvedFields.folder, resolvedFields.file, modId)

    if not registered then
        return false, nil
    end

    return true, requiredValues.index
end

local function processState(modId, defName, compName, stateName, frames, inheritedFields)

    local basePath = { "components", compName, "states", stateName }

    local ok, requiredValues = validateAndReportRequired(
        modId, defName, basePath, STATE_REQUIRED, 
        "animationValidation.lua.stateMissingProperty",
        compName, stateName)

    if not ok then
        return false, 0
    end

    -- Create runtime properties.
    createRuntimeFields(modId, defName, basePath, STATE_RUNTIME) 

    local cascadeFields =
    buildCascadeFields(modId, defName, basePath, inheritedFields)

    -- Process frames.
    local validFrames = {}

    for frameKey, _ in pairs(frames) do

        local frameOk, index = processFrame(modId, 
            defName, compName, stateName, frameKey, cascadeFields)

        if frameOk then
            validFrames[frameKey] = index
        end
    end

    if next(validFrames) == nil then
        print(Localize(
            "animationValidation.lua.stateNoValidFrames",
            modId, defName, compName, stateName)) 

        return false, 0
    end

    -- Sort frames by index.
    local orderedFrames = {}

    for frameKey, index in pairs(validFrames) do
        table.insert(orderedFrames, {key = frameKey, index = index })
    end

    table.sort(orderedFrames, function(a, b)
        return a.index < b.index
    end)

    local frameList = LedgerArray.Create()

    for _, frame in ipairs(orderedFrames) do
        LedgerArray.InsertLast(frameList, frame.key)
    end

    Definition.SetPayload(targetDefType, defName,  
        { "components", compName, "states", stateName, "frameList" },
        frameList, modId)

    local frameCount = LedgerArray.Count(frameList)

    Definition.SetPayload(targetDefType, defName,
        { "components", compName, "states", stateName, "currentFrame" },
        frameCount, modId)

    return true, frameCount
end

local function processComponent(modId, defName, compName, states, inheritedFields)

    local basePath = { "components", compName }

    local ok, requiredValues = validateAndReportRequired(
        modId, defName, basePath, COMPONENT_REQUIRED, 
        "animationValidation.lua.compMissingProperty", 
        compName)

    if not ok then
        return false, 0, 0
    end

    createRuntimeFields(modId, defName, basePath, COMPONENT_RUNTIME)

    local cascadeFields = buildCascadeFields(modId, defName, basePath, inheritedFields)

    local defaultState = requiredValues.defaultState

    if type(defaultState) ~= "string" then
        print(Localize(
            "animationValidation.lua.compInvalidDefaultStateType",
            modId, defName, compName))

        return false, 0, 0
    end

    local totalFrameCount = 0
    local validStateCount = 0
    local validStates = {}

    for stateName, frames in pairs(states) do

        local stateOk, frameCount =
            processState(modId, defName, compName, stateName, frames, cascadeFields)

        if stateOk then
            validStates[stateName] = true
            validStateCount = validStateCount + 1
            totalFrameCount = totalFrameCount + frameCount
        end
    end

    if next(validStates) == nil then
        print(Localize(
            "animationValidation.lua.compNoValidStates",
            modId, defName, compName))

        return false, 0, 0
    end

    if not validStates[defaultState] then
        print(Localize(
            "animationValidation.lua.compInvalidDefaultState",
            modId, defName, compName, defaultState))

        return false, 0, 0
    end

    Definition.SetPayload(targetDefType, defName, 
        { "components", compName, "currentState" },
        defaultState, modId)

    return true, validStateCount, totalFrameCount
end

local function processAnimation(modId, defName, components)
    
    local ok, requiredValues = validateAndReportRequired(
        modId, defName, {}, ANIMATION_REQUIRED,
        "animationValidation.lua.animationMissingProperty")

    if not ok then
        return false, 0, 0, 0
    end
    
    createRuntimeFields(modId, defName, {}, ANIMATION_RUNTIME)

    local cascadeFields = buildCascadeFields(modId, defName, {}, nil)

    local baseComponent = requiredValues.baseComponent

    if type(baseComponent) ~= "string" or baseComponent == "" then
        print(Localize(
            "animationValidation.lua.animationInvalidBaseComponentType",
            modId, defName))

        return false, 0, 0, 0
    end

    local validCompCount = 0
    local totalStateCount = 0
    local totalFrameCount = 0

    local validComponents = {}
    local componentLedger = LedgerArray.Create()

    for compName, states in pairs(components) do

        local compOk, stateCount, frameCount =
            processComponent(modId, defName, compName, states, cascadeFields)

        if compOk then
            validComponents[compName] = true

            validCompCount = validCompCount + 1
            totalStateCount = totalStateCount + stateCount
            totalFrameCount = totalFrameCount + frameCount

            LedgerArray.InsertLast(componentLedger, compName)
        end
    end

    if next(validComponents) == nil then
        print(Localize(
            "animationValidation.lua.animationNoValidComponents",
            modId, defName))

        return false, 0, 0, 0
    end

    if not validComponents[baseComponent] then
        print(Localize(
            "animationValidation.lua.animationInvalidBaseComponent",
            modId, defName, baseComponent)) 

        return false, 0, 0, 0
    end

    Definition.SetPayload(targetDefType, defName,  
        { "componentList" }, componentLedger, modId)

    return true,
        validCompCount,
        totalStateCount,
        totalFrameCount
end

AnimationValidation = AnimationValidation or {}

AnimationValidation.ProcessAnimation = processAnimation