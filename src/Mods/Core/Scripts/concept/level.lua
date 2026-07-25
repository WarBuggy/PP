local cachedSpawnPoints = nil

local function testInit(input)

    local worldWidth = World.Width
    local worldHeight = World.Height

    local result = SpawnPoint.CreateCircle({
        centerX = 0,
        centerY = 0,
        radiusMeters = ,
        pointCount = 8
    })

    cachedSpawnPoints = result.spawnPoints
end