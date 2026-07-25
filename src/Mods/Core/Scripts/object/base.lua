local cachedPosX = nil
local cachedPosY = nil
local cachedDrawRequest = nil

local function loadSetting(input)
    return DefinitionHelper.LoadSetting(
    {
        {
            targetDefType = "worldViewSetting",
            defName = "base",
            params =
            {
                posX = {},
                posY = {},
                width = {},
                height = {},
            }
        }
    })
end

local function getPosition(input)

    if not cachedPosX or not cachedPosY then
        error(Localize("base.lua.notInitialized"))
    end

    return {
        posX = cachedPosX,
        posY = cachedPosY,
    }
end

local function createDrawRequest(input)

    local setting = input.setting
    local width = setting.width
    local height = setting.height

    cachedDrawRequest = WorldRenderer.CreateRectDrawRequest(
    {
        posX = setting.posX - width / 2,
        posY = setting.posY - height / 2,

        width = width,
        height = height,

        r = 255,
        g = 255,
        b = 0,
        a = 255,
    })

end

local function init()

    local setting = loadSetting()

    cachedPosX = setting.posX
    cachedPosY = setting.posY

    createDrawRequest({ setting = setting, })

end

Base = Base or {}
Base.Init = init
Base.GetPosition = getPosition


local function draw(deltaTime, totalTime)

    if not cachedDrawRequest then
        return
    end

    DrawQueue.AddToQueue(cachedDrawRequest)
    
end

Events.OnUpdate.Add(draw)