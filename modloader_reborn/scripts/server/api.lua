-- Modloader Reborn by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn) [June 2024]

API = {}

API.SetModForModel = function(model, mod)
    assert(type(model) == "number", "Model must be a number")
    assert(type(mod) == "table", "Mod must be a table")
    if modList[model] then
        outputMsg(("Model %d already has a mod assigned"):format(model), 1)
        return false
    end
    if not DATA_VEHICLES[model] and not DATA_SKINS[model] and not DATA_OBJECTS[model] then
        outputMsg(("Model %d is not a valid vehicle, skin or object ID"):format(model), 1)
        return false
    end
    modList[model] = {}
    for _, pathType in pairs({"colPath", "txdPath", "dffPath"}) do
        local realFilePath = mod[pathType]
        if realFilePath then
            if type(realFilePath) ~= "string" then
                outputMsg(("Invalid path: %s"):format(inspect(realFilePath)), 1)
                return false
            end
            if not pathIsFile(realFilePath) then
                outputMsg(("Mod file %does not exist: %s"):format(realFilePath), 1)
                return false
            end
            modList[model][pathType] = realFilePath
        end
    end
    if not next(modList[model]) then
        outputMsg(("Trying to assign no valid dff/txd/col files to model %d"):format(model), 1)
        modList[model] = nil
        return false
    end
    if type(mod.name) == "string" then
        modList[model].name = mod.name
    end
    if type(mod.author) == "string" then
        modList[model].author = mod.author
    end
    outputMsg(("Model %d has been assigned a mod"):format(model), 3)
    loadOneModForReadyPlayers(model, modList[model])
    return true
end

API.RemoveModForModel = function(model)
    assert(type(model) == "number", "Model must be a number")
    if not modList[model] then
        outputMsg(("Model %d does not have a mod assigned"):format(model), 1)
        return false
    end
    modList[model] = nil
    outputMsg(("Model %d has had its mod removed"):format(model), 3)
    unloadOneModForReadyPlayers(model)
    return true
end

-- Exported functions
setModForModel = API.SetModForModel
removeModForModel = API.RemoveModForModel
