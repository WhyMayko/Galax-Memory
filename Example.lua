loadstring(game:HttpGet("https://raw.githubusercontent.com/WhyMayko/Galax-Memory/main/GalaxMemory.lua"))()

local memory = GalaxMemory.new()
local camera = memory:bind(game:GetService("Workspace").CurrentCamera)

camera.FieldOfView = 100
print("fov: " .. tostring(camera.FieldOfView))
