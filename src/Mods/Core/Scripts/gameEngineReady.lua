local function onGameEngineReady()
    World.Init()
    Base.Init()
end

Events.OnGameEngineReady.Add(onGameEngineReady)