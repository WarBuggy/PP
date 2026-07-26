local cachedSpawnPoints = nil
local cachedSpawnPointDrawRequests = {}

local movementHz = 60
local slowestEnemyMetersPerSecond = 1
local pathNodeSpacing = slowestEnemyMetersPerSecond / movementHz
local cachedPaths = {}

local cachedMockupEnemies = {}
local lastClosestEnemy = nil
local function createMockupEnemies()

    cachedMockupEnemies = {}

    local enemyCount = 15
    local count = 0

    for _ = 1, enemyCount do
        count = count + 1

        local metersPerSecond =
            1 + (math.random() * 3)

        table.insert(cachedMockupEnemies, {
            name = "E" .. count,
            path = cachedPaths[
                math.random(#cachedPaths)
            ],

            pathNodeIndex = 1,
            direction = 1,

            nodesPerSecond =
                metersPerSecond / pathNodeSpacing,
            nodeAccumulator = 0,

            width =
                0.5 + (math.random() * 1.5),

            height =
                0.5 + (math.random() * 1.5),

            r = math.random(0, 255),
            g = math.random(0, 255),
            b = math.random(0, 255),
        })
    end

end
local predefinedMockupEnemies1 = {}
local function createPredefinedMockupEnemies1()
    predefinedMockupEnemies1 = {
        {
            name = "E1",
            path = cachedPaths[1],
            pathNodeIndex = 1,
            direction = 1,

            nodesPerSecond = 120,
            nodeAccumulator = 0,

            width = 1.0,
            height = 1.0,

            r = 255,
            g = 0,
            b = 0,
        },
        {
            name = "E2",
            path = cachedPaths[2],
            pathNodeIndex = 1,
            direction = 1,

            nodesPerSecond = 150,
            nodeAccumulator = 0,

            width = 1.2,
            height = 1.2,

            r = 0,
            g = 255,
            b = 0,
        },
        {
            name = "E3",
            path = cachedPaths[3],
            pathNodeIndex = 1,
            direction = 1,

            nodesPerSecond = 150,
            nodeAccumulator = 0,

            width = 0.8,
            height = 0.8,

            r = 0,
            g = 0,
            b = 255,
        },
        {
            name = "E4",
            path = cachedPaths[4],
            pathNodeIndex = 1,
            direction = 1,

            nodesPerSecond = 100,
            nodeAccumulator = 0,

            width = 1.5,
            height = 1.5,

            r = 255,
            g = 255,
            b = 0,
        },
    }
end

local function findClosestEnemy(input)

    local closestEnemies =
        input.closestEnemies

    local closestEnemy = nil

    if #closestEnemies > 0 then

        if lastClosestEnemy ~= nil then

            for _, enemy in ipairs(closestEnemies) do

                if enemy == lastClosestEnemy then

                    closestEnemy = enemy
                    break

                end

            end

        end

        if closestEnemy == nil then

            closestEnemy = closestEnemies[1]

        end

    end

    lastClosestEnemy = closestEnemy

    return {
        closestEnemy = closestEnemy,
    }

end

local function updateMockupEnemies(input)

    local deltaTime = input.deltaTime
    local mockupEnemies = input.mockupEnemies

    local closestEnemies = {}
    local closestDistanceToBase = math.huge

    for _, enemy in ipairs(mockupEnemies) do

        enemy.nodeAccumulator =
            enemy.nodeAccumulator +
            (enemy.nodesPerSecond * deltaTime)

        local nodesToAdvance =
            math.floor(enemy.nodeAccumulator)

        enemy.nodeAccumulator =
            enemy.nodeAccumulator % 1

        enemy.pathNodeIndex =
            enemy.pathNodeIndex +
            (nodesToAdvance * enemy.direction)

        local pathNodeCount =
            #enemy.path.pathNodes

        if enemy.pathNodeIndex >= pathNodeCount then

            enemy.pathNodeIndex = pathNodeCount
            enemy.direction = -1

        elseif enemy.pathNodeIndex <= 1 then

            enemy.pathNodeIndex = 1
            enemy.direction = 1

        end

        local pathNode =
            enemy.path.pathNodes[enemy.pathNodeIndex]

        local distanceToBase =
            pathNode.distanceToBase

        if distanceToBase < closestDistanceToBase then

            closestDistanceToBase =
                distanceToBase

            closestEnemies = { enemy }

        elseif distanceToBase == closestDistanceToBase then

            table.insert(closestEnemies, enemy)

        end

        DrawQueue.AddToQueue(
            WorldRenderer.CreateRectDrawRequest({
                posX = pathNode.posX - (enemy.width / 2),
                posY = pathNode.posY - (enemy.height / 2),

                width = enemy.width,
                height = enemy.height,

                r = enemy.r,
                g = enemy.g,
                b = enemy.b,
                a = 255,

                layer = "ui"
            })
        )

    end

    local closestEnemy =
        findClosestEnemy({
            closestEnemies = closestEnemies,
        }).closestEnemy

    if closestEnemy ~= nil then

        local pathNode =
            closestEnemy.path.pathNodes[
                closestEnemy.pathNodeIndex
            ]

        DrawQueue.AddToQueue(
            WorldRenderer.CreateRectDrawRequest({
                posX = pathNode.posX - 1.5,
                posY = pathNode.posY - 1.5,

                width = 3,
                height = 3,

                r = 255,
                g = 0,
                b = 0,
                a = 128,

                layer = "ui"
            })
        )

    end

end

local function testInit(input)

    local worldHeight = World.GetSize().height

    cachedSpawnPoints = SpawnPoint.CreateCircle(
    {
        posX = 0,
        posY = 0,

        radiusMeters = worldHeight / 2,

        pointCount = 10,
    }).spawnPoints

    for _, spawnPoint in ipairs(cachedSpawnPoints) do
        local request = SpawnPoint.DebugCreateDrawRequest({
            spawnPoint = spawnPoint,
        })

        table.insert(cachedSpawnPointDrawRequests, request)
    end

    local basePosition = Base.GetPosition()

    cachedPaths = {}

    for _, spawnPoint in ipairs(cachedSpawnPoints) do
        table.insert(
            cachedPaths,
            Path.CreateStraight({
                startPosX = spawnPoint.posX,
                startPosY = spawnPoint.posY,

                endPosX = basePosition.posX,
                endPosY = basePosition.posY,

                pathNodeSpacing = pathNodeSpacing,
            })
        )
    end

    createMockupEnemies()
    createPredefinedMockupEnemies1()

end

Level = Level or {}

Level.Init = testInit

local function draw(deltaTime, totalTime)

    if not cachedSpawnPointDrawRequests then
        return
    end

    for _, request in ipairs(cachedSpawnPointDrawRequests) do
        DrawQueue.AddToQueue(request)
    end

    updateMockupEnemies({ 
        deltaTime = deltaTime, 
        mockupEnemies = predefinedMockupEnemies1,
    })
end

Events.OnUpdate.Add(draw)