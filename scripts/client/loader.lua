-- Modloader Reborn by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn) [June 2024]

-- Internal event
addEvent("modloader_reborn:client:loadMods", true)

-- For developers
addEvent("modloader_reborn:client:onModLoaded", false)

local modsToLoad = {}
local settingsFromServer = {}
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

local function loadOneMod(model, mod)
    assert(type(model) == "number", "Invalid mod model: " .. inspect(model))
    assert(type(mod) == "table", "Invalid mod data: " .. inspect(mod))

    if mod.colPath then
        local colElement = loadFile(mod.colPath, engineLoadCOL)
        if not colElement then
            return false, "COL(load)"
        end
        if not engineReplaceCOL(model, colElement) then
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

    return true
end

local function tableCount(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

local function processBatch()
    local loadedCounter = 0

    for model, mod in pairs(modsToLoad) do
        local loadSuccess, whatFailed = loadOneMod(model, mod)
        if loadSuccess then
            outputMsg(("Successfully loaded mod for model %d."):format(model), 3)
        else
            outputMsg(("Failed to load %s for model %d."):format(whatFailed, model), 1)
        end
        loadedCounter = loadedCounter + 1
        local remainingCounter = tableCount(modsToLoad) - 1

        triggerEvent("modloader_reborn:client:onModLoaded", localPlayer,
            model, mod,
            loadSuccess,
            loadedCounter, remainingCounter
        )

        modsToLoad[model] = nil
        if loadedCounter >= (settingsFromServer["*AMOUNT_MODS_PER_BATCH"]) then
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
            until getTickCount() - startTick >= settingsFromServer["*TIME_MS_BETWEEN_BATCHES"]
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
        outputMsg("Finished loading all mods.", 3)
    end
end

local function beginLoadingMods()
    loaderCoroutine = coroutine.create(coroutineLoader)
    addEventHandler("onClientRender", root, onClientRenderHandler)
end

local function loadMods(modList, settings)
    assert(type(modList) == "table", "Invalid argument #1 to 'loadMods' (table expected, got " .. type(modList) .. ")" )
    assert(type(settings) == "table", "Invalid argument #2 to 'loadMods' (table expected, got " .. type(settings) .. ")" )
    modsToLoad = modList
    settingsFromServer = settings
    outputSuccessMessages = settingsFromServer["*OUTPUT_SUCCESS_MESSAGES"] == "true"
    beginLoadingMods()
end
addEventHandler("modloader_reborn:client:loadMods", resourceRoot, loadMods, false)
