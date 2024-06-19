-- Modloader Reborn by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn) [June 2024]

-- For developers
addEvent("modloader_reborn:client:onModLoaded", false)

function apiGetModLoadedForModel(model)
    return modelsReplaced[model]
end

function apiInformModLoaded(...)
    triggerEvent("modloader_reborn:client:onModLoaded", localPlayer, ...)
end

-- Exported functions
getModLoadedForModel = apiGetModLoadedForModel
