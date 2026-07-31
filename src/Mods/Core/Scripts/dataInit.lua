local function onDataInit()
    GameData.Set("actions.list", LedgerMap.Create(), "Core")
    GameData.Set("drawLayers.layerIndexMap", LedgerMap.Create(), "Core")
    GameData.Set("zoomLevel.list", LedgerArray.Create(), "Core")
end

Events.OnDataInit.Add(onDataInit)