-- Modloader Reborn by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn) [June 2024]

addEvent("modloader_reborn:loadMods", true)

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

local function processMod(model, mod)
    assert(type(model) == "number", "Invalid mod model: " .. inspect(model))
    assert(type(mod) == "table", "Invalid mod data: " .. inspect(mod))

    local txdElement = loadFile(mod.txdPath, engineLoadTXD)
    if txdElement then
        engineImportTXD(txdElement, model)
    end

    local dffElement = loadFile(mod.dffPath, engineLoadDFF)
    if dffElement then
        engineReplaceModel(dffElement, model)
    end
end

local function processBatch()
    local loadedCounter = 0

    for model, mod in pairs(modsToLoad) do
        processMod(model, mod)
        modsToLoad[model] = nil
        loadedCounter = loadedCounter + 1
        if loadedCounter >= (settingsFromServer["*AMOUNT_MODS_PER_BATCH"]) then
            break
        end
    end

    outputMsg(("Loaded %d mods."):format(loadedCounter), 3)
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
    beginLoadingMods()
end
addEventHandler("modloader_reborn:loadMods", resourceRoot, loadMods, false)
