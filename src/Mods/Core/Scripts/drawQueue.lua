
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

-- Collect frames for a single animation
local function collectFramesForAnimation(modId, animationName)
    local frames = {}
    local components = Animation.TryGetComponentList(animationName, modId)
    if not components then return frames end
    for compName in LedgerArray.Iterator(components) do
        if type(compName) == "string" and compName ~= "" then
            local state, _ = Animation.TryGetCompProperty(animationName, compName, "currentState", modId)
            local frameIndex, frameKey, _ = Animation.TryGetCurrentFrameInfo(animationName, compName, state, modId)

            local textureId, _  = Animation.TryGetFrameProperty(animationName, compName, state, frameKey, "textureId", modId)
            local posX, _       = Animation.TryGetFrameProperty(animationName, compName, state, frameKey, "posX", modId) or 0
            local posY, _       = Animation.TryGetFrameProperty(animationName, compName, state, frameKey, "posY", modId) or 0
            local width, _      = Animation.TryGetFrameProperty(animationName, compName, state, frameKey, "width", modId) or 0
            local height, _     = Animation.TryGetFrameProperty(animationName, compName, state, frameKey, "height", modId) or 0
            local offsetX, _    = Animation.TryGetFrameProperty(animationName, compName, state, frameKey, "offsetX", modId) or 0
            local offsetY, _    = Animation.TryGetFrameProperty(animationName, compName, state, frameKey, "offsetY", modId) or 0
            local flipX, _      = Animation.TryGetFrameProperty(animationName, compName, state, frameKey, "flipX", modId) or false
            local flipY, _      = Animation.TryGetFrameProperty(animationName, compName, state, frameKey, "flipY", modId) or false
            local layerOrder, _ = tryGetFrameLayerOrder(animationName, compName, state, frameKey, modId) 
            
            table.insert(frames, {
                layerOrder = layerOrder,
                textureId  = textureId,
                posX       = posX,
                posY       = posY,
                width      = width,
                height     = height,
                offsetX    = offsetX,
                offsetY    = offsetY,
                flipX      = flipX,
                flipY      = flipY 
            })
        end
    end

    return frames
end

-- Collect all frames from all GOWI
local function collectAllFrames()
    local drawQueue = {}

    local gowiLedger, exists = GameData.TryGet("gowi.list", "Core")
    if not exists or not gowiLedger then
        print(Localize("drawQueue.lua.noGowiLedgerFound"))
        return drawQueue
    end

    for pair in LedgerMap.Iterator(gowiLedger) do
        if type(pair) == "table" then
            local animationName = pair.Key
            local modId = pair.Value
            if type(animationName) == "string" and type(modId) == "string" then
                local frames = collectFramesForAnimation(modId, animationName)
                for _, frame in ipairs(frames) do
                    table.insert(drawQueue, frame)
                end
            end
        end
    end

    return drawQueue
end

-- Sort draw queue by layerOrder
local function sortDrawQueue(drawQueue)
    table.sort(drawQueue, function(a, b)
        return a.layerOrder < b.layerOrder
    end)
end

-- Submit frames to Drawing
local function submitDrawQueue(drawQueue)
    for _, frame in ipairs(drawQueue) do
        Drawing.AddRequest(
            frame.textureId,
            {frame.posX, frame.posY},
            0,             -- rotation
            {1, 1},        -- scale
            nil,           -- color
            0,             -- layerDepth
            frame.width, frame.height,
            frame.offsetX, frame.offsetY,
            frame.flipX, frame.flipY
        )
    end
end

-- Main draw queue processing
local function processGowi()
    local drawQueue = collectAllFrames()
    if #drawQueue == 0 then return end

    sortDrawQueue(drawQueue)
    submitDrawQueue(drawQueue)
end

Events.OnDraw.Add(processGowi)
