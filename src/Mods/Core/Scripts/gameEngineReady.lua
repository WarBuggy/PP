local function onGameEngineReady()
    PlayableBox.Init()
    Player.Init()
end

Events.OnGameEngineReady.Add(onGameEngineReady)