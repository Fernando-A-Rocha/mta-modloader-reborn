-- Modloader Reborn by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn) [June 2024]

resourceName = getResourceName(resource)

function outputMsg(msg, level)
    if ((not level) or (level == 3)) and (settings["*OUTPUT_SUCCESS_MESSAGES"] ~= "true") then return end
    local addPrefix = (not level) or (level == 3) or (level == 4)
    outputDebugString((addPrefix and "["..resourceName.."] " or "") .. tostring(msg), level)
end
