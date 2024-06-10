-- Modloader Reborn by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn) [June 2024]

addEvent("modloader_reborn:loadMods", true)

local function loadMods(modList)
    assert(type(modList)=="table", "Invalid argument #1 to 'loadMods' (table expected, got " .. type(modList) .. ")" )

    local replaceTextures = {}
    local replaceModels = {}

    for _, mod in pairs(modList) do
        local modType = mod.type
        local filePath = mod.path
        assert(type(modType)=="string", "Invalid mod entry (type) in 'loadMods' (string expected, got " .. type(modType) .. ")" )
        assert(type(filePath)=="string", "Invalid mod entry (path) in 'loadMods' (string expected, got " .. type(filePath) .. ")" )
        local fileHandle = fileOpen(filePath, true)
        if fileHandle then
            local fileContent = fileGetContents(fileHandle, true) -- Verifies checksum
            fileClose(fileHandle)
            if fileContent then
                local model = mod.model
                assert(type(model)=="number", "Invalid mod entry (model) in 'loadMods' (number expected, got " .. type(model) .. ")" )
                if modType == "txd" then
                    replaceTextures[model] = fileContent
                elseif modType == "dff" then
                    replaceModels[model] = fileContent
                end
            end
        end
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
addEventHandler("modloader_reborn:loadMods", resourceRoot, loadMods, false)
