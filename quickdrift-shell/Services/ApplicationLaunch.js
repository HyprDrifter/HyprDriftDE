.pragma library

function stringValue(value) {
    return value === undefined || value === null ? "" : String(value)
}

function scopedCommand(command) {
    if (!command || command.length === 0)
        return []

    var output = [
        "/usr/bin/systemd-run",
        "--user",
        "--scope",
        "--collect",
        "--quiet",
        "--"
    ]
    for (var index = 0; index < command.length; index++)
        output.push(stringValue(command[index]))
    return output
}
