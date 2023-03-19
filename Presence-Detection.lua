commandArray = {}

DebugLevel = 0

function Debug (log)

   if(DebugLevel == 1) then

       print('Presence-Detection.lua DEBUG: ' .. log)

    end

end

Presence = false

if tonumber(otherdevices_svalues['Motion - Living Room']) > 0 then
    
    Debug("Motion detected at Living Room.")
    Presence = true
    
end

if tonumber(otherdevices_svalues['Motion - Hallway']) > 0 then
    
    Debug("Motion detected at Hallway.")
    Presence = true
    
end

if tonumber(otherdevices_svalues['PU Living Room - TV']) > 80  then
    
    Debug("Power consumption detected at Living Room - TV.")
    Presence = true
    
end

if tonumber(otherdevices_svalues['PU Living Room - PC']) > 100 then
    
    Debug("Power consumption detected at Living Room - PC.")
    Presence = true

end
 
if otherdevices['950XL Peter'] == 'On' then
    
    Debug("Device 950XL Peter came online.")
    Presence = true

end

if otherdevices['Front Door'] == 'On' then
    
    Debug("Front Door opened.")
    Presence = true

end


if Presence == true then
    
    if otherdevices['Presence Detection'] == 'Off' then
        
    Debug("One or more presence conditions are set to true, activating Presence Detection switch.")
    commandArray['Presence Detection'] = 'On'

    end

else

    if otherdevices['Presence Detection'] == 'On' then
        
    Debug("Presence Detection is set to false, deactivating Presence Detection switch.")
    commandArray['Presence Detection'] = 'Off'

    end

end

return commandArray
