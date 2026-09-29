loadstring(game:HttpGet("https://raw.githubusercontent.com/WhyMayko/Memory-Module/main/MemoryModule.lua"))()

local memory = MemoryModule.new()
local camera = memory:bind(game:GetService("Workspace").CurrentCamera)

camera.FieldOfView = 100
print("fov: " .. tostring(camera.FieldOfView))
