local GridModel = {}
GridModel.__index = GridModel

function GridModel.new(config)
    local self = setmetatable({}, GridModel)
    self.Config = config
    self.Revision = 0
    self:Reset()
    return self
end

function GridModel:Reset()
    self.Fuel = 0
    self.Running = false
    self.Auxiliary = false
    self.Contamination = self.Config.InitialContamination
    self.Circuits = {}
    self.Elapsed = 0
    self.Complete = false
    self.Extracted = {}
    self.Event = "BLACK START REQUIRED"
    for id, definition in pairs(self.Config.Circuits) do
        self.Circuits[id] = {Status = definition.Initial, Powered = false, Load = 0}
    end
    self.Revision += 1
    self:Resolve()
end

function GridModel:Changed(message)
    self.Revision += 1
    if message then
        self.Event = message
    end
end

function GridModel:Resolve()
    local total = 0
    local candidates = {}
    for id, circuit in pairs(self.Circuits) do
        local definition = self.Config.Circuits[id]
        local demand = definition.Demand + ((id == self.Config.AuxiliaryCircuit and self.Auxiliary) and self.Config.AuxiliaryDemand or 0)
        if self.Running and circuit.Status == "Online" and demand > definition.Capacity then
            circuit.Status = "Tripped"
            self:Changed(definition.Name .. " OVERLOAD / DISENGAGE LOAD BANK")
        end
        circuit.Powered = self.Running and circuit.Status == "Online"
        circuit.Load = circuit.Powered and demand or 0
        total += circuit.Load
        if circuit.Powered then
            table.insert(candidates, {Id = id, Priority = definition.Priority or 0})
        end
    end
    if total > self.Config.GeneratorCapacity then
        table.sort(candidates, function(a, b)
            return a.Priority < b.Priority or (a.Priority == b.Priority and a.Id < b.Id)
        end)
        for _, candidate in ipairs(candidates) do
            if total <= self.Config.GeneratorCapacity then
                break
            end
            local circuit = self.Circuits[candidate.Id]
            total -= circuit.Load
            circuit.Status = "Tripped"
            circuit.Powered = false
            circuit.Load = 0
            self:Changed("GENERATOR OVERLOAD / " .. self.Config.Circuits[candidate.Id].Name .. " SHED")
        end
    end
    self.Load = total
    self.Ventilating = self.Circuits[self.Config.VentilationCircuit].Powered
    self.DoorOpen = self.Circuits[self.Config.SecurityCircuit].Powered and self.Ventilating and self.Contamination <= self.Config.SafeContamination
end

function GridModel:Can(kind, circuitId)
    if kind == "Refuel" then
        return self.Fuel <= 75, "Fuel tank is nearly full."
    elseif kind == "Breaker" then
        if self.Auxiliary and circuitId == self.Config.AuxiliaryCircuit then
            return false, "Disengage the diagnostic load bank first."
        end
        return self.Circuits[circuitId].Status == "Tripped", "Circuit is already online."
    elseif kind == "Fuse" then
        return self.Circuits[circuitId].Status == "FuseMissing", "Fuse is already installed."
    elseif kind == "Extract" then
        return self.DoorOpen, "Restore required circuits and purge air to " .. self.Config.SafeContamination .. "% or below."
    elseif kind == "Restart" then
        return self.Complete, "Finish this shift before starting the next."
    end
    return true
end

function GridModel:Apply(kind, circuitId)
    local allowed, reason = self:Can(kind, circuitId)
    if not allowed then
        return false, reason
    end
    if kind == "Refuel" then
        self.Fuel = math.min(100, self.Fuel + self.Config.FuelPerCan)
        self.Running = true
        self:Changed("GENERATOR ONLINE")
    elseif kind == "Breaker" then
        self.Circuits[circuitId].Status = "Online"
        self:Changed(self.Config.Circuits[circuitId].Name .. " CIRCUIT RESTORED")
    elseif kind == "Fuse" then
        self.Circuits[circuitId].Status = "Online"
        self:Changed(self.Config.Circuits[circuitId].Name .. " CIRCUIT RESTORED")
    elseif kind == "Load" then
        self.Auxiliary = not self.Auxiliary
        self:Changed(self.Auxiliary and "DIAGNOSTIC LOAD ENGAGED" or "DIAGNOSTIC LOAD DISENGAGED")
    end
    self:Resolve()
    return true
end

function GridModel:Step(dt)
    dt = math.clamp(dt, 0, 2)
    if not self.Complete then
        self.Elapsed += dt
    end
    if self.Running then
        self.Fuel = math.max(0, self.Fuel - dt * self.Config.FuelDrain)
        if self.Fuel == 0 then
            self.Running = false
            self:Changed("FUEL DEPLETED / GENERATOR OFFLINE")
        end
    end
    self:Resolve()
    local old = self.Contamination
    local rate = self.Ventilating and -self.Config.PurgeRate or self.Config.LeakRate
    self.Contamination = math.clamp(old + rate * dt, 0, 100)
    if old > self.Config.SafeContamination and self.Contamination <= self.Config.SafeContamination then
        self:Changed("AIR SAFE / EVACUATION AUTHORIZED")
    end
    self:Resolve()
end

function GridModel:Extract(userId)
    if not self.DoorOpen then
        return false, "Evacuation is locked."
    end
    if self.Extracted[userId] then
        return false, "You have already evacuated this shift."
    end
    self.Extracted[userId] = true
    self.Complete = true
    self:Changed("SHIFT COMPLETE / CREW EVACUATED")
    return true, self.Elapsed
end

function GridModel:Snapshot()
    local circuits = {}
    for id, circuit in pairs(self.Circuits) do
        circuits[id] = {
            Status = circuit.Status,
            Powered = circuit.Powered,
            Load = circuit.Load,
            Capacity = self.Config.Circuits[id].Capacity,
            Name = self.Config.Circuits[id].Name,
        }
    end
    return {
        Revision = self.Revision,
        Fuel = math.floor(self.Fuel * 10) / 10,
        Running = self.Running,
        Auxiliary = self.Auxiliary,
        Contamination = math.floor(self.Contamination * 10) / 10,
        Ventilating = self.Ventilating,
        DoorOpen = self.DoorOpen,
        Load = self.Load,
        Capacity = self.Config.GeneratorCapacity,
        Circuits = circuits,
        Elapsed = math.floor(self.Elapsed),
        Complete = self.Complete,
        Event = self.Event,
    }
end

return GridModel
