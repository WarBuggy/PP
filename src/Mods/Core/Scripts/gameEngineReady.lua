local function onGameEngineReady()
    PlayableBox.InitializePlayableBox()
end

Events.OnGameEngineReady.Add(onGameEngineReady)