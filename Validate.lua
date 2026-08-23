local memory = GalaxMemory.new()
local instances = {
    game,
    game:GetService("Workspace"),
    game:GetService("Lighting"),
    game:GetService("Players"),
    game:GetService("RunService"),
    game:GetService("UserInputService"),
}

for _, instance in ipairs(game:GetDescendants()) do
    instances[#instances + 1] = instance
end

local samples = {}
local attempted = {}
for _, instance in ipairs(instances) do
    if not attempted[instance.ClassName] then
        attempted[instance.ClassName] = true
        local ok = pcall(function()
            memory:bind(instance)
        end)
        if ok then
            samples[instance.ClassName] = instance
        end
    end
end

local classes = 0
local properties = 0
local failures = 0

for classname, instance in pairs(samples) do
    local proxy = memory:bind(instance)
    local checked = 0
    local failed = 0
    for _, property in ipairs(proxy:properties()) do
        checked = checked + 1
        properties = properties + 1
        local ok = pcall(function()
            return proxy[property]
        end)
        if not ok then
            failed = failed + 1
            failures = failures + 1
        end
    end
    classes = classes + 1
    print(classname .. ":" .. tostring(checked) .. ":" .. tostring(failed))
end

print("summary=" .. tostring(classes) .. ":" .. tostring(properties) .. ":" .. tostring(failures))
