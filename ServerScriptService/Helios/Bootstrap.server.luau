local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local package = ReplicatedStorage:WaitForChild("Helios")
local Config = require(package.Shared.Config)
local GridModel = require(package.Shared.GridModel)
local InventoryService = require(script.Parent.InventoryService)
local DataService = require(script.Parent.DataService)
local WorldService = require(script.Parent.WorldService)
local InteractionService = require(script.Parent.InteractionService)
local remote = package:WaitForChild("Channel")
local facility = workspace:WaitForChild("HeliosFacility")
local model = GridModel.new(Config)
local inventory = InventoryService.new(Config)
local world = WorldService.new(facility)
local data
local interactions
local shift = 1
local sendState

local function notify(player, message)
    if player.Parent == Players then
        remote:FireClient(player, "Notice", message)
    end
end

sendState = function(player)
    if player.Parent ~= Players or not data then
        return
    end
    remote:FireClient(player, "State", {
        Grid = model:Snapshot(),
        Inventory = inventory:Snapshot(player),
        Profile = data:Snapshot(player),
        Shift = shift,
        Extracted = model.Extracted[player.UserId] == true,
    })
end

local function broadcast()
    world:Update(model)
    for _, player in ipairs(Players:GetPlayers()) do
        sendState(player)
    end
end

data = DataService.new(Config, sendState)

local function restart()
    interactions:Reset()
    model:Reset()
    inventory:Reset()
    shift += 1
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            player.Character:PivotTo(CFrame.new(Config.SafeZone + Vector3.new(0, 2, 0)))
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = humanoid.MaxHealth
            end
        end
        remote:FireClient(player, "Restart", shift)
    end
    broadcast()
end

interactions = InteractionService.new({
    Config = Config,
    Model = model,
    Inventory = inventory,
    Data = data,
    Remote = remote,
    Targets = facility.Interactions,
    Notify = notify,
    Broadcast = broadcast,
    Restart = restart,
})

local function joined(player)
    inventory:AddPlayer(player)
    player.CharacterAdded:Connect(function(character)
        interactions:Cancel(player)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if humanoid then
            humanoid.WalkSpeed = 18
            humanoid.Died:Connect(function()
                interactions:Cancel(player)
            end)
        end
        sendState(player)
    end)
    task.spawn(function()
        data:Load(player)
    end)
end

Players.PlayerAdded:Connect(joined)
Players.PlayerRemoving:Connect(function(player)
    interactions:RemovePlayer(player)
    inventory:RemovePlayer(player)
    data:RemovePlayer(player)
end)
for _, player in ipairs(Players:GetPlayers()) do
    joined(player)
end

remote.OnServerEvent:Connect(function(player, verb)
    if type(verb) ~= "string" or (verb ~= "Sync" and verb ~= "Cancel") then
        return
    end
    if not interactions:Allow(player) then
        return
    end
    if verb == "Sync" then
        sendState(player)
    else
        interactions:Cancel(player, "Action cancelled.")
    end
end)

local accumulator = 0
local broadcastElapsed = 0
local hazardElapsed = 0
RunService.Heartbeat:Connect(function(dt)
    accumulator += dt
    if accumulator < Config.UpdateInterval then
        return
    end
    local step = math.min(accumulator, 2)
    accumulator = 0
    model:Step(step)
    interactions:Step()
    world:Update(model)
    broadcastElapsed += step
    hazardElapsed += step
    if hazardElapsed >= 1 then
        hazardElapsed = 0
        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and root and humanoid.Health > 0 then
                local protected = (root.Position - Config.SafeZone).Magnitude < Config.SafeZoneRadius or model.Extracted[player.UserId]
                if model.Contamination >= Config.HazardThreshold and not protected then
                    humanoid:TakeDamage(Config.HazardDamage)
                elseif model.Contamination <= Config.SafeContamination or protected then
                    humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 2)
                end
            end
        end
    end
    if broadcastElapsed >= Config.BroadcastInterval then
        broadcastElapsed = 0
        broadcast()
    end
end)

interactions:Start()
data:Start()
broadcast()

if RunService:IsStudio() then
    local diagnostics = Instance.new("BindableFunction")
    diagnostics.Name = "HeliosDiagnostics"
    diagnostics.OnInvoke = function(command, player, target)
        if command == "Snapshot" then
            return {Grid = model:Snapshot(), Inventory = player and inventory:Snapshot(player), Profile = player and data:Snapshot(player)}
        elseif command == "Begin" then
            return interactions:Begin(player, target)
        elseif command == "Cancel" then
            interactions:Cancel(player)
            return true
        elseif command == "Restart" then
            restart()
            return true
        end
        return false
    end
    diagnostics.Parent = ServerStorage
end

print("HELIOS station online / server authority active")
