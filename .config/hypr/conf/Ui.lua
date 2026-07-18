-- Look and feel.
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 10,
        border_size = 3,
        col = {
            active_border = "rgba(b8a1e3cc)",
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
        no_focus_fallback = true,
    },
    decoration = {
        rounding = 10,
        rounding_power = 2.0,
        active_opacity = 1.0,
        inactive_opacity = 0.8,
        shadow = {
           enabled = true,
           range = 5,
           render_power = 4,

          -- Visible only around the active window.
           color = "rgba(ffffff80)",
           color_inactive = "rgba(ffffff00)",
        },
        blur = {
            enabled = true,
            size = 3,
            passes = 2,
            vibrancy = 0.1696,
        },
    },
})
