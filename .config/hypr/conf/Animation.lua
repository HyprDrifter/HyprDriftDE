-- Animation configuration converted from Animation.conf.

-- This is intentionally loaded before Ui.lua, matching the old source order.
-- Ui.lua later changes the final layout from master to dwindle.
hl.config({
    general = {
        layout = "master",
    },
    animations = {
        enabled = true,
    },
})

-- Custom bezier curves.
hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },     { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 },  { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },        { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },    { 0.75, 1.0 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },     { 0.1, 1 } } })
hl.curve("bounceFastStart",{ type = "bezier", points = { { 0.2, 0.9 },    { 0.3, 1.6 } } })
hl.curve("bounceIn",       { type = "bezier", points = { { 0.3, 0 },      { 0.745, 0.715 } } })
hl.curve("bounceOut",      { type = "bezier", points = { { 0.3, 0.575 },  { 0.565, 1 } } })

-- Animation tree.
hl.animation({ leaf = "global",        enabled = true, speed = 7.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "border",        enabled = true, speed = 4.2, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 3.2, bezier = "bounceFastStart" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 3.2, bezier = "bounceFastStart" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.4, bezier = "quick",          style = "popin 30%" })
hl.animation({ leaf = "fade",          enabled = true, speed = 2.5, bezier = "quick" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.5, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.3, bezier = "almostLinear" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.4, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 3.5, bezier = "easeOutQuint",   style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5, bezier = "linear",         style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.5, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.2, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 2.0, bezier = "easeInOutCubic", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.4, bezier = "easeInOutCubic", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2.0, bezier = "easeInOutCubic", style = "fade" })
