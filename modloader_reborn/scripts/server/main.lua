-- Modloader Reborn by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn) [June 2024]

local CONFIG_DIR_MODS = "mods"

-- must match meta.xml <settings/> names
local SETTING_NAMES = {
    "*AMOUNT_MODS_PER_BATCH", "*TIME_MS_BETWEEN_BATCHES", "*OUTPUT_SUCCESS_MESSAGES",
    "*WARN_FILE_SIZE_ABOVE_DFF", "*WARN_FILE_SIZE_ABOVE_COL", "*WARN_FILE_SIZE_ABOVE_TXD"
} 

modList = {}
settings = {}

local startupLoading = true
local playersWaitingQueue = {}
local clientsReady = {}

for _, settingName in pairs(SETTING_NAMES) do
    local settingValue = get(settingName)
    if not settingValue then
        outputMsg("Setting value not set for: " .. settingName, 1)
        return
    end
    settings[settingName] = settingValue
end

function outputLogMsg(msg)
    outputServerLog("["..resourceName.."] " .. tostring(msg))
end

local function endsWith(str, ending)
    return ending == '' or str:sub(-#ending) == ending
end

local function loadOneModForPlayer(player, model, mod)
    if startupLoading then
        return
    end
    triggerClientEvent(player, "modloader_reborn:client:loadOneMod", resourceRoot, model, mod)
end

function loadOneModForReadyPlayers(model, mod)
    for player, _ in pairs(clientsReady) do
        loadOneModForPlayer(player, model, mod)
    end
end

local function unloadOneModForPlayer(player, model)
    if startupLoading then
        return
    end
    triggerClientEvent(player, "modloader_reborn:client:unloadOneMod", resourceRoot, model)
end

function unloadOneModForReadyPlayers(model)
    for player, _ in pairs(clientsReady) do
        unloadOneModForPlayer(player, model)
    end
end

local function loadAllModsForPlayer(player)
    triggerClientEvent(player, "modloader_reborn:client:loadMods", resourceRoot, modList)
end

local function sendSettingsToPlayer(player)
    triggerClientEvent(player, "modloader_reborn:client:applySettings", resourceRoot, settings)
end

local function handlePlayerResourceStart(res)
    if res ~= resource then
        return
    end
    clientsReady[source] = true

    sendSettingsToPlayer(source)

    if startupLoading then
        playersWaitingQueue[source] = true
        return
    end
    loadAllModsForPlayer(source)
end
addEventHandler("onPlayerResourceStart", root, handlePlayerResourceStart)

addEventHandler("onPlayerQuit", root, function()
    clientsReady[source] = nil
    if startupLoading then
        playersWaitingQueue[source] = nil
    end
end)

function checkFileAboveSizeThreshold(filePath)
    -- Check if file path belongs to a different resource
    if filePath:sub(1, 1) == ":" then
        local resourcePath = filePath:match("^:(.-)/")
        if resourcePath and getResourceFromName(resourcePath) ~= resource then
            if not hasObjectPermissionTo(resource, "general.ModifyOtherObjects") then
                outputMsg("checkFileAboveSizeThreshold cannot proceed: file path belongs to a different resource, and ModifyOtherObjects is not granted: " .. filePath, 2)
                return
            end
        end
    end

    local file = fileOpen(filePath, true)
    if not file then
        outputMsg("Could not open file: " .. filePath, 1)
        return
    end
    local fileSize = fileGetSize(file)
    fileClose(file)
    if not fileSize then
        outputMsg("Could not get file size: " .. filePath, 1)
        return
    end

    local isDFF = endsWith(filePath, ".dff")
    local isCOL = endsWith(filePath, ".col")
    local isTXD = endsWith(filePath, ".txd")
    local warnSize = 0
    if isDFF then
        warnSize = tonumber(settings["*WARN_FILE_SIZE_ABOVE_DFF"]) or 0
    elseif isCOL then
        warnSize = tonumber(settings["*WARN_FILE_SIZE_ABOVE_COL"]) or 0
    elseif isTXD then
        warnSize = tonumber(settings["*WARN_FILE_SIZE_ABOVE_TXD"]) or 0
    end
    if warnSize > 0 and fileSize > (warnSize * 1024) then
        local fileExtension = string.upper(string.sub(filePath, -3))
        outputLogMsg(fileExtension.." file is above warning threshold ("..(("%.2f kB"):format(warnSize)).."): " .. filePath .. " ("..(("%.2f kB"):format(fileSize/1024))..")")
    end
end

local function processModFile(completePath, fileName)
    if not pathIsFile(completePath) then
        return
    end
    local isDFF = endsWith(fileName, ".dff")
    local isTXD = endsWith(fileName, ".txd")
    local isCOL = endsWith(fileName, ".col")
    if not (isDFF or isTXD or isCOL) then
        return
    end
    
    checkFileAboveSizeThreshold(completePath)

    local modelStr = string.sub(fileName, 1, -5)
    local model
    if tonumber(modelStr) then
        local modelCheck = tonumber(modelStr)
        if DATA_VEHICLES[modelCheck] then
            model = modelCheck
        elseif DATA_SKINS[modelCheck] then
            model = modelCheck
        elseif DATA_OBJECTS[modelCheck] then
            model = modelCheck
        end
    else
        modelStr = modelStr:lower()
        if isCOL then
            for model_, data in pairs(DATA_OBJECTS) do
                if data.dff == modelStr then
                    model = model_
                    break
                end
            end
        else
            for model_, data in pairs(DATA_VEHICLES) do
                if isDFF and data.dff == modelStr
                or isTXD and data.txd == modelStr then
                    model = model_
                    break
                end
            end
            if not model then
                for model_, data in pairs(DATA_SKINS) do
                    if isDFF and data.dff == modelStr
                    or isTXD and data.txd == modelStr then
                        model = model_
                        break
                    end
                end
                if not model then
                    for model_, data in pairs(DATA_OBJECTS) do
                        if isDFF and data.dff == modelStr
                        or isTXD and data.txd == modelStr then
                            model = model_
                            break
                        end
                    end
                end
            end
        end
    end
    if not model then
        outputMsg("Could not find a model to apply: " .. fileName, 2)
        return
    end
    if not modList[model] then
        modList[model] = {}
    end
    if isCOL then
        modList[model].colPath = completePath
    elseif isTXD then
        modList[model].txdPath = completePath
    elseif isDFF then
        modList[model].dffPath = completePath
    end
end

local function prepareMods()
    if not pathIsDirectory(CONFIG_DIR_MODS) then
        outputMsg("Mods directory not found: " .. CONFIG_DIR_MODS, 1)
        playersWaitingQueue = nil
        startupLoading = nil
        return
    end

    -- Recursively search for mods in the mods directory and its subdirectories
    local function processFileOrFolder(pathToLocation, fileOrDirName)
        local completePath = pathToLocation.."/"..fileOrDirName
        if pathIsFile(completePath) then
            processModFile(completePath, fileOrDirName)
        elseif pathIsDirectory(completePath) then
            for _, fileOrDirName2 in pairs(pathListDir(completePath) or {}) do
                processFileOrFolder(completePath, fileOrDirName2)
            end
        end
    end
    for _, fileOrDirName in pairs(pathListDir(CONFIG_DIR_MODS) or {}) do
        processFileOrFolder(CONFIG_DIR_MODS, fileOrDirName)
    end

    for player, _ in pairs(playersWaitingQueue) do
        loadAllModsForPlayer(player)
    end
    playersWaitingQueue = nil
    startupLoading = nil
end
addEventHandler("onResourceStart", resourceRoot, prepareMods, false)

addEventHandler("onSettingChange", root, function(settingName)
    settingName = settingName:gsub(resourceName..("."), "")
    if settings[settingName] == nil then
        return
    end
    settings[settingName] = get(settingName)
    for player, _ in pairs(clientsReady) do
        sendSettingsToPlayer(player)
    end
end, false)
