local function onGameEngineReady()
    World.Init()
    Camera.Init()
    ZoomLevel.Init()
    -- Base.Init()
    -- Level.Init()
end

Events.OnGameEngineReady.Add(onGameEngineReady)