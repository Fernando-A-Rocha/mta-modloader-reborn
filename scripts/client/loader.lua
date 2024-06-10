-- Modloader Reborn by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn) [June 2024]

-- Currently supports vehicle and skin models

-- Security feature: Only files provided by the server are loaded, meaning that if the user adds random files
-- to the mods directory in their resource cache, they won't be recognized and loaded.

local CONFIG_DIR_MODS = "mods"

local resourceName = getResourceName(resource)

local function outputMsg(msg, level)
    outputDebugString("["..resourceName.."] " .. msg, level)
end

local function endsWith(str, ending)
    return ending == '' or str:sub(-#ending) == ending
end

local function loadMods()

    if not pathIsDirectory(CONFIG_DIR_MODS) then
        outputMsg("Mods directory not found: " .. CONFIG_DIR_MODS, 2)
        return
    end

    local replaceTextures = {}
    local replaceModels = {}

    local function parseModFile(fileName)
        local realFilePath = string.format("%s/%s", CONFIG_DIR_MODS, fileName)
        if not pathIsFile(realFilePath) then
            return
        end
        local isDFF = endsWith(fileName, ".dff")
        local isTXD = endsWith(fileName, ".txd")
        if not (isDFF or isTXD) then
            return
        end
        local modelStr = string.sub(fileName, 1, -5)
        local model
        if tonumber(modelStr) then
            local modelCheck = tonumber(modelStr)
            if DATA_VEHICLES[modelCheck] then
                model = modelCheck
            elseif DATA_SKINS[modelCheck] then
                model = modelCheck
            end
        else
            for model_, data in pairs(DATA_VEHICLES) do
                if data.dff == modelStr or data.txd == modelStr then
                    model = model_
                    break
                end
            end
            if not model then
                for model_, data in pairs(DATA_SKINS) do
                    if data.dff == modelStr or data.txd == modelStr then
                        model = model_
                        break
                    end
                end
            end
        end
        if not model then
            outputMsg("File name doesn't correspond to vehicle/skin model name/ID: " .. fileName, 2)
            return
        end
        local fileHandle = fileOpen(realFilePath, true)
        if not fileHandle then
            return
        end
        local fileContent = fileGetContents(fileHandle, true) -- Verifies checksum
        fileClose(fileHandle)
        if not fileContent then
            return
        end
        if isDFF then
            replaceModels[model] = fileContent
        else
            replaceTextures[model] = fileContent
        end
    end
    
    for _, fileName in pairs(pathListDir(CONFIG_DIR_MODS) or {}) do
        parseModFile(fileName)
    end

    for model, fileContent in pairs(replaceTextures) do
        local txdElement = engineLoadTXD(fileContent)
        if txdElement then
            engineImportTXD(txdElement, model)
        end
    end
    for model, fileContent in pairs(replaceModels) do
        local dffElement = engineLoadDFF(fileContent)
        if dffElement then
            engineReplaceModel(dffElement, model)
        end
    end

    collectgarbage("collect")
end
addEventHandler("onClientResourceStart", resourceRoot, loadMods, false)
