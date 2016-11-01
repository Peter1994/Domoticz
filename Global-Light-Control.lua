commandArray = {}
-- Start config
-- Set the debug level. 0 = No debugging, 1 = debug on
DebugLevel = 0
-- At what Dim level should the Hallway light set to when no motion is detected at the hallway?
SleepDimLevel = 5
-- What minimum Dim level should the script not exceed?
MinDimLevel = 25
-- What maximum Dim level should the script not exceed?
MaxDimLevel = 50
-- How much earlier should the script calculate the sunset Dim level?
SunsetOffset = 60
-- How much later should the script calculate the sunrise Dim level?
SunriseOffset = 60
-- From what time should the script calculate the sunrise? Count from 0:00, for example after 05:00 SunriseTimeOffset = 300
SunriseTimeOffset = 300
-- How long should the script wait to turn off the lights after no devices report the lights should be turned on?
LightSwitchTimeoutValue = 10
-- End config
-- Define time variables
timenow = os.date("*t")
minutesnow = timenow.min + timenow.hour * 60
-- Debug function
function Debug (log)

   if(DebugLevel == 1) then

       print('Global-Light-Control.lua DEBUG: ' .. log)

    end

end

-- Calculate dim level based on sunrise / sunset time and current time
function CalcDimLevel ()

    Debug("Calculating Dim level...")

        -- Choose the dim level based on static time
        if timenow.hour > 15 and timenow.hour < 24 then
            
            -- Calculate Sunset Dim level
            Debug("Choosing Sunset Dim level as Dim level.")  
            Suntime = timeofday['SunsetInMinutes'] - SunsetOffset
            CurrentSuntime = minutesnow - Suntime
            TotalSuntime = 1440 - Suntime
            CalcDimLevel1 = CurrentSuntime / TotalSuntime
            CalcDimLevel2 = 100 - CalcDimLevel1 * 100
            DimLevel = tonumber(string.format("%.0f", CalcDimLevel2))

        elseif minutesnow >= SunriseTimeOffset and timenow.hour < 12 then

            -- Calculate Sunrise Dim level
            Debug("Choosing Sunrise Dim level as Dim level.") 
            Suntime = timeofday['SunriseInMinutes'] + SunriseOffset
            TotalSuntime = Suntime - SunriseTimeOffset
            CurrentSuntime = minutesnow - SunriseTimeOffset
            CalcDimLevel1 = CurrentSuntime / TotalSuntime
            CalcDimLevel2 = CalcDimLevel1 * 100
            DimLevel = tonumber(string.format("%.0f", CalcDimLevel2))
            
        else

            Debug("Current time does not qualify one of the Sunset or Sunrise periods, configuring Dim level at Minimum Dim level!")
            DimLevel = MinDimLevel

        end

        -- Check the dim level for errors and configure the DimLevel variable
        if DimLevel < MinDimLevel then

            Debug("Calculated Dim level is at " ..DimLevel.. "%, lower than the Minimum Dim level, configuring Dim level at " ..MinDimLevel.. "%.")
            DimLevel = MinDimLevel

        elseif DimLevel >= MinDimLevel and DimLevel <= MaxDimLevel then

            Debug("Calculated Dim level is at " ..DimLevel.. "%.")
            
        elseif DimLevel > MaxDimLevel then

            Debug("Calculated Dim level is at " ..DimLevel.. "%, higher than the Maximum Dim level, configuring Dim level at " ..MaxDimLevel.. "%.")
            DimLevel = MaxDimLevel

        elseif DimLevel >= 100 then

            Debug("Calculated Dim level is " ..DimLevel.. "%, higher than 100%, configuring Dim level at 100%.")
            DimLevel = 100

        else

            Debug("ERROR: Dim level calculation went wrong, configuring DimLevel at Minimum Dim level!")
            DimLevel = MinDimLevel

        end

    -- Return the configured DimLevel variable
    return DimLevel

end

-- Set dim level for light function
function SwitchLight (lightname, level)

        if (otherdevices_svalues[lightname] ~= tostring(level)) then

            commandArray[lightname] = 'Set Level: ' ..tostring(level)
            Debug("Switching " .. lightname .. " to " .. level .. "%.")

        else
        
            Debug(lightname.. " is already at " ..level.. ".")

        end
end

-- Timeout function to prevent the lights switchting on right after they have been turned off
function LightSwitchTimeout ()

    LightSwitchTimeoutOutput = true

    t1 = os.time()
    s = otherdevices_lastupdate['Presence Detection']
    -- returns a date time like 2013-07-11 17:23:12
    hour = string.sub(s, 12, 13)
    minutes = string.sub(s, 15, 16)
    
    lastupdatetime = minutes + hour * 60
    
    if (otherdevices['Presence Detection'] == 'Off' and minutesnow > lastupdatetime + LightSwitchTimeoutValue) then
       
       Debug("LightSwitchTimeout exceeded, returning false.")
       LightSwitchTimeoutOutput = false
       
    elseif (otherdevices['Presence Detection'] == 'Off' and minutesnow > lastupdatetime and minutesnow < lastupdatetime + LightSwitchTimeoutValue) then
       
       Debug("LightSwitchTimeout between lastupdatetime and LightSwitchTimeout, returning true.")
        LightSwitchTimeoutOutput = true
       
    else
    
        Debug("Something went wrong with the LightSwitchTimeout function.")
       
    end 
    
    return LightSwitchTimeoutOutput

end

Debug("--------------- START ---------------")
Debug("The script has been activated.")

-- Check if Motion is detected or if one of the Wall Plugs is reporting power usage
if (otherdevices['Presence Detection'] == 'On') then
    
    Debug("It seems like somebody is home...")
        -- First check if the Lux level is under certain value
        if (tonumber(otherdevices_svalues['Lux - Living Room']) <= 30) then

            Debug("Lux Sensor reporting Lux value under 30")
    
            -- Call CalcDimLevel function
            SwitchDimLevel = CalcDimLevel()
    
            -- Hallway part start
            if (minutesnow >= timeofday['SunsetInMinutes'] - SunsetOffset or minutesnow <= timeofday['SunriseInMinutes'] + SunriseOffset) then
            
                if (otherdevices['Motion - Hallway'] == 'On' or otherdevices['Front Door'] == 'On') then
                
                    Debug("Someone is walking at the Hallway, waking light up...")
                    SwitchLight('Lights - Hallway', SwitchDimLevel - 15)
                
                else
                
                    Debug("It seems like nobody is at the hallway anymore, returning light to sleep dim level...")
                    SwitchLight('Lights - Hallway', SleepDimLevel)
                
                end
            
            else
            
                Debug("Current time is outside schedule for Hallway light, turning off light...")
                SwitchLight('Lights - Hallway', 0)
            
            end
            -- Hallway part end

            -- Check if current time is 30 minutes before sunset
            if (minutesnow >= timeofday['SunsetInMinutes'] - SunsetOffset) then

                -- Switch lights to on with decided dim level
                Debug("Current time is after current sunset time, activating lights.")
                SwitchLight('Lights - Living Room - TV', SwitchDimLevel)
                SwitchLight('Lights - Living Room - PC', SwitchDimLevel - 20)
                SwitchLight('Lights - Kitchen', SwitchDimLevel - 15)

            -- Check if current time is 240 minutes before sunrise and 30 minutes after sunrise
            elseif (minutesnow >= 0 and minutesnow <= timeofday['SunriseInMinutes'] + SunriseOffset) then

                -- Switch lights to on with decided dim level
                Debug("Current time is between the configured schedule before sunrise, activating lights.")
                SwitchLight('Lights - Living Room - TV', SwitchDimLevel)
                SwitchLight('Lights - Living Room - PC', SwitchDimLevel - 20)
                SwitchLight('Lights - Kitchen', SwitchDimLevel - 15)

            else

                -- Switch lights to off
                Debug("Current time didn't match any sunset/sunrise schedule, deactivating lights.")
                SwitchLight('Lights - Living Room - TV', 0)
                SwitchLight('Lights - Living Room - PC', 0)
                SwitchLight('Lights - Kitchen', 0)

            end
        else

        Debug("Lux Sensor is reporting too much light! Turning off lights.")
        SwitchLight('Lights - Living Room - TV', 0)
        SwitchLight('Lights - Living Room - PC', 0)
        SwitchLight('Lights - Kitchen', 0)
        SwitchLight('Lights - Hallway', 0)

    end

-- Check if power usage is high enough to keep the lights at current state
elseif(otherdevices['Presence Detection'] == 'Off') then

    Debug("It seems like nobody is home...")
    -- Timeout check to prevent the lights switchting on right after they have been turned off
    LightSwitchTimeout()
    if LightSwitchTimeoutOutput == false then

        -- Current time exceeded timeout value, now it's time to turn the lights off
        Debug("Presence Detection is off, turning off lights.")
        SwitchLight('Lights - Living Room - TV', 0)
        SwitchLight('Lights - Living Room - PC', 0)
        SwitchLight('Lights - Kitchen', 0)
        SwitchLight('Lights - Hallway', 0)

    elseif LightSwitchTimeoutOutput == true then

        -- Making sure the lights are switched off after LightSwitchTimeout countdown
        Debug("Waiting before turning lights off, LightSwitchTimeout still active.")

    else
    
        -- Do nothing...
        Debug("Nothing to do, script sleeping...")

    end
else

    Debug("Something went wrong. Leaving lights at current state...")

end

Debug("---------------- END ----------------")

return CommandArray
