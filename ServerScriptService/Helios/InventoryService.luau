local InventoryService = {}
InventoryService.__index = InventoryService

function InventoryService.new(config)
    return setmetatable({Config = config, Records = {}}, InventoryService)
end

function InventoryService:AddPlayer(player)
    self.Records[player] = {Fuel = 0, Fuse = 0}
end

function InventoryService:Has(player, item)
    local inventory = self.Records[player]
    return inventory ~= nil and (inventory[item] or 0) > 0
end

function InventoryService:Give(player, item)
    local inventory = self.Records[player]
    local limit = self.Config.InventoryLimits[item]
    if not inventory or not limit then
        return false, "Inventory is unavailable."
    end
    if inventory[item] >= limit then
        return false, "You cannot carry more " .. string.lower(item) .. "."
    end
    inventory[item] += 1
    return true
end

function InventoryService:Take(player, item)
    if not self:Has(player, item) then
        return false, "Collect a " .. string.lower(item) .. " from stores first."
    end
    self.Records[player][item] -= 1
    return true
end

function InventoryService:Snapshot(player)
    local record = self.Records[player] or {Fuel = 0, Fuse = 0}
    return {Fuel = record.Fuel, Fuse = record.Fuse}
end

function InventoryService:Reset()
    for player in pairs(self.Records) do
        self:AddPlayer(player)
    end
end

function InventoryService:RemovePlayer(player)
    self.Records[player] = nil
end

return InventoryService
