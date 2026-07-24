local function onGameEngineReady()
    World.Init()
    Base.Init()

    local screenCenter = Base.GetScreenCenter()
    World.SetScreenOrigin(screenCenter.x, screenCenter.y)
end

Events.OnGameEngineReady.Add(onGameEngineReady)