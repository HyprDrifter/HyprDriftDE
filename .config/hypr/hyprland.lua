-- Hyprland 0.55+ Lua configuration
-- Converted from the supplied split Hyprlang configuration.

-- Keep the original source order so later files retain the same override behavior.
require("conf.Animation")
require("conf.Autostart")
require("conf.KeyBinds")
-- require("conf.Monitor")             -- alternate DP-3 / DP-1 layout
require("conf.Monitor2")               -- active DP-1 / DP-2 layout
-- require("conf.Monitor2Alternating") -- old DP-4 / DP-2 alternating layout
require("conf.Ui")
require("conf.WindowRules")
require("conf.DefaultPrograms")
require("conf.Environment")
require("conf.Input")
require("conf.Misc")
require("conf.Render")

-- This file existed in the old folder but was not sourced by the main config.
-- require("conf.Mouse")
