local Players = game:GetService("Players")
local InteractionService = {}
InteractionService.__index = InteractionService

function InteractionService.new(context)
    return setmetatable({Context = context, Active = {}, Locks = {}, Buckets = {}, Connections = {}, Epoch = 1}, InteractionService)
end

function InteractionService:Allow(player)
    local now = os.clock()
    local bucket = self.Buckets[player] or {Tokens = 5, Time = now}
    bucket.Tokens = math.min(5, bucket.Tokens + (now - bucket.Time) * 2)
    bucket.Time = now
    self.Buckets[player] = bucket
    if bucket.Tokens < 1 then
        return false
    end
    bucket.Tokens -= 1
    return true
end

function InteractionService:InRange(player, target)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return player.Parent == Players and root ~= nil and humanoid ~= nil and humanoid.Health > 0
        and target.Parent ~= nil and (root.Position - target.Position).Magnitude <= self.Context.Config.InteractionRange
end

function InteractionService:Check(player, target, definition)
    if not self:InRange(player, target) then
        return false, "Move closer to the equipment."
    end
    local context = self.Context
    if context.Data:Snapshot(player).Mode == "LOADING" then
        return false, "Your profile is loading. Try again shortly."
    end
    if definition.Kind == "Supply" then
        local inventory = context.Inventory:Snapshot(player)
        if inventory[definition.Item] >= context.Config.InventoryLimits[definition.Item] then
            return false, "Your " .. string.lower(definition.Item) .. " storage is full."
        end
    end
    if definition.Kind == "Refuel" or definition.Kind == "Fuse" then
        if not context.Inventory:Has(player, definition.Item) then
            return false, "Collect a " .. string.lower(definition.Item) .. " from STORES first."
        end
    end
    if definition.Kind == "Extract" and context.Model.Extracted[player.UserId] then
        return false, "Shift recorded. Use the arrival console for a new shift."
    end
    if definition.Kind == "Restart" and context.Model.Complete then
        for _, crew in ipairs(Players:GetPlayers()) do
            if not context.Model.Extracted[crew.UserId] then
                return false, "Wait for every crew member to evacuate."
            end
        end
    end
    return context.Model:Can(definition.Kind, definition.Circuit)
end

function InteractionService:Begin(player, target)
    if not self:Allow(player) then
        return false, "Slow down."
    end
    local id = target:GetAttribute("ActionId")
    local definition = self.Context.Config.Actions[id]
    if not definition or not target:IsDescendantOf(self.Context.Targets) then
        return false, "Unknown interaction."
    end
    if self.Active[player] then
        self.Context.Notify(player, "Finish or cancel your current action.")
        return false, "Already working."
    end
    if self.Locks[target] then
        self.Context.Notify(player, "Another crew member is using this equipment.")
        return false, "Equipment occupied."
    end
    local allowed, reason = self:Check(player, target, definition)
    if not allowed then
        self.Context.Notify(player, reason)
        return false, reason
    end
    local action = {
        Target = target,
        Definition = definition,
        FinishAt = os.clock() + definition.Duration,
        Epoch = self.Epoch,
        Character = player.Character,
    }
    self.Active[player] = action
    self.Locks[target] = player
    self.Context.Remote:FireClient(player, "Action", {
        Label = definition.Label,
        Duration = definition.Duration,
        EndsAt = workspace:GetServerTimeNow() + definition.Duration,
    })
    return true
end

function InteractionService:Cancel(player, message)
    local action = self.Active[player]
    if not action then
        return
    end
    if self.Locks[action.Target] == player then
        self.Locks[action.Target] = nil
    end
    self.Active[player] = nil
    if player.Parent == Players then
        self.Context.Remote:FireClient(player, "Action", false)
        if message then
            self.Context.Notify(player, message)
        end
    end
end

function InteractionService:Commit(player, action)
    local context = self.Context
    local definition = action.Definition
    local allowed, reason = self:Check(player, action.Target, definition)
    if not allowed then
        return false, reason
    end
    if definition.Kind == "Supply" then
        return context.Inventory:Give(player, definition.Item)
    elseif definition.Kind == "Restart" then
        context.Restart()
        return true
    elseif definition.Kind == "Extract" then
        local success, seconds = context.Model:Extract(player.UserId)
        if success then
            context.Data:Award(player, "Escape", seconds)
            context.Remote:FireClient(player, "Victory", {Time = math.floor(seconds)})
        end
        return success, seconds
    end
    local success, errorMessage = context.Model:Apply(definition.Kind, definition.Circuit)
    if not success then
        return false, errorMessage
    end
    if definition.Kind == "Refuel" or definition.Kind == "Fuse" then
        context.Inventory:Take(player, definition.Item)
    end
    if definition.Kind == "Fuse" or definition.Kind == "Breaker" then
        context.Data:Award(player, "Repair")
    end
    return true
end

function InteractionService:Step()
    for player, action in pairs(self.Active) do
        if action.Epoch ~= self.Epoch or player.Character ~= action.Character or not self:InRange(player, action.Target) then
            self:Cancel(player, "Action cancelled: remain close to the equipment.")
        elseif os.clock() >= action.FinishAt then
            self:Cancel(player)
            local success, reason = self:Commit(player, action)
            self.Context.Notify(player, success and (action.Definition.Label .. " / complete") or tostring(reason))
            self.Context.Broadcast()
        end
    end
end

function InteractionService:Reset()
    self.Epoch += 1
    for player in pairs(self.Active) do
        self:Cancel(player)
    end
end

function InteractionService:RemovePlayer(player)
    self:Cancel(player)
    self.Buckets[player] = nil
end

function InteractionService:Start()
    local targets = self.Context.Targets
    local function register(object)
        if not object:IsA("ProximityPrompt") or self.Connections[object] then
            return
        end
        local target = object.Parent
        if not target or not target:IsA("BasePart") then
            return
        end
        self.Connections[object] = object.Triggered:Connect(function(player)
            self:Begin(player, target)
        end)
    end
    for _, object in ipairs(targets:GetDescendants()) do
        register(object)
    end
    self.AddedConnection = targets.DescendantAdded:Connect(register)
    self.RemovedConnection = targets.DescendantRemoving:Connect(function(object)
        local connection = self.Connections[object]
        if connection then
            connection:Disconnect()
            self.Connections[object] = nil
        end
    end)
end

function InteractionService:Destroy()
    self:Reset()
    if self.AddedConnection then self.AddedConnection:Disconnect() end
    if self.RemovedConnection then self.RemovedConnection:Disconnect() end
    for prompt, connection in pairs(self.Connections) do
        connection:Disconnect()
        self.Connections[prompt] = nil
    end
end

return InteractionService
