function test_colors(pin, led_count, delay, red, green, blue)
    local rgb_value = string.char(red, green, blue)
    local rgb = rgb_value

    for idx = 0,led_count-1 do
        ws2812.writergb(pin, rgb)
        rgb = rgb .. rgb_value
        tmr.delay(delay*1000)
    end
end

function set_color(pin, led_count, red, green, blue)
    local rgb_value = string.char(red, green, blue)
    local rgb = rgb_value

    for idx = 0,led_count-1 do
        rgb = rgb .. rgb_value
    end

    ws2812.writergb(pin, rgb)
end

wifi.setmode(wifi.STATION)
wifi.setphymode(wifi.PHYMODE_G)
--wifi.sta.config("%%WIFI-NAME%%", "%%PASWORD%%", 0)

wifi.sta.eventMonReg(wifi.STA_GOTIP, function()
    ip = wifi.sta.getip()
    print('IP: ' .. ip)
    wifi.sta.eventMonStop("unreg all")
end)
wifi.sta.eventMonStart()

wifi.sta.connect()

serverinfo = "{\"info\":{\"effects\":[],\"hostname\":\"test\",\"priorities\":[],"
serverinfo = serverinfo .. "\"transform\":[{\"blacklevel\":[0.0,0.0,0.0],\"gamma\":[1.0,1.0,1.0],"
serverinfo = serverinfo .. "\"id\":\"default\",\"saturationGain\":1.0,\"threshold\":[0.0,0.0,0.0],"
serverinfo = serverinfo .. "\"valueGain\":1.0,\"whitelevel\":[1.0,1.0,1.0]}]},\"success\":true}"

srv=net.createServer(net.TCP, 60)
srv:listen(19444, function(conn)
    conn:on("receive", function(conn,payload)
        local ok, data = pcall(function () return cjson.decode(payload) end)
        if not ok then return end

        if data.command == "serverinfo" then
            --print("serverinfo requested")
            conn:send(serverinfo)

        elseif data.command == "clearall" then
            --print("off")
            set_color(2, 150, 0, 0, 0)
            conn:send("{\"success\":true}")

        elseif data.command == "color" then
            --print("color")
            local red =  math.floor(data.color[1] * 0.39215)
            local green =  math.floor(data.color[2] * 0.39215)
            local blue =  math.floor(data.color[3] * 0.39215)

            set_color(2, 150, red, green, blue)
            conn:send("{\"success\":true}")

        else
            conn:send("{\"success\":false}")
        end
    end)
    conn:on("sent", function(conn) end)
end)

print('Init done')
