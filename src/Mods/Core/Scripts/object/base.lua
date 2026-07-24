local cachedSetting = nil
local cachedBounds = nil
local cachedDrawRequest = nil

local function loadSetting()
    return DefinitionHelper.LoadSetting(
    {
        {
            targetDefType = "worldViewSetting",
            defName = "base",
            params =
            {
                playableBoxCenterXRatio = {},
                playableBoxCenterYRatio = {},
                playableBoxWidthRatio = {},
                playableBoxHeightRatio = {},
            }
        }
    })
end

local function calculateBounds(playableBoxBounds, setting)

    local width =
        playableBoxBounds.width * setting.playableBoxWidthRatio

    local height =
        playableBoxBounds.height * setting.playableBoxHeightRatio

    local centerX = playableBoxBounds.left +
        playableBoxBounds.width * setting.playableBoxCenterXRatio

    local centerY = playableBoxBounds.top +
        playableBoxBounds.height * setting.playableBoxCenterYRatio

    local left = centerX - width * 0.5
    local top = centerY - height * 0.5

    return
    {
        left = left,
        top = top,
        right = left + width,
        bottom = top + height,

        centerX = centerX,
        centerY = centerY,

        width = width,
        height = height
    }
end

local function buildDrawRequest(bounds)

    return BasicShape.CreateRectDrawRequest(
    {
        x = bounds.left,
        y = bounds.top,

        width = bounds.width,
        height = bounds.height,

        r = 255,
        g = 0,
        b = 255,
        a = 255,

        layer = "ui",
    })
end

local function init()

    cachedSetting = loadSetting()

    local playableBoxBounds = PlayableBox.GetBounds()

    cachedBounds = calculateBounds(playableBoxBounds, cachedSetting)

    cachedDrawRequest = buildDrawRequest(cachedBounds)
end

local function draw(deltaTime, totalTime)
    if cachedDrawRequest then
        DrawQueue.AddToQueue(cachedDrawRequest)
    end
end

Events.OnUpdate.Add(draw)

Base = Base or {}
Base.Init = init