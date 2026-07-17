function addToQueue(request)

    if type(request) ~= "table" then
        print(Localize("system.drawRequests.requestMustBeTable"))
    end

    local drawRequestLedger, exists =
        GameData.TryGet("drawRequest.list", "Core")

    if not exists or not drawRequestLedger then
        print(Localize("drawQueue.lua.noDrawRequestLedgerFound"))
    end

    LedgerArray.InsertLast(drawRequestLedger, request)
end


function addListToQueue(requests)

    if type(requests) ~= "table" then
        print(Localize("system.drawRequests.requestListMustBeTable"))
    end

    for _, request in ipairs(requests) do
        addToQueue(request)
    end
end

local function collectDrawRequests(drawRequestLedger)

    local requests = {}

    for request in LedgerArray.Iterator(drawRequestLedger) do
        table.insert(requests, request)
    end

    return requests
end

local function sortDrawQueue(drawQueue)
    table.sort(drawQueue, function(a, b)
        return (a.layerOrder or 0) < (b.layerOrder or 0)
    end)
end

local function submitDrawQueue(drawQueue)
    for _, request in ipairs(drawQueue) do
        Drawing.AddRequest(request)
    end
end

local function processDrawQueue()

    local drawRequestLedger, exists =
        GameData.TryGet("drawRequest.list", "Core")

    if not exists or not drawRequestLedger then
        print(Localize("drawQueue.lua.noDrawRequestLedgerFound"))
        return
    end

    local drawQueue = collectDrawRequests(drawRequestLedger)

    if #drawQueue == 0 then
        return
    end

    sortDrawQueue(drawQueue)

    submitDrawQueue(drawQueue)

end

Events.OnDraw.Add(processDrawQueue)

DrawQueue = DrawQueue or {}

DrawQueue.AddToQueue = addToQueue
DrawQueue.AddListToQueue = addListToQueue