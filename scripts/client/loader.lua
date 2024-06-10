-- Modloader Reborn by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn) [June 2024]

addEvent("modloader_reborn:loadMods", true)

local AMOUNT_MODS_PER_BATCH = 2
local TIME_MS_BETWEEN_BATCHES = 1000

local modsToLoad = {}

local function beginLoadingMods()

    local loadedCounter = 0

    for model, mod in pairs(modsToLoad) do
        assert(type(model)=="number", "Invalid mod model: " .. inspect(model))
        assert(type(mod)=="table", "Invalid mod data: " .. inspect(mod))
        local txdPath = mod.txdPath
        if type(txdPath) == "string" then
            local fileHandle = fileOpen(txdPath, true)
            if fileHandle then
                local fileContent = fileGetContents(fileHandle, true) -- Verifies checksum
                fileClose(fileHandle)
                if fileContent then
                    local txdElement = engineLoadTXD(fileContent)
                    if txdElement then
                        engineImportTXD(txdElement, model)
                    end
                end
            end
        end
        local dffPath = mod.dffPath
        if type(dffPath) == "string" then
            local fileHandle = fileOpen(dffPath, true)
            if fileHandle then
                local fileContent = fileGetContents(fileHandle, true) -- Verifies checksum
                fileClose(fileHandle)
                if fileContent then
                    local dffElement = engineLoadDFF(fileContent)
                    if dffElement then
                        engineReplaceModel(dffElement, model)
                    end
                end
            end
        end
        modsToLoad[model] = nil
        loadedCounter = loadedCounter + 1
        if loadedCounter >= AMOUNT_MODS_PER_BATCH then
            break
        end
    end

    outputMsg(("Replaced %d game models."):format(loadedCounter), 3)

    if next(modsToLoad) then
        outputMsg(("Waiting %d seconds to load next batch of mods..."):format(TIME_MS_BETWEEN_BATCHES/1000), 3)
        setTimer(beginLoadingMods, TIME_MS_BETWEEN_BATCHES, 1)
    end
end

local function loadMods(modList)
    assert(type(modList)=="table", "Invalid argument #1 to 'loadMods' (table expected, got " .. type(modList) .. ")" )
    modsToLoad = modList
    beginLoadingMods()
end
addEventHandler("modloader_reborn:loadMods", resourceRoot, loadMods, false)
