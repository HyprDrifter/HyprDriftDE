.pragma library

var schemaVersion = 1

function stringValue(value) {
    return value === undefined || value === null ? "" : String(value)
}

function normalizedDesktopId(value) {
    return stringValue(value).trim()
}

function normalizedPinnedIds(values) {
    var output = []
    var seen = ({})
    if (!Array.isArray(values))
        return output

    for (var index = 0; index < values.length; index++) {
        var id = normalizedDesktopId(values[index])
        if (id.length === 0 || seen["id:" + id])
            continue
        seen["id:" + id] = true
        output.push(id)
    }
    return output
}

function decode(contents) {
    var text = stringValue(contents).trim()
    if (text.length === 0)
        return { valid: true, pinnedIds: [] }

    var payload
    try {
        payload = JSON.parse(text)
    } catch (error) {
        return { valid: false, pinnedIds: [] }
    }

    if (!payload || payload.schemaVersion !== schemaVersion
            || !Array.isArray(payload.pinnedDesktopIds))
        return { valid: false, pinnedIds: [] }

    return {
        valid: true,
        pinnedIds: normalizedPinnedIds(payload.pinnedDesktopIds)
    }
}

function encode(pinnedIds) {
    return JSON.stringify({
        schemaVersion: schemaVersion,
        pinnedDesktopIds: normalizedPinnedIds(pinnedIds)
    })
}

function isPinned(pinnedIds, desktopId) {
    return normalizedPinnedIds(pinnedIds).indexOf(
        normalizedDesktopId(desktopId)) >= 0
}

function pin(pinnedIds, desktopId) {
    var id = normalizedDesktopId(desktopId)
    var output = normalizedPinnedIds(pinnedIds)
    if (id.length > 0 && output.indexOf(id) < 0)
        output.push(id)
    return output
}

function unpin(pinnedIds, desktopId) {
    var id = normalizedDesktopId(desktopId)
    return normalizedPinnedIds(pinnedIds).filter(function(candidate) {
        return candidate !== id
    })
}

function movePin(pinnedIds, desktopId, targetIndex) {
    var id = normalizedDesktopId(desktopId)
    var output = normalizedPinnedIds(pinnedIds)
    var sourceIndex = output.indexOf(id)
    if (sourceIndex < 0)
        return output

    var boundedTarget = Math.max(0, Math.min(
        Number(targetIndex) || 0, output.length - 1))
    if (boundedTarget === sourceIndex)
        return output

    output.splice(sourceIndex, 1)
    output.splice(boundedTarget, 0, id)
    return output
}

function prunePins(pinnedIds, availableIds) {
    var available = ({})
    var ids = normalizedPinnedIds(availableIds)
    for (var index = 0; index < ids.length; index++)
        available["id:" + ids[index]] = true

    return normalizedPinnedIds(pinnedIds).filter(function(id) {
        return available["id:" + id] === true
    })
}

function applicationRoot(toplevel) {
    var current = toplevel
    var depth = 0
    while (current && current.parent && depth < 8) {
        current = current.parent
        depth += 1
    }
    return current || toplevel
}

function createGroup(groupId, desktopId, appId, record, pinned,
        pinIndex, firstSeen) {
    return {
        modelKey: groupId,
        groupId: groupId,
        desktopId: desktopId || "",
        appId: appId || "",
        record: record || null,
        pinned: pinned === true,
        pinIndex: pinIndex,
        firstSeen: firstSeen,
        name: record?.name || appId || desktopId || "Application",
        windows: [],
        running: false,
        active: false,
        windowCount: 0,
        available: record?.available === true
    }
}

function buildGroups(pinnedRows, windowRows) {
    var groups = []
    var byId = ({})
    var pins = Array.isArray(pinnedRows) ? pinnedRows : []
    var windows = Array.isArray(windowRows) ? windowRows : []

    for (var pinIndex = 0; pinIndex < pins.length; pinIndex++) {
        var pinRow = pins[pinIndex]
        if (!pinRow || !pinRow.groupId)
            continue
        var pinnedGroup = createGroup(pinRow.groupId,
            pinRow.desktopId, "", pinRow.record, true, pinIndex,
            Number.MAX_SAFE_INTEGER)
        groups.push(pinnedGroup)
        byId["group:" + pinRow.groupId] = pinnedGroup
    }

    for (var windowIndex = 0; windowIndex < windows.length; windowIndex++) {
        var windowRow = windows[windowIndex]
        if (!windowRow || !windowRow.groupId || !windowRow.toplevel)
            continue

        var lookupKey = "group:" + windowRow.groupId
        var group = byId[lookupKey]
        if (!group) {
            group = createGroup(windowRow.groupId,
                windowRow.desktopId, windowRow.appId,
                windowRow.record, false, -1, windowRow.firstSeen)
            groups.push(group)
            byId[lookupKey] = group
        }

        if (!group.record && windowRow.record)
            group.record = windowRow.record
        if (group.desktopId.length === 0 && windowRow.desktopId)
            group.desktopId = windowRow.desktopId
        if (group.appId.length === 0 && windowRow.appId)
            group.appId = windowRow.appId
        if (windowRow.name)
            group.name = group.record?.name || windowRow.name
        group.firstSeen = Math.min(group.firstSeen, windowRow.firstSeen)
        group.windows.push(windowRow)
    }

    for (var groupIndex = 0; groupIndex < groups.length; groupIndex++) {
        var current = groups[groupIndex]
        current.windows.sort(function(left, right) {
            if (left.mru !== right.mru)
                return right.mru - left.mru
            return left.firstSeen - right.firstSeen
        })
        current.running = current.windows.length > 0
        current.windowCount = current.windows.length
        current.active = current.windows.some(function(windowRow) {
            return windowRow.activated === true
        })
        current.available = current.record?.available === true
        current.name = current.record?.name || current.name
            || current.appId || current.desktopId || "Application"
    }

    groups.sort(function(left, right) {
        if (left.pinned !== right.pinned)
            return left.pinned ? -1 : 1
        if (left.pinned)
            return left.pinIndex - right.pinIndex
        if (left.firstSeen !== right.firstSeen)
            return left.firstSeen - right.firstSeen
        return left.name.localeCompare(right.name)
    })
    return groups
}
