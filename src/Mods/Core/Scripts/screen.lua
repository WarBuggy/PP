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

    Drawing.AddRectangle(
        {x, y},
        boxWidth,
        boxHeight,
        0,0, 255, 
        "m11cHeight"
    )

end

Events.OnDraw.Add(drawTestBox)