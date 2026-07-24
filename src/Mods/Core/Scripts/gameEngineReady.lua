local function onGameEngineReady()
    PlayableBox.Init()
    Base.Init()
end

Events.OnGameEngineReady.Add(onGameEngineReady)