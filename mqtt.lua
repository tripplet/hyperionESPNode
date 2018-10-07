local mqtt_timeout_retry = 2

local mqtt_update_tmr = tmr.create()

local mqtt_client = mqtt.Client("esp_licht", 60, mqtt_user, mqtt_password)
mqtt_client:lwt(mqtt_topic .. "/status", "0" , 1, 1)


local function ends_with(str, trailing)
   return trailing=="" or string.sub(str, -string.len(trailing))==trailing
end

mqtt_client:on("offline", function(client)
    print("offline")
    handle_mqtt_error(mqtt_client, -10)
end)

mqtt_client:on("message", function(client, topic, payload)
    if not pcall(function ()
        if payload ~= nil and topic ~= nil and ends_with(topic, "/rgb/set") then
            local decoder = sjson.decoder()
            decoder:write(payload)
            local data = decoder:result()

            if data.state then

                if data.state:lower() == "off" then
                    set_color_off()
                    return

                elseif data.state:lower() == "on" then
                    if data.color and data.color.r and data.color.g and data.color.b then
                        set_color(data.color.r, data.color.g, data.color.b, nil)
                    else
                        set_color(nil, nil, nil, data.brightness)
                    end

                    local duration = 6870947 -- 1h 54m max
                    if data.duration and data.duration ~= 0 then
                        duration = data.duration * 1000
                    end

                    tmr.create():alarm(duration, tmr.ALARM_SINGLE, function()
                        dim_down()
                    end)
                end
            end
        end
    end) then
        print("error in mqtt payload")
    end
end)

local function handle_mqtt_error(client, reason)
    --Try reconnect
    if mqtt_timeout_retry < 32 then
        mqtt_timeout_retry = mqtt_timeout_retry * 2
    end

    print("Error connecting to mqtt server (retrying in "..mqtt_timeout_retry.."s): " .. reason)

    mqtt_update_tmr:stop()
    tmr.create():alarm(mqtt_timeout_retry * 1000, tmr.ALARM_SINGLE, do_mqtt_connect)
end

local function update_mqtt()
    local ip, _ = wifi.sta.getip()

    mqtt_client:publish(mqtt_topic .. "/status", "1", 0, 1)
    mqtt_client:publish(mqtt_topic .. "/uptime", tostring(tmr.time()), 0, 1)
    mqtt_client:publish(mqtt_topic .. "/freeheap", tostring(node.heap()), 0, 1)
    mqtt_client:publish(mqtt_topic .. "/rssi", tostring(wifi.sta.getrssi()), 0, 1)
    mqtt_client:publish(mqtt_topic .. "/ip", tostring(ip), 0, 1)

    mqtt_update_tmr:start()
end

function update_mqtt_color(color)
    if mqtt_client == nil then
        return
    end

    tmr.create():alarm(1, tmr.ALARM_SINGLE, function ()
        local state = "ON"
        if (color.red == 0 and color.green == 0 and color.blue == 0) or color.brightness == 0 then
            state = "OFF"
        end
    
        local json_color_status = '{"state":"' .. tostring(state)
               .. '","color": {"r":' .. tostring(color.red)
               .. ',"g":' .. tostring(color.green)
               .. ',"b":' .. tostring(color.blue) .. '},'
               .. '"brightness":' .. tostring(color.brightness) .. '}'

        mqtt_client:publish(mqtt_topic .. "/rgb", json_color_status, 0, 1)
        update_mqtt()
    end)
end

function do_mqtt_connect()
    if mqtt_server == "" then
        mqtt_client = nil
        return
    end

    print("Connecting to mqtt server")

    mqtt_client:connect(mqtt_server, mqtt_port, 0, 0,
        function(client)
            print("Connected to mqtt server")
            mqtt_timeout_retry = 1
            client:subscribe(mqtt_topic .. "/rgb/set", 0, function(client) print("subscribe success") end)

            update_mqtt_color({red = 0, green = 0, blue = 0, brightness = 0})
        end,
        function(client, reason)
            handle_mqtt_error(client, reason)
        end
    )
end

mqtt_update_tmr:register(60 * 1000, tmr.ALARM_SEMI, update_mqtt)
