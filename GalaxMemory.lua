local galaxmemory = {}
local httpservice = game:GetService("HttpService")

local defaults = {
    offseturls = {
        "https://offsets.imtheo.lol/Offsets.json",
        "https://offsets.femboythighs.org/Offsets.json",
        "https://raw.githubusercontent.com/WhyMayko/Matcha-Scripts/refs/heads/main/Offsets/Offsets.json",
    },
    typeurls = {
        "https://offsets.imtheo.lol/types.json",
        "https://offsets.femboythighs.org/types.json",
        "https://raw.githubusercontent.com/WhyMayko/Matcha-Scripts/refs/heads/main/Offsets/types.json",
    },
}

local aliases = {
    ["bool"] = "bool",
    ["byte"] = "byte",
    ["BYTE"] = "byte",
    ["unsigned char"] = "byte",
    ["int"] = "int",
    ["short"] = "int",
    ["float"] = "float",
    ["double"] = "double",
    ["string"] = "string",
    ["unsigned __int64"] = "pointer",
    ["uintptr_t"] = "pointer",
    ["Vector2"] = "vector2",
    ["Vector3"] = "vector3",
    ["Color3"] = "color3",
    ["UDim2"] = "udim2",
    ["Matrix3x3"] = "matrix3x3",
    ["ViewMatrix_t"] = "matrix3x3",
}

local readonly = {
    ["unknown"] = true,
    ["matrix3x3"] = true,
    ["string"] = true,
    ["rgbbyte"] = true,
}

local classbases = {
    ScreenGui = { "GuiObject" },
    BillboardGui = { "GuiObject" },
    SurfaceGui = { "GuiObject" },
    Frame = { "GuiObject" },
    ScrollingFrame = { "GuiObject" },
    TextLabel = { "GuiObject" },
    TextButton = { "GuiObject" },
    TextBox = { "GuiObject" },
    ImageLabel = { "GuiObject" },
    ImageButton = { "GuiObject" },
    VideoFrame = { "GuiObject" },
    ViewportFrame = { "GuiObject" },
    Part = { "BasePart" },
    MeshPart = { "BasePart" },
    WedgePart = { "BasePart" },
    CornerWedgePart = { "BasePart" },
    TrussPart = { "BasePart" },
    Seat = { "BasePart" },
    VehicleSeat = { "BasePart" },
    SpawnLocation = { "BasePart" },
    UnionOperation = { "BasePart" },
    NegateOperation = { "BasePart" },
    PartOperation = { "BasePart" },
    Shirt = { "Clothing" },
    Pants = { "Clothing" },
    ShirtGraphic = { "Clothing" },
    Decal = { "Textures" },
    Texture = { "Textures" },
}

local function fail(message)
    assert(false, "GalaxMemory: " .. message .. "!")
end

local function validaddress(address)
    return type(address) == "number" and address > 4096
end

local function request(url)
    local raw = game:HttpGet(url)
    if type(raw) ~= "string" or raw == "" then
        return nil
    end
    local ok, document = pcall(function()
        return httpservice:JSONDecode(raw)
    end)
    if ok and type(document) == "table" then
        return document
    end
    return nil
end

local function loaddocument(urls, key)
    if type(urls) ~= "table" or #urls == 0 then
        fail(key .. " urls are required")
    end
    for _, url in ipairs(urls) do
        if type(url) == "string" and url ~= "" then
            local ok, document = pcall(request, url)
            if ok and type(document) == "table" and type(document[key]) == "table" then
                return document
            end
        end
    end
    fail("unable to load " .. key)
end

local function normalize(name)
    return string.lower((name:gsub("[^%w]", "")))
end

local function memoryread(kind, address)
    local ok, value = pcall(memory_read, kind, address)
    if not ok then
        fail("read failed at " .. tostring(address))
    end
    return value
end

local function memorywrite(entry)
    local ok = pcall(memory_write, entry.kind, entry.address, entry.value)
    if not ok then
        fail("write failed at " .. tostring(entry.address))
    end
end

local function readvector2(address)
    return Vector2.new(memoryread("float", address), memoryread("float", address + 4))
end

local function readvector3(address)
    return Vector3.new(memoryread("float", address), memoryread("float", address + 4), memoryread("float", address + 8))
end

local function readcolor3(address)
    return Color3.new(memoryread("float", address), memoryread("float", address + 4), memoryread("float", address + 8))
end

local function readrgbbyte(address)
    return Color3.fromRGB(memoryread("byte", address), memoryread("byte", address + 1), memoryread("byte", address + 2))
end

local function readudim2(address)
    return {
        xscale = memoryread("float", address),
        xoffset = memoryread("int", address + 4),
        yscale = memoryread("float", address + 8),
        yoffset = memoryread("int", address + 12),
    }
end

local function readmatrix(address)
    local values = {}
    for index = 0, 8 do
        values[index + 1] = memoryread("float", address + index * 4)
    end
    return values
end

local function readvalue(entry)
    if entry.kind == "bool" then
        return memoryread("byte", entry.address) ~= 0
    end
    if entry.kind == "pointer" then
        return memoryread("uintptr_t", entry.address)
    end
    if entry.kind == "fov" then
        return memoryread("float", entry.address) * 180 / math.pi
    end
    if entry.kind == "string" then
        local pointer = memoryread("uintptr_t", entry.address)
        if not validaddress(pointer) then
            fail(entry.property .. " has an invalid string pointer")
        end
        return memoryread("string", pointer)
    end
    if entry.kind == "vector2" then
        return readvector2(entry.address)
    end
    if entry.kind == "vector3" then
        return readvector3(entry.address)
    end
    if entry.kind == "color3" then
        return readcolor3(entry.address)
    end
    if entry.kind == "rgbbyte" then
        return readrgbbyte(entry.address)
    end
    if entry.kind == "udim2" then
        return readudim2(entry.address)
    end
    if entry.kind == "matrix3x3" then
        return readmatrix(entry.address)
    end
    if entry.kind == "unknown" then
        fail("unsupported type for " .. entry.property)
    end
    return memoryread(entry.kind, entry.address)
end

local function writevector2(entry)
    local value = entry.value
    if typeof(value) ~= "Vector2" then
        fail(entry.property .. " expects Vector2")
    end
    memorywrite({ kind = "float", address = entry.address, value = value.X })
    memorywrite({ kind = "float", address = entry.address + 4, value = value.Y })
end

local function writevector3(entry)
    local value = entry.value
    if typeof(value) ~= "Vector3" then
        fail(entry.property .. " expects Vector3")
    end
    memorywrite({ kind = "float", address = entry.address, value = value.X })
    memorywrite({ kind = "float", address = entry.address + 4, value = value.Y })
    memorywrite({ kind = "float", address = entry.address + 8, value = value.Z })
end

local function writecolor3(entry)
    local value = entry.value
    if typeof(value) ~= "Color3" then
        fail(entry.property .. " expects Color3")
    end
    memorywrite({ kind = "float", address = entry.address, value = value.R })
    memorywrite({ kind = "float", address = entry.address + 4, value = value.G })
    memorywrite({ kind = "float", address = entry.address + 8, value = value.B })
end

local function writeudim2(entry)
    local value = entry.value
    if type(value) ~= "table" or type(value.xscale) ~= "number" or type(value.xoffset) ~= "number" or type(value.yscale) ~= "number" or type(value.yoffset) ~= "number" then
        fail(entry.property .. " expects a UDim2 table")
    end
    memorywrite({ kind = "float", address = entry.address, value = value.xscale })
    memorywrite({ kind = "int", address = entry.address + 4, value = value.xoffset })
    memorywrite({ kind = "float", address = entry.address + 8, value = value.yscale })
    memorywrite({ kind = "int", address = entry.address + 12, value = value.yoffset })
end

local function writevalue(entry)
    if readonly[entry.kind] then
        fail(entry.property .. " is read only")
    end
    if entry.kind == "bool" then
        if type(entry.value) ~= "boolean" then
            fail(entry.property .. " expects boolean")
        end
        entry.kind = "byte"
        entry.value = entry.value and 1 or 0
        memorywrite(entry)
        return
    end
    if entry.kind == "fov" then
        if type(entry.value) ~= "number" or entry.value <= 0 or entry.value > 120 then
            fail(entry.property .. " expects degrees from one to one hundred twenty")
        end
        entry.kind = "float"
        entry.value = entry.value * math.pi / 180
        memorywrite(entry)
        return
    end
    if entry.kind == "vector2" then
        writevector2(entry)
        return
    end
    if entry.kind == "vector3" then
        writevector3(entry)
        return
    end
    if entry.kind == "color3" then
        writecolor3(entry)
        return
    end
    if entry.kind == "udim2" then
        writeudim2(entry)
        return
    end
    if type(entry.value) ~= "number" then
        fail(entry.property .. " expects number")
    end
    memorywrite(entry)
end

local methods = {}
local proxymetatable = {}

function methods:address()
    return self.instance.Address
end

function methods:class()
    return self.classname
end

function methods:properties()
    local result = {}
    local seen = {}
    for _, descriptor in pairs(self.lookup) do
        if not seen[descriptor.property] then
            seen[descriptor.property] = true
            result[#result + 1] = descriptor.property
        end
    end
    table.sort(result)
    return result
end

function methods:animations()
    return self.owner:animations(self.instance)
end

function methods:lookat(target_pos)
    return self.owner:lookat(self.instance, target_pos)
end

function proxymetatable.__index(proxy, key)
    local method = methods[key]
    if method then
        return method
    end
    local descriptor = proxy.lookup[normalize(key)]
    if descriptor then
        return readvalue(proxy:entry(key))
    end
    local ok, native = pcall(function()
        return proxy.instance[key]
    end)
    if ok and native ~= nil then
        if type(native) == "function" then
            return function(_, ...)
                return native(proxy.instance, ...)
            end
        end
        return native
    end
    fail("unknown property " .. tostring(key) .. " for " .. proxy.classname)
end

function proxymetatable.__newindex(proxy, key, value)
    local descriptor = proxy.lookup[normalize(key)]
    if descriptor then
        local entry = proxy:entry(key)
        entry.value = value
        writevalue(entry)
        return
    end
    local ok = pcall(function()
        proxy.instance[key] = value
    end)
    if ok then
        return
    end
    fail("unknown property " .. tostring(key) .. " for " .. proxy.classname)
end

function galaxmemory.new(options)
    options = options or {}
    if type(options) ~= "table" then
        fail("options must be a table")
    end
    local offsetdocument
    if options.offsets then
        offsetdocument = { Offsets = options.offsets, ["Roblox Version"] = options.version or "custom" }
    else
        offsetdocument = loaddocument(options.offseturls or defaults.offseturls, "Offsets")
    end

    local typedocument
    if options.types then
        typedocument = { Types = options.types, ["Roblox Version"] = options.version or "custom" }
    else
        typedocument = loaddocument(options.typeurls or defaults.typeurls, "Types")
    end

    if offsetdocument["Roblox Version"] ~= typedocument["Roblox Version"] then
        fail("offset and type versions do not match")
    end
    local self = {
        offsets = offsetdocument.Offsets,
        types = typedocument.Types,
        version = offsetdocument["Roblox Version"],
        proxies = setmetatable({}, { __mode = "k" }),
    }

    function self:schemas(instance, requestedclass)
        if typeof(instance) ~= "Instance" or not validaddress(instance.Address) then
            fail("a valid instance is required")
        end
        local candidates = { instance.ClassName }
        for _, classname in ipairs(classbases[instance.ClassName] or {}) do
            candidates[#candidates + 1] = classname
        end
        local schemas = {}
        for _, classname in ipairs(candidates) do
            if self.offsets[classname] and self.types[classname] then
                schemas[#schemas + 1] = classname
            end
        end
        if requestedclass then
            if type(requestedclass) ~= "string" then
                fail("requested class must be a string")
            end
            for _, classname in ipairs(schemas) do
                if classname == requestedclass then
                    return { classname }
                end
            end
            fail("no compatible schema for " .. requestedclass)
        end
        if #schemas == 0 then
            fail("no schema for " .. instance.ClassName)
        end
        return schemas
    end

    function self:entry(instance, property, requestedclass)
        if type(property) ~= "string" then
            fail("property must be a string")
        end
        local target = normalize(property)
        for _, classname in ipairs(self:schemas(instance, requestedclass)) do
            local offsets = self.offsets[classname]
            local types = self.types[classname]
            for rawprop, offset in pairs(offsets) do
                if normalize(rawprop) == target and type(offset) == "number" and type(types[rawprop]) == "string" then
                    local kind = aliases[types[rawprop]] or "unknown"
                    if classname == "BasePart" and rawprop == "Color3" then
                        kind = "rgbbyte"
                    end
                    if classname == "Camera" and rawprop == "FieldOfView" then
                        kind = "fov"
                    end
                    return {
                        address = instance.Address + offset,
                        kind = kind,
                        property = rawprop,
                    }
                end
            end
        end
        fail("unknown property " .. property .. " for " .. instance.ClassName)
    end

    function self:read(instance, property, requestedclass)
        return readvalue(self:entry(instance, property, requestedclass))
    end

    function self:write(instance, property, value)
        local entry = self:entry(instance, property)
        entry.value = value
        writevalue(entry)
    end

    function self:bind(instance, requestedclass)
        if not requestedclass and self.proxies[instance] then
            return self.proxies[instance]
        end
        local schemas = self:schemas(instance, requestedclass)
        local lookup = {}
        if instance.ClassName == "ScreenGui" then
            lookup.enabled = { classname = "GuiObject", property = "ScreenGui_Enabled" }
        else
            for _, classname in ipairs(schemas) do
                local offsets = self.offsets[classname]
                local types = self.types[classname]
                for property, offset in pairs(offsets) do
                    if type(offset) == "number" and type(types[property]) == "string" and not lookup[normalize(property)] then
                        lookup[normalize(property)] = { classname = classname, property = property }
                    end
                end
            end
        end
        local proxy = {
            instance = instance,
            classname = instance.ClassName,
            lookup = lookup,
        }
        function proxy:entry(key)
            local descriptor = self.lookup[normalize(key)]
            if not descriptor then
                fail("unknown property " .. tostring(key) .. " for " .. self.classname)
            end
            return self.owner:entry(self.instance, descriptor.property, descriptor.classname)
        end
        proxy.owner = self
        local bound = setmetatable(proxy, proxymetatable)
        if not requestedclass then
            self.proxies[instance] = bound
        end
        return bound
    end

    function self:pointer(address)
        if not validaddress(address) then return nil end
        local ok, val = pcall(memory_read, "uintptr_t", address)
        return (ok and validaddress(val)) and val or nil
    end
    self.ptr = self.pointer

    function self:string(address)
        if not validaddress(address) then return nil end
        local ok, val = pcall(memory_read, "string", address)
        return ok and val or nil
    end

    function self:float(address)
        if not validaddress(address) then return nil end
        local ok, val = pcall(memory_read, "float", address)
        return (ok and type(val) == "number") and val or nil
    end

    function self:byte(address)
        if not validaddress(address) then return nil end
        local ok, val = pcall(memory_read, "byte", address)
        return (ok and type(val) == "number") and val or nil
    end

    function self:int(address)
        if not validaddress(address) then return nil end
        local ok, val = pcall(memory_read, "int", address)
        return (ok and type(val) == "number") and val or nil
    end

    function self:matrix(address)
        if not validaddress(address) then return nil end
        local values = {}
        for i = 0, 8 do
            local ok, val = pcall(memory_read, "float", address + i * 4)
            if not ok or type(val) ~= "number" then return nil end
            values[i + 1] = val
        end
        return values
    end

    function self:writematrix(address, values)
        if not validaddress(address) or type(values) ~= "table" or #values < 9 then return false end
        for i = 1, 9 do
            pcall(memory_write, "float", address + (i - 1) * 4, values[i])
        end
        return true
    end

    function self:animations(animator)
        local result = {}
        local inst = (type(animator) == "table" and animator.instance) and animator.instance or animator
        local addr = (typeof(inst) == "Instance") and inst.Address or (type(inst) == "number" and inst or nil)
        if not validaddress(addr) then return result end
        local anim_off = self.offsets.Animator and self.offsets.Animator.ActiveAnimations
        local track_anim_off = self.offsets.AnimationTrack and self.offsets.AnimationTrack.Animation
        local track_tp_off = self.offsets.AnimationTrack and self.offsets.AnimationTrack.TimePosition
        local id_off = self.offsets.Misc and self.offsets.Misc.AnimationId
        if not (anim_off and track_anim_off and track_tp_off and id_off) then return result end

        local head = self:pointer(addr + anim_off)
        if not head then return result end

        local current, count = self:pointer(head), 0
        while current and current ~= head and count < 40 do
            count = count + 1
            local track = self:pointer(current + 16)
            if track then
                local anim_ptr = self:pointer(track + track_anim_off)
                if anim_ptr then
                    local id_ptr = self:pointer(anim_ptr + id_off)
                    local raw = self:string(id_ptr)
                    if raw then
                        local id = raw:match("%d+$")
                        if id then
                            local tp = self:float(track + track_tp_off) or 0
                            result[id] = { id = id, tp = tp }
                        end
                    end
                end
            end
            current = self:pointer(current)
        end
        return result
    end

    local function compute_look_matrix(from_pos, to_pos)
        local dx, dy, dz = to_pos.X - from_pos.X, to_pos.Y - from_pos.Y, to_pos.Z - from_pos.Z
        local zx, zy, zz = -dx, -dy, -dz
        local zmag = math.sqrt(zx * zx + zy * zy + zz * zz)
        if zmag == 0 then return nil end
        zx, zy, zz = zx / zmag, zy / zmag, zz / zmag
        local ux, uy, uz = 0, 1, 0
        if math.abs(zy) > 0.9999 then ux, uy, uz = 0, 0, 1 end
        local xx, xy, xz = uy * zz - uz * zy, uz * zx - ux * zz, ux * zy - uy * zx
        local xmag = math.sqrt(xx * xx + xy * xy + xz * xz)
        if xmag == 0 then return nil end
        xx, xy, xz = xx / xmag, xy / xmag, xz / xmag
        local yx, yy, yz = zy * xz - zz * xy, zz * xx - zx * xz, zx * xy - zy * xx
        return { xx, yx, zx, xy, yy, zy, xz, yz, zz }
    end

    function self:lookat(part, target_pos)
        local inst = (type(part) == "table" and part.instance) and part.instance or part
        if typeof(inst) ~= "Instance" or not validaddress(inst.Address) or typeof(target_pos) ~= "Vector3" then
            return false
        end
        local my_pos = inst.Position
        local prim_off = self.offsets.BasePart and self.offsets.BasePart.Primitive
        local rot_off = self.offsets.Primitive and self.offsets.Primitive.Rotation
        local prim = prim_off and self:pointer(inst.Address + prim_off)
        if prim and rot_off then
            local mat = compute_look_matrix(my_pos, Vector3.new(target_pos.X, my_pos.Y, target_pos.Z))
            if mat then
                return self:writematrix(prim + rot_off, mat)
            end
        end
        pcall(function()
            inst.CFrame = CFrame.lookAt(my_pos, Vector3.new(target_pos.X, my_pos.Y, target_pos.Z))
        end)
        return true
    end

    return self
end

getfenv().GalaxMemory = galaxmemory
return galaxmemory
