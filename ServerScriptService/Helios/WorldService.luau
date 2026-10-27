local TweenService = game:GetService("TweenService")
local WorldService = {}
WorldService.__index = WorldService

function WorldService.new(facility)
    local self = setmetatable({Facility = facility, Devices = {}, Displays = {}, Last = {}, DoorState = nil}, WorldService)
    local function register(object)
        if object:GetAttribute("PowerCircuit") and (object:IsA("BasePart") or object:IsA("Light")) then
            self.Devices[object] = true
        end
        if object:IsA("TextLabel") and (object:GetAttribute("DisplayKind") or object:GetAttribute("CircuitId")) then
            self.Displays[object] = true
        end
    end
    for _, object in ipairs(facility:GetDescendants()) do
        register(object)
    end
    self.AddedConnection = facility.DescendantAdded:Connect(register)
    self.RemovedConnection = facility.DescendantRemoving:Connect(function(object)
        self.Devices[object] = nil
        self.Displays[object] = nil
        self.Last[object] = nil
    end)
    self.Door = facility.Architecture.SecurityDoor
    self.ClosedCFrame = self.Door.CFrame
    return self
end

function WorldService:Update(model)
    for object in pairs(self.Devices) do
        local circuit = model.Circuits[object:GetAttribute("PowerCircuit")]
        local powered = circuit and circuit.Powered or false
        if self.Last[object] ~= powered then
            self.Last[object] = powered
            if object:IsA("Light") then
                object.Enabled = powered
            elseif object:IsA("BasePart") then
                object.Color = powered and Color3.fromRGB(62, 236, 199) or Color3.fromRGB(126, 48, 37)
                object.Material = Enum.Material.SmoothPlastic
            end
        end
    end
    if self.DoorState ~= model.DoorOpen then
        self.DoorState = model.DoorOpen
        if self.DoorTween then
            self.DoorTween:Cancel()
        end
        self.Door.CanCollide = not model.DoorOpen
        self.DoorTween = TweenService:Create(self.Door, TweenInfo.new(1.4, Enum.EasingStyle.Quart), {
            CFrame = self.ClosedCFrame * CFrame.new(0, model.DoorOpen and 13 or 0, 0),
        })
        self.DoorTween:Play()
    end
    for label in pairs(self.Displays) do
        local kind = label:GetAttribute("DisplayKind")
        local circuitId = label:GetAttribute("CircuitId") or kind
        local circuit = model.Circuits[circuitId]
        local value
        if circuit then
            value = "CIRCUIT " .. circuitId .. "\n" .. string.upper(circuit.Status) .. "\n" .. (circuit.Powered and "ENERGIZED" or "NO SUPPLY")
        elseif kind == "Generator" then
            value = string.format("GENERATOR\n%s\nFUEL %02d%%", model.Running and "ONLINE" or "OFFLINE", math.floor(model.Fuel))
        elseif kind == "Air" then
            value = string.format("AIR TOXICITY\n%02d%%\n%s", math.ceil(model.Contamination), model.Ventilating and "PURGING" or "VENT OFFLINE")
        elseif kind == "Exit" then
            value = model.DoorOpen and "EVACUATION\nAUTHORIZED" or "EVACUATION\nLOCKED / AIR UNSAFE"
        end
        if value and label.Text ~= value then
            label.Text = value
        end
    end
    self.Facility:SetAttribute("GeneratorOnline", model.Running)
    self.Facility:SetAttribute("AirToxicity", model.Contamination)
    self.Facility:SetAttribute("EvacuationOpen", model.DoorOpen)
end

function WorldService:Destroy()
    self.AddedConnection:Disconnect()
    self.RemovedConnection:Disconnect()
    if self.DoorTween then self.DoorTween:Cancel() end
end

return WorldService
