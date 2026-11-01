.pragma library


var classIconOverrides = {
    "spotify": "spotify-launcher",
}

// Short labels for workspaces that should not just use their first letter.
var labelOverrides = {
    "grave": "~",
}

// Hyprland may report named workspaces as "name:foo" or just "foo".
// Strip the prefix so the rest of the code only deals with the bare name.
function normalizeName(name) {
    if (typeof name !== "string") return ""
    return name.replace(/^name:/, "")
}

// True when the workspace has a real (non-numeric) name.
function hasCustomName(name) {
    return name.length > 0 && isNaN(Number(name))
}

// Label shown next to the app icons, e.g. "D:", "~:", "3:".
// Named workspaces use the first character of their name.
function workspaceLabel(ws) {
    const name = normalizeName(ws.name)

    if (hasCustomName(name)) {
        const override = labelOverrides[name.toLowerCase()]
        if (override) return override + ":"
        return Array.from(name)[0].toUpperCase() + ":"
    }

    return ws.id + ":"
}

// Value to hand to the hyprctl focus dispatcher.
function workspaceTarget(ws) {
    const name = normalizeName(ws.name)
    return hasCustomName(name) ? "name:" + name : ws.id
}

// Parses `hyprctl -j workspaces` output into a sorted list of {id, name}.
function parseWorkspaces(jsonText) {
    let raw
    try {
        raw = JSON.parse(jsonText)
    } catch (e) {
        return []
    }

    if (!Array.isArray(raw)) return []

    return raw
        .map(ws => ({ id: ws.id, name: normalizeName(ws.name) }))
        .sort((a, b) => a.id - b.id)
}

// Parses `hyprctl -j clients` output into a map of
// workspaceId -> [{ wmClass, title }, ...]
function groupClientsByWorkspace(jsonText) {
    let raw
    try {
        raw = JSON.parse(jsonText)
    } catch (e) {
        return {}
    }

    if (!Array.isArray(raw)) return {}

    const grouped = {}

    for (const client of raw) {
        if (!client.workspace || client.workspace.id === undefined) continue

        const wsId = client.workspace.id
        if (!grouped[wsId]) grouped[wsId] = []

        grouped[wsId].push({
            wmClass: client.class || client.initialClass || "",
            title: client.title || client.initialTitle || ""
        })
    }

    return grouped
}

// Combines the workspace list + grouped client data into the final
// model consumed by the PathView.
function buildWorkspaceModel(workspaces, groupedClients) {
    return workspaces.map(ws => ({
        id: ws.id,
        name: ws.name,
        apps: groupedClients[ws.id] || []
    }))
}

// Finds the index of a workspace id within an already-built model array.
function indexOfWorkspaceId(model, id) {
    for (let i = 0; i < model.length; i++) {
        if (model[i].id === id) return i
    }
    return -1
}
