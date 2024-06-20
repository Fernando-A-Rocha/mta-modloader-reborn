-- Modloader Reborn by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn) [June 2024]

-- Internal events
addEvent("modloader_reborn:client:applySettings", true)
addEvent("modloader_reborn:client:loadMods", true)
addEvent("modloader_reborn:client:loadOneMod", true)
addEvent("modloader_reborn:client:unloadOneMod", true)

settings = {}
modelsReplaced = {}

local modsToLoad = {}
local loaderCoroutine

local function loadFile(filePath, loaderFunc)
    if type(filePath) == "string" then
        local fileHandle = fileOpen(filePath, true)
        if fileHandle then
            local fileContent = fileGetContents(fileHandle, true) -- Verifies checksum
            fileClose(fileHandle)
            if fileContent then
                local element = loaderFunc(fileContent)
                return element
            end
        end
    end
    return nil
end

local function processMod(model, mod)
    assert(type(model) == "number", "Invalid mod model: " .. inspect(model))
    assert(type(mod) == "table", "Invalid mod data: " .. inspect(mod))

    if mod.colPath then
        local colElement = loadFile(mod.colPath, engineLoadCOL)
        if not colElement then
            return false, "COL(load)"
        end
        if not engineReplaceCOL(colElement, model) then
            return false, "COL(replace)"
        end
    end

    if mod.txdPath then
        local txdElement = loadFile(mod.txdPath, engineLoadTXD)
        if not txdElement then
            return false, "TXD(load)"
        end
        if not engineImportTXD(txdElement, model) then
            return false, "TXD(import)"
        end
    end

    if mod.dffPath then
        local dffElement = loadFile(mod.dffPath, engineLoadDFF)
        if not dffElement then
            return false, "DFF(load)"
        end
        if not engineReplaceModel(dffElement, model) then
            return false, "DFF(replace)"
        end
    end

    modelsReplaced[model] = mod
    return true
end

local function tableCount(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

local function getModFiles(mod)
    local modFiles = {}
    if mod.colPath then
        table.insert(modFiles, mod.colPath)
    end
    if mod.txdPath then
        table.insert(modFiles, mod.txdPath)
    end
    if mod.dffPath then
        table.insert(modFiles, mod.dffPath)
    end
    return modFiles
end

local function processBatch()
    local loadedCounter = 0

    for model, mod in pairs(modsToLoad) do
        local loadSuccess, whatFailed = processMod(model, mod)
        if loadSuccess then
            outputMsg(("Successfully loaded mod for model %d (%s)."):format(model, table.concat(getModFiles(mod), ", ")), 3)
        else
            outputMsg(("Failed to load %s for model %d."):format(whatFailed, model), 1)
        end
        loadedCounter = loadedCounter + 1
        local remainingCounter = tableCount(modsToLoad) - 1

        API.InformModLoaded(
            model, mod,
            loadSuccess,
            loadedCounter, remainingCounter
        )

        modsToLoad[model] = nil
        if loadedCounter >= (settings["*AMOUNT_MODS_PER_BATCH"]) then
            break
        end
    end
    outputMsg(("Loaded %d mods in one batch."):format(loadedCounter), 3)
end

local function coroutineLoader()
    while next(modsToLoad) do
        local startTick = getTickCount()
        processBatch()

        if next(modsToLoad) then
            repeat
                coroutine.yield()
            until getTickCount() - startTick >= settings["*TIME_MS_BETWEEN_BATCHES"]
        end
    end
end

local function onClientRenderHandler()
    if loaderCoroutine and coroutine.status(loaderCoroutine) == "suspended" then
        local success, errorMsg = coroutine.resume(loaderCoroutine)
        if not success then
            removeEventHandler("onClientRender", root, onClientRenderHandler)
            outputMsg(("Error in coroutine: %s"):format(errorMsg), 1)
        end
    elseif loaderCoroutine and coroutine.status(loaderCoroutine) == "dead" then
        removeEventHandler("onClientRender", root, onClientRenderHandler)
        outputMsg("Finished loading all queued mods.", 3)
    end
end

local function restoreOneModel(model)
    if modelsReplaced[model] then
        engineRestoreModel(model)
        modelsReplaced[model] = nil
    end
end

local function restoreReplacedModels()
    for model, _ in pairs(modelsReplaced) do
        restoreOneModel(model)
    end
    modelsReplaced = {}
end
addEventHandler("onClientResourceStop", resourceRoot, restoreReplacedModels, false)

local function beginLoadingMods()
    loaderCoroutine = coroutine.create(coroutineLoader)
    addEventHandler("onClientRender", root, onClientRenderHandler)
end

local function applySettingsFromServer(settingsFromServer)
    assert(type(settingsFromServer) == "table", "Invalid argument #1 to 'applySettingsFromServer' (table expected, got " .. type(settingsFromServer) .. ")" )
    settings = settingsFromServer
end
addEventHandler("modloader_reborn:client:applySettings", resourceRoot, applySettingsFromServer, false)

local function loadMods(modList)
    assert(type(modList) == "table", "Invalid argument #1 to 'loadMods' (table expected, got " .. type(modList) .. ")" )
    modsToLoad = modList
    beginLoadingMods()
end
addEventHandler("modloader_reborn:client:loadMods", resourceRoot, loadMods, false)

local function loadOneMod(model, mod)
    assert(type(model) == "number", "Invalid argument #1 to 'loadOneMod' (number expected, got " .. type(model) .. ")" )
    assert(type(mod) == "table", "Invalid argument #2 to 'loadOneMod' (table expected, got " .. type(mod) .. ")" )
    modsToLoad[model] = mod
    if not loaderCoroutine or coroutine.status(loaderCoroutine) == "dead" then
        beginLoadingMods()
    end
end
addEventHandler("modloader_reborn:client:loadOneMod", resourceRoot, loadOneMod, false)

local function unloadOneMod(model)
    assert(type(model) == "number", "Invalid argument #1 to 'unloadOneMod' (number expected, got " .. type(model) .. ")" )
    restoreOneModel(model)
end
addEventHandler("modloader_reborn:client:unloadOneMod", resourceRoot, unloadOneMod, false)
