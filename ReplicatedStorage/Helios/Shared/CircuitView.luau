local CircuitView = {}

function CircuitView.Ordered(circuits, definitions)
    local ids = {}
    for id in pairs(circuits) do
        table.insert(ids, id)
    end
    table.sort(ids, function(a, b)
        local left = definitions[a] and definitions[a].Order or math.huge
        local right = definitions[b] and definitions[b].Order or math.huge
        return left < right or (left == right and a < b)
    end)
    return ids
end

function CircuitView.Describe(id, circuit)
    local description = circuit.Powered and "on" or (circuit.Status == "FuseMissing" and "needs a fuse" or (circuit.Status == "Tripped" and "tripped" or "no power"))
    return "Circuit " .. id .. ": " .. description
end

function CircuitView.Objective(grid, inventory, config)
    if grid.Auxiliary and not grid.Circuits[config.AuxiliaryCircuit].Powered then
        return "Turn off the load bank, then reset circuit " .. config.AuxiliaryCircuit .. "."
    end
    if not grid.Running then
        return inventory.Fuel > 0 and "Refuel the generator." or "Get a fuel can from stores."
    end
    local actionIds = {}
    for id in pairs(config.Actions) do
        table.insert(actionIds, id)
    end
    table.sort(actionIds)
    for _, id in ipairs(CircuitView.Ordered(grid.Circuits, config.Circuits)) do
        local circuit = grid.Circuits[id]
        if not circuit.Powered then
            local kind = circuit.Status == "FuseMissing" and "Fuse" or "Breaker"
            for _, actionId in ipairs(actionIds) do
                local action = config.Actions[actionId]
                if action.Circuit == id and action.Kind == kind then
                    if action.Item and (inventory[action.Item] or 0) == 0 then
                        return "Collect " .. string.lower(action.Item) .. " from stores for circuit " .. id .. "."
                    end
                    return action.Label .. "."
                end
            end
            return "Restore circuit " .. id .. " / " .. (circuit.Name or id) .. "."
        end
    end
    return grid.DoorOpen and "Use the north exit to evacuate." or ("Wait for air toxicity to drop to " .. config.SafeContamination .. "% or below.")
end

return CircuitView
