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
    if entry.kind == "string" then
        local pointer = memoryread("uintptr_t", entry.address)
        if not validaddress(pointer) then
            return ""
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

function proxymetatable.__index(proxy, key)
    local method = methods[key]
    if method then
        return method
    end
    local descriptor = proxy.lookup[normalize(key)]
    if not descriptor then
        fail("unknown property " .. tostring(key) .. " for " .. proxy.classname)
    end
    return readvalue(proxy:entry(key))
end

function proxymetatable.__newindex(proxy, key, value)
    local descriptor = proxy.lookup[normalize(key)]
    if not descriptor then
        fail("unknown property " .. tostring(key) .. " for " .. proxy.classname)
    end
    local entry = proxy:entry(key)
    entry.value = value
    writevalue(entry)
end

function galaxmemory.new(options)
    options = options or {}
    if type(options) ~= "table" then
        fail("options must be a table")
    end
    local offsetdocument = loaddocument(options.offseturls or defaults.offseturls, "Offsets")
    local typedocument = loaddocument(options.typeurls or defaults.typeurls, "Types")
    if offsetdocument["Roblox Version"] ~= typedocument["Roblox Version"] then
        fail("offset and type versions do not match")
    end
    local self = {
        offsets = offsetdocument.Offsets,
        types = typedocument.Types,
        version = offsetdocument["Roblox Version"],
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
        for _, classname in ipairs(self:schemas(instance, requestedclass)) do
            local offsets = self.offsets[classname]
            local types = self.types[classname]
            if type(offsets[property]) == "number" and type(types[property]) == "string" then
                local kind = aliases[types[property]] or "unknown"
                if classname == "BasePart" and property == "Color3" then
                    kind = "rgbbyte"
                end
                return {
                    address = instance.Address + offsets[property],
                    kind = kind,
                    property = property,
                }
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
        return setmetatable(proxy, proxymetatable)
    end

    return self
end

getfenv().GalaxMemory = galaxmemory
