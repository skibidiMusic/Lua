local WebSocket = assert(
    WebSocket or Websocket or websocket or (syn and syn.websocket),
    "Your executor is missing a websocket API!"
)

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local function connect()
    local wait_time = 0
    local success, socket = xpcall(WebSocket.connect, function()
        wait_time = 3
    end, 'ws://[::1]:16640/')

    if (success) then
        local connected = true
        socket.OnMessage:Connect(function(data)
            if (data == 'pong') then
                connected = true
                return
            end

            if data then
                loadstring(data)()
            end
        end)

        while (connected) do
            connected = false
            socket:Send('ping')
            task.wait(3)
        end
    end

    task.delay(wait_time, connect)
end

connect()