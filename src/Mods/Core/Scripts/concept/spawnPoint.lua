local function createCircle(input)

    local centerX = input.centerX
    local centerY = input.centerY
    local radiusMeters = input.radiusMeters
    local pointCount = input.pointCount
    local startAngle = input.startAngle or 0

    local spawnPoints = {}

    local radiusPixels = radiusMeters * World.PixelPerMeter
    local angleStep = (math.pi * 2) / pointCount

    for i = 0, pointCount - 1 do
        local angle = startAngle + i * angleStep

        table.insert(spawnPoints, {
            x = centerX + math.cos(angle) * radiusPixels,
            y = centerY + math.sin(angle) * radiusPixels
        })
    end

    return {
        spawnPoints = spawnPoints
    }
end

local function debugDraw(input)

    local spawnPoint = input.spawnPoint
    local size = input.size or 10
    local r = input.r or 255
    local g = input.g or 0
    local b = input.b or 0
    local a = input.a or 255

    local screenCoord = World.WorldToScreen({
        worldX = spawnPoint.x,
        worldY = spawnPoint.y
    })

    local drawRequest = BasicShape.CreateRectDrawRequest(
    {
        x = screenCoord.screenX,
        y = screenCoord.screenY,

        width = size,
        height = size,

        r = r,
        g = g,
        b = b,
        a = a,

        layer = "ui",
    })

    DrawQueue.AddToQueue(cachedDrawRequest)
end


SpawnPoint = SpawnPoint or {}

SpawnPoint.CreateCircle = createCircle
SpawnPoint.DebugDraw = debugDraw
