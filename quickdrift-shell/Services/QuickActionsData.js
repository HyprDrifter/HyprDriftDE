.pragma library

var schemaVersion = 1

function clean(value) {
    return String(value ?? "").trim()
}

function normalizedAction(id, label, icon, command) {
    const normalizedId = clean(id)
    const normalizedLabel = clean(label)
    const normalizedCommand = clean(command)

    if (normalizedId.length === 0
            || normalizedLabel.length === 0
            || normalizedCommand.length === 0)
        return null

    return {
        id: normalizedId,
        label: normalizedLabel,
        icon: clean(icon),
        command: normalizedCommand
    }
}

function normalizedActions(actions) {
    const source = Array.isArray(actions) ? actions : []
    const result = []
    const seenIds = ({})

    for (const action of source) {
        const normalized = normalizedAction(
            action?.id,
            action?.label,
            action?.icon,
            action?.command)
        if (!normalized || seenIds[normalized.id] === true)
            continue

        seenIds[normalized.id] = true
        result.push(normalized)
    }

    return result
}

function decode(payload) {
    const contents = String(payload ?? "").trim()
    if (contents.length === 0)
        return { valid: true, actions: [] }

    try {
        const parsed = JSON.parse(contents)
        if (!parsed || parsed.schemaVersion !== schemaVersion
                || !Array.isArray(parsed.actions))
            return { valid: false, actions: [] }

        return {
            valid: true,
            actions: normalizedActions(parsed.actions)
        }
    } catch (error) {
        return { valid: false, actions: [] }
    }
}

function encode(actions) {
    return JSON.stringify({
        schemaVersion: schemaVersion,
        actions: normalizedActions(actions)
    })
}

function uniqueId(actions, timestamp, serial) {
    const usedIds = ({})
    for (const action of normalizedActions(actions))
        usedIds[action.id] = true

    const safeTimestamp = Math.max(0, Math.floor(Number(timestamp) || 0))
    const safeSerial = Math.max(0, Math.floor(Number(serial) || 0))
    const base = "action-" + safeTimestamp.toString(36)
        + "-" + safeSerial.toString(36)
    let candidate = base
    let collision = 0

    while (usedIds[candidate] === true) {
        collision += 1
        candidate = base + "-" + collision.toString(36)
    }

    return candidate
}

function addAction(actions, action) {
    const current = normalizedActions(actions)
    const normalized = normalizedAction(
        action?.id,
        action?.label,
        action?.icon,
        action?.command)
    if (!normalized || current.some(item => item.id === normalized.id))
        return current

    return current.concat([normalized])
}

function updateAction(actions, id, label, icon, command) {
    const current = normalizedActions(actions)
    const normalizedId = clean(id)
    const replacement = normalizedAction(
        normalizedId, label, icon, command)
    if (!replacement)
        return current

    const index = current.findIndex(action => action.id === normalizedId)
    if (index < 0)
        return current

    const result = current.slice()
    result[index] = replacement
    return result
}

function removeAction(actions, id) {
    const normalizedId = clean(id)
    return normalizedActions(actions).filter(action =>
        action.id !== normalizedId)
}

function moveAction(actions, id, targetIndex) {
    const current = normalizedActions(actions)
    const sourceIndex = current.findIndex(action => action.id === clean(id))
    if (sourceIndex < 0 || current.length < 2)
        return current

    const destination = Math.max(0, Math.min(
        current.length - 1,
        Math.floor(Number(targetIndex) || 0)))
    if (sourceIndex === destination)
        return current

    const result = current.slice()
    const moved = result.splice(sourceIndex, 1)[0]
    result.splice(destination, 0, moved)
    return result
}

function findAction(actions, id) {
    const normalizedId = clean(id)
    return normalizedActions(actions).find(action =>
        action.id === normalizedId) ?? null
}

function buildLaunchCommand(command) {
    const normalizedCommand = clean(command)
    if (normalizedCommand.length === 0)
        return []

    return [
        "/usr/bin/systemd-run",
        "--user",
        "--scope",
        "--collect",
        "--quiet",
        "--",
        "/bin/bash",
        "-lc",
        normalizedCommand
    ]
}

function buildTrackedLaunchCommand(command, completionPath) {
    const launchCommand = buildLaunchCommand(command)
    const statusPath = clean(completionPath)
    if (launchCommand.length === 0 || statusPath.length === 0)
        return []

    return [
        "/bin/bash",
        "-c",
        "status_path=$1; shift; /usr/bin/rm -f -- \"$status_path\"; \"$@\"; status=$?; /usr/bin/printf '%s\\n' \"$status\" > \"$status_path\"; exit \"$status\"",
        "quick-actions-runner",
        statusPath
    ].concat(launchCommand)
}
