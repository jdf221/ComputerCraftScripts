function setAutoFarmInfo(farmInfo)
  local infoFile = fs.open("AutoFarmInfo.txt", "w")
 
  infoFile.writeLine(farmInfo["width"])
  infoFile.writeLine(farmInfo["length"])
  infoFile.writeLine(farmInfo["seedName"])
  infoFile.writeLine(farmInfo["plantName"])
  infoFile.writeLine(farmInfo["grownMetadata"])
  infoFile.writeLine(farmInfo["x"])
  infoFile.writeLine(farmInfo["y"])
 
  infoFile.close()
end
 
function getAutoFarmInfo()
  local infoFile = fs.open("AutoFarmInfo.txt", "r")
 
  infoTable = {}
  infoTable["width"] = tonumber(infoFile.readLine())
  infoTable["length"] = tonumber(infoFile.readLine())
  infoTable["seedName"] = infoFile.readLine()
  infoTable["plantName"] = infoFile.readLine()
  infoTable["grownMetadata"] = tonumber(infoFile.readLine())
  infoTable["x"] = tonumber(infoFile.readLine())
  infoTable["y"] = tonumber(infoFile.readLine())
 
  infoFile.close()
 
  return infoTable
end  
 
function selectItem(itemName)
  for slotNumber = 1,16,1 do
    details = turtle.getItemDetail(slotNumber)
    
    if details and details.name == itemName then
      turtle.select(slotNumber)
      return details
    end
  end
  
  return false
end
 
if not fs.exists("AutoFarmInfo.txt") then
  local farmInfo = {}
 
  print("AutoFarm Setup")
  
  print("Inventory Items:")
  for slotNumber = 1,16,1 do    
    details = turtle.getItemDetail(slotNumber)
    
    if details then
      print(slotNumber .. ": " .. details.name)
    end
  end
  print("")
 
  io.write("Farm width: ")
  farmInfo["width"] = tonumber(read()) - 1
 
  io.write("Farm length: ")
  farmInfo["length"] = tonumber(read()) - 1
    
  io.write("Seed name: ")
  farmInfo["seedName"] = read()
    
  io.write("Plant name: ")
  farmInfo["plantName"] = read()
    
  io.write("Grown Metadata: ")
  farmInfo["grownMetadata"] = tonumber(read())
 
  farmInfo["x"] = 0
  farmInfo["y"] = 0
 
  setAutoFarmInfo(farmInfo)
end
 
function goFarm()
local seedSlot = nil
for slotNumber = 1,16,1 do
  details = turtle.getItemDetail(slotNumber)

  if details and details.name == farmInfo["seedName"] then
    if seedSlot == nil then
      seedSlot = slotNumber
    else
      turtle.select(slotNumber)
      turtle.transferTo(seedSlot)      
      turtle.drop()
    end
  end
end
    
farmInfo = getAutoFarmInfo()

selectItem("minecraft:coal")
turtle.refuel()
if turtle.getFuelLevel() > (farmInfo["width"] * (farmInfo["length"] + 3)) then
  for currentY = farmInfo["y"],farmInfo["width"],1 do
    farmInfo["y"] = currentY
  
    if farmInfo["x"] == farmInfo["length"] then
      forLoopEnd = 0
      forLoopStep = -1

      turtle.turnRight()
      turtle.forward()
      turtle.turnRight()
    else
      forLoopEnd = farmInfo["length"]
      forLoopStep = 1

      if currentY ~= 0 and currentX ~= 0 then
        turtle.turnLeft()
        turtle.forward()
        turtle.turnLeft()
      end
    end

    for currentX = farmInfo["x"],forLoopEnd,forLoopStep do
      farmInfo["x"] = currentX
      
      if forLoopStep == 1 and currentX ~= 0 then
        turtle.forward()
      end
      
      if forLoopStep == -1 and currentX ~= farmInfo["length"] then
          turtle.forward()
      end
      setAutoFarmInfo(farmInfo)
           
      local success, blockDetails = turtle.inspectDown()
      if success then
        if blockDetails.metadata == farmInfo["grownMetadata"] then
          turtle.digDown()
        end        
      end
      if selectItem(farmInfo["seedName"]) then
        turtle.placeDown()
      end
    end
  end

  if farmInfo["x"] ~= 0 then
  for i = 0,farmInfo["length"] - 1,1 do
      farmInfo["x"] = farmInfo["x"] - 1
      turtle.back()
      setAutoFarmInfo(farmInfo)
  end
  turtle.turnLeft()
  else
  turtle.turnRight()
  end
  
  
  for i = 0,farmInfo["width"] - 1,1 do
    farmInfo["y"] = farmInfo["y"] - 1
    turtle.forward()
    setAutoFarmInfo(farmInfo)
  end
  turtle.turnRight()

  farmInfo["x"] = farmInfo["x"] - 1
  turtle.back()
  setAutoFarmInfo(farmInfo)
  
  while selectItem(farmInfo["plantName"]) do
    turtle.dropDown()
  end
        
  
  farmInfo["x"] = farmInfo["x"] + 1
  turtle.forward()
  setAutoFarmInfo(farmInfo)
else
print("Not enough fuel")
end
end

farmInfo = getAutoFarmInfo()

while true do
  local success, blockDetails = turtle.inspectDown()
  if success then
    if blockDetails.metadata == farmInfo["grownMetadata"] then
      goFarm()
    end        
  end
end
