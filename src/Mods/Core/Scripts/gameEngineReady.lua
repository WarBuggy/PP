local function onGameEngineReady()
    World.Init()
    Base.Init()
    Level.Init()
end

Events.OnGameEngineReady.Add(onGameEngineReady)