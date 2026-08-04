local function onGameEngineReady()
    World.Init()
    Camera.Init()
    ZoomLevel.Init()
    Backdrop.Init()
    -- Base.Init()
    -- Level.Init()
end

Events.OnGameEngineReady.Add(onGameEngineReady)