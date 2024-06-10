-- Modloader Reborn by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn) [June 2024]

local modList = nil
local playersWaitingQueue = {}

local function handlePlayerResourceStart(res)
    if res ~= resource then
        return
    end
    if not modList then
        playersWaitingQueue[source] = true
        return
    end
    triggerClientEvent(source, "modloader_reborn:loadMods", resourceRoot, modList)
end
addEventHandler("onPlayerResourceStart", root, handlePlayerResourceStart)

local function prepareMods()

    local CONFIG_DIR_MODS = "mods"

    local function endsWith(str, ending)
        return ending == '' or str:sub(-#ending) == ending
    end

    if not pathIsDirectory(CONFIG_DIR_MODS) then
        outputMsg("Mods directory not found: " .. CONFIG_DIR_MODS, 1)
        return
    end

    modList = {}

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
        if isDFF then
            modList[#modList+1] = {type="dff", model=model, path=realFilePath}
        else
            modList[#modList+1] = {type="txd", model=model, path=realFilePath}
        end
    end

    for _, fileName in pairs(pathListDir(CONFIG_DIR_MODS) or {}) do
        parseModFile(fileName)
    end
    for player, _ in pairs(playersWaitingQueue) do
        triggerClientEvent(player, "modloader_reborn:loadMods", resourceRoot, modList)
    end
    playersWaitingQueue = nil
end
addEventHandler("onResourceStart", resourceRoot, prepareMods, false)
