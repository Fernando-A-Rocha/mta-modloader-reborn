local resourceName = getResourceName(resource)
local modloaderResourceName = "modloader_reborn"
addEventHandler("onResourceStart", root, function(res)
    if not (res == resource or getResourceName(res) == modloaderResourceName) then return end
    exports[modloaderResourceName]:importModForModel(12887, {
        colPath = ":".. resourceName .. "/files/cunte_roads50.col"
    })
end)
addEventHandler("onResourceStop", resourceRoot, function()
    exports[modloaderResourceName]:removeModForModel(12887)
end, false)
