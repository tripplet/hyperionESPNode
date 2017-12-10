local led_buffer = ws2812.newBuffer(led_count, 3)

current_color = { r = 0, g = 0, b = 0 }

function disable_led()
    tmr.create():alarm(500, tmr.ALARM_SINGLE, function()
        local pin = 4
        gpio.mode(pin, gpio.OUTPUT)
        gpio.write(pin, gpio.HIGH)
    end)
end

function set_color(red, green, blue)
    tmr.create():alarm(1, tmr.ALARM_SINGLE, function()
        ws2812.init()
        led_buffer:fill(green, red, blue)
        ws2812.write(led_buffer)
        current_color = { r = red, g = green, b = blue }
        disable_led()
    end)
end

function dim_down()
    tmr.create():alarm(30, tmr.ALARM_SINGLE, function()
        if current_color.r > 0 then
            current_color.r = current_color.r - 1
        end
        if current_color.g > 0 then
            current_color.g = current_color.g - 1
        end
        if current_color.b > 0 then
            current_color.b = current_color.b - 1
        end

        if current_color.r > 0 or current_color.b > 0 or current_color.b > 0 then
            ws2812.init()
            led_buffer:fill(current_color.g, current_color.r, current_color.b)
            ws2812.write(led_buffer)
            dim_down()
        else
            led_buffer:fill(0, 0, 0)
            ws2812.write(led_buffer)
            disable_led()
        end
    end)
end
