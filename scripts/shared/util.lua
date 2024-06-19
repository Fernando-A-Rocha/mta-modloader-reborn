-- Modloader Reborn by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn) [June 2024]

outputSuccessMessages = true
function outputMsg(msg, level)
    if ((not level) or (level == 3)) and (not outputSuccessMessages) then return end
    outputDebugString("["..getResourceName(resource).."] " .. msg, level)
end
