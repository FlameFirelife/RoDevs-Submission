local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local package = ReplicatedStorage:WaitForChild("Helios")
local remote = package:WaitForChild("Channel")
local Config = require(package.Shared.Config)
local CircuitView = require(package.Shared.CircuitView)
local Theme = {
    Background = Color3.fromRGB(31, 33, 36),
    Button = Color3.fromRGB(65, 68, 72),
    Hover = Color3.fromRGB(83, 86, 91),
    Pressed = Color3.fromRGB(49, 52, 56),
    Text = Color3.fromRGB(242, 242, 240),
    Muted = Color3.fromRGB(198, 200, 202),
    Good = Color3.fromRGB(159, 211, 170),
    Warning = Color3.fromRGB(240, 201, 130),
    Focus = Color3.fromRGB(234, 234, 231),
    Font = Enum.Font.SourceSans,
    Strong = Enum.Font.SourceSansSemibold,
    Radius = 4,
}
local gui = Instance.new("ScreenGui")
gui.Name = "HeliosHUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
local root = Instance.new("Frame")
root.Name = "Interface"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local function panel(name, size, position)
    local object = Instance.new("Frame")
    object.Name = name
    object.Size = size
    object.Position = position
    object.BackgroundColor3 = Theme.Background
    object.BackgroundTransparency = 0.2
    object.BorderSizePixel = 0
    object.Parent = root
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Theme.Radius)
    corner.Parent = object
    return object
end

local function text(name, parent, value, size, position, strong)
    local object = Instance.new("TextLabel")
    object.Name = name
    object.Text = value
    object.Size = size
    object.Position = position
    object.BackgroundTransparency = 1
    object.Font = strong and Theme.Strong or Theme.Font
    object.TextSize = 18
    object.TextColor3 = Theme.Text
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.TextYAlignment = Enum.TextYAlignment.Center
    object.Parent = parent
    return object
end

local function button(name, parent, value, size, position)
    local object = Instance.new("TextButton")
    object.Name = name
    object.Text = value
    object.Size = size
    object.Position = position
    object.BackgroundColor3 = Theme.Button
    object.BorderSizePixel = 0
    object.TextColor3 = Theme.Text
    object.TextSize = 17
    object.Font = Theme.Font
    object.AutoButtonColor = false
    object.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Theme.Radius)
    corner.Parent = object
    local focus = Instance.new("UIStroke")
    focus.Color = Theme.Focus
    focus.Thickness = 2
    focus.Enabled = false
    focus.Parent = object
    object.MouseEnter:Connect(function() object.BackgroundColor3 = Theme.Hover end)
    object.MouseLeave:Connect(function() object.BackgroundColor3 = Theme.Button end)
    object.MouseButton1Down:Connect(function() object.BackgroundColor3 = Theme.Pressed end)
    object.MouseButton1Up:Connect(function() object.BackgroundColor3 = Theme.Hover end)
    object.SelectionGained:Connect(function() focus.Enabled = true end)
    object.SelectionLost:Connect(function() focus.Enabled = false end)
    return object
end

local objective = panel("Objective", UDim2.fromOffset(370, 74), UDim2.fromOffset(16, 16))
local goal = text("Goal", objective, "Loading station...", UDim2.new(1, -24, 0, 42), UDim2.fromOffset(12, 3), true)
goal.TextWrapped = true
local controls = text("Controls", objective, "E to interact. X to cancel.", UDim2.new(1, -24, 0, 24), UDim2.fromOffset(12, 45))
controls.TextSize = 16
controls.TextColor3 = Theme.Muted
local help = button("Help", root, "Help (H)", UDim2.fromOffset(94, 36), UDim2.new(1, -110, 0, 16))
local timer = text("Timer", root, "", UDim2.fromOffset(160, 24), UDim2.new(1, -176, 0, 57))
timer.TextXAlignment = Enum.TextXAlignment.Right
timer.TextSize = 16

local status = panel("Status", UDim2.fromOffset(218, 114), UDim2.new(0, 16, 1, -130))
local fuel = text("Fuel", status, "Fuel: --", UDim2.fromOffset(194, 24), UDim2.fromOffset(12, 7))
local air = text("Air", status, "Air toxicity: --", UDim2.fromOffset(194, 24), UDim2.fromOffset(12, 32))
local circuitList = Instance.new("ScrollingFrame")
circuitList.Name = "CircuitList"
circuitList.Position = UDim2.fromOffset(12, 59)
circuitList.Size = UDim2.new(1, -24, 1, -70)
circuitList.BackgroundTransparency = 1
circuitList.BorderSizePixel = 0
circuitList.ScrollBarThickness = 3
circuitList.ScrollingDirection = Enum.ScrollingDirection.Y
circuitList.Parent = status
local circuits = text("Circuits", circuitList, "", UDim2.new(1, -8, 0, 44), UDim2.fromOffset(0, 0))
circuits.TextSize = 16
circuits.TextYAlignment = Enum.TextYAlignment.Top
circuits.TextColor3 = Theme.Muted
local inventory = panel("Inventory", UDim2.fromOffset(230, 38), UDim2.new(1, -246, 1, -54))
local items = text("Items", inventory, "Fuel cans: 0     Fuses: 0", UDim2.new(1, -24, 1, 0), UDim2.fromOffset(12, 0))
items.TextSize = 17

local guide = panel("FieldGuide", UDim2.fromOffset(420, 330), UDim2.new(0.5, -210, 0.5, -165))
guide.Visible = false
guide.BackgroundTransparency = 0.03
text("Title", guide, "How to play", UDim2.new(1, -32, 0, 30), UDim2.fromOffset(16, 12), true)
local instructions = text("Instructions", guide, "Take fuel and a fuse from stores.\nRefuel the generator.\nReset circuit A and repair circuit B.\nWait for clean air, then use the north exit.\n\nTurn off the load bank before resetting a tripped circuit.", UDim2.new(1, -32, 0, 150), UDim2.fromOffset(16, 47))
instructions.TextWrapped = true
instructions.TextYAlignment = Enum.TextYAlignment.Top
instructions.TextSize = 17
local profile = text("Profile", guide, "Loading progress...", UDim2.new(1, -32, 0, 47), UDim2.fromOffset(16, 204))
profile.TextSize = 16
local saving = text("Saving", guide, "", UDim2.new(1, -32, 0, 22), UDim2.fromOffset(16, 252))
saving.TextSize = 15
saving.TextColor3 = Theme.Muted
local closeGuide = button("CloseGuide", guide, "Close", UDim2.fromOffset(78, 34), UDim2.new(1, -94, 1, -46))

local notice = panel("Notice", UDim2.fromOffset(390, 42), UDim2.new(0.5, -195, 0, 102))
notice.Visible = false
local message = text("Message", notice, "", UDim2.new(1, -24, 1, -8), UDim2.fromOffset(12, 4))
message.TextWrapped = true
message.TextSize = 17
local progress = panel("Action", UDim2.fromOffset(320, 68), UDim2.new(0.5, -160, 1, -154))
progress.Visible = false
local actionText = text("ActionText", progress, "", UDim2.new(1, -24, 0, 28), UDim2.fromOffset(12, 6))
actionText.TextSize = 17
local cancel = button("Cancel", progress, "Cancel", UDim2.fromOffset(72, 26), UDim2.new(1, -84, 0, 35))
local remain = text("Remaining", progress, "", UDim2.fromOffset(180, 24), UDim2.fromOffset(12, 36))
remain.TextSize = 16
remain.TextColor3 = Theme.Muted

local victory = panel("Victory", UDim2.fromOffset(340, 162), UDim2.new(0.5, -170, 0.5, -81))
victory.BackgroundTransparency = 0.03
victory.Visible = false
text("Title", victory, "You escaped", UDim2.new(1, -32, 0, 30), UDim2.fromOffset(16, 10), true)
local winTime = text("Time", victory, "", UDim2.new(1, -32, 0, 24), UDim2.fromOffset(16, 42))
local replay = text("Replay", victory, "Use the arrival console to play again.", UDim2.new(1, -32, 0, 34), UDim2.fromOffset(16, 73))
replay.TextSize = 16
replay.TextWrapped = true
local continue = button("ContinueButton", victory, "Close", UDim2.fromOffset(78, 32), UDim2.new(1, -94, 1, -44))

local function layoutPanels()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local width = camera.ViewportSize.X
    local height = status.Size.Y.Offset
    inventory.Position = width < 500 and UDim2.new(0, 16, 1, -height - 62) or UDim2.new(1, -246, 1, -54)
    progress.Position = UDim2.new(0.5, -160, 1, width < 640 and -height - 140 or -154)
end

local action
local state
local noticeToken = 0
local completedMessages = {
    ["Collect fuel can / complete"] = "Fuel can collected.",
    ["Collect spare fuse / complete"] = "Fuse collected.",
    ["Refuel generator / complete"] = "Generator refuelled.",
    ["Reset security circuit / complete"] = "Circuit A reset.",
    ["Replace life-support fuse / complete"] = "Circuit B repaired.",
    ["Toggle diagnostic load / complete"] = "Load bank switched.",
    ["Evacuate facility / complete"] = "You escaped.",
    ["Start next shift / complete"] = "New shift started.",
}
local function clock(seconds)
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end
local function showNotice(value)
    noticeToken += 1
    local token = noticeToken
    message.Text = completedMessages[value] or tostring(value)
    notice.Visible = true
    task.delay(4, function()
        if token == noticeToken then notice.Visible = false end
    end)
end
local function render(payload)
    state = payload
    local grid = payload.Grid
    if payload.Extracted then
        goal.Text = "Shift complete. Return to the arrival console."
    else
        goal.Text = CircuitView.Objective(grid, payload.Inventory, Config)
    end
    timer.Text = string.format("Shift %d   %s", payload.Shift, clock(grid.Elapsed))
    fuel.Text = string.format("Fuel: %d%%", math.floor(grid.Fuel))
    air.Text = string.format("Air toxicity: %d%%", math.ceil(grid.Contamination))
    air.TextColor3 = grid.Contamination <= Config.SafeContamination and Theme.Good or Theme.Warning
    local lines = {}
    for _, id in ipairs(CircuitView.Ordered(grid.Circuits, Config.Circuits)) do
        table.insert(lines, CircuitView.Describe(id, grid.Circuits[id]))
    end
    local contentHeight = math.max(22, #lines * 22)
    local panelHeight = math.min(224, 70 + contentHeight)
    status.Size = UDim2.fromOffset(218, panelHeight)
    status.Position = UDim2.new(0, 16, 1, -panelHeight - 16)
    circuits.Size = UDim2.new(1, -8, 0, contentHeight)
    circuitList.CanvasSize = UDim2.fromOffset(0, contentHeight)
    circuits.Text = table.concat(lines, "\n")
    layoutPanels()
    items.Text = string.format("Fuel cans: %d     Fuses: %d", payload.Inventory.Fuel, payload.Inventory.Fuse)
    local best = payload.Profile.BestTime > 0 and clock(payload.Profile.BestTime) or "--"
    profile.Text = string.format("Escapes: %d     Repairs: %d\nBest time: %s", payload.Profile.Escapes, payload.Profile.Repairs, best)
    saving.Text = payload.Profile.Mode == "SAVED" and "Progress is saved." or (payload.Profile.Mode == "LOADING" and "Loading progress..." or "Progress lasts for this session.")
end

help.Activated:Connect(function() guide.Visible = not guide.Visible end)
closeGuide.Activated:Connect(function() guide.Visible = false end)
continue.Activated:Connect(function() victory.Visible = false end)
cancel.Activated:Connect(function() remote:FireServer("Cancel") end)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.H then
        guide.Visible = not guide.Visible
    elseif input.KeyCode == Enum.KeyCode.X then
        remote:FireServer("Cancel")
    end
end)
remote.OnClientEvent:Connect(function(kind, payload)
    if kind == "State" then
        render(payload)
    elseif kind == "Notice" then
        showNotice(payload)
    elseif kind == "Action" then
        action = payload or nil
        progress.Visible = action ~= nil
        if action then actionText.Text = action.Label end
    elseif kind == "Victory" then
        guide.Visible = false
        winTime.Text = "Time: " .. clock(payload.Time)
        victory.Visible = true
    elseif kind == "Restart" then
        victory.Visible = false
        showNotice("New shift started.")
    end
end)

local cameraConnection
local function resize()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    objective.Size = UDim2.fromOffset(math.min(370, viewport.X - 136), 74)
    timer.Visible = viewport.X >= 640
    guide.Size = UDim2.fromOffset(math.min(420, viewport.X - 32), 330)
    guide.Position = UDim2.new(0.5, -guide.Size.X.Offset / 2, 0.5, -165)
    notice.Size = UDim2.fromOffset(math.min(390, viewport.X - 32), 42)
    notice.Position = UDim2.new(0.5, -notice.Size.X.Offset / 2, 0, 102)
    layoutPanels()
end
local function bindCamera()
    if cameraConnection then cameraConnection:Disconnect() end
    local camera = workspace.CurrentCamera
    if camera then cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
    resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
    if not action then return end
    elapsed += dt
    if elapsed < 0.1 then return end
    elapsed = 0
    local left = math.max(0, action.EndsAt - workspace:GetServerTimeNow())
    remain.Text = string.format("%.1f seconds left", left)
end)
remote:FireServer("Sync")
task.delay(3, function()
    if not state then remote:FireServer("Sync") end
end)
