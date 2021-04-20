
-- TODO: Update the RTF Documentation with Changelog info...

do -- globals
	PROXY_CMDS = {}
	EX_CMDS = {}
	ON_PROPERTY_CHANGED = {}
	STATE = STATE or false
	TOGGLE_STATE = TOGGLE_STATE or false
	LED = LED or {}
	LED ['On'] = LED ['On'] or '000000'
	LED ['Off'] = LED ['Off'] or '000000'
	LED ['Pressed'] = LED ['Pressed'] or '000000'

	C4:AddVariable("STATE", "", "STRING")
	STATE_NAME = STATE_NAME or {}
	STATE_NAME ['Selected'] = 'On'
	STATE_NAME ['Default'] = 'Off'
end

function OnDriverInit ()
	C4:UpdateProperty ('Driver Version', C4:GetDriverConfigInfo ("version"))
	OnPropertyChanged('On LED Color')
	OnPropertyChanged('Off LED Color')
	OnPropertyChanged('Toggle State Each Time Selected')
end


function OnVariableChanged(sVariable)
  if (sVariable == "STATE") then
    STATE = (Variables[sVariable] == "On")
    DisplayState (STATE)
  end
end


function OnPropertyChanged(sProperty)

	local propertyValue = Properties[sProperty]

	-- Remove any spaces (trim the property)
	local trimmedProperty = string.gsub(sProperty, " ", "")

	-- if function exists then execute (non-stripped)
	if (ON_PROPERTY_CHANGED[sProperty] ~= nil and type(ON_PROPERTY_CHANGED[sProperty]) == "function") then
		ON_PROPERTY_CHANGED[sProperty](propertyValue)
		return
	-- elseif trimmed function exists then execute
	elseif (ON_PROPERTY_CHANGED[trimmedProperty] ~= nil and type(ON_PROPERTY_CHANGED[trimmedProperty]) == "function") then
		ON_PROPERTY_CHANGED[trimmedProperty](propertyValue)
		return
	end
end

function ON_PROPERTY_CHANGED.ToggleStateEachTimeSelected (value)
	TOGGLE_STATE = (value == 'Yes')
	DisplayState (STATE)
end

function ON_PROPERTY_CHANGED.OnLEDColor (value)
	LED ['On'] = RGB2HEX (value)
	C4:SendToProxy(500, "BUTTON_COLORS", {ON_COLOR = {COLOR_STR = LED ['On']}, OFF_COLOR = {COLOR_STR = LED ['Off']}}, "NOTIFY")
	C4:SendToProxy(501, "BUTTON_COLORS", {ON_COLOR = {COLOR_STR = LED ['On']}, OFF_COLOR = {COLOR_STR = '000000'}}, "NOTIFY")
end

function ON_PROPERTY_CHANGED.OffLEDColor (value)
	LED ['Off'] = RGB2HEX (value)
	C4:SendToProxy(500, "BUTTON_COLORS", {ON_COLOR = {COLOR_STR = LED ['On']}, OFF_COLOR = {COLOR_STR = LED ['Off']}}, "NOTIFY")
	C4:SendToProxy(502, "BUTTON_COLORS", {ON_COLOR = {COLOR_STR = LED ['Off']}, OFF_COLOR = {COLOR_STR = '000000'}}, "NOTIFY")
end

function ExecuteCommand (strCommand, tParams)
    if EX_CMDS and type(EX_CMDS[strCommand]) == "function" then
            EX_CMDS[strCommand](tParams)
    elseif strCommand == "LUA_ACTION" then
        if tParams ~= nil then
            for cmd, cmdv in pairs(tParams) do
                print (cmd,cmdv)
                if cmd == "ACTION" then
                    if ACTIONS and type(ACTIONS[cmdv]) == "function" then
                        ACTIONS[cmdv](tParams)
                    else
                        print("From ExecuteCommand Function - Undefined Action")
                        print("Key: " .. cmd .. " Value: " .. cmdv)
                    end
                else
                    print("From ExecuteCommand Function - Undefined ACTION")
                    print("Key: " .. cmd .. " Value: " .. cmdv)
                end
            end
        end
    end
end

function ReceivedFromProxy (idBinding, strCommand, tParams)
    if type(PROXY_CMDS[strCommand]) == "function" then
        local success, retVal = pcall(PROXY_CMDS[strCommand], tParams, idBinding)
        if success then
            return retVal
        end
    end
    return nil
end

function PROXY_CMDS.DO_CLICK (tParams, idBinding)
	if (idBinding == 500) then
		-- Toggle button click acts like UI button pressed
		PROXY_CMDS.SELECT (tParams)

	elseif (idBinding == 501) then
		STATE = true
		DisplayState (STATE)

	elseif (idBinding == 502) then
		STATE = false
		DisplayState (STATE)

	else
		print ('Unhandled binding ' .. idBinding)
	end
end

function PROXY_CMDS.REQUEST_BUTTON_COLORS (tParams, idBinding)
	if (idBinding == 500) then
		C4:SendToProxy(500, "BUTTON_COLORS", {ON_COLOR = {COLOR_STR = LED ['On']}, OFF_COLOR = {COLOR_STR = LED ['Off']}}, "NOTIFY")

	elseif (idBinding == 501) then
		C4:SendToProxy(501, "BUTTON_COLORS", {ON_COLOR = {COLOR_STR = LED ['On']}, OFF_COLOR = {COLOR_STR = '000000'}}, "NOTIFY")

	elseif (idBinding == 502) then
		C4:SendToProxy(502, "BUTTON_COLORS", {ON_COLOR = {COLOR_STR = LED ['Off']}, OFF_COLOR = {COLOR_STR = '000000'}}, "NOTIFY")

	else
		print ('Unhandled binding ' .. idBinding)
	end
end

function PROXY_CMDS.SELECT (tParams, idBinding)
	--print("SELECT")
	--print(tostring(STATE))
	STATE = not STATE
	--print(tostring(STATE))
	if TOGGLE_STATE then
		DisplayState (STATE)
	end

end

function EX_CMDS.SetState (tParams)
	STATE = (tParams.State == 'On')
	DisplayState (STATE)
end

function EX_CMDS.ToggleState (tParams)
  PROXY_CMDS.SELECT (tParams)
end

function DisplayState (state)
		if state then
			C4:SendToProxy(5001, "ICON_CHANGED", {icon= 'Selected'})
			C4:FireEvent('On')
	                C4:SetVariable("STATE", STATE_NAME["Selected"])
	                C4:UpdateProperty ('Current State', STATE_NAME['Selected'])
			C4:SendToProxy (500, 'MATCH_LED_STATE', {STATE = '1'})
			C4:SendToProxy (501, 'MATCH_LED_STATE', {STATE = '1'})
			C4:SendToProxy (502, 'MATCH_LED_STATE', {STATE = '0'})
		else
			C4:SendToProxy(5001, "ICON_CHANGED", {icon= 'Default'})
			C4:FireEvent('Off')
	                C4:SetVariable("STATE", STATE_NAME["Default"])
	                C4:UpdateProperty ('Current State', STATE_NAME['Default'])
			C4:SendToProxy (500, 'MATCH_LED_STATE', {STATE = '0'})
			C4:SendToProxy (502, 'MATCH_LED_STATE', {STATE = '1'})
			C4:SendToProxy (501, 'MATCH_LED_STATE', {STATE = '0'})
		end
end
function RGB2HEX (rgb)
	local hex = ''
	for color in string.gmatch(rgb, "%d+") do
		hex = hex .. string.format ('%02x', color)
	end
	return hex
end




