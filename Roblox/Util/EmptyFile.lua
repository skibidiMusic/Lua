-- Decompiled with Velocity Luau Decompiler
local v1 = game:GetService("Players")
local v2 = game:GetService("ReplicatedStorage")
local v_u_3 = game:GetService("RunService")
local v_u_4 = require(v2.Packages.Knit)
local v_u_5 = require(v2.Packages.Fusion)
require(v2.Content.Style)
require(v2.Content.Special)
local v_u_6 = require(script.Move)
local v_u_7 = nil
local v8 = v_u_4.CreateController({
    ["Name"] = "SpecialController",
    ["Player"] = v1.LocalPlayer
})
function v8.KnitStart(p9)
    -- upvalues: (ref) v_u_7, (copy) v_u_4
    v_u_7 = v_u_4.GetController("InterfaceController")
    p9.Scope = v_u_7.Scope:innerScope({})
    p9.Debounce = false
    p9.Special = p9.Scope:Value()
    p9.Direction = p9.Scope:Value()
    p9.CurrentDirection = p9.Scope:Value()
    p9.Movement = p9:BindToMovement()
    p9.ChargeSpringSpeed = p9.Scope:Value(30)
    p9.ChargeSpringDamping = p9.Scope:Value(1)
    p9.Charge = p9.Scope:Spring(p9.Movement, p9.ChargeSpringSpeed, p9.ChargeSpringDamping)
end
function v8.BindToMovement(p_u_10)
    -- upvalues: (ref) v_u_7, (copy) v_u_5, (copy) v_u_3, (copy) v_u_6
    local v_u_11 = p_u_10.Scope:Value(0)
    local v_u_12 = p_u_10.Player.Character
    local v_u_13
    if v_u_12 then
        v_u_13 = v_u_12:FindFirstChildOfClass("Humanoid")
    else
        v_u_13 = nil
    end
    local v_u_14 = Vector3.new()
    p_u_10.Player.CharacterAdded:Connect(function(p15)
        -- upvalues: (copy) p_u_10, (ref) v_u_12, (ref) v_u_13
        p_u_10.Direction:set(nil)
        v_u_12 = p15
        v_u_13 = v_u_12:FindFirstChildOfClass("Humanoid")
    end)
    local v_u_16 = nil
    p_u_10.Scope:Observer(v_u_7.InGame):onBind(function()
        -- upvalues: (ref) v_u_5, (ref) v_u_7, (ref) v_u_16, (ref) v_u_3, (ref) v_u_12, (copy) p_u_10, (ref) v_u_13, (ref) v_u_6, (ref) v_u_14, (copy) v_u_11
        if v_u_5.peek(v_u_7.InGame or false) then
            v_u_16 = v_u_3.Heartbeat:Connect(function()
                -- upvalues: (ref) v_u_12, (ref) p_u_10, (ref) v_u_13, (ref) v_u_6, (ref) v_u_14, (ref) v_u_5, (ref) v_u_11
                if v_u_12 then
                    local v17 = v_u_12:GetPivot().LookVector
                    if p_u_10.Debounce then
                        return
                    elseif v_u_12 and v_u_12.Parent and v_u_12.PrimaryPart and v_u_13 and v_u_13.Parent and v_u_13.Health > 0 and v_u_13.WalkSpeed > 0 and v_u_6.angleBetween(v17, v_u_14) < 2 then
                        v_u_14 = v17
                        local v18 = v_u_12.PrimaryPart.AssemblyLinearVelocity / v_u_13.WalkSpeed
                        local v19 = workspace.CurrentCamera.CFrame:VectorToObjectSpace(v18)
                        local v20 = v_u_6.getDirection(v19)
                        p_u_10.CurrentDirection:set(v20)
                        if v20 == v_u_5.peek(p_u_10.Direction) or v_u_5.peek(p_u_10.Charge) <= 0.05 then
                            p_u_10.Direction:set(v20)
                            v_u_11:set(v19.Magnitude)
                            p_u_10:UpdateMovementSpring()
                        else
                            p_u_10:UpdateMovementSpring({
                                ["Speed"] = 20
                            })
                            v_u_11:set(0)
                        end
                    else
                        v_u_14 = v17
                        if v_u_12 and v_u_12:GetAttribute("Jumping") then
                            v_u_11:set(v_u_5.peek(p_u_10.Charge or 0))
                        else
                            v_u_11:set(0)
                        end
                    end
                else
                    return
                end
            end)
        elseif v_u_16 then
            v_u_16:Disconnect()
        end
    end)
    return v_u_11
end
function v8.SetSpecialFromStyle(p21, p22)
    if p22 and p22.Metadata and p22.Metadata.Special then
        local v23 = p22.Metadata.Special
        p21.Special:set(v23)
        p21.Debounce = false
        p21:UpdateMovementSpring()
    else
        p21.Special:set(nil)
    end
end
function v8.UpdateMovementSpring(p24, p25)
    -- upvalues: (copy) v_u_5
    local v26 = v_u_5.peek(p24.Special)
    if v26 and v26.Metadata and v26.Metadata.Spring then
        local v27 = p25 or {}
        v27.Speed = v27.Speed or v_u_5.peek(v26.Metadata.Spring.Speed)
        v27.Damping = v27.Damping or v_u_5.peek(v26.Metadata.Spring.Damping)
        p24.ChargeSpringSpeed:set(v27.Speed)
        p24.ChargeSpringDamping:set(v27.Damping)
    end
end
function v8.DebounceSprings(p_u_28)
    -- upvalues: (copy) v_u_5
    local v29 = v_u_5.peek(p_u_28.Special)
    if v29 and v29.Metadata and v29.Metadata.Spring then
        local v_u_30 = os.clock()
        p_u_28.Debounce = v_u_30
        task.delay(v29.Metadata.Debounce or 1, function()
            -- upvalues: (copy) p_u_28, (copy) v_u_30
            if p_u_28.Debounce == v_u_30 then
                p_u_28.Debounce = false
                p_u_28:UpdateMovementSpring()
            end
        end)
        p_u_28.ChargeSpringSpeed:set(v29.Metadata.Spring.Speed * 0.2)
        p_u_28.Movement:set(0)
    end
end
return v8
