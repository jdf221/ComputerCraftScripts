local debug = false

local shouldRunListenLoopArg, networkIdArg = ...

local shouldRunListenLoopBool = false
local networkId = _G["wppNetworkId"]

networkId = networkId and networkId or networkIdArg 
if(shouldRunListenLoopArg == "--listen") then
    shouldRunListenLoopBool = true
else
    networkId = networkId or networkId and shouldRunListenLoopArg
end

if networkId == nil then
    print("A network ID must be supplied as an argument")
    return
end

local PROTOCOL = "wpp" .. "@" .. networkId
local THIS_COMPUTER_ID = os.getComputerID()

for n,v in ipairs({"top", "bottom", "front", "back", "left", "right"}) do
    if peripheral.getType(v) == "modem" and peripheral.call(v, "isWireless") then
        rednet.open(v)
        break
    elseif v == "right" then
        error("No wireless modem found", 2)
    end
end

os.setComputerLabel(PROTOCOL .. "://" .. THIS_COMPUTER_ID)
rednet.host(PROTOCOL, tostring(THIS_COMPUTER_ID))

local function log(message)
    if debug then
        print(message)
    end
end

local function splitString (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end


local function parsePeripheralUrl(peripheralUrl)
    urlParts = splitString(peripheralUrl, "/")
    

    return {clientId=tonumber(urlParts[2]), peripheralId=urlParts[3]}
end

local function sendMessage(clientId, func, data)
    log("Sending message: ".. func)
    if(data and data.method) then
        log("the method " .. data.method)
    end
    rednet.send(clientId, {func=func, data=data}, PROTOCOL)
end

local function sendReply(clientId, data)
    local dataTable = {func="reply", data=data}
    rednet.send(clientId, dataTable, PROTOCOL)
end

local function recieveReply()
    local clientId, message = rednet.receive(PROTOCOL, 2)
    
    if message == nil then
        return nil
    end
    
    
    if(message.func == "reply") then
        message.fromId = clientId;
        return message
    end
end


local wrappedFunctions = {
  getNames = function(message)
    log("getNames()")
    local names = {}
    for n, name in ipairs(peripheral.getNames()) do 
        table.insert(names,name)
    end

    sendReply(message.fromId, names)
  end,
  isPresent = function(message)
    log("isPresent(".. message.data ..")")

    sendReply(message.fromId, peripheral.isPresent(message.data))
  end,
  getType = function(message)
    log("getType(".. message.data ..")")

    sendReply(message.fromId, peripheral.getType(message.data))
  end,
  getMethods = function(message)
    log("getMethods(".. message.data ..")")

    sendReply(message.fromId, peripheral.getMethods(message.data))
  end,
  call = function(message)
    if message.data.args == nil then
        message.data.args = {}
    end
    
    log("call(".. message.data.peripheralId ..", ".. message.data.method ..", ".. textutils.serialize(message.data.args) ..")")
    
    local status,result = pcall(
            function() 
                local r = {peripheral.call(message.data.peripheralId, message.data.method, unpack(message.data.args))}
                return r
            end)
        
    sendReply(message.fromId, {result=result, err=not status})
  end,
  find = function()
    return false
  end
}

-- Public API Functions
rednetListenLoop = function()
    local event = {os.pullEventRaw()}
    if event[1] == "rednet_message" then
        if event[4] == PROTOCOL then
            log("Recieved message: " .. event[3].func)
            
            local message = event[3]
            message.fromId = event[2]
            wrappedFunctions[event[3].func](message)
        end
    elseif event[1] == "char" then
        if event[2] == "q" then
            return false
        end
    elseif event[1] == "terminate" then
        return false
    end
end

getNames = function()
    local allNames = {}
    
    local clients = table.pack(rednet.lookup(PROTOCOL))

    for n,clientId in ipairs(clients) do
        if clientId == THIS_COMPUTER_ID then
            allNames = peripheral.getNames()
        else
            sendMessage(clientId, "getNames")
            local reply = recieveReply()
    
            for n,name in ipairs(reply.data) do
                table.insert(allNames, PROTOCOL .."://" .. reply.fromId .. "/" .. name)
            end
        end
    end
        
    return allNames
end

isPresent = function(peripheralUrl)
    local parsedPeripheralUrl = parsePeripheralUrl(peripheralUrl)
    
    if parsedPeripheralUrl.clientId == nil then
        return peripheral.isPresent(peripheralUrl)
    else
        sendMessage(parsedPeripheralUrl.clientId, "isPresent", parsedPeripheralUrl.peripheralId)
        local reply = recieveReply()
    
        return reply.data;
    end
end

getType = function(peripheralUrl)
    local parsedPeripheralUrl = parsePeripheralUrl(peripheralUrl)
    
    if parsedPeripheralUrl.clientId == nil then
        return peripheral.getType(peripheralUrl)
    else
        sendMessage(parsedPeripheralUrl.clientId, "getType", parsedPeripheralUrl.peripheralId)
        local reply = recieveReply()
    
        return reply.data;
    end
end

getMethods = function(peripheralUrl)
    local parsedPeripheralUrl = parsePeripheralUrl(peripheralUrl)
    
    if parsedPeripheralUrl.clientId == nil then
        return peripheral.call(peripheralUrl, method)
    else
        sendMessage(parsedPeripheralUrl.clientId, "getMethods", parsedPeripheralUrl.peripheralId)
        local reply = recieveReply()
    
        return reply.data;
    end
end

call = function(peripheralUrl, method, ...)
    local parsedPeripheralUrl = parsePeripheralUrl(peripheralUrl)
    
    if parsedPeripheralUrl.clientId == nil then
        return peripheral.getMethods(peripheralUrl)
    else
        sendMessage(parsedPeripheralUrl.clientId, "call", {peripheralId=parsedPeripheralUrl.peripheralId, method=method, args={...}})
        local reply = recieveReply()
    
        if reply then
            if reply.data.err then
                error(reply.data.result)
            elseif reply.data.result then
                return unpack(reply.data.result)
            end
        end
    end
end

wrap = function(peripheralUrl)
    local parsedPeripheralUrl = parsePeripheralUrl(peripheralUrl)
    
    if parsedPeripheralUrl.clientId == nil then
        return peripheral.wrap(peripheralUrl)
    else
        local peripheralMethods = getMethods(peripheralUrl)
        
        local wrappedFunctionTable = {}
        for n,method in pairs(peripheralMethods) do 
            wrappedFunctionTable[method] = function(...)
                return call(peripheralUrl, method, ...)
            end
        end
    
        return wrappedFunctionTable;
    end
end

find = function(peripheralType, fnFilter)
    --TODO
    return false
end

if(shouldRunListenLoopBool) then
    log("Listening for Wireless Peripheral P2P messages on Rednet.\n\n  URL: ".. PROTOCOL .."://" .. os.getComputerID())
    while true do
        if rednetListenLoop() == false then
            return
        end
    end
end
