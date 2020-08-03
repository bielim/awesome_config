# awesome_config
A configuration for the awesome window manager


Welcome to my awesome awesome configuration

 Most important

    Show cheatsheet                             Ctrl-Win-Alt h

 Most used 

    Type command to launch                      Alt-Space (similar to Alfred)
    Get out of the "mini shell" in top left     Esc
    Start a shell                               Alt-Enter
    Make window the master                      Win-Enter
    Go to next window                           Win-h
    Swap window with next                       Win-Shift-h
    Close window                                Win-w
    Toggle window maximization                  Win-m
    Minimize window                             Win-d
    Cycle through list of minimized windows     Win-Tab
    Cycle through list of all windows           Ctrl-Tab
    Go to next tag/desktop                      Win-i
    Go to tag <n>                               Win-<n>
    Move window to next desktop                 Win-Shift-i
    Make master area bigger                     Win-;
    Make master area smaller                    Win-g
    Toggle showing tag <n>                      Win-Shift-<n>
    ``Increase horizontal splits''              Win-|   (i.e. Win-Shift-\)
    ``Decrease horizontal splits''              Win-\
    ``Increase vertical splits''                Win-_   (i.e. Win-Shift--)
    ``Decrease vertical splits''                Win-- 
    Exit                                        Ctrl-Win-Alt q
    Cycle through layouts                       Ctrl-Alt-Tab
    Have a window float (i.e. not be tiled)     Win-f
        Move (with mouse)                       Win-<left_mouse_drag>
        Resize (with mouse)                     Win-<right_mouse_drag>



    The other keybindings can be read from ~/.config/awesome/rc.lua:

    Example (line 439):

        
         -- Move client to previous tag
         awful.key({ modkey, "Shift" }, "u",
           function (c)
            ...
           end
         ),

    The comment says what it should do, 'modkey' means Win-key,
    "Shift" means Shift-key and "u" is the u-key :)

        => Move window to previous tag is Win-Shift-u

-------------------------------------------------------------

 The main idea is to use vim-style movement commands, i.e.

    left  (<--)  =  h

    down  (\|/)  =  j

    up    (/|\)  =  k

    right (-->)  =  l

  and 'Win' as modifier key to indicate awesome should do someting.

    Win-h & Win-k           -> go to next (left/upper) window
    Win-j & Win-l           -> go to previous (right/lower) window


  The row above j & k, i.e. u & i, is for tags (``desktops''). Thus:

    Win-u                   -> go to next lower tag
    Win-i                   -> go to next higher tag

  'Shift' indicates that something should be moved. So:

    Win-Shift-{h|k}         -> move window to the left/up
    Win-Shift-{j|l}         -> move window to the right/lower

    Win-Shift-u             -> move window to next lower tag
    Win-Shift-i             -> move window to next higher tag

  g and y move the master-area separator to the left or up, ; and / move
  it down

    Win-{y|g}               -> move separator to left or up
    Win-{;|/}               -> move separator to right or down

