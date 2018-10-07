print('Booting\r\n3s delay to allow for abort, send "abort_boot=true" to stop')

local load = function(filename, message)
    if file.open(filename .. '.lua') then
        file.close()
        print('Compiling: ', filename)
        node.compile(filename .. '.lua')
        file.remove(filename .. '.lua')
        collectgarbage()
    end

    if file.open(filename .. '.lc') then
        file.close()
        print('Loading: ', filename)
        dofile(filename .. '.lc')
        return true
    else
        print('Failed to load: ', filename)
        return false
    end
end

tmr.create():alarm(3000, tmr.ALARM_SINGLE, function()
    if abort_boot then return end

    print('Booting...')
    if not load('config') then return end
    if not load('led') then return end
    if not load('mqtt') then return end
    if not load('server') then return end

    print('Init successful')
    set_color_off()
    collectgarbage()
end)
