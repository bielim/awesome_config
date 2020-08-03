local wibox = require("wibox")

batterywidget = wibox.widget.textbox()    
batterywidget:set_text(" | pwr | ")    
batterywidgetupdate = 
  function()    
    local fh = assert(io.popen("acpi | cut -d, -f 2,3 -", "r"))    
    batterywidget:set_text(" | pwr: " .. fh:read("*l") .. " | ")    
    fh:close()    
  end    
batterywidgettimer = timer({ timeout = 5 })    
batterywidgettimer:connect_signal("timeout", batterywidgetupdate)    
batterywidgetupdate()
batterywidgettimer:start()
