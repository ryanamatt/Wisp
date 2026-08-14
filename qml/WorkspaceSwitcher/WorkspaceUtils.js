.pragma library


var classIconOverrides = {
    "spotify": "spotify-launcher",
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
        .map(ws => ({ id: ws.id, name: ws.name }))
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