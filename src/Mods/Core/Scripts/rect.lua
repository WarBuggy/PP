local function drawTestBox(deltaTime, totalTime)

    local screenWidth = Screen.Width()
    local screenHeight = Screen.Height()

    if not screenWidth or not screenHeight then
        return
    end

    local boxWidth = 100
    local boxHeight = 100

    local x = (screenWidth - boxWidth) * 0.5
    local y = (screenHeight - boxHeight) * 0.5

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

Events.OnUpdate.Add(drawTestBox)