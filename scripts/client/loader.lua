

function endsWith(str, ending)
	return ending == '' or str:sub(-#ending) == ending
end

local function loadMods()
    local replaceTextures = {}
    local replaceModels = {}
    local paths = {}
    if CONFIG_LOAD_VEHICLES then
        table.insert(paths, "vehicles")
    end
    if CONFIG_LOAD_SKINS then
        table.insert(paths, "skins")
    end
    for _, path in pairs(paths) do
        for _, fileName in pairs(pathListDir(CONFIG_DIR_MODS .. path) or {}) do
            local isDFF = endsWith(fileName, ".dff")
            local isTXD = endsWith(fileName, ".txd")
            if isDFF or isTXD then
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
                    outputDebugString("Could not find model for " .. fileName)
                else
                    if isDFF then
                        replaceModels[model] = CONFIG_DIR_MODS .. path .. "/" .. fileName
                    else
                        replaceTextures[model] = CONFIG_DIR_MODS .. path .. "/" .. fileName
                    end
                end
            end
        end
    end
    for model, filePath in pairs(replaceTextures) do
        local txdElement = engineLoadTXD(filePath)
        if txdElement then
            engineImportTXD(txdElement, model)
        end
    end
    for model, filePath in pairs(replaceModels) do
        local dffElement = engineLoadDFF(filePath)
        if dffElement then
            engineReplaceModel(dffElement, model)
        end
    end
end
addEventHandler("onClientResourceStart", resourceRoot, loadMods, false)
