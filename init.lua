-- Configuration
led_count = 150
mdns_name = ""
wifi_name = "%%WIFI-NAME%%"
wifi_password = "%%WIFI-PASSWORD%%"
----------------------------------------------------------------------------------------------------

led_buffer = ws2812.newBuffer(led_count, 3)

wifi.setmode(wifi.STATION)
wifi.setphymode(wifi.PHYMODE_G)
wifi.sta.config(wifi_name, wifi_password, 0)

wifi.sta.eventMonReg(wifi.STA_GOTIP, function()
    ip = wifi.sta.getip()
    print('IP: ' .. ip)

    if not (mdns_name == "" or mdns_name == nil) then
        mdns.register(mdns_name, {hardware='NodeMCU'})
    end

    wifi.sta.eventMonStop("unreg all")
end)
wifi.sta.eventMonStart()

wifi.sta.connect()

serverinfo = "{\"info\":{\"effects\":[],\"hostname\":\"test\",\"priorities\":[],"
serverinfo = serverinfo .. "\"transform\":[{\"blacklevel\":[0.0,0.0,0.0],\"gamma\":[1.0,1.0,1.0],"
serverinfo = serverinfo .. "\"id\":\"default\",\"saturationGain\":1.0,\"threshold\":[0.0,0.0,0.0],"
serverinfo = serverinfo .. "\"valueGain\":1.0,\"whitelevel\":[1.0,1.0,1.0]}]},\"success\":true}\r\n"

function disable_led()
    tmr.alarm(2, 1000, tmr.ALARM_SINGLE, function()
        local pin = 4
        gpio.mode(pin, gpio.OUTPUT)
        gpio.write(pin, gpio.HIGH)
    end)
end

function set_color(red, green, blue)
    tmr.alarm(1, 1, tmr.ALARM_SINGLE, function()
        ws2812.init()
        led_buffer:fill(green, red, blue)
        led_buffer:write()
        disable_led()
    end)
end

srv=net.createServer(net.TCP, 120)
srv:listen(19444, function(conn)
    conn:on("receive", function(conn,payload)
        --print("rx")
        local ok, data = pcall(function () return cjson.decode(payload) end)
        if not ok then
            conn:send("{\"success\":true}\r\n")
            return
        end

        if data.command == "serverinfo" then
            --print("serverinfo requested")
            conn:send(serverinfo)

        elseif data.command == "clearall" or
               data.command == "clear" then
            --print("off")
            set_color(0, 0, 0)
            conn:send("{\"success\":true}\r\n")

        elseif data.command == "color" then
            -- Scale 0..1 to 0..255
            local red   = math.floor(data.color[1] * 0.39215)
            local green = math.floor(data.color[2] * 0.39215)
            local blue  = math.floor(data.color[3] * 0.39215)

            set_color(red, green, blue)
            conn:send("{\"success\":true}\r\n")

            local duration = 3600000 -- 1 hour max

            if data.duration and data.duration ~= 0 then
                duration = data.duration
                print(data.duration)
            end

            tmr.alarm(0, duration, tmr.ALARM_SINGLE, function()
                set_color(0, 0, 0)
            end)
        else
            conn:send("{\"success\":true}\r\n")
        end
    end)
    conn:on("sent", function(conn) end)
end)

print('Init done')
set_color(0, 0, 0)
