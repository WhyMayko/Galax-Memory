local memory = GalaxMemory.new()
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local character = players.LocalPlayer.Character
assert(character, "character is required!")
local humanoidinstance = character:FindFirstChildWhichIsA("Humanoid")
assert(humanoidinstance, "humanoid is required!")
local humanoid = memory:bind(humanoidinstance)
local camera = memory:bind(workspace.CurrentCamera)

print("offset version: " .. memory.version)
print("walk speed: " .. humanoid.WalkSpeed)
print("camera fov: " .. camera.FieldOfView)

local characterproxy = memory:bind(character)
local head = memory:bind(character:FindFirstChild("Head"))
local skin = head.Color3
print("skin color: " .. tostring(skin.R) .. "," .. tostring(skin.G) .. "," .. tostring(skin.B))
print("dark color: " .. tostring(characterproxy.DarkColor))

humanoid.WalkSpeed = 50
humanoid.Sit = true
camera.FieldOfView = 100
