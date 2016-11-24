print("Booting\r\n2s delay to allow for abort")

tmr.alarm(3, 2000, tmr.ALARM_SINGLE, function()
    print("Booting...")
    if file.open("config.lua") then
        file.close()
        print("Loading config file")
        dofile("config.lua")
    else
        print("No config file found")
        return
    end

    if file.open("server.lua") then
        file.close()
        print("Starting hyperion server")
        dofile("server.lua")
    else
        print("Server script not found")
        return
    end
    print("Init done")
end)
