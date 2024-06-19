-- Modloader Reborn by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn) [June 2024]

outputSuccessMessages = true
function outputMsg(msg, level)
    if ((not level) or (level == 3)) and (not outputSuccessMessages) then return end
    local addPrefix = (not level) or (level == 3) or (level == 4)
    outputDebugString((addPrefix and "["..getResourceName(resource).."] " or "") .. msg, level)
end
