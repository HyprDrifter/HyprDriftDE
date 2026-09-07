.pragma library

var schemaVersion = 1

function stringValue(value) {
    return value === undefined || value === null ? "" : String(value)
}

function stringList(value) {
    var output = []
    if (!value)
        return output

    for (var index = 0; index < value.length; index++) {
        var item = stringValue(value[index]).trim()
        if (item.length > 0)
            output.push(item)
    }
    return output
}

function normalizeText(value) {
    var normalized = stringValue(value)
    if (normalized.length === 0)
        return ""

    var hasNonAscii = /[^\x00-\x7f]/.test(normalized)
    if (hasNonAscii) {
        try {
            normalized = normalized.normalize("NFKD")
        } catch (error) {
            // Older JavaScript engines may not expose String.normalize().
        }
    }

    normalized = normalized.toLowerCase()
    if (!hasNonAscii)
        return normalized.replace(/[^a-z0-9]+/g, " ").trim()

    return normalized.replace(/[\u0300-\u036f]/g, "")
        .replace(/[\u2000-\u206f\u2e00-\u2e7f\u3000-\u303f\ufe10-\ufe1f\ufe30-\ufe4f\uff00-\uff65]+/g, " ")
        .replace(/[^a-z0-9\u00c0-\u02af\u0370-\u052f\u0590-\u1fff\u2c00-\ud7ff\uf900-\ufaff]+/g, " ")
        .trim()
}

function words(value) {
    var normalized = normalizeText(value)
    return normalized.length === 0 ? [] : normalized.split(" ")
}

function initialsFromWords(parts) {
    var output = ""
    for (var index = 0; index < parts.length; index++) {
        if (parts[index].length > 0)
            output += parts[index][0]
    }
    return output
}

function initials(value) {
    return initialsFromWords(words(value))
}

function splitNormalized(value) {
    return value.length === 0 ? [] : value.split(" ")
}

function executableName(command) {
    if (!command || command.length === 0)
        return ""

    var executable = stringValue(command[0]).trim()
    var separator = Math.max(executable.lastIndexOf("/"), executable.lastIndexOf("\\"))
    if (separator >= 0)
        executable = executable.slice(separator + 1)
    return executable
}

function applicationLaunchIdentifiers(command) {
    var argumentsList = stringList(command)
    var output = []
    var seen = ({})

    function appendSteamIdentifier(appId) {
        var normalizedId = stringValue(appId).trim()
        if (!/^\d+$/.test(normalizedId))
            return

        var identifier = "steam_app_" + normalizedId
        if (seen[identifier])
            return
        seen[identifier] = true
        output.push(identifier)
    }

    for (var index = 0; index < argumentsList.length; index++) {
        var argument = argumentsList[index]
        var uriMatch = argument.match(
            /^steam:\/\/(?:rungameid|run|launch)\/(\d+)/i)
        if (uriMatch) {
            appendSteamIdentifier(uriMatch[1])
            continue
        }

        if (argument.toLowerCase() === "-applaunch"
                && index + 1 < argumentsList.length)
            appendSteamIdentifier(argumentsList[index + 1])
    }

    return output
}

function normalizeAppIdentifier(value) {
    var identifier = stringValue(value).trim().toLowerCase()
    if (identifier.length === 0)
        return ""

    var separator = Math.max(identifier.lastIndexOf("/"),
        identifier.lastIndexOf("\\"))
    if (separator >= 0)
        identifier = identifier.slice(separator + 1)
    if (identifier.slice(-8) === ".desktop")
        identifier = identifier.slice(0, -8)
    return identifier
}

function identifierTail(value) {
    var identifier = normalizeAppIdentifier(value)
    var separator = identifier.lastIndexOf(".")
    return separator >= 0 ? identifier.slice(separator + 1) : identifier
}

function iconNameCandidates(record) {
    var output = []
    var seen = ({})

    function append(value) {
        var candidate = stringValue(value).trim()
        if (candidate.length === 0 || candidate.startsWith("/")
                || candidate.startsWith("file:")
                || candidate.startsWith("image:")
                || candidate.startsWith("data:")
                || seen["icon:" + candidate])
            return
        seen["icon:" + candidate] = true
        output.push(candidate)
    }

    var desktopId = stringValue(record?.id).trim()
    if (desktopId.slice(-8).toLowerCase() === ".desktop")
        desktopId = desktopId.slice(0, -8)

    append(record?.icon)
    append(desktopId)
    append(record?.commandName)
    append(record?.startupClass)
    append(identifierTail(desktopId))
    return output
}

function prepareRecord(record) {
    record.id = stringValue(record.id).trim()
    record.name = stringValue(record.name).trim()
    record.genericName = stringValue(record.genericName).trim()
    record.comment = stringValue(record.comment).trim()
    record.icon = stringValue(record.icon).trim()
    record.startupClass = stringValue(record.startupClass).trim()
    record.commandName = stringValue(record.commandName).trim()
    if (record.launchIdentifiers)
        record.launchIdentifiers = stringList(record.launchIdentifiers)
    record.keywords = stringList(record.keywords)
    record.categories = stringList(record.categories)
    record.nameSearch = normalizeText(record.name)
    record.genericSearch = normalizeText(record.genericName)
    record.commentSearch = normalizeText(record.comment)
    record.keywordSearch = normalizeText(record.keywords.join(" "))
    record.categorySearch = normalizeText(record.categories.join(" "))
    record.commandSearch = normalizeText(record.commandName)
    record.idSearch = normalizeText(record.id)
    record.startupSearch = record.startupClass.length > 0
        ? normalizeText(record.startupClass)
        : ""
    record.idMatchKey = normalizeAppIdentifier(record.id)
    record.startupMatchKey = record.startupClass.length > 0
        ? normalizeAppIdentifier(record.startupClass)
        : ""
    record.commandMatchKey = normalizeAppIdentifier(record.commandName)
    if (record.launchIdentifiers) {
        record.launchMatchKeys = []
        for (var matchIndex = 0;
                matchIndex < record.launchIdentifiers.length; matchIndex++) {
            var launchMatchKey = normalizeAppIdentifier(
                record.launchIdentifiers[matchIndex])
            if (launchMatchKey.length > 0
                    && record.launchMatchKeys.indexOf(launchMatchKey) < 0)
                record.launchMatchKeys.push(launchMatchKey)
        }
    }
    record.nameMatchKey = record.nameSearch
    record.nameWords = splitNormalized(record.nameSearch)
    record.genericWords = splitNormalized(record.genericSearch)
    record.commentWords = splitNormalized(record.commentSearch)
    record.keywordWords = splitNormalized(record.keywordSearch)
    record.categoryWords = splitNormalized(record.categorySearch)
    record.commandWords = splitNormalized(record.commandSearch)
    record.idWords = splitNormalized(record.idSearch)
    record.nameInitials = initialsFromWords(record.nameWords)
    record.genericInitials = initialsFromWords(record.genericWords)
    record.sortKey = record.nameSearch + "\u0000" + record.idSearch
    record.modelKey = "app:" + record.id
    record.description = record.genericName.length > 0
        ? record.genericName
        : record.comment
    return record
}

function recordFromDesktopEntry(entry) {
    if (!entry || entry.noDisplay)
        return null

    var id = stringValue(entry.id).trim()
    var name = stringValue(entry.name).trim()
    if (id.length === 0 || name.length === 0)
        return null

    var commandName = executableName(entry.command)

    var recordData = {
        id: id,
        name: name,
        genericName: entry.genericName,
        comment: entry.comment,
        keywords: entry.keywords,
        categories: entry.categories,
        icon: entry.icon,
        startupClass: entry.startupClass,
        commandName: commandName,
        liveEntry: entry,
        available: true,
        baseOrder: 0
    }
    if (commandName === "steam")
        recordData.launchIdentifiers = applicationLaunchIdentifiers(
            entry.command)
    return prepareRecord(recordData)
}

function recordFromCache(data) {
    if (!data || typeof data !== "object")
        return null

    var id = stringValue(data.id).trim()
    var name = stringValue(data.name).trim()
    if (id.length === 0 || name.length === 0)
        return null

    return prepareRecord({
        id: id,
        name: name,
        genericName: data.genericName,
        comment: data.comment,
        keywords: data.keywords,
        categories: data.categories,
        icon: data.icon,
        startupClass: data.startupClass,
        commandName: data.commandName,
        launchIdentifiers: data.launchIdentifiers,
        liveEntry: null,
        available: false,
        baseOrder: 0
    })
}

function cachedRecord(record) {
    var cached = {
        id: record.id,
        name: record.name,
        genericName: record.genericName,
        comment: record.comment,
        keywords: stringList(record.keywords),
        categories: stringList(record.categories),
        icon: record.icon,
        startupClass: record.startupClass,
        commandName: record.commandName
    }
    if (record.launchIdentifiers)
        cached.launchIdentifiers = stringList(record.launchIdentifiers)
    return cached
}

function compareRecords(left, right) {
    if (left.sortKey < right.sortKey)
        return -1
    if (left.sortKey > right.sortKey)
        return 1
    return 0
}

function sortAndDeduplicate(records) {
    var byId = ({})
    var output = []

    for (var index = 0; index < records.length; index++) {
        var record = records[index]
        if (!record || byId["id:" + record.id])
            continue
        byId["id:" + record.id] = true
        output.push(record)
    }

    output.sort(compareRecords)
    for (var order = 0; order < output.length; order++)
        output[order].baseOrder = order
    return output
}

function recordsFromDesktopEntries(entries) {
    var records = []
    if (!entries)
        return records

    for (var index = 0; index < entries.length; index++) {
        var record = recordFromDesktopEntry(entries[index])
        if (record)
            records.push(record)
    }
    return sortAndDeduplicate(records)
}

function uniqueMatch(records, predicate) {
    var match = null
    for (var index = 0; index < records.length; index++) {
        if (!predicate(records[index]))
            continue
        if (match !== null)
            return null
        match = records[index]
    }
    return match
}

function recordForAppId(records, appId) {
    var identifier = normalizeAppIdentifier(appId)
    if (identifier.length === 0)
        return null

    var tail = identifierTail(identifier)
    var normalizedName = normalizeText(appId)
    var match = uniqueMatch(records, function(record) {
        return record.startupMatchKey.length > 0
            && (record.startupMatchKey === identifier
                || record.startupMatchKey === tail)
    })
    if (match)
        return match

    match = uniqueMatch(records, function(record) {
        return record.launchMatchKeys
            && record.launchMatchKeys.indexOf(identifier) >= 0
    })
    if (match)
        return match

    match = uniqueMatch(records, function(record) {
        return record.idMatchKey === identifier
    })
    if (match)
        return match

    match = uniqueMatch(records, function(record) {
        return record.commandMatchKey.length > 0
            && (record.commandMatchKey === identifier
                || record.commandMatchKey === tail)
    })
    if (match)
        return match

    // Reverse-domain desktop IDs commonly end with the actual application
    // name. Only accept a unique tail match so generic names cannot merge
    // unrelated applications.
    match = uniqueMatch(records, function(record) {
        return identifierTail(record.idMatchKey) === tail
    })
    if (match)
        return match

    return uniqueMatch(records, function(record) {
        return record.nameMatchKey.length > 0
            && record.nameMatchKey === normalizedName
    })
}

function decodeCache(contents) {
    var text = stringValue(contents).trim()
    if (text.length === 0)
        return { valid: true, entries: [] }

    var payload
    try {
        payload = JSON.parse(text)
    } catch (error) {
        return { valid: false, entries: [] }
    }

    if (!payload || payload.schemaVersion !== schemaVersion
            || !Array.isArray(payload.entries))
        return { valid: false, entries: [] }

    var records = []
    for (var index = 0; index < payload.entries.length; index++) {
        var record = recordFromCache(payload.entries[index])
        if (record)
            records.push(record)
    }
    return { valid: true, entries: sortAndDeduplicate(records) }
}

function encodeCache(records) {
    var entries = []
    for (var index = 0; index < records.length; index++)
        entries.push(cachedRecord(records[index]))
    return JSON.stringify({ schemaVersion: schemaVersion, entries: entries })
}

function boundedEditDistance(left, right, maximum) {
    if (Math.abs(left.length - right.length) > maximum)
        return maximum + 1

    var previous = []
    for (var column = 0; column <= right.length; column++)
        previous[column] = column

    for (var row = 1; row <= left.length; row++) {
        var current = [row]
        var rowMinimum = current[0]
        for (var columnIndex = 1; columnIndex <= right.length; columnIndex++) {
            var substitution = previous[columnIndex - 1]
                + (left[row - 1] === right[columnIndex - 1] ? 0 : 1)
            var insertion = current[columnIndex - 1] + 1
            var deletion = previous[columnIndex] + 1
            current[columnIndex] = Math.min(substitution, insertion, deletion)
            rowMinimum = Math.min(rowMinimum, current[columnIndex])
        }
        if (rowMinimum > maximum)
            return maximum + 1
        previous = current
    }
    return previous[right.length]
}

function typoLimit(token) {
    if (token.length < 3)
        return 0
    return token.length <= 5 ? 1 : 2
}

function fieldScore(field, fieldWords, fieldInitials, token) {
    if (!field || field.length === 0)
        return -1
    if (field === token)
        return 1000
    if (field.indexOf(token) === 0)
        return 900

    for (var index = 0; index < fieldWords.length; index++) {
        if (fieldWords[index] === token)
            return 860
    }
    for (var prefixIndex = 0; prefixIndex < fieldWords.length; prefixIndex++) {
        if (fieldWords[prefixIndex].indexOf(token) === 0)
            return 820
    }

    if (token.length >= 2 && fieldInitials.length > 0
            && fieldInitials.indexOf(token) === 0)
        return 800
    if (field.indexOf(token) >= 0)
        return 700

    return -1
}

function typoScore(fieldWords, token) {
    var maximum = typoLimit(token)
    if (maximum === 0)
        return -1

    var bestDistance = maximum + 1
    for (var wordIndex = 0; wordIndex < fieldWords.length; wordIndex++) {
        var candidate = fieldWords[wordIndex]
        if (candidate.length < 3)
            continue
        bestDistance = Math.min(bestDistance,
            boundedEditDistance(candidate, token, maximum))
    }
    return bestDistance <= maximum ? 600 - bestDistance * 100 : -1
}

function adjustedScore(score, offset) {
    return score < 0 ? -1 : score - offset
}

function tokenScore(record, token) {
    var best = -1
    var nameScore = fieldScore(record.nameSearch, record.nameWords,
        record.nameInitials, token)
    if (nameScore >= 900)
        return nameScore
    best = Math.max(best, nameScore)
    best = Math.max(best,
        adjustedScore(fieldScore(record.genericSearch, record.genericWords,
            record.genericInitials, token), 120))
    best = Math.max(best,
        adjustedScore(fieldScore(record.keywordSearch, record.keywordWords,
            "", token), 180))
    best = Math.max(best,
        adjustedScore(fieldScore(record.commandSearch, record.commandWords,
            "", token), 220))
    best = Math.max(best,
        adjustedScore(fieldScore(record.idSearch, record.idWords,
            "", token), 240))

    if (token.length >= 3) {
        best = Math.max(best,
            adjustedScore(fieldScore(record.commentSearch, record.commentWords,
                "", token), 340))
        best = Math.max(best,
            adjustedScore(fieldScore(record.categorySearch,
                record.categoryWords, "", token), 360))
    }

    // Typo expansion is intentionally the fallback path. Exact, prefix,
    // substring, and metadata matches avoid edit-distance work entirely.
    if (best >= 0)
        return best

    if (!/[a-z]/.test(token))
        return -1

    best = Math.max(best, typoScore(record.nameWords, token))
    best = Math.max(best,
        adjustedScore(typoScore(record.genericWords, token), 120))
    best = Math.max(best,
        adjustedScore(typoScore(record.keywordWords, token), 180))
    return best
}

function scoreRecord(record, normalizedQuery, tokens) {
    var score = 0
    for (var index = 0; index < tokens.length; index++) {
        var current = tokenScore(record, tokens[index])
        if (current < 0)
            return -1
        score += current
    }

    if (record.nameSearch === normalizedQuery)
        score += 2000
    else if (record.nameSearch.indexOf(normalizedQuery) === 0)
        score += 1000
    if (record.genericSearch === normalizedQuery)
        score += 700
    return score
}

function rankRecords(records, query) {
    var normalizedQuery = normalizeText(query)
    if (normalizedQuery.length === 0)
        return records.slice()

    var tokens = normalizedQuery.split(" ")
    var ranked = []
    for (var index = 0; index < records.length; index++) {
        var score = scoreRecord(records[index], normalizedQuery, tokens)
        if (score >= 0)
            ranked.push({ record: records[index], score: score })
    }

    ranked.sort(function(left, right) {
        if (left.score !== right.score)
            return right.score - left.score
        return left.record.baseOrder - right.record.baseOrder
    })

    var output = []
    for (var rankedIndex = 0; rankedIndex < ranked.length; rankedIndex++)
        output.push(ranked[rankedIndex].record)
    return output
}
