-- Precision used when rounding calculated path distances to eliminate
-- insignificant floating-point differences between equivalent path lengths.
local DISTANCE_PRECISION = 1000000

local function calculateDistanceToWorldPosition(input)

    local nodePosX = input.nodePosX
    local nodePosY = input.nodePosY
    local worldPosX = input.worldPosX
    local worldPosY = input.worldPosY

    local deltaX = worldPosX - nodePosX
    local deltaY = worldPosY - nodePosY

    local distance =
        math.sqrt(deltaX * deltaX + deltaY * deltaY)

    distance =
        math.floor(distance * DISTANCE_PRECISION + 0.5) / DISTANCE_PRECISION

    return {
        distance = distance,
    }

end

local function createPathNode(input)

    local posX = input.posX
    local posY = input.posY
    local basePosX = input.basePosX
    local basePosY = input.basePosY
    local distanceToBase = calculateDistanceToWorldPosition({
        nodePosX = posX,
        nodePosY = posY,
        worldPosX = basePosX,
        worldPosY = basePosY,
    }).distance

    return {
        posX = posX,
        posY = posY,
        distanceToBase = distanceToBase,
    }

end

local function createStraight(input)

    local startPosX = input.startPosX
    local startPosY = input.startPosY
    local endPosX = input.endPosX
    local endPosY = input.endPosY
    local pathNodeSpacing = input.pathNodeSpacing

    local deltaX = endPosX - startPosX
    local deltaY = endPosY - startPosY

    local distance = math.sqrt(deltaX * deltaX + deltaY * deltaY)

    local directionX = deltaX / distance
    local directionY = deltaY / distance

    local segmentCount = math.floor(distance / pathNodeSpacing)

    local pathNodes = {}

    for i = 0, segmentCount do

        local posX = startPosX + directionX * i * pathNodeSpacing
        local posY = startPosY + directionY * i * pathNodeSpacing

        table.insert(pathNodes,
            createPathNode({
                posX = posX,
                posY = posY,
                basePosX = endPosX,
                basePosY = endPosY,
            })
        )

    end

    -- Ensure the final node is exactly at the end position.
    table.insert(pathNodes,
        createPathNode({
            posX = endPosX,
            posY = endPosY,
            basePosX = endPosX,
            basePosY = endPosY,
        })
    )

    return {
        pathNodes = pathNodes,
    }

end

Path = Path or {}

Path.CreateStraight = createStraight