commandArray = {}

if otherdevices['All Lights'] == "On" then
    
    print("Turning all lights on if not yet on.")
    if otherdevices['Living Room'] == 'Off' then
    commandArray['Living Room'] = 'On'
    end
    
    if otherdevices['Kitchen'] == 'Off' then
    commandArray['Kitchen'] = 'On'
    end
    
elseif otherdevices['All Lights'] == "Off" then
    
    print("Turning all lights off if not yet off.")
    if otherdevices['Living Room'] == 'On' or tonumber(otherdevices_svalues['Living Room']) > 0 then
    commandArray['Living Room'] = 'Off'
    end
    
    if otherdevices['Kitchen'] == 'On' or tonumber(otherdevices_svalues['Kitchen']) > 0 then
    commandArray['Kitchen'] = 'Off'
    end
    
else
    
    print("AllSwitchesToggle script didn't know what to do!")
    
end

return commandArray
