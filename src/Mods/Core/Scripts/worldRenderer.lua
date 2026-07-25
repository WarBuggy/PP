local function mergeRemainingFields(input)

    local source = input.source
    local target = input.target

    for key, value in pairs(source) do

        if target[key] == nil then
            target[key] = value
        end

    end

end

local function createRectDrawRequest(input)

    local screenPosition = World.WorldToScreen({
        posX = input.posX,
        posY = input.posY,
    })

    local request = {
        x = screenPosition.x,
        y = screenPosition.y,

        width = World.MeterToPixel({
            meter = input.width,
        }).pixel,

        height = World.MeterToPixel({
            meter = input.height,
        }).pixel,

        layer = input.layer,
    }

    mergeRemainingFields({
        source = input,
        target = request,
    })

    return BasicShape.CreateRectDrawRequest(request)
end

WorldRenderer = WorldRenderer or {}

WorldRenderer.CreateRectDrawRequest = createRectDrawRequest