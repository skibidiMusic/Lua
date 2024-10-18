local WebSocket = assert(
    WebSocket or Websocket or websocket or (syn and syn.websocket),
    "Your executor is missing a websocket API!"
)

if not game:IsLoaded() then
    game.Loaded:Wait()
end

while true do
    local success, client = pcall(WebSocket.connect, "ws://localhost:33882/")
    if success then
        client.OnMessage:Connect(function(payload)
            local callback, exception = loadstring(payload)
            if exception then
                client:Send("compile_err:" .. exception)
                error(exception, 2)
            end

            task.spawn(callback)
        end)

        client.OnClose:Wait()
    end

    task.wait(1)
end