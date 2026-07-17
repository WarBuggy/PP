local function collectDrawRequests()
    local drawRequestLedger, exists = GameData.TryGet("drawRequest.list", "Core")

    if not exists or not drawRequestLedger then
        print(Localize("drawQueue.lua.noDrawRequestLedgerFound"))
        return {}
    end

    local requests = {}
    for request in LedgerArray.Iterator(drawRequestLedger) do
        table.insert(requests, request)
    end

    return requests
end


local function sortDrawQueue(drawQueue)
    table.sort(drawQueue, function(a, b)
        return (a.layerDepth or 0) < (b.layerDepth or 0)
    end)
end


local function submitDrawQueue(drawQueue)
    for index, request in ipairs(drawQueue) do
        Drawing.AddRequest(request)
    end
end


local function processDrawQueue()
    local drawQueue = collectDrawRequests()

    if #drawQueue == 0 then
        return
    end

    sortDrawQueue(drawQueue)
    submitDrawQueue(drawQueue)
end

Events.OnDraw.Add(processDrawQueue)