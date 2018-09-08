local mqtt_timeout_retry = 2

local mqtt_client = mqtt.Client("eps_licht", 60, mqtt_user, mqtt_password)
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

            if data.state then

                if data.state:lower() == "off" then
                    dim_down_with_brightness()
                    return

                elseif data.state:lower() == "on" then
                    if data.color and data.color.r and data.color.g and data.color.b then
                        set_color_with_last_brightness(data.color.r, data.color.g, data.color.b)
                    end

                    if data.brightness then
                        set_brightness(data.brightness)
                    end

                    if not data.color and not data.brightness then
                        set_last_color_and_brightness()
                    end

                    local duration = 3600000 -- 1 hour max
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

function handle_mqtt_error(client, reason)
    --Try reconnect
    if mqtt_timeout_retry < 32 then
        mqtt_timeout_retry = mqtt_timeout_retry * 2
    end

    print("Error connecting to mqtt server (retrying in "..mqtt_timeout_retry.."s): " .. reason)
    tmr.create():alarm(mqtt_timeout_retry * 1000, tmr.ALARM_SINGLE, do_mqtt_connect)
end

function do_mqtt_connect()
    if mqtt_server == "" then
        return
    end

    print("Connecting to mqtt server")

    mqtt_client:connect(mqtt_server, mqtt_port, 0, 0, 
    function(client)
        print("Connected to mqtt server")
        mqtt_timeout_retry = 1
        client:subscribe(mqtt_topic .. "/rgb/set", 0, function(client) print("subscribe success") end)
        client:publish(mqtt_topic .. "/status", "1", 0, 1)
    end,
    function(client, reason)
        handle_mqtt_error(client, reason)
    end)
end
