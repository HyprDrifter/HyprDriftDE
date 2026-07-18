-- Dwindle and miscellaneous options originally stored beside the window rules.
hl.config({
    dwindle = {
        preserve_split = true,
    },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
        animate_mouse_windowdragging = false,
    },
})

-- Floating drop-style Kitty terminal. The dedicated class prevents this
-- rule and the toggle key from affecting normal Kitty windows.
hl.window_rule({
    name = "floating-kitty-dropterm",
    match = {
        initial_class = "dropterm",
    },
    float = true,
    size = "(monitor_w*0.98) (monitor_h*0.4)",
    move = "(monitor_w*0.01) (monitor_h*0.04)",
})

-- Ignore maximize requests from applications.
hl.window_rule({
    name = "suppress-maximize",
    match = {
        class = ".*",
    },
    suppress_event = "maximize",
})

-- Ignore empty XWayland helper windows that otherwise steal focus.
hl.window_rule({
    name = "xwayland-empty-no-focus",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

-- Force EveGuru to tile.
hl.window_rule({
    name = "tile-eveguru",
    match = {
        initial_title = "^EveGuru!$",
    },
    tile = true,
})

-- Hide tiny empty XWayland tray bubble windows.
hl.window_rule({
    name = "hide-xwayland-tray-bubbles",
    match = {
        xwayland = true,
        float = true,
        title = "^$",
        class = "^$",
    },
    no_focus = true,
    size = "1 1",
    move = "99999 99999",
    opacity = "0.0 0.0",
})

-- Rift program.
hl.window_rule({
    name = "float-rift",
    match = {
        initial_class = "^dev-nohus-rift-MainKt$",
    },
    float = true,
})

-- Nemo transparency.
hl.window_rule({
    name = "nemo-opacity",
    match = {
        class = "^nemo$",
    },
    opacity = "0.85 0.85",
})
