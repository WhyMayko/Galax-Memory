# Galax Memory

A Matcha memory library. It loads `Offsets.json` and `types.json`, requires both documents to use the same version, and converts reads and writes to the correct type. Consumer scripts never contain hardcoded offsets.

## Loading

Run `GalaxMemory.lua` before the consumer script. It registers `GalaxMemory` in Matcha's global environment because `loadstring` drops a chunk's top-level `return` value.

```lua
loadstring(game:HttpGet("URL/TO/GalaxMemory.lua"))()
local memory = GalaxMemory.new()
```

`GalaxMemory.new()` tries three sources for each document. If you host the files elsewhere, provide matching URL pairs:

```lua
local memory = GalaxMemory.new({
    offseturls = { "https://host/Offsets.json" },
    typeurls = { "https://host/types.json" },
})
```

## Usage

```lua
local humanoid = memory:bind(game:GetService("Players").LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid"))
humanoid.WalkSpeed = 50
humanoid.Sit = true
print(humanoid.Health)

local camera = memory:bind(workspace.CurrentCamera)
camera.FieldOfView = 100
print(camera.Position)
```

`bind` selects the most specific class available in the dump and also accepts an explicit base class: `memory:bind(part, "BasePart")`. Property names ignore case and separators, so `WalkSpeed` resolves to the current `Walkspeed` offset.

For Roblox's internal UI, always use the memory proxy rather than the original instance:

```lua
local screen = memory:bind(screenGui)
screen.Enabled = false

local label = memory:bind(textLabel)
label.Visible = false
```

`ScreenGui.Enabled` exclusively uses the `ScreenGui_Enabled` offset. A `ScreenGui` proxy does not expose `Visible` because that property does not belong to the class; this prevents accessing a `GuiObject` offset on the wrong type.

`BasePart.Color3` is read as three consecutive RGB bytes and returns a normalized `Color3`. The layout was verified on the character's `Head` with bytes `F8 F8 F8`, which equal `RGB(248, 248, 248)`. It remains read-only until writes are separately validated.

`DarkColor` is read-only. To use another threshold from `0` to `1`, call `memory:darkcolor(rawcharacter, threshold)`.

Other computed values can follow the same pattern: `memory:virtual("Class", "Property", getter)`. Register it before calling `bind`; it then appears on the proxy as a read-only value, such as `proxy.Property`.

For use without a proxy: `memory:read(instance, "Health")` and `memory:write(instance, "Health", 100)`.

## Supported types

Reads: `bool`, `byte`, `int`, `float`, `double`, pointers, `string`, `Vector2`, `Vector3`, `Color3`, `UDim2`, and 3×3 matrices. Writes are type-checked; `string`, matrices, and `unknown` types are read-only for safety. `UDim2` uses `{ xscale, xoffset, yscale, yoffset }`.

Every operation validates the instance, address, class, property, and type. Failures stop with an explicit message; the library never silently falls back to a different read.

## Validation

Run `Validate.lua` after loading the library for a read-only verification. It examines one instance of every class that exists in the open game and attempts to read every property exposed by the proxy, printing `Class:properties:failures`. Classes absent from the current game cannot be validated in that client, but remain available in the dump for games where they exist.
