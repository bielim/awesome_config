local wibox = require("wibox")
local awful = require("awful")

volumewidget = wibox.widget.textbox()
volumewidget:set_text(" | vol ")
volumewidgetupdate = 
  function()
    local fh_vol = assert(io.popen("amixer sget Master | tail -n1 | cut -d' ' -f6 | tr -d \[\%\]"))
    local vol = fh_vol:read("*all")
    local fh_stat = assert(io.popen("amixer sget Master | tail -n1 | cut -d' ' -f8 | tr -d \[\]"))
    local stat = fh_stat:read("*all")
    fh_vol:close()
    fh_stat:close()

    local volume = tonumber(vol)
    status = stat

    if string.find(status, "on", 1, true) then
      volume = "| vol: " .. volume .. "%"
    else
      volume = "| vol: muted "
    end

    volumewidget:set_text(volume)
  end

volumewidgettimer = timer({ timeout = 1 })
volumewidgettimer:connect_signal("timeout", volumewidgetupdate)

volumewidgetupdate()
volumewidgettimer:start();
