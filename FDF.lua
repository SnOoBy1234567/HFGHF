local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer
local backpack = lp:WaitForChild("Backpack")
local r_time = Players.RespawnTime or 5

-- Set maximal simulation radius for localplayer
local function setsimradius(r)
    settings().Physics.AllowSleep = false
    lp.MaximumSimulationRadius = r
    lp.SimulationRadius = r
end

-- Enforce collision and physics properties on handle
local function hardenHandle(handle)
    RunService.Heartbeat:Connect(function()
        handle.CanCollide = true
        handle.Massless = false
        handle.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0.5)
    end)
end

-- The core routine for flinging with a single tool
local function toolFlinger(tool)
    local chr = lp.Character or lp.CharacterAdded:Wait()
    local rhand = chr:FindFirstChild("RightHand") or chr:FindFirstChild("Right Arm")
    local hum = chr:FindFirstChildOfClass("Humanoid")
    local hrp = chr:FindFirstChild("HumanoidRootPart")
    local handle = tool:FindFirstChild("Handle")
    if not (rhand and hum and hrp and handle) then return end

    -- Equip and unequip to refresh tool
    tool.Parent = chr
    task.wait(0.1)
    tool.Parent = backpack

    -- Character stat reset
    hum.Sit = false
    hum.WalkSpeed = 16
    hum.JumpPower = 50
    hrp.CFrame = CFrame.new(0, -499, 0) * CFrame.Angles(0, 0, math.rad(90))

    -- Bind to hand removal (tool equip state change)
    rhand:GetPropertyChangedSignal("Parent"):Connect(function()
        if not rhand.Parent then
            workspace.CurrentCamera.CameraSubject = handle
            setsimradius(9e9)

            -- BodyPosition for forced movement
            local bpObj = Instance.new("BodyPosition")
            bpObj.MaxForce = Vector3.one * 9e12
            bpObj.P = 1e6
            bpObj.D = 2000
            bpObj.Parent = handle

            -- Maintain collision and position
            handle.CanCollide = true
            handle.CanQuery = true
            tool.Parent = chr
            hardenHandle(handle)

            -- Wait until handle is synced above
            bpObj.Position = handle.Position + Vector3.new(0, 20, 0)
            repeat
                task.wait()
                setsimradius(9e9)
            until (handle.Position - bpObj.Position).Magnitude < 5

            -- FLING EVERYONE (except self)
            for _, v in ipairs(Players:GetPlayers()) do
                if v ~= lp and v.Character then
                    local vhum = v.Character:FindFirstChildOfClass("Humanoid")
                    local vroot = v.Character:FindFirstChild("HumanoidRootPart")
                    if vhum and vroot and not vhum.Sit and vroot.Velocity.Magnitude < 600 then
                        for _ = 1, math.ceil(r_time + 3) do
                            task.wait()
                            handle.RotVelocity = Vector3.new(9e9, 9e9, -9e9)
                            handle.Position = vroot.Position + (vhum.MoveDirection * 3.8)
                            bpObj.Position = handle.Position
                            handle.CanCollide = true
                        end
                    end
                end
            end
        end
    end)

    -- If tool is removed from game, auto-recover
    tool.AncestryChanged:Connect(function()
        if not tool:IsDescendantOf(game) then
            task.wait(0.1)
            tool.Parent = backpack
        end
    end)
end

-- Kickstart all tools in backpack (at script start)
for _, tool in ipairs(backpack:GetChildren()) do
    if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
        coroutine.wrap(toolFlinger)(tool)
    end
end

-- Auto-run on new tools added to backpack
backpack.ChildAdded:Connect(function(tool)
    if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
        coroutine.wrap(toolFlinger)(tool)
    end
end)
