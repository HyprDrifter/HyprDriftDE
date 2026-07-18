local programs = require("conf.DefaultPrograms")

local main_mod = "SUPER"
local hyprscripts = "~/.config/hypr/scripts"
local scripts = "~/.config/ml4w/scripts"

hl.config({
    binds = {
        pass_mouse_when_bound = true,
    },
})

local function bind(keys, dispatcher, flags)
    hl.bind(keys, dispatcher, flags)
end

local function exec(keys, command, flags)
    hl.bind(keys, hl.dsp.exec_cmd(command), flags)
end

-- Quickshell shortcuts.
bind("SUPER + SPACE", hl.dsp.global("quickshell:toggleLauncher"))
bind("SUPER + Y", hl.dsp.global("quickshell:toggleMinimizeManager"))
bind("SUPER + mouse:273", hl.dsp.global("quickshell:minimizeFocusedWindow"), { locked = true })

-- Drop terminal and launchers.
-- Native Hyprland 0.55 implementation replacing hdrop, whose legacy
-- hyprctl dispatch commands no longer hide or relocate windows correctly.
local dropterm_class = "dropterm"
local dropterm_workspace = "special:hdrop"
local dropterm_launching = false

local function toggle_dropterm()
    -- The pointer decides which monitor receives the terminal. Focusing that
    -- monitor also makes its currently displayed workspace the active one.
    local target_monitor = hl.get_monitor_at_cursor() or hl.get_active_monitor()
    if target_monitor ~= nil then
        hl.dispatch(hl.dsp.focus({ monitor = target_monitor }))
    end

    local target_workspace = hl.get_active_workspace()
    if target_workspace == nil then
        return
    end

    -- A dedicated Kitty class guarantees that only one dropdown instance is
    -- controlled and ordinary Kitty windows are left alone.
    local terminal = hl.get_window("class:^" .. dropterm_class .. "$")

    if terminal == nil then
        -- Prevent two windows if the shortcut is pressed twice while Kitty is
        -- still starting and has not mapped its first window yet.
        if dropterm_launching then
            return
        end

        dropterm_launching = true
        hl.dispatch(hl.dsp.exec_cmd("kitty --class " .. dropterm_class))
        hl.timer(function()
            dropterm_launching = false
        end, { timeout = 5000, type = "oneshot" })
        return
    end

    dropterm_launching = false

    -- If it is already visible on this workspace, hide it. Otherwise bring
    -- the same window here, including from the other monitor or scratchpad.
    local visible_here = false
    for _, window in ipairs(hl.get_workspace_windows(target_workspace)) do
        if window == terminal then
            visible_here = true
            break
        end
    end

    if visible_here then
        hl.dispatch(hl.dsp.window.move({
            workspace = dropterm_workspace,
            follow = false,
            window = terminal,
        }))
        return
    end

    hl.dispatch(hl.dsp.window.move({
        workspace = target_workspace,
        follow = false,
        window = terminal,
    }))
    hl.dispatch(hl.dsp.window.float({ action = "on", window = terminal }))
    hl.dispatch(hl.dsp.focus({ window = terminal }))
end

bind("CTRL + grave", toggle_dropterm)
exec("ALT + SPACE", "pkill rofi || rofi -show drun -replace -i")
exec("SUPER + D", programs.menu)
exec("CTRL + Escape", "resources")

-- Screenshots.
exec("Print", [[grim -g "$(slurp)" - | satty -f -]])
exec("SHIFT + Print", [[grim -o "$(hyprctl activeworkspace -j | jq -r '.monitor')" - | satty -f -]])
exec("CTRL + Print", [[bash -c 'grim -g "$(hyprctl activewindow -j | jq -r ".at.x",".at.y",".size.width",".size.height" | paste -sdx -)" - | satty -f -']])
exec("ALT + Print", [[grim - | satty -f -]])

-- Fullscreen and maximize.
bind("SUPER + mouse_up", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind("SUPER + mouse_down", hl.dsp.window.fullscreen({ mode = "maximized" }))

-- Applications.
exec(main_mod .. " + Return", "~/.config/ml4w/settings/terminal.sh")
exec(main_mod .. " + B", "~/.config/ml4w/settings/browser.sh")
exec(main_mod .. " + E", programs.file_manager)
exec(main_mod .. " + CTRL + E", "~/.config/ml4w/settings/emojipicker.sh")
exec(main_mod .. " + CTRL + C", "~/.config/ml4w/settings/calculator.sh")
exec("xF86Calculator", "kalk")

-- Toggle every window on the active workspace between tiled and floating.
-- This replaces the removed `workspaceopt allfloat` dispatcher with native Lua.
local function toggle_workspace_floating()
    local workspace = hl.get_active_workspace()
    if workspace == nil then
        return
    end

    local windows = hl.get_workspace_windows(workspace)
    local make_floating = false

    for _, window in ipairs(windows) do
        if not window.floating then
            make_floating = true
            break
        end
    end

    local action = make_floating and "set" or "unset"
    for _, window in ipairs(windows) do
        hl.dispatch(hl.dsp.window.float({ action = action, window = window }))
    end
end

-- Windows.
bind(main_mod .. " + Q", hl.dsp.window.close())
exec(main_mod .. " + SHIFT + Q", [[hyprctl activewindow | grep pid | tr -d 'pid:' | xargs kill]])
bind(main_mod .. " + T", hl.dsp.window.float({ action = "toggle" }))
bind(main_mod .. " + SHIFT + T", toggle_workspace_floating)
bind(main_mod .. " + J", hl.dsp.layout("togglesplit"))

bind(main_mod .. " + left",  hl.dsp.focus({ direction = "left" }))
bind(main_mod .. " + right", hl.dsp.focus({ direction = "right" }))
bind(main_mod .. " + up",    hl.dsp.focus({ direction = "up" }))
bind(main_mod .. " + down",  hl.dsp.focus({ direction = "down" }))

bind(main_mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
bind(main_mod .. " + mouse:274", hl.dsp.window.resize(), { mouse = true })

bind(main_mod .. " + SHIFT + right", hl.dsp.window.resize({ x = 100,  y = 0,    relative = true }))
bind(main_mod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -100, y = 0,    relative = true }))
bind(main_mod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0,    y = 100,  relative = true }))
bind(main_mod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0,    y = -100, relative = true }))

bind(main_mod .. " + G", hl.dsp.group.toggle())
bind(main_mod .. " + ALT + left",  hl.dsp.window.swap({ direction = "left" }))
bind(main_mod .. " + ALT + right", hl.dsp.window.swap({ direction = "right" }))
bind(main_mod .. " + ALT + up",    hl.dsp.window.swap({ direction = "up" }))
bind(main_mod .. " + ALT + down",  hl.dsp.window.swap({ direction = "down" }))

bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end, { repeating = true })

-- Actions.
exec(main_mod .. " + CTRL + R", "hyprctl reload")
exec(main_mod .. " + SHIFT + A", hyprscripts .. "/toggle-animations.sh")
exec(main_mod .. " + Print", hyprscripts .. "/screenshot.sh")
exec(main_mod .. " + SHIFT + S", hyprscripts .. "/screenshot.sh")
exec(main_mod .. " + CTRL + Q", "~/.config/ml4w/scripts/wlogout.sh")
exec(main_mod .. " + SHIFT + W", "waypaper --random")
exec(main_mod .. " + CTRL + W", "waypaper")
exec(main_mod .. " + ALT + W", hyprscripts .. "/wallpaper-automation.sh")
exec(main_mod .. " + CTRL + Return", "pkill rofi || rofi -show drun -replace -i")
exec(main_mod .. " + CTRL + K", hyprscripts .. "/keybindings.sh")
exec(main_mod .. " + SHIFT + B", "~/.config/waybar/launch.sh")
exec(main_mod .. " + CTRL + B", "~/.config/waybar/toggle.sh")
exec(main_mod .. " + SHIFT + R", hyprscripts .. "/loadconfig.sh")
exec(main_mod .. " + V", scripts .. "/cliphist.sh")
exec(main_mod .. " + CTRL + T", "~/.config/waybar/themeswitcher.sh")
exec(main_mod .. " + CTRL + S", "flatpak run com.ml4w.settings")
exec(main_mod .. " + SHIFT + H", hyprscripts .. "/hyprshade.sh")
exec(main_mod .. " + ALT + G", hyprscripts .. "/gamemode.sh")
exec(main_mod .. " + L", "~/.config/hypr/scripts/power.sh lock")

-- Workspaces 1-10. The 10th workspace remains on the 0 key.
for workspace = 1, 10 do
    local key = (workspace == 10) and "0" or tostring(workspace)
    bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({
        workspace = workspace,
        follow = true,
    }))
    exec(main_mod .. " + CTRL + " .. key, hyprscripts .. "/moveTo.sh " .. tostring(workspace))
end

bind(main_mod .. " + Tab", hl.dsp.focus({ workspace = "m+1" }))
bind(main_mod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }))

-- Function and media keys.
exec("XF86MonBrightnessUp", "brightnessctl -q s +10%")
exec("XF86MonBrightnessDown", "brightnessctl -q s 10%-")
exec("XF86AudioRaiseVolume", "pactl set-sink-mute @DEFAULT_SINK@ 0 && pactl set-sink-volume @DEFAULT_SINK@ +5%", { repeating = true })
exec("XF86AudioLowerVolume", "pactl set-sink-mute @DEFAULT_SINK@ 0 && pactl set-sink-volume @DEFAULT_SINK@ -5%", { repeating = true })
exec("XF86AudioMute", "pactl set-sink-mute @DEFAULT_SINK@ toggle")
exec("XF86AudioPlay", "playerctl play-pause")
exec("XF86AudioPause", "playerctl pause")
exec("XF86AudioNext", "playerctl next")
exec("XF86AudioPrev", "playerctl previous")
exec("XF86AudioMicMute", "pactl set-source-mute @DEFAULT_SOURCE@ toggle")
exec("XF86Calculator", "~/.config/ml4w/settings/calculator.sh")
exec(main_mod .. " + L", "hyprlock")
exec("XF86Tools", "flatpak run com.ml4w.settings")
exec("code:238", "brightnessctl -d smc::kbd_backlight s +10")
exec("code:237", "brightnessctl -d smc::kbd_backlight s 10-")
