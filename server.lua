if wifi_name == "" or mdns_name == nil or wifi_password == "" then
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
    do_mqtt_connect()
end)

wifi.sta.connect()

serverinfo = "{\"info\":{\"effects\":[],\"hostname\":\"test\",\"priorities\":[],"
serverinfo = serverinfo .. "\"transform\":[{\"blacklevel\":[0.0,0.0,0.0],\"gamma\":[1.0,1.0,1.0],"
serverinfo = serverinfo .. "\"id\":\"default\",\"saturationGain\":1.0,\"threshold\":[0.0,0.0,0.0],"
serverinfo = serverinfo .. "\"valueGain\":1.0,\"whitelevel\":[1.0,1.0,1.0]}]},\"success\":true}\r\n"

function nil_str(var)
    if var ~= nil then
        return var
    else
        return ''
    end
end

if http_srv ~= nil then
    print("Stopping old server")
    http_srv:close()
end

http_srv=net.createServer(net.TCP, 120)
http_srv:listen(19444, function(conn)
    conn:on("receive", function(conn, payload)
        local decoder = sjson.decoder()
        decoder:write(payload)
        local data = decoder:result()

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

            set_color(red, green, blue, 255)
            conn:send("{\"success\":true}\r\n")

            local duration = 6870947 -- 1h 54m max

            if data.duration and data.duration ~= 0 then
                duration = data.duration
            end

           tmr.create():alarm(duration, tmr.ALARM_SINGLE, function()
                dim_down()
            end)
        else
            conn:send("{\"success\":true}\r\n")
        end
    end)
    conn:on("sent", function(conn) end)
end)
