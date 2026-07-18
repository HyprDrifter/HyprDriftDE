-- Active monitor layout requested during conversion.
hl.monitor({
    output = "DP-1",
    mode = "2560x1440@144",
    position = "0x0",
    scale = 1,
    bitdepth = 10,
    cm = "srgb",
})

hl.monitor({
    output = "DP-2",
    mode = "2560x1440@144",
    position = "auto-right",
    scale = 1,
    bitdepth = 10,
    cm = "srgb",
})

for workspace = 1, 5 do
    hl.workspace_rule({ workspace = tostring(workspace), monitor = "DP-1" })
end

for workspace = 6, 10 do
    hl.workspace_rule({ workspace = tostring(workspace), monitor = "DP-2" })
end
