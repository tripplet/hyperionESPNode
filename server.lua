local led_buffer = ws2812.newBuffer(led_count, 3)
local current_color = { r = 0, g = 0, b = 0 }

if wifi_name == "" or mdns_name == nil or
    wifi_password == "" or mdns_name == nil then
    print('No wifi configuration -> Exit')
    return
else
    wifi.setmode(wifi.STATION)
    wifi.setphymode(wifi.PHYMODE_G)
    wifi.sta.config({ ssid = wifi_name, pwd = wifi_password, auto = true })    
end

wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(event)
    print("Connected to SSID: " .. event.SSID .. ", BSSID: " .. event.BSSID .. ", Channel: " .. event.channel)
end)

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(event)
    print("IP: " .. event.IP)
    mdns.register(mdns_name, {hardware='NodeMCU'})
end)

wifi.sta.connect()

serverinfo = "{\"info\":{\"effects\":[],\"hostname\":\"test\",\"priorities\":[],"
serverinfo = serverinfo .. "\"transform\":[{\"blacklevel\":[0.0,0.0,0.0],\"gamma\":[1.0,1.0,1.0],"
serverinfo = serverinfo .. "\"id\":\"default\",\"saturationGain\":1.0,\"threshold\":[0.0,0.0,0.0],"
serverinfo = serverinfo .. "\"valueGain\":1.0,\"whitelevel\":[1.0,1.0,1.0]}]},\"success\":true}\r\n"

function disable_led()
    tmr.alarm(2, 500, tmr.ALARM_SINGLE, function()
        local pin = 4
        gpio.mode(pin, gpio.OUTPUT)
        gpio.write(pin, gpio.HIGH)
    end)
end

function set_color(red, green, blue)
    tmr.alarm(1, 1, tmr.ALARM_SINGLE, function()
        ws2812.init()
        led_buffer:fill(green, red, blue)
        ws2812.write(led_buffer)
        current_color = { r = red, g = green, b = blue }
        disable_led()
    end)
end

function nil_str(var)
    if var ~= nil then
        return var
    else
        return ''
    end
end

if srv ~= nil then
    print("Stopping old server")
    srv:close()
end

set_color(0, 0, 0)

srv=net.createServer(net.TCP, 120)
srv:listen(19444, function(conn)
    conn:on("receive", function(conn, payload)
        decoder = sjson.decoder()
        decoder:write(payload)
        data = decoder:result()

        if data.command == "status" then
            local wifi_config = wifi.sta.getconfig(true)
            local remaining, used, total=file.fsinfo()
            local _, reset_reason = node.bootreason()
        
            local status = '{"uptime":' .. tostring(tmr.time()) 
                .. ',"heap":' .. tostring(node.heap())
                .. ',"reset_reason":' .. tostring(reset_reason)
                .. ',"chipid":' .. tostring(node.chipid())
                .. ',"wifi":{"mac":"' .. wifi.sta.getmac()                
                .. '","ip":"' .. wifi.sta.getip()
                .. '","mode":' .. tostring(wifi.getmode())
                .. ',"channel":' .. tostring(wifi.getchannel())
                .. ',"rssi":' .. tostring(wifi.sta.getrssi())
                .. ',"ssid":"' .. wifi_config.ssid
                .. '"},"filesystem":{"total":' .. tostring(total)
                .. ',"used":' .. used                
                .. '},"color":{"red":' .. tostring(current_color.r) 
                .. ',"green":' .. tostring(current_color.g) 
                .. ',"blue":' .. tostring(current_color.b) .. '}}'
            conn:send(status)

        elseif data.command == "serverinfo" then
            conn:send(serverinfo)

        elseif data.command == "clearall" or
               data.command == "clear" then
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
