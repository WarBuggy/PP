local function createCircle(input)

    local posX = input.posX
    local posY = input.posY
    local radiusMeters = input.radiusMeters
    local pointCount = input.pointCount

    local startAngle =
        math.rad(input.startAngle or 0)

    local spawnPoints = {}

    local angleStep = (math.pi * 2) / pointCount

    for i = 0, pointCount - 1 do

        local angle = startAngle + i * angleStep

        table.insert(spawnPoints,
        {
            posX = posX + math.cos(angle) * radiusMeters,
            posY = posY + math.sin(angle) * radiusMeters,
        })
    end

    return
    {
        spawnPoints = spawnPoints
    }
end

local function debugCreateDrawRequest(input)

    local spawnPoint = input.spawnPoint
    local size = input.size or 1
    local r = input.r or 255
    local g = input.g or 0
    local b = input.b or 0
    local a = input.a or 255

    local halfSize = size / 2

    local drawRequest = WorldRenderer.CreateRectDrawRequest(
    {
        posX = spawnPoint.posX - halfSize,
        posY = spawnPoint.posY - halfSize,

        width = size,
        height = size,

        r = r,
        g = g,
        b = b,
        a = a,

        layer = "ui",
    })

    return drawRequest
end


SpawnPoint = SpawnPoint or {}

SpawnPoint.CreateCircle = createCircle
SpawnPoint.DebugCreateDrawRequest = debugCreateDrawRequest
