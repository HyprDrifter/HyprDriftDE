-- Alternate layout converted from the extensionless Monitor2 file.
-- Not loaded by default.
hl.monitor({
    output = "DP-4",
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

for workspace = 1, 10 do
    local monitor = (workspace % 2 == 1) and "DP-4" or "DP-2"
    hl.workspace_rule({ workspace = tostring(workspace), monitor = monitor })
end
