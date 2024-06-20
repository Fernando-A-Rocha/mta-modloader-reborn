--[[
    San Andreas Map Bug Fixes

    This resource is intended to fix some bugs in the MTA:SA world.

    Some of the issues are not present in the Singleplayer GTA:SA game
    because the game loads additional SCM scripts related to
    missions/progression that are not loaded in MTA:SA.
]]

local resourceName = getResourceName(resource)
local modloaderResourceName = "modloader_reborn"

local MODEL_FIXES = {
    -- ID, TXD, DFF, COL, Name(optional), Author(optional)
    {12887, false, false, "cunte_roads50.col", "Palomino Red Bridge Fix"},
}

local function loadModelFixes()
    for _, data in pairs(MODEL_FIXES) do
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
end

local function unloadModelFixes()
    for _, data in pairs(MODEL_FIXES) do
        local modelId = data[1]
        exports[modloaderResourceName]:removeModForModel(modelId)
    end
end

addEventHandler("onResourceStart", resourceRoot, function()
    loadModelFixes()
end)
addEventHandler("onResourceStop", resourceRoot, function()
    unloadModelFixes()
end, false)
