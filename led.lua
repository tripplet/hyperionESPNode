local led_buffer = ws2812.newBuffer(led_count, 3)

local last_color = { red = 0, green = 0, blue = 0, brightness = 255 }
current_color = { red = 0, green = 0, blue = 0, brightness = 255 }

function disable_led()
    tmr.create():alarm(500, tmr.ALARM_SINGLE, function()
        local pin = 4
        gpio.mode(pin, gpio.OUTPUT)
        gpio.write(pin, gpio.HIGH)
    end)
end

function set_color_off()
    ws2812.init()
    led_buffer:fill(0, 0, 0)
    ws2812.write(led_buffer)
    disable_led()

    current_color = { red = 0, green = 0, blue = 0, brightness = 255 }
end

function set_color(red, green, blue, brightness)
    tmr.create():alarm(1, tmr.ALARM_SINGLE, function()
        if red == nil then red = last_color.red end
        if green == nil then green = last_color.green end
        if blue == nil then blue = last_color.blue end

        if brightness == nil then
            brightness = last_color.brightness
        end

        local factor = brightness / 255.0

        ws2812.init()
        led_buffer:fill(green * factor, red * factor, blue * factor)
        ws2812.write(led_buffer)
        disable_led()

        current_color = { red = red, green = green, blue = blue, brightness = brightness }
        last_color = { red = red, green = green, blue = blue, brightness = brightness }
    end)
end

function set_last_color()
    tmr.create():alarm(1, tmr.ALARM_SINGLE, function()
        local factor = last_color.brightness / 255.0

        ws2812.init()
        led_buffer:fill(last_color.green * factor, last_color.red * factor, last_color.blue * factor)
        ws2812.write(led_buffer)
        disable_led()

        current_color = last_color
    end)
end

function dim_down()
    tmr.create():alarm(30, tmr.ALARM_SINGLE, function()
        local factor = (current_color.brightness) / 255.0

        local r = current_color.red * factor
        local g = current_color.green * factor
        local b = current_color.blue * factor

        if current_color.brightness > 0 then
            ws2812.init()
            led_buffer:fill(g, r, b)
            ws2812.write(led_buffer)

            current_color.brightness = current_color.brightness - 1
            dim_down()
        else
            led_buffer:fill(0, 0, 0)
            ws2812.write(led_buffer)
            disable_led()

            current_color = { red = 0, green = 0, blue = 0, brightness = 0 }
        end
    end)
end
