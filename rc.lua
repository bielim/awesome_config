-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

-- Extra stuff
local cyclefocus = require("cyclefocus")
--local minimized_clients = require("minimized_clients")
require("debian.menu")


-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}


-- {{{ Menu with xrandr choices
-- taken from https://github.com/vincentbernat/\
--              awesome-configuration/blob/master/rc/xrandr.lua

local displayicon = "/usr/share/icons/gnome/32x32/devices/display.png"

-- Get active outputs
local function outputs()
   local outputs = {}
   local xrandr = io.popen("xrandr -q")
   if xrandr then
      for line in xrandr:lines() do
         output = line:match("^([%w-]+) connected ")
         if output then
            outputs[#outputs + 1] = output
         end
      end
      xrandr:close()
   end

   return outputs
end

local function arrange(out)
   -- We need to enumerate all the way to combinate output. We assume
   -- we want only an horizontal layout.
   local choices = {}
   local previous = { {} }
   for i = 1, #out do
      -- Find all permutation of length `i`: we take the permutation
      -- of length `i-1` and for each of them, we create new
      -- permutations by adding each output at the end of it if it is
      -- not already present.
      local new = {}
      for _, p in pairs(previous) do
         for _, o in pairs(out) do
             if not awful.util.table.hasitem(p, o) then
                new[#new + 1] = awful.util.table.join(p, {o})
             end
         end
      end
      choices = awful.util.table.join(choices, new)
      previous = new
   end

   return choices
end

-- Build available choices
local function menu()
   local menu = {}
   local out = outputs()
   local choices = arrange(out)

   for _, choice in pairs(choices) do
      local cmd = "xrandr --auto"
      -- Enabled outputs
      for i, o in pairs(choice) do
         cmd = cmd .. " --output " .. o .. " --auto"
         if i > 1 then
             -- This ensures that the monitor to the right is always the
             -- primary. If you don't want that, remove the --pimary flag
             -- on the following line:
             cmd = cmd .. " --primary --right-of " .. choice[i-1]
         end
      end
      -- Disabled outputs
      for _, o in pairs(out) do
         if not awful.util.table.hasitem(choice, o) then
             cmd = cmd .. " --output " .. o .. " --off"
         end
      end

      local label = ""
      if #choice == 1 then
         label = 'Only <span weight="bold">' .. choice[1] .. '</span>'
      else
         for i, o in pairs(choice) do
             if i > 1 then 
                 label = label .. " + "
             end
             label = label .. '<span weight="bold">' .. o .. '</span>'
         end
      end

      menu[#menu + 1] = { label,
                         cmd,
                         displayicon }
   end

   return menu
end

-- Display xrandr notifications from choices
local state = { iterator = nil,
                timer = nil,
                cid = nil }
local function xrandr()
   -- Stop any previous timer
   if state.timer then
      state.timer:stop()
      state.timer = nil
   end

   -- Build the list of choices
   if not state.iterator then
      state.iterator = awful.util.table.iterate(menu(),
                                        function() return true end)
   end

   -- Select one and display the appropriate notification
   local next = state.iterator()
   local label, action, icon
   if not next then
      label, icon = "Keep the current configuration", displayicon
      state.iterator = nil
   else
      label, action, icon = unpack(next)
   end
   state.cid = naughty.notify({ text = label,
                                icon = icon,
                                timeout = 4,
                                screen = mouse.screen, -- Important, not all screens may be visible
                                font = "Free Sans 18",
                                replaces_id = state.cid }).id

   -- Setup the timer
   state.timer = timer { timeout = 4 }
   state.timer:connect_signal("timeout",
                         function()
                         state.timer:stop()
                         state.timer = nil
                         state.iterator = nil
                         if action then
                                awful.util.spawn(action, false)
                         end
                         end)
   state.timer:start()
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
--beautiful.init("/usr/share/awesome/themes/zenburn/theme.lua")
--beautiful.init(awful.util.getdir("config") .. "/themes/mmc/theme.lua");
beautiful.init(awful.util.getdir("config") .. "/themes/mmc.lua");
for s= 1, screen.count() do
    gears.wallpaper.maximized(beautiful.wallpaper, s, true)
end


-- This is used later as the default terminal and editor to run.
terminal = "gnome-terminal"
--terminal = "lilyterm"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- My own config stuff
sloppy_focus = False
opacity_focused = 1.0
opacity_unfocused = 0.85

-- This here is the naughty notification library configuration
--naughty.config.presets.low.opacity = 0.8
--naughty.config.presets.normal.opacity = 0.8
--naughty.config.presets.high.opacity = 0.8


-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    awful.layout.suit.tile.bottom,
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
				    { "Applications", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })
-- }}}

--{{{ Widgets

--{{{ The final wibox

-- Create a textclock widget
mytextclock = awful.widget.textclock()

-- Create an battery widget                                                        
require("battery")

-- Create a volume widget
require("volume")

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(volumewidget)
    right_layout:add(batterywidget) -- extra widget
    right_layout:add(mytextclock)
    right_layout:add(mylayoutbox[s])


    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
    --}}}

end
--}}}
--}}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end)
    --awful.button({ }, 4, awful.tag.viewnext),
    --awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
--
-- mauro: a list of key identifiers
--    Key:        Identifier:
--    -----------------------
--    Alt:        Mod1
--    Win:        Mod4 (here also: modkey)
--    Shift:      Shift
--    Control:    Control
--    Space:      space [sic]
--    Enter:      return
--    Arrows:     Left, Right, Up, Down
--    Esc:        Escape
--    Tabulator:  Tab
--
-- Mauro shortcuts
--
-- Rationale:
--    The idea is to have awesome be consistent with the vim and tmux
--    configurations. WRT client and tag handling, where a client 
--    corresponds to a pane or split in tmux and vim, respectively, and
--    a tag corresponds to a window or tab in tmux and vim, respectively.
--    The ``leader'' for awesome is the 'Win' key
--
--    Keybindings concerning the layout start with Ctrl+Alt (legacy)
--    Keybindings affecting the screen (monitor) start with Win+Ctrl
--    Keybindings related to the window manager start with Win+Ctrl+Alt
--
-- Other:
--    Arrow keys are to be avoided, using vi-style moving:
--      h: left
--      k: up 
--      j: down
--      l: right
--
--    Shift means 'move to'

-- Keybindings for handling tags are created in for-loops
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-------------------------------------
-- Application related bindings (Alt)
-------------------------------------
globalkeys = awful.util.table.join(
  awful.key({ "Mod1" }, "space",
    function ()
      mypromptbox[mouse.screen]:run()
    end
  )
)

--------------------------------
-- Tag related bindings (Win)
--------------------------------
clientkeys = awful.util.table.join(
  -- Move window to previous tag
  awful.key({ modkey, "Shift" }, "u",
    function (c)
      local curidx = awful.tag.getidx()
      if curidx == 1 then
          awful.client.movetotag(tags[client.focus.screen][9])
      else
          awful.client.movetotag(tags[client.focus.screen][curidx - 1])
      end
      awful.tag.viewprev()
    end
  ),
  -- Move window to next tag
  awful.key({ modkey, "Shift" }, "i",
    function (c)
      local curidx = awful.tag.getidx()
      if curidx == 9 then
          awful.client.movetotag(tags[client.focus.screen][1])
      else
          awful.client.movetotag(tags[client.focus.screen][curidx + 1])
      end
      awful.tag.viewnext()
    end
  )
)
globalkeys = awful.util.table.join(globalkeys,
  -- Show previous tag
  awful.key({ modkey }, "u",
    function ()
      awful.tag.viewprev()
      if awful.client.getmaster() then
          client.focus = awful.client.getmaster()
          client.focus:raise()
      end
    end
  ),
  -- Show next tag
  awful.key({ modkey }, "i",
    function ()
      awful.tag.viewnext()
      if awful.client.getmaster() then
          client.focus = awful.client.getmaster()
          client.focus:raise()
      end
    end
  )
)
-- Show tag <n> 
for i = 1, keynumber do
  globalkeys = awful.util.table.join(globalkeys,
    awful.key({ modkey }, "#" .. i + 9,
      function ()
        local screen = mouse.screen
        if tags[screen][i] then
          awful.tag.viewonly(tags[screen][i])
        end
      end
    ),
-- Toggle tag <n>'s visibility
    awful.key({ modkey, "Shift" }, "#" .. i + 9,
      function ()
        local screen = mouse.screen
        if tags[screen][i] then
          awful.tag.viewtoggle(tags[screen][i])
        end
      end
    )
  )
end


--------------------------------------
-- Layout specific bindings 
-- new: Win
-- old: Ctrl+Alt
--------------------------------------

-- Helper function
local capi = { client = client, mouse = mouse }
function modify_split(direction, amount)
  local cur_screen = (capi.client.focus and capi.client.focus.screen) 
                     or capi.mouse.screen
  local cur_layout = awful.layout.getname(awful.layout.get(cur_screen))
  if cur_layout == awful.layout.suit.tile.name then
    if direction == "v" then
      awful.tag.incncol(amount)
    elseif direction == "h" then
      awful.tag.incnmaster(amount)
    end
  elseif cur_layout == awful.layout.suit.bottom then
    if direction == "v" then
      awful.tag.incnmaster(amount)
    elseif direction == "h" then
      awful.tag.incncol(amount)
    end
  end
end
globalkeys = awful.util.table.join(globalkeys,
  -- Increase master area
  awful.key({ modkey }, ";",
    function ()
      awful.tag.incmwfact(0.05)
    end
  ),
  awful.key({ modkey }, "/",
    function ()
      awful.tag.incmwfact(0.05)
    end
  ),
  -- Decrease master area
  awful.key({ modkey }, "y",
    function ()
      awful.tag.incmwfact(-0.05)
    end
  ),
  awful.key({ modkey }, "g",
    function ()
      awful.tag.incmwfact(-0.05)
    end
  ),
  -- Create a vertical split (as good as possible)
  awful.key({ modkey, "Shift" }, "\\",
    function()
      modify_split("v", 1)
    end
  ),
  -- Remove a vertical split (as good as possible)
  awful.key({ modkey }, "\\",
    function()
      modify_split("v", -1)
    end
  ),
  -- Create a horizontal split (as good as possible)
  awful.key({ modkey, "Shift" }, "-",
    function()
      modify_split("h", 1)
    end
  ),
  -- Remove a horizontal split (as good as possible)
  awful.key({ modkey }, "-",
    function()
      modify_split("h", -1)
    end
  ),

  -- old
  --awful.key({ "Control", "Mod1" }, "k",
  --  function ()
  --    awful.tag.incnmaster(1)
  --  end
  --),
  --awful.key({ "Control", "Mod1" }, "j",
  --  function()
  --    awful.tag.incnmaster(-1)
  --  end
  --),
  --awful.key({ "Control", "Mod1" }, "i",
  --  function ()
  --    awful.tag.incncol(1)
  --  end
  --),
  --awful.key({ "Control", "Mod1" }, "u",
  --  function ()
  --    awful.tag.incncol(-1)
  --  end
  --),

  -- Cycle through layouts
  awful.key({ "Control", "Mod1" }, "Tab",
    function ()
      awful.layout.inc(layouts, 1)
    end
  ),
  -- Toggle menu bar visibility
  awful.key({ "Control", "Mod1" }, "t",
    function()
      mywibox[mouse.screen].visible = not mywibox[mouse.screen].visible
    end
  )
)


---------------------------------
-- window specific bindings (Win)
---------------------------------
globalkeys = awful.util.table.join(globalkeys,
  -- Show next client
  awful.key({ modkey }, "l",
    function ()
        awful.client.focus.byidx(1)
        if client.focus then client.focus:raise() end
    end
  ),
  awful.key({ modkey }, "k",
    function ()
        awful.client.focus.byidx(-1)
        if client.focus then client.focus:raise() end
    end
  ),
  -- Show previous client
  awful.key({ modkey }, "h",
    function ()
        awful.client.focus.byidx(-1)
        if client.focus then client.focus:raise() end
    end
  ),
  awful.key({ modkey }, "j",
    function ()
        awful.client.focus.byidx(1)
        if client.focus then client.focus:raise() end
    end
  ),
  -- Swap with previous client
  awful.key({ modkey, "Shift" }, "l",
    function ()
      awful.client.swap.byidx(1)
    end
  ),
  awful.key({ modkey, "Shift" }, "k",
    function ()
      awful.client.swap.byidx(-1)
    end
  ),
  -- Swap with next client
  awful.key({ modkey, "Shift" }, "h",
    function ()
      awful.client.swap.byidx(-1)
    end
  ),
  awful.key({ modkey, "Shift" }, "j",
    function ()
      awful.client.swap.byidx(1)
    end
  )
)
clientkeys = awful.util.table.join(clientkeys,
  -- Maximize client
  awful.key({ modkey, }, "m", 
    function (c)
      c.maximized_horizontal = not c.maximized_horizontal
      c.maximized_vertical = not c.maximized_vertical
    end
  ),
  -- Fullscreen
  awful.key({ modkey, "Shift" }, "m",
    function (c)
      c.fullscreen = not c.fullscreen
    end
  ),
  -- Toggle stickyness
  awful.key({ modkey }, "s",
    function (c)
      c.sticky = not c.sticky
    end
  ),
  -- Close window
  awful.key({ modkey }, "w",
    function (c)
      c:kill()
    end
  ),
  -- Toggle window floating state
  awful.key({ modkey }, "f",
    awful.client.floating.toggle
  ),
  -- Make window master
  awful.key({ modkey }, "Return",
    function (c)
      c:swap(awful.client.getmaster())
    end
  ),
  -- Toggle be on top always
  awful.key({ modkey }, "y",
    function (c)
      c.ontop = not c.ontop
    end
  ),
  -- Minimize window
  awful.key({ modkey }, "d",
    function (c)
      c.minimized = true
    end
  ),
  -- Cycle through all clients
  awful.key({ "Control" }, "Tab",
    function ()
      cyclefocus.cycle(1, {modifier="Control_L", 
                           raise_clients=false,
                           focus_clients=false,
                           cycle_filter = function (c, source_c) 
                             return true 
                           end
                          })
    end
  ),
  -- Cycle through hidden clients on displayed tags
  awful.key({ modkey }, "Tab",
    function ()
      cyclefocus.cycle(1, {modifier="Super_L", 
                           raise_clients=false,
                           focus_clients=false,
                           cycle_filter = function (c, source_c)

                             -- shortcuts
                             if not c.minimized then return false end
                             local d_tags = awful.tag.selectedlist(mouse.screen)
                             if d_tags == nil then return false end

                             -- compare active tags to tags of client
                             local c_tags = c:tags()
                             for i1 = 1,#d_tags do
                               for i2 = 1,#c_tags do
                                 if (d_tags[i1] == c_tags[i2]) then
                                     return true
                                 end
                               end
                             end
                             return false

                           end
                       })
    end
  )
)

--------------------------------------
-- Screen specific bindings (Win+Ctrl)
--------------------------------------
globalkeys = awful.util.table.join(globalkeys,
  -- Go to next / right screen
  awful.key({ modkey, "Control" }, "l",
    function ()
      awful.screen.focus_relative(1)
    end
  ),
  -- Go to previous / left screen
  awful.key({ modkey, "Control" }, "h",
    function ()
      awful.screen.focus_relative(-1)
    end
  )
)
clientkeys = awful.util.table.join(clientkeys,
  -- Move window to next / right screen
  awful.key({ modkey, "Control", "Shift" }, "l",
    function (c)
      awful.client.movetoscreen(c, mouse.screen+1)
    end
  ),
  -- Move window to previous / left screen
  awful.key({ modkey, "Control", "Shift" }, "h",
    function (c)
      awful.client.movetoscreen(c, mouse.screen-1)
    end
  )
)



-------------------------------------------------
-- Windowmanager specific bindings (Win+Ctrl+Alt)
-- and multimedia keys
-------------------------------------------------
globalkeys = awful.util.table.join(globalkeys,
  -- Restart awesome
  awful.key({ modkey, "Control", "Mod1" }, "r", awesome.restart),
  -- Quit awesome
  awful.key({ modkey, "Control", "Mod1" }, "q", awesome.quit),
  -- Activate screensaver
  awful.key({ modkey, "Control", "Mod1" }, "l", 
    function()
      awful.util.spawn("sync")
      awful.util.spawn("xautolock -locknow")
    end
  ),
  -- Spawn terminal
  awful.key({ modkey, "Control", "Mod1" }, "Return",
    function ()
      awful.util.spawn(terminal)
    end
  ),
  -- Spawn org-mode
  awful.key({ modkey, "Control", "Mod1" }, "o",
    function()
        local matcher = function (c)
            return awful.rules.match(c, {class = 'Emacs24'})
        end
        awful.client.run_or_raise('emacs org/life.org', matcher, true)
    end
  ),
  -- Cheat sheet
  awful.key({ modkey, "Control", "Mod1" }, "h",
    function()
        local matcher = function (c)
            return awful.rules.match(c, {class = 'Gvim'})
        end
        awful.client.run_or_raise('gvim .config/awesome/cheatsheet.txt', 
                                  matcher, true)
    end
  ),
  -- Run command
  awful.key({ modkey, "Control", "Mod1" }, "space",
    function ()
      mypromptbox[mouse.screen]:run()
    end
  ),
  -- Configure multi-screen
  awful.key({ modkey, "Control", "Mod1" }, "d",
    xrandr
  ),
  awful.key({}, "XF86Display", xrandr),
  -- Volume up
  awful.key({}, "XF86AudioRaiseVolume",
    function()
        awful.util.spawn("amixer set Master 9%+", false)
        volumewidgetupdate()
    end
  ),
  -- Volume down
  awful.key({}, "XF86AudioLowerVolume",
    function()
        awful.util.spawn("amixer set Master 9%-", false)
        volumewidgetupdate()
    end
  ),
  -- Mute speaker
  awful.key({}, "XF86AudioMute", 
    function()
        awful.util.spawn("amixer -D pulse set Master 1+ toggle", false)
        volumewidgetupdate()
    end
  ),
  -- Printscreen
  awful.key({}, "Print",
    function ()
        awful.util.spawn_with_shell(
          "import -window root screenshot-`date +%Y-%m-%d_%H:%M`.png"
        )
    end
  )
)



-- Mouse bindings/modifiers
clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize)
)

-- Set keys
root.keys(globalkeys)


-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    -- This will make all new windows start as slaves
    { rule = { }, properties = { }, callback = awful.client.setslave },
    -- Make terminals have very slightly thiker borders to fit nicely
    -- on my dual-screen setup
    { rule = { class = "Gnome-terminal"}, 
      properties = { border_width = beautiful.terminal_border_width } },
    { rule = { class = "LilyTerm"}, 
      properties = { border_width = beautiful.terminal_border_width } },
    -- Make gimp float
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Make rescuetime popup float
    { rule = { class = "RescueTime" },
      properties = { floating = true } },
    { rule = { class = "Synapse" },
      properties = { border_width = 0 } },
    { rule = { class = "crx_eggkanocgddhmamlbiijnphhppkpkmkl" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 4 of screen 1.
    --{ rule = { class = "Firefox" },
    --  properties = { tag = tags[1][4] } },
    --{ rule = { class = "Thunderbird" },
    --  properties = { tag = tags[1][5] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    --c:connect_signal("mouse::enter", function(c)
    --    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
    --        and awful.client.focus.filter(c) then
    --        client.focus = c
    --    end
    --end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus 
    c.opacity = opacity_focused
  end)
client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
    c.opacity = opacity_unfocused
  end)


-- }}}

--{{{ Mauro stuff

autorun = true
autorunApps = {
    "xcompmgr -cF",
    "nm-applet",
    "rescuetime",
    "gnome-settings-daemon",
    "~/.config/awesome/screenlocker"
}

--{{{ run_once()
function run_once(cmd)
	findme = cmd
	firstspace = cmd:find(" ")
	if firstspace then
		findme = cmd:sub(0, firstspace-1)
	end
	awful.util.spawn_with_shell("pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd .. " & )")
end
--}}} 
--{{{ autorun loop
if autorun then
  for app = 1, #autorunApps do
    run_once(autorunApps[app])
  end
end
--}}}
--}}}

