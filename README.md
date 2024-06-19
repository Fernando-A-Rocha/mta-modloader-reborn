![MTA modloader reborn banner SM](https://github.com/Fernando-A-Rocha/mta-modloader-reborn/assets/34967844/d330016b-03e4-42a3-bd8b-bdb8793d25bc)

Easy to use modloader for MTA:SA.

Simply drag and drop the modded DFF/TXD files into the mods folder. They will be downloaded and applied automatically for every player.

**Security feature**: Only files provided by the server are loaded, meaning that if the user adds random files to the mods directory in their resource cache, they won't be recognized and loaded.

**Supported models**: Currently the script will automatically replace vehicle and skin models via their ID or model name according to GTA:SA.

## Download

**Latest release**: [https://github.com/Fernando-A-Rocha/mta-modloader-reborn/releases/latest](https://github.com/Fernando-A-Rocha/mta-modloader-reborn/releases/latest)

## Tutorial

This script automatically matches the file names to the model IDs of the game. The files must be placed in the `mods` folder in the resource directory.

- Vehicles

Model IDs and game model names (dff & txd) are supported. [https://wiki.multitheftauto.com/wiki/Vehicle_IDs](https://wiki.multitheftauto.com/wiki/Vehicle_IDs)

- Skins

Model IDs and game model names (dff & txd) are supported. [https://wiki.multitheftauto.com/wiki/All_Skins_Page](https://wiki.multitheftauto.com/wiki/All_Skins_Page)

## Examples of valid mods
  
Replacing the Infernus (ID 411):

- infernus.dff
- infernus.txd

or

- 411.dff
- 411.txd

Replacing the Clown skin (ID 264):

- wmoice.dff
- wmoice.txd

or

- 264.dff
- 264.txd

## Scripting API

This resource features a scripting API that allows you to interact with the modloader or get information about the loaded mods.

### Clientside Events

- `modloader_reborn:client:onModLoaded` | *Source*: always **localPlayer**

```lua
addEventHandler("modloader_reborn:client:onModLoaded", localPlayer,
    function(
            model, -- MTA Model ID number
            mod, -- Table containing mod information such as file paths
            loadSuccess, -- Boolean indicating if the mod was loaded successfully
            loadedCount, remainingCount -- Number of mods loaded and remaining
        )
        local progress = loadedCount / (loadedCount + remainingCount)
        print("Mods loading progress: " .. math.floor(progress * 100) .. "%")
        if progress == 1 then
            print("All mods loaded.")
        end
    end,
false)
```

### Clientside Functions

- `table / nil getModLoadedForModel(number model)`

```lua
local mod = getModLoadedForModel(model)
if mod then
    print(("Mod loaded for model %d: %s"):format(
        model,
        (mod.dffPath and (mod.dffPath .. " ") or "")
        .. (mod.txdPath and (mod.txdPath .. " ") or "")
        .. (mod.colPath and (mod.colPath) or "")
    ))
else
    print(("No mod loaded for model %d"):format(model))
end
```
