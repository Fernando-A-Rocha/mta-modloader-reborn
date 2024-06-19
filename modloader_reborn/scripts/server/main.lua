-- Modloader Reborn by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn) [June 2024]

local CONFIG_DIR_MODS = "mods"
local SETTING_NAMES = {"*AMOUNT_MODS_PER_BATCH", "*TIME_MS_BETWEEN_BATCHES", "*OUTPUT_SUCCESS_MESSAGES"} -- must match meta.xml <settings/>

modList = {}

local startupLoading = true
local playersWaitingQueue = {}
local clientsReady = {}
local settings = {}

for _, settingName in pairs(SETTING_NAMES) do
    local settingValue = get(settingName)
    if not settingValue then
        outputMsg("Setting value not set for: " .. settingName, 1)
        return
    end
    settings[settingName] = settingValue
end
outputSuccessMessages = settings["*OUTPUT_SUCCESS_MESSAGES"] == "true"

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

local function handlePlayerResourceStart(res)
    if res ~= resource then
        return
    end
    triggerClientEvent(source, "modloader_reborn:client:applySettings", resourceRoot, settings)
    clientsReady[source] = true
    if startupLoading then
        playersWaitingQueue[source] = true
        return
    end
    loadAllModsForPlayer(source)
end
addEventHandler("onPlayerResourceStart", root, handlePlayerResourceStart)

addEventHandler("onPlayerQuit", root, function()
    clientsReady[source] = nil
    playersWaitingQueue[source] = nil
end)

local function parseModFile(fileName)
    local realFilePath = string.format("%s/%s", CONFIG_DIR_MODS, fileName)
    if not pathIsFile(realFilePath) then
        return
    end
    local isDFF = endsWith(fileName, ".dff")
    local isTXD = endsWith(fileName, ".txd")
    local isCOL = endsWith(fileName, ".col")
    if not (isDFF or isTXD or isCOL) then
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
        modList[model].colPath = realFilePath
    elseif isTXD then
        modList[model].txdPath = realFilePath
    elseif isDFF then
        modList[model].dffPath = realFilePath
    end
end

local function prepareMods()
    if not pathIsDirectory(CONFIG_DIR_MODS) then
        outputMsg("Mods directory not found: " .. CONFIG_DIR_MODS, 1)
        return
    end

    for _, fileName in pairs(pathListDir(CONFIG_DIR_MODS) or {}) do
        parseModFile(fileName)
    end

    for player, _ in pairs(playersWaitingQueue) do
        loadAllModsForPlayer(player)
    end
    playersWaitingQueue = nil
    startupLoading = nil
end
addEventHandler("onResourceStart", resourceRoot, prepareMods, false)
