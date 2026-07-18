-- Keyboard, pointer, touchpad, and cursor configuration.
hl.config({
    input = {
        kb_layout = "us",
        numlock_by_default = true,
        mouse_refocus = true,
        special_fallthrough = true,
        follow_mouse = 1,
        follow_mouse_threshold = 0.0,
        sensitivity = 0.0,
        touchpad = {
            natural_scroll = true,
            -- Input.conf set this twice; the final effective old value was 1.0.
            scroll_factor = 1.0,
        },
    },
    cursor = {
        no_warps = true,
    },
})

-- The old gestures block contained no active gesture rules.
