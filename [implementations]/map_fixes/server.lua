local resourceName = getResourceName(resource)
local modloaderResourceName = "modloader_reborn"

local MAP_FIXES = {
    -- ID, TXD, DFF, COL, Name(optional), Author(optional)
    {12887, false, false, "cunte_roads50.col", "Palomino Red Bridge Fix"},
}

addEventHandler("onResourceStart", resourceRoot, function()
    for _, data in pairs(MAP_FIXES) do
        local modelId = data[1]
        local txdPath = data[2] and (":".. resourceName .. "/files/".. data[2]) or nil
        local dffPath = data[3] and (":".. resourceName .. "/files/".. data[3]) or nil
        local colPath = data[4] and (":".. resourceName .. "/files/".. data[4]) or nil
        local name = data[5] or nil
        local author = data[6] or nil

        exports[modloaderResourceName]:setModForModel(modelId, {
            txdPath = txdPath,
            dffPath = dffPath,
            colPath = colPath,
            name = name,
            author = author
        })
    end
end)
addEventHandler("onResourceStop", resourceRoot, function()
    for _, data in pairs(MAP_FIXES) do
        local modelId = data[1]
        exports[modloaderResourceName]:removeModForModel(modelId)
    end
end, false)
