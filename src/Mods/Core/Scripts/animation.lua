local targetDefType = "animation"

local SPTITE_DRAW_REQUEST_PROPERTIES =
{
    "textureId",

    "x",
    "y",

    "width",
    "height",

    "offsetX",
    "offsetY",

    "pivotX",
    "pivotY",

    "flipX",
    "flipY"
}

local function tryGetBaseComponent(animation, modId)
    return Definition.TryGetPayload(targetDefType, animation, {"baseComponent"}, modId)
end

local function tryGetComponentList(animation, modId)
    return Definition.TryGetPayload(targetDefType, animation, {"componentList"}, modId)
end

local function tryGetFrameProperty(animation, comp, state, frame, property, modId)
    return Definition.TryGetPayload(targetDefType, animation, 
        {"components", comp, "states", state, "frames", frame, property}, modId)
end

local function setFrameProperty(animation, comp, state, frame, property, value, modId)
    Definition.SetPayload(targetDefType, animation,
        {"components", comp, "states", state, "frames", frame, property}, 
        value, modId)
end

local function tryGetStateProperty(animation, comp, state, property, modId)
    return Definition.TryGetPayload(targetDefType, animation, 
        {"components", comp, "states", state, property}, modId)
end

local function setStateProperty(animation, comp, state, property, value, modId)
    Definition.SetPayload(targetDefType, animation,
        {"components", comp, "states", state, property}, 
        value, modId)
end

local function tryGetCompProperty(animation, comp, property, modId)
    return Definition.TryGetPayload(targetDefType, animation, 
        {"components", comp, property}, modId)
end

local function setCurrentState(animation, comp, currentState, modId)
    Definition.SetPayload(targetDefType, animation, 
        {"components", comp, "currentState"}, 
        currentState, modId)
end

local function tryGetFrameLayerOrder(animationName, compName, stateName, frameKey, modId)

    -- Check cached layerOrder first
    local layerOrder, exists = Animation.TryGetFrameProperty(
            animationName, compName, stateName, frameKey, "layerOrder", modId)

    if exists and layerOrder ~= nil then
        return layerOrder, true
    end

    -- Get raw layer name
    local layerName, layerExists = Animation.TryGetFrameProperty( 
            animationName, compName, stateName, frameKey, "layer", modId)

    if not layerExists or type(layerName) ~= "string" then
        return nil, false
    end

    -- Resolve layer order
    local resolvedOrder, orderExists = DrawLayers.TryGetLayerOrder(layerName)

    if not orderExists then
        return nil, false
    end

    -- Cache resolved value
    Animation.SetFrameProperty(
        animationName, compName, stateName, frameKey, "layerOrder", resolvedOrder, modId)

    return resolvedOrder, true
end

local function tryGetCurrentFrameInfo(animation, comp, state, modId)
    local currentFrame, exists = tryGetStateProperty(animation, comp, state, "currentFrame", modId)
    if not exists then 
        return nil, nil, false
    end

    local frameList, flExists = tryGetStateProperty(animation, comp, state, "frameList", modId)
    if not flExists or LedgerArray.Count(frameList) == 0 then
        return nil, nil, false
    end

    local frameKey, keyExists = LedgerArray.TryGet(frameList, currentFrame)
    if not keyExists then
        return nil, nil, false
    end

    return currentFrame, frameKey, true
end

local function collectAnimationData(modId, defName, defPaths)
    local components = {}

    local frameIndexPattern =
        "definition%.animation%." .. defName ..
        "%.payload%.components%.([^%.]+)%.states%.([^%.]+)%.frames%.([^%.]+)%.index$"

    for _, path in ipairs(defPaths) do
        local comp, state, frameKey = string.match(path, frameIndexPattern)

        if comp then
            local indexValue, exists = tryGetFrameProperty(defName, comp, state, frameKey, "index", modId)
            
            if exists then
                components[comp] = components[comp] or {}
                components[comp][state] = components[comp][state] or {}
                components[comp][state][frameKey] = indexValue
            end
        end
    end

    return components
end

local function onAnimationCreated(modId, defType, defName, defPaths)
    if defType ~= targetDefType then
        return
    end
    
    local componentsData = collectAnimationData(modId, defName, defPaths)

    local ok, compCount, stateCount, frameCount =
        AnimationValidation.ProcessAnimation(modId, defName, componentsData) 

    if not ok then return end

    print(Localize("animation.lua.animationPassValidation", modId, defName, compCount, stateCount, frameCount))
end

local function createDrawRequests(modId, animationName)
    local requests = {}

    local components = tryGetComponentList(animationName, modId)
    if not components then
        return requests
    end

    for compName in LedgerArray.Iterator(components) do

        if type(compName) == "string" and compName ~= "" then

            local state, exists =
                tryGetCompProperty(animationName, compName, "currentState", modId)

            if exists then

                local _, frameKey, frameExists =
                    tryGetCurrentFrameInfo(animationName, compName, state, modId)

                if frameExists then

                    local request = { type = "sprite" }

                    for _, propertyName in ipairs(SPTITE_DRAW_REQUEST_PROPERTIES) do

                        local value, _ =
                            tryGetFrameProperty(
                                animationName, compName, state, frameKey, propertyName, modId)

                        if value ~= nil then
                            request[propertyName] = value
                        end
                    end

                    local layerOrder, _ =
                        tryGetFrameLayerOrder(
                            animationName, compName, state, frameKey, modId) 
                    request.layerOrder = layerOrder or 0
                    table.insert(requests, request)
                end
            end
        end
    end

    return requests
end

Events.OnDefinitionCreated.Add(onAnimationCreated)

-- Animation API
Animation = Animation or {}

Animation.CreateDrawRequests = createDrawRequests
Animation.CollectRenderRequest = collectFramesForAnimation
Animation.TryGetBaseComponent = tryGetBaseComponent
Animation.TryGetComponentList = tryGetComponentList
Animation.TryGetFrameProperty = tryGetFrameProperty
Animation.SetFrameProperty = setFrameProperty
Animation.TryGetStateProperty = tryGetStateProperty
Animation.SetStateProperty = setStateProperty
Animation.SetCurrentFrame = function(animation, comp, state, value, modId)
    setStateProperty(animation, comp, state, "currentFrame", value, modId)
end
Animation.TryGetCompProperty = tryGetCompProperty
Animation.SetCurrentState = setCurrentState

local function setCurrentFrameKey(animation, comp, state, frameKey, modId)
    local frameList, exists = tryGetStateProperty(animation, comp, state, "frameList", modId)
    if not exists or LedgerArray.Count(frameList) == 0 then
        return nil, false
    end

    local frameIndex = LedgerArray.IndexOf(frameList, frameKey)
    if  frameIndex == 0 then
        return nil, false
    end

    -- Set the currentFrame index
    setStateProperty(animation, comp, state, "currentFrame", frameIndex, modId)
    return frameIndex, true
end
Animation.SetCurrentFrameKey = setCurrentFrameKey

Animation.TryGetCurrentFrameInfo = tryGetCurrentFrameInfo

