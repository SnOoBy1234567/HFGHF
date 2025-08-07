local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer
local backpack = lp:WaitForChild("Backpack")
local r_time = Players.RespawnTime or 5

local function setsimradius(r)
    settings().Physics.AllowSleep = false
    lp.MaximumSimulationRadius = r
    lp.SimulationRadius = r
end

local function hardenHandle(handle)
    RunService.Heartbeat:Connect(function()
        handle.CanCollide = true
        handle.Massless = false
        handle.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 1)
    end)
end

local function toolFlinger(tool)
    local chr = lp.Character or lp.CharacterAdded:Wait()
    local rhand = chr:FindFirstChild("RightHand") or chr:FindFirstChild("Right Arm")
    local hum = chr:FindFirstChildOfClass("Humanoid")
    local hrp = chr:FindFirstChild("HumanoidRootPart")
    local handle = tool:FindFirstChild("Handle")
    if not (rhand and hum and hrp and handle) then return end

    tool.Parent = chr
    task.wait(0.1)
    tool.Parent = backpack

    hum.Sit = false
    hum.WalkSpeed = 16
    hum.JumpPower = 50
    hrp.CFrame = CFrame.new(0, -499, 0) * CFrame.Angles(0, 0, math.rad(90))

    rhand:GetPropertyChangedSignal("Parent"):Connect(function()
        if not rhand.Parent then
            workspace.CurrentCamera.CameraSubject = handle
            setsimradius(1e10)

            local bp = Instance.new("BodyPosition")
            bp.MaxForce = Vector3.one * 1e13
            bp.P = 1e7
            bp.D = 500
            bp.Parent = handle

            handle.CanCollide = true
            tool.Parent = chr
            hardenHandle(handle)

            task.wait(0.2)
            bp.Position = handle.Position + Vector3.new(0, 25, 0)
            repeat task.wait() setsimradius(1e10) until (handle.Position - bp.Position).Magnitude < 10

            -- Çok daha agresif fling
            while true do
                for _, v in ipairs(Players:GetPlayers()) do
                    if v ~= lp and v.Character then
                        local vhum = v.Character:FindFirstChildOfClass("Humanoid")
                        local vroot = v.Character:FindFirstChild("HumanoidRootPart")
                        if vhum and vroot and not vhum.Sit then
                            for _ = 1, math.ceil(r_time + 5) do
                                task.wait()
                                setsimradius(1e10)
                                handle.RotVelocity = Vector3.new(1e10, -1e10, 1e10)
                                handle.Position = vroot.Position + Vector3.new(0, 2, 0)
                                bp.Position = handle.Position
                                handle.CanCollide = true
                            end
                        end
                    end
                end
            end
        end
    end)

    tool.AncestryChanged:Connect(function()
        if not tool:IsDescendantOf(game) then
            task.wait(0.1)
            tool.Parent = backpack
        end
    end)
end

for _, tool in ipairs(backpack:GetChildren()) do
    if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
        coroutine.wrap(toolFlinger)(tool)
    end
end

backpack.ChildAdded:Connect(function(tool)
    if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
        coroutine.wrap(toolFlinger)(tool)
    end
end)
