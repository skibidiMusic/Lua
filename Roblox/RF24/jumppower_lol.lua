local enabled = false

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent and input.KeyCode == Enum.KeyCode.Insert then
        enabled = not enabled
    end
end)

game:GetService("RunService"):BindToRenderStep("-_cksakcmas_csjmajcas", Enum.RenderPriority.Last.Value + 012903129423, function()
    local localChar = game.Players.LocalPlayer.Character
    if localChar then
        local hum = localChar:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.JumpPower = enabled and 60 or 45
            hum.UseJumpPower = true
        end
    end
end)