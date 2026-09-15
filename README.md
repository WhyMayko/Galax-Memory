# Galax Memory

Galax Memory is a Matcha memory library. It loads version-matched `Offsets.json` and `types.json`, resolves the required memory type, and exposes supported fields through a Lua proxy. Consumer scripts do not contain hardcoded offsets.

## Quick start

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/WhyMayko/Galax-Memory/main/GalaxMemory.lua"))()

local memory = GalaxMemory.new()
local camera = memory:bind(game:GetService("Workspace").CurrentCamera)

camera.FieldOfView = 100
print(camera.FieldOfView)
```

## API

### `GalaxMemory.new(options?)`

Loads the offset and type manifests and returns a library instance. The manifests must report the same Roblox version. The default configuration tries three URLs for each manifest.

```lua
local memory = GalaxMemory.new({
    offseturls = { "https://host/Offsets.json" },
    typeurls = { "https://host/types.json" },
})
```

Status: runtime validated.

### `memory:bind(instance, requestedclass?)`

Returns a memory proxy for an Instance. The proxy uses field access with `.`. Property names ignore case and separators, so `WalkSpeed`, `walkspeed`, and `WALK_SPEED` resolve to the same dump property.

```lua
local humanoid = memory:bind(rawhumanoid)
humanoid.WalkSpeed = 50
print(humanoid.Health)
```

Pass `requestedclass` only when a supported base schema is required:

```lua
local part = memory:bind(rawpart, "BasePart")
print(part.Transparency)
```

Status: runtime validated for `Camera`, `Humanoid`, `MeshPart`, `Workspace`, and `DataModel`. Other classes require validation in a game that contains them.

### `memory:read(instance, property, requestedclass?)`

Reads one property without creating a proxy.

```lua
local health = memory:read(rawhumanoid, "Health")
```

Status: structurally validated; the public call has not been independently runtime-tested.

### `memory:write(instance, property, value)`

Writes one property without creating a proxy. The value is checked against the resolved memory type.

```lua
memory:write(rawcamera, "FieldOfView", 100)
```

Status: structurally validated; the public call has not been independently runtime-tested.

### Proxy methods

```lua
local proxy = memory:bind(rawinstance)

print(proxy:address())
print(proxy:class())
for _, property in ipairs(proxy:properties()) do
    print(property)
end
```

| Method | Result | Status |
| --- | --- | --- |
| `proxy:address()` | Instance memory address | Runtime validated |
| `proxy:class()` | Original instance class name | Runtime validated |
| `proxy:properties()` | Sorted supported property names | Used by `Validate.lua`; runtime validated |
| `proxy:animations()` | Dictionary of active animation tracks `{ [id] = { id = id, tp = tp } }` | Runtime validated |
| `proxy:lookat(target_pos, method?)` | Rotates BasePart primitive rotation matrix towards target position | Runtime validated |

### `memory:animations(animator)`

Traverses an `Animator` instance's `ActiveAnimations` linked list directly in memory. Resolves each playing track's `AnimationId` string and `TimePosition` float. Returns `{ [id] = { id = id, tp = tp } }`.

```lua
local tracks = memory:animations(rawanimator)
for id, info in pairs(tracks) do
    print(id, info.tp)
end
```

### `memory:lookat(part, target_pos, method?)`

Rotates a `BasePart` instance (or proxy) towards a 3D `Vector3` position.

- `method = "rotation"` (default): Writes the 3x3 orthonormal orientation matrix directly to `Primitive.Rotation` (`BasePart.Primitive + 200`) in memory without modifying CFrame. **Crucial for combat:** Preserves `AssemblyLinearVelocity` and running/strafing physics without freezing player momentum.
- `method = "cframe"`: Sets `part.CFrame = CFrame.lookAt(part.Position, target_pos)`. Triggers the native Roblox physics transform setter, which halts/resets character velocity.

```lua
memory:lookat(humanoidRootPart, enemyPosition, "rotation")
```

### Safe Raw Memory Access

Direct, guarded accessors with null/invalid address protection (returns `nil` instead of throwing):

```lua
local ptr = memory:pointer(address)   -- or memory:ptr(address)
local str = memory:string(address)
local num = memory:float(address)
local val = memory:byte(address)
local int = memory:int(address)
local mat = memory:matrix(address)
memory:writematrix(address, mat_table)
```

## Proxy behavior

The bound proxy wraps the original Matcha Instance, providing seamless access to both memory-backed fields and native Matcha properties:

```lua
local raw = game:GetService("Workspace").CurrentCamera
local camera = memory:bind(raw)

camera.FieldOfView = 100 -- memory-backed field
print(camera.Name)       -- native Matcha property fallback!
```

- **Transparent Fallback:** If a field is not mapped in memory, the proxy seamlessly delegates to `proxy.instance[field]`. Native methods (e.g. `:GetChildren()`) are automatically bound.
- **Weak-Table Proxy Cache:** `memory:bind(instance)` caches proxies using a weak table (`__mode = "k"`), returning the existing wrapper with zero allocations in high-frequency 60 FPS render loops.

For Roblox UI, bind the UI instance before accessing memory-backed fields:

```lua
local screen = memory:bind(screenGui)
screen.Enabled = false

local label = memory:bind(textLabel)
label.Visible = false
```

`ScreenGui.Enabled` maps to `GuiObject.ScreenGui_Enabled`. A `ScreenGui` proxy intentionally does not expose `Visible`.

## Type support

| Dump type | Library behavior | Runtime status |
| --- | --- | --- |
| `bool` | Reads and writes one byte as `true` or `false` | Read validated through `Humanoid.Sit`, Lighting shadows, and enabled effects; writes not validated |
| `byte`, `BYTE`, `unsigned char` | Reads and writes one byte | Byte reads validated as part of `BasePart.Color3`; generic write not validated |
| `int` | Reads and writes a signed integer | Executed in the read probe; value semantics not verified |
| `short` | Reads as `int` | Not validated; this layout requires dedicated verification |
| `float` | Reads and writes IEEE float | Semantically validated for Lighting fog/brightness and effect intensity/size fields; writes not validated |
| `double` | Reads and writes IEEE double | Executed in the read probe; value semantics not verified |
| `unsigned __int64`, `uintptr_t` | Reads and writes a pointer | Pointer reads validated; writes not validated |
| `string` | Reads a pointer, then a null-terminated string | Validated with Decal, Texture, MeshPart, SurfaceAppearance, and Clothing asset paths |
| `Vector2` | Reads or writes two floats | Not validated |
| `Vector3` | Reads or writes three floats | Not validated |
| `Color3` | Reads or writes three floats | Not validated |
| `BasePart.Color3` | Reads three consecutive RGB bytes as normalized `Color3` | Validated on a character `Head` |
| `Camera.FieldOfView` | Converts between public degrees and the internal radians float | Experimental: the memory field accepts and retains writes, but does not synchronize Matcha's native camera property |
| `UDim2` | Reads or writes `{ xscale, xoffset, yscale, yoffset }` | Not validated |
| `Matrix3x3`, `ViewMatrix_t` | Reads nine floats | Not validated; read-only |
| `unknown`, `ColorUint_8` | Rejected with an explicit error | Rejection path not independently runtime-tested |

`string`, matrices, `unknown`, and the byte-packed `BasePart.Color3` are read-only. The library errors explicitly instead of silently choosing another type.

## Class support

Every offset/type pair in the current manifest is loaded dynamically. The proxy also includes explicit base-schema support for these runtime classes:

| Runtime class | Added base schema |
| --- | --- |
| `Part`, `MeshPart`, `WedgePart`, `CornerWedgePart`, `TrussPart`, `Seat`, `VehicleSeat`, `SpawnLocation`, `UnionOperation`, `NegateOperation`, `PartOperation` | `BasePart` |
| `ScreenGui`, `BillboardGui`, `SurfaceGui`, `Frame`, `ScrollingFrame`, `TextLabel`, `TextButton`, `TextBox`, `ImageLabel`, `ImageButton`, `VideoFrame`, `ViewportFrame` | `GuiObject` |
| `Shirt`, `Pants`, `ShirtGraphic` | `Clothing` |
| `Decal`, `Texture` | `Textures` |

The Matcha runtime reports `Instance:IsA` as unreliable, so class inheritance uses this explicit table rather than calling `IsA`.

## Validation status

| Scope | Result |
| --- | --- |
| Manifest structure | All 388 current offset/type pairs have matching local entries |
| Remote manifest loading | Validated in Matcha; both documents loaded and reported the same version |
| Library remote loading | Validated from the published GitHub raw URL |
| `Camera.FieldOfView` | Memory read converted correctly; a 100-degree write persisted for 0.5 s and was restored, but native Matcha FOV remained unchanged |
| `Humanoid.WalkSpeed` and `Humanoid.Sit` | Read validated |
| `BasePart.Color3` | Validated against raw `F8 F8 F8` bytes and returned RGB `248, 248, 248` |
| Low-level read probe | 222 properties across 34 schemas read without runtime errors |
| Lighting | `FogStart = 0`, `FogEnd = 100000`, `Brightness = 3`, and `GlobalShadows = true` read from memory |
| Lighting effects | Sky, Atmosphere, SunRaysEffect, BloomEffect, DepthOfFieldEffect, and BlurEffect read without errors; their scalar values were plausible for the active scene |
| Texture assets | Decal/Texture IDs, MeshPart.MeshId, SurfaceAppearance ColorMap/NormalMap, and Clothing.Template returned concrete asset paths or IDs |
| All 388 runtime values | Not fully validated; only schemas and instances present in the test game were probed |

No bulk write test was run. Memory writes use the exact address and type selected by the manifest, so each new writable layout should be validated separately before relying on it.

## Validation script

Run `Validate.lua` after loading the library for a read-only scan of classes that exist in the current game:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/WhyMayko/Galax-Memory/main/GalaxMemory.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/WhyMayko/Galax-Memory/main/Validate.lua"))()
```

It prints `Class:properties:failures`. Classes absent from the current game cannot be tested in that client.
