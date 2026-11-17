
-- FOREST DONATIONS MOBILE GUI
-- Delta Executor

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "ForestAutoGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(270, 370)
frame.Position = UDim2.new(0.5, -135, 0.5, -185)
frame.BackgroundColor3 = Color3.fromRGB(28, 38, 32)
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius =
    UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "FOREST DONATIONS"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 18
title.Parent = frame

local function makeButton(name, text, y)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(1, -24, 0, 38)
    b.Position = UDim2.fromOffset(12, y)
    b.BackgroundColor3 = Color3.fromRGB(48, 115, 70)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 14
    b.Text = text
    b.Parent = frame

    Instance.new("UICorner", b).CornerRadius =
        UDim.new(0, 8)

    return b
end

local detectBtn = makeButton("Detect", "DETECT BOOTHS", 48)
local claimBtn = makeButton("Claim", "CLAIM NEAREST BOOTH", 94)
local goBtn = makeButton("Go", "GO TO NEAREST BOOTH", 140)
local jumpBtn = makeButton("Jump", "AUTO JUMP: OFF", 186)
local timeBtn = makeButton("Time", "JUMP DELAY: 3s", 232)
local minimizeBtn = makeButton("Minimize", "MINIMIZE", 278)
local closeBtn = makeButton("Close", "CLOSE GUI", 324)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 22)
status.Position = UDim2.fromOffset(10, 345)
status.BackgroundTransparency = 1
status.Text = "Ready"
status.TextColor3 = Color3.new(1, 1, 1)
status.TextSize = 12
status.Parent = frame

local booths = {}
local highlights = {}
local jumping = false
local delayTime = 3
local minimized = false

local function clearHighlights()
    for _, h in ipairs(highlights) do
        h:Destroy()
    end
    table.clear(highlights)
end

local function scan()
    clearHighlights()
    table.clear(booths)

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt")
        and obj.ActionText:lower():find("claim") then

            local part = obj.Parent

            if part:IsA("BasePart") then
                local model = part:FindFirstAncestorWhichIsA("Model")

                if model then
                    table.insert(booths, {
                        model = model,
                        prompt = obj,
                        part = part
                    })

                    local h = Instance.new("Highlight")
                    h.Adornee = model
                    h.FillColor = Color3.fromRGB(50, 255, 100)
                    h.OutlineColor = Color3.new(1, 1, 1)
                    h.Parent = Workspace

                    table.insert(highlights, h)
                end
            end
        end
    end

    status.Text = "Found " .. #booths .. " claim prompts"
end

local function nearest()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local best
    local distance = math.huge

    for _, booth in ipairs(booths) do
        if booth.prompt.Enabled and booth.part.Parent then
            local d = (root.Position - booth.part.Position).Magnitude

            if d < distance then
                best = booth
                distance = d
            end
        end
    end

    return best
end

detectBtn.MouseButton1Click:Connect(scan)

claimBtn.MouseButton1Click:Connect(function()
    local booth = nearest()

    if booth then
        status.Text = "Found booth. Use its Claim prompt."
    else
        status.Text = "No available claim prompt found"
    end
end)

goBtn.MouseButton1Click:Connect(function()
    local booth = nearest()

    if booth then
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")

        if root then
            local target = booth.part.Position
            local direction = booth.part.CFrame.LookVector

            char:PivotTo(
                CFrame.new(target + direction * 5, target)
            )

            status.Text = "Moved near booth"
        end
    else
        status.Text = "No booth found. Scan first."
    end
end)

jumpBtn.MouseButton1Click:Connect(function()
    jumping = not jumping
    jumpBtn.Text = jumping and "AUTO JUMP: ON" or "AUTO JUMP: OFF"
end)

timeBtn.MouseButton1Click:Connect(function()
    delayTime = delayTime + 1

    if delayTime > 30 then
        delayTime = 1
    end

    timeBtn.Text = "JUMP DELAY: " .. delayTime .. "s"
end)

task.spawn(function()
    while gui.Parent do
        if jumping then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if hum and hum.Health > 0 then
                hum.Jump = true
            end

            task.wait(delayTime)
        else
            task.wait(0.1)
        end
    end
end)

minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized

    for _, obj in ipairs(frame:GetChildren()) do
        if obj:IsA("TextButton")
        and obj ~= minimizeBtn then
            obj.Visible = not minimized
        end

        if obj == status then
            obj.Visible = not minimized
        end
    end

    minimizeBtn.Text = minimized and "EXPAND" or "MINIMIZE"
end)

closeBtn.MouseButton1Click:Connect(function()
    jumping = false
    clearHighlights()
    gui:Destroy()
end)

-- Initial booth scan
scan()
