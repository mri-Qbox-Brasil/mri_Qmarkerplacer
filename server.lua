local QBCore = exports['qb-core']:GetCoreObject()

-- Load locale support
lib.locale()

local markers = {}

--- Load markers from data.json
local function loadMarkers()
    local file = LoadResourceFile(GetCurrentResourceName(), 'data.json')
    if file then
        markers = json.decode(file) or {}
    end
end

--- Save markers to data.json
local function saveMarkers()
    SaveResourceFile(GetCurrentResourceName(), 'data.json', json.encode(markers, { indent = true }), -1)
end

--- Initialize markers on server start
loadMarkers()

--- Handle marker creation
---@param source number - The player's source ID
---@param markerData table - The data for the marker to be added
lib.callback.register('markerplacer:addMarker', function(source, markerData)
    table.insert(markers, markerData)
    saveMarkers()
    TriggerClientEvent('markerplacer:receiveMarkers', -1, markers) -- Sync markers with all clients

    -- Send confirmation message to the player
    TriggerClientEvent('chat:addMessage', source, {
        args = { locale('marker_added') }
    })
end)

--- Handle marker synchronization
---@param source number - The player's source ID
---@param updatedMarkers table - The updated markers data
lib.callback.register('markerplacer:syncMarkers', function(source, updatedMarkers)
    markers = updatedMarkers
    saveMarkers()
    TriggerClientEvent('markerplacer:receiveMarkers', -1, markers)

    -- Send confirmation message to the player
    TriggerClientEvent('chat:addMessage', source, {
        args = { locale('markers_synced') }
    })
end)

--- Send markers to a player when they join
---@param source number - The player's source ID
lib.callback.register('markerplacer:requestMarkers', function(source)
    TriggerClientEvent('markerplacer:receiveMarkers', source, markers)
end)

--- Register the command securely
---@param source number - The player's source ID
---@param args table - The command arguments
lib.addCommand('markermenu', {
    help = locale('open_marker_menu_help'),
    restricted = 'group.admin', -- Restrict to specific groups
}, function(source, args)
    TriggerClientEvent('markerplacer:showMainMenu', source)
end)
