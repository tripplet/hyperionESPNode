mqtt_client = mqtt.Client("eps_licht", 60)
mqtt_client:lwt(mqtt_topic .. "/status", "0" , 1, 1)

function ends_with(str, trailing)
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

            if data.r and data.g and data.b then
                set_color(data.r, data.g, data.b)
            end

            local duration = 3600000 -- 1 hour max

            if data.duration and data.duration ~= 0 then
                duration = data.duration * 1000
            end

           tmr.create():alarm(duration, tmr.ALARM_SINGLE, function()
                dim_down()
            end)
        end
    end) then
        print("error in mqtt payload")
    end
end)

function handle_mqtt_error(client, reason)
    --Try reconnect in 1 minute
    print("Error connecting to mqtt server (retrying in 30s): " .. reason)
    tmr.create():alarm(30 * 1000, tmr.ALARM_SINGLE, do_mqtt_connect)
end

function do_mqtt_connect()
    if mqtt_server == "" then
        return
    end

    print("Connecting to mqtt server")
    mqtt_client:connect(mqtt_server, 1883, 0, function(client)
        print("Connected to mqtt server")
        client:subscribe(mqtt_topic .. "/rgb/set", 0, function(client) print("subscribe success") end)
        client:publish(mqtt_topic .. "/status", "1", 0, 1)
    end,
    function(client, reason)
        handle_mqtt_error(client, reason)
    end)
end
