local _setting = nil
local _size = nil
local _originOffset = nil

local function loadSetting(input)
    return DefinitionHelper.LoadSetting(
    {
        {
            targetDefType = "world",
            defName = "setting",

            params =
            {
                primaryDimension = {},
                primaryDimensionInMeters = {},
                aspectRatio = {},
                widthRatioOriginPosX = {},
                heightRatioOriginPosY = {},
            }
        },
    })
end

local function calculateWorldSize(input)

    local setting = input.setting

    local result = DefinitionHelper.TryParseAspectRatio(
    {
        ratioString = setting.aspectRatio,
    })

    if not result.success then
        error(Localize("world.lua.failedToParseWorldAspectRatio",
            setting.aspectRatio))
    end

    local aspectRatio = result.aspectWidth / result.aspectHeight

    local width
    local height

    if setting.primaryDimension == "width" then

        width = setting.primaryDimensionInMeters
        height = width / aspectRatio

    elseif setting.primaryDimension == "height" then

        height = setting.primaryDimensionInMeters
        width = height * aspectRatio

    else

        error(Localize("world.lua.invalidPrimaryDimension",
            tostring(setting.primaryDimension)))

    end

    return
    {
        width = width,
        height = height,
    }

end

local function calculateOriginOffset(input)

    local setting = input.setting
    local worldWidth = input.worldWidth
    local worldHeight = input.worldHeight

    local originOffsetX =
        worldWidth * setting.widthRatioOriginPosX

    local originOffsetY =
        worldHeight * setting.heightRatioOriginPosY

    return
    {
        originOffsetX = originOffsetX,
        originOffsetY = originOffsetY,
    }

end

local function init(input)

    _setting = loadSetting()

    _size = calculateWorldSize({
        setting = _setting,
    })

    _originOffset = calculateOriginOffset({
        setting = _setting,
        worldWidth = _size.width,
        worldHeight = _size.height,
    })

end

local function getSize(input)

    if _size == nil then
        error(Localize("world.lua.notInitialized"))
    end

    return
    {
        width = _size.width,
        height = _size.height,
    }

end

local function getOriginOffset(input)

    if _originOffset == nil then
        error(Localize("world.lua.originNotInitialized"))
    end

    return
    {
        x = _originOffset.originOffsetX,
        y = _originOffset.originOffsetY,
    }

end

World = World or {}

World.Init = init
World.GetSize = getSize
World.GetOriginOffset = getOriginOffset