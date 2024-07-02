![MTA modloader reborn banner SM](https://github.com/Fernando-A-Rocha/mta-modloader-reborn/assets/34967844/d330016b-03e4-42a3-bd8b-bdb8793d25bc)

Modern, robust and easy to use modloader for MTA:SA.

Simply drag and drop the modded DFF/TXD/COL files into the mods folder. They will be downloaded and applied automatically for every player.

**Security feature**: Only files provided by the server are loaded, meaning that if the user adds random files to the mods directory in their resource cache, they won't be recognized and loaded.

**Supported models**: Currently the script will automatically replace vehicle, skin and object models via their ID or model name according to GTA:SA. Read the tutorial below.

## Download

**Latest release**: [https://github.com/Fernando-A-Rocha/mta-modloader-reborn/releases/latest](https://github.com/Fernando-A-Rocha/mta-modloader-reborn/releases/latest)

## Video

📽️ **Getting Started** video coming soon. I know it's easier to understand with a visual guide.

## Tutorial

Install the resource that you downloaded from the **Releases** page. Read [this guide](https://wiki.multitheftauto.com/wiki/Server_Manual#Installing/Updating_resources_on_your_server) if unsure how to add the resource to your server.

This script automatically matches the file names to the model IDs of the game. The files must be placed in the `mods` folder in the resource directory.

- Vehicles

Model IDs and game model names (dff & txd) are supported. [https://wiki.multitheftauto.com/wiki/Vehicle_IDs](https://wiki.multitheftauto.com/wiki/Vehicle_IDs)

- Skins

Model IDs and game model names (dff & txd) are supported. [https://wiki.multitheftauto.com/wiki/All_Skins_Page](https://wiki.multitheftauto.com/wiki/All_Skins_Page)

- Objects

Model IDs and game model names (dff, col and txd) are supported. [https://dev.prineside.com/gtasa_samp_model_id/](https://dev.prineside.com/gtasa_samp_model_id/)

Texture file names usually vary, and the same .txd can be reused for multiple models in GTA:SA.

To replace a model's collision, give the .col file the exact same name as the .dff (model name).

⚠️ Please note that GTA:SA has COL files that are used as **containers of multiple model collisions**. MTA will only load single-collision COL files. If you want to extract collisions into their own files use a tool like [CollEditor2](https://www.google.com/search?q=gta+sa+CollEditor2). Select a collision and right click - Export selected.

## Examples of valid mods
  
- Replacing the Infernus (ID 411): infernus.dff, infernus.txd OR 411.dff, 411.txd

- Replacing the Clown skin (ID 264): wmoice.dff, wmoice.txd OR 264.dff, 264.txd

## Scripting API

This resource features a scripting API that allows you to interact with the modloader or get information about the loaded mods.

### Clientside Events

- `"modloader_reborn:client:onModLoaded"` | *Source*: always **localPlayer**

Event is triggered when a mod is loaded (if it failed for some reason, the variable `loadSuccess` will be false)

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

Returns the mod loaded for a specific model ID

```lua
local mod = getModLoadedForModel(model)
if mod then
    print("Mod loaded for model ID " .. model,
        mod.dffPath,
        mod.txdPath,
        mod.colPath
    )
else
    print(("No mod loaded for model %d"):format(model))
end
```

- `table getModsLoaded()`

Returns a table containing all the mods loaded

```lua
local mods = getModsLoaded()
for model, mod in pairs(mods) do
    print(("Mod loaded for model %d: %s"):format(
        model,
        (mod.dffPath and (mod.dffPath .. " ") or "")
        .. (mod.txdPath and (mod.txdPath .. " ") or "")
        .. (mod.colPath and (mod.colPath) or "")
    ))
end
```

### Serverside Functions

- `bool setModForModel(number model, table mod)`

Defines a mod for a specific model ID that all players will automatically load.

- `bool removeModForModel(number model)`

Removes a mod for a specific model ID, unloading it for all players.
