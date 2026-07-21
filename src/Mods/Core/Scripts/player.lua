-- Local constant: seconds per frame
local FRAME_DURATION = 0.12

-- Store accumulated time for the player animation
local frameTimer = 0

local pcPosition = nil

local function updateAnimation(deltaTime, totalTime)

    local bounds = PlayableBox.GetBounds()

    if not bounds then
        return
    end

    local boxWidth = 100
    local boxHeight = 130

    -- Bottom center of playable box
    local x = (bounds.left + bounds.right - boxWidth) * 0.5
    local y = bounds.bottom - boxHeight

    local request = BasicShape.CreateRectDrawRequest(
    {
        x = x,
        y = y,

        width = boxWidth,
        height = boxHeight,

        r = 255,
        g = 0,
        b = 255,

        layer = "mcHeight",
    })

    DrawQueue.AddToQueue(request)
end

Events.OnUpdate.Add(updateAnimation)


local function calculatePcPosition(playableBoxBounds)
    return {
        x = (playableBoxBounds.left + playableBoxBounds.right) * 0.5,
        y = playableBoxBounds.bottom
    }
end

local function init()
    local playableBoxBounds = PlayableBox.GetBounds()
    calculatePcPosition(playableBoxBounds)
end 

Player = Player or {}
Player.Init = init