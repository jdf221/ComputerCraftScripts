fs.delete("wpp")
local newSource = http.get("https://ghcdn.rawgit.org/jdf221/RandomFiles/master/WirelessPeripheralP2P/client.lua")
local sourceFile = fs.open("wpp", "w")
sourceFile.write(newSource.readAll())
sourceFile.close()
