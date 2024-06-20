-- Modloader Reborn by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn) [June 2024]

-- For developers
addEvent("modloader_reborn:client:onModLoaded", false)

API = {}

API.GetModLoadedForModel = function(model)
    return modelsReplaced[model]
end

API.GetModsLoaded = function()
    return modelsReplaced
end

API.InformModLoaded = function(...)
    triggerEvent("modloader_reborn:client:onModLoaded", localPlayer, ...)
end

-- Exported functions
getModLoadedForModel = API.GetModLoadedForModel
getModsLoaded = API.GetModsLoaded
