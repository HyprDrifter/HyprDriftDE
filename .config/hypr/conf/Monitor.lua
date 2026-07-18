-- Alternate monitor layout converted from Monitor.conf.
-- Not loaded by default.
hl.monitor({
    output = "DP-3",
    mode = "2560x1440@144",
    position = "0x0",
    scale = 1,
    bitdepth = 10,
    cm = "srgb",
})

hl.monitor({
    output = "DP-1",
    mode = "2560x1440@144",
    position = "auto-right",
    scale = 1,
    bitdepth = 10,
    cm = "srgb",
})

for workspace = 1, 5 do
    hl.workspace_rule({ workspace = tostring(workspace), monitor = "DP-3" })
end

for workspace = 6, 10 do
    hl.workspace_rule({ workspace = tostring(workspace), monitor = "DP-1" })
end

-- Former commented HDR variants, retained as Lua examples:
-- hl.monitor({ output = "DP-4", mode = "2560x1440@144", position = "auto-left",  scale = 1, bitdepth = 10, cm = "hdredid", sdrbrightness = 1.35, sdrsaturation = 1.05 })
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "auto-right", scale = 1, bitdepth = 10, cm = "hdredid", sdrbrightness = 1.55, sdrsaturation = 1.25 })
