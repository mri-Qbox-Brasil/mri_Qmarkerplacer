-- Initialize the Core object from QBCore.
local QBCore = exports['qb-core']:GetCoreObject()

-- Table to store marker data.
local markers = {}

-- Debug mode flag for additional debug information.
local debugMode = false

-- Index of the currently selected marker type.
local selectedMarkerIndex = 0

-- Flag to indicate if a marker is currently being shown.
local markerShowing = false

-- Maximum number of marker types available.
local maxMarkerTypes = 43

-- Default scale for the marker.
local markerScale = 2.0

-- Height offset for the marker.
local markerHeightOffset = 0.0

-- Initialize the localization module.
lib.locale()

--- Creates the input dialog for marker creation or editing.
---@param coords table The coordinates where the marker will be created or edited.
---@param markerData table|nil Data of the marker to be edited, if applicable.
---@return table The input data from the user.
local function createMarkerInputDialog(coords, markerData)
    return lib.inputDialog(
        markerData and locale('edit_marker') or locale('create_marker'),
        {
            {type = 'input', label = locale('marker_type'), default = markerData and tostring(markerData.marker) or tostring(selectedMarkerIndex), required = true},
            {type = 'input', label = locale('position_xyz'), default = ('%.2f, %.2f, %.2f'):format(coords.x, coords.y, coords.z + markerHeightOffset), required = true, placeholder = locale('position_placeholder')},
            {type = 'number', label = locale('scale'), default = markerData and markerData.scale or markerScale, placeholder = locale('scale_placeholder'), required = true, precision = 2},
            {type = 'color', label = locale('color'), default = markerData and ('rgb(%d, %d, %d)'):format(markerData.r, markerData.g, markerData.b) or 'rgb(255, 0, 0)', required = true, format = 'rgb'},
            {type = 'checkbox', label = locale('bob_up_and_down'), checked = markerData and markerData.bobUpAndDown or false, options = {{value = 'yes', label = locale('yes')}}},
            {type = 'checkbox', label = locale('face_camera'), checked = markerData and markerData.faceCamera or false, options = {{value = 'yes', label = locale('yes')}}},
            {type = 'checkbox', label = locale('rotate_marker'), checked = markerData and markerData.rotate or false, options = {{value = 'yes', label = locale('yes')}}},
            {type = 'number', label = locale('view_range'), default = markerData and markerData.range or 100.0, placeholder = locale('range_placeholder'), required = true, precision = 1},
            {type = 'checkbox', label = locale('show_all_players'), checked = markerData and markerData.show or true, options = {{value = 'yes', label = locale('yes')}}},
        }
    )
end

--- Handles the creation or editing of a marker.
---@param coords table The coordinates where the marker is to be created or edited.
---@param markerIndex number|nil The index of the marker in the markers table (nil for new markers).
local function handleMarkerCreationOrEdit(coords, markerIndex)
    local markerData = markerIndex and markers[markerIndex] or nil
    local input = createMarkerInputDialog(coords, markerData)

    if input then
        local x, y, z = string.match(input[2], '([%d%.%-]+),%s*([%d%.%-]+),%s*([%d%.%-]+)')
        local r, g, b = string.match(input[4], 'rgb%((%d+),%s*(%d+),%s*(%d+)%)')

        local data = {
            marker = tonumber(input[1]),
            vector = {x = tonumber(x), y = tonumber(y), z = tonumber(z)},
            scale = tonumber(input[3]),
            r = tonumber(r),
            g = tonumber(g),
            b = tonumber(b),
            alpha = 255,
            bobUpAndDown = input[5] and true or false,
            faceCamera = input[6] and true or false,
            rotate = input[7] and true or false,
            range = tonumber(input[8]), -- New range value
            show = input[9] and true or false,
            text = markerData and markerData.text or nil,
            textsize = markerData and markerData.textsize or nil,
            textfont = markerData and markerData.textfont or nil,
            textcolor = markerData and markerData.textcolor or nil,
            togglerect = markerData and markerData.togglerect or nil,
            textvectorz = markerData and markerData.textvectorz or nil
        }

        if markerIndex then
            markers[markerIndex] = data
            lib.callback.await('markerplacer:syncMarkers', false, markers)
            reopenMarkerMenu(markerIndex)
        else
            lib.callback.await('markerplacer:addMarker', false, data)
            refreshMainMenu()
            lib.showContext('marker_context_menu')
        end

        refreshMainMenu() -- Refresh the menu after creation or editing
    else
        print(markerIndex and locale('edit_cancelled') or locale('create_cancelled'))
        refreshMainMenu() -- Refresh the menu after cancellation
        if markerIndex then
            reopenMarkerMenu(markerIndex)
        else
            lib.showContext('marker_context_menu')
        end
    end
end

--- Displays the marker selection UI using mouse and scroll wheel.
function showMarkerSelection()
    selectedMarkerIndex = 0
    markerShowing = true
    markerScale = 2.0
    markerHeightOffset = 0.0
    lib.showTextUI(
        locale('controls_instructions'),
        {icon = 'hand-pointer', position = 'left-center'}
    )

    Citizen.CreateThread(function()
        local coords = vector3(0, 0, 0)
        while markerShowing do
            local hit, _, hitCoords, _, _ = lib.raycast.cam(1, 4, 10)
            if hit and hitCoords then
                coords = hitCoords
                DrawMarker(
                    selectedMarkerIndex,
                    coords.x, coords.y, coords.z + markerHeightOffset,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    markerScale, markerScale, markerScale,
                    255, 0, 0, 150,
                    false, true, 2, false, false, false, false
                )
            end
            
            if IsControlJustPressed(0, 241) and not IsControlPressed(0, 21) then -- Scroll up
                selectedMarkerIndex = (selectedMarkerIndex + 1) % (maxMarkerTypes + 1)
                lib.showTextUI(locale('controls_instructions'), {icon = 'hand-pointer', position = 'left-center'})
            elseif IsControlJustPressed(0, 242) and not IsControlPressed(0, 21) then -- Scroll down
                selectedMarkerIndex = (selectedMarkerIndex - 1) % (maxMarkerTypes + 1)
                if selectedMarkerIndex < 0 then selectedMarkerIndex = maxMarkerTypes end
                lib.showTextUI(locale('controls_instructions'), {icon = 'hand-pointer', position = 'left-center'})
            end

            -- Increase/decrease scale while holding Shift and scrolling the mouse
            if IsControlPressed(0, 21) then -- Shift key
                if IsControlJustPressed(0, 241) then -- Scroll up
                    markerScale = markerScale + 0.1
                elseif IsControlJustPressed(0, 242) then -- Scroll down
                    markerScale = markerScale - 0.1
                    if markerScale < 0.1 then markerScale = 0.1 end
                end
            end

            -- Adjust height with Q (decrease) and E (increase)
            if IsControlPressed(0, 44) then -- Q key
                markerHeightOffset = markerHeightOffset - 0.01
            elseif IsControlPressed(0, 38) then -- E key
                markerHeightOffset = markerHeightOffset + 0.01
            end
            
            if IsControlJustPressed(0, 191) then -- Enter key
                markerShowing = false
                lib.hideTextUI()
                if hit then
                    handleMarkerCreationOrEdit(coords)
                end
            end
            
            if IsControlJustPressed(0, 200) then -- ESC key
                markerShowing = false
                lib.hideTextUI()
                refreshMainMenu() -- Refresh the menu after cancellation
            end
        end
    end)
end

--- Refreshes and reopens the main marker menu.
function refreshMainMenu()
    local options = {
        {
            title = locale('select_marker_type'),
            description = locale('use_mouse_select'),
            icon = 'hand-pointer',
            onSelect = function()
                showMarkerSelection()
            end
        },
        {
            title = locale('create_new_marker'),
            onSelect = function()
                local pedCoords = GetEntityCoords(PlayerPedId())
                handleMarkerCreationOrEdit(pedCoords)
            end,
            icon = 'plus-circle',
        },
        {
            title = debugMode and locale('disable_debug') or locale('enable_debug'),
            event = 'markerplacer:toggleDebug',
            icon = 'bug',
        }
    }

    for i, v in ipairs(markers) do
        local markerName = v.name and ('[%d] %s'):format(i, v.name) or ('Marker %d'):format(i)
        table.insert(options, {
            title = markerName,
            description = locale('visible') .. ': ' .. (v.show and locale('true') or locale('false')),
            event = 'markerplacer:openMarkerMenu',
            args = i,
            icon = 'map-marker-alt',
        })
    end

    lib.registerContext({
        id = 'marker_context_menu',
        title = locale('marker_menu'),
        options = options
    })
end

--- Refreshes and reopens the specific marker menu.
---@param markerIndex number The index of the marker in the markers table.
function reopenMarkerMenu(markerIndex)
    local marker = markers[markerIndex]
    lib.registerContext({
        id = ('marker_%d_context'):format(markerIndex),
        title = locale('marker') .. ' ' .. markerIndex .. ' - ' .. locale('options'),
        description = locale('visible') .. ': ' .. (marker.show and locale('true') or locale('false')),
        menu = 'marker_context_menu',
        options = {
            {
                title = locale('teleport_to_marker'),
                event = 'markerplacer:teleportToMarker',
                args = markerIndex,
                icon = 'location-arrow',
            },
            {
                title = locale('edit_marker'),
                onSelect = function()
                    handleMarkerCreationOrEdit(marker.vector, markerIndex)
                end,
                icon = 'edit',
            },
            {
                title = locale('name_marker'),
                event = 'markerplacer:nameMarker',
                args = markerIndex,
                icon = 'font',
            },
            {
                title = locale('text_marker'),
                event = 'markerplacer:textMarker',
                args = markerIndex,
                icon = 'pencil',
            },
            {
                title = locale('reset_location'),
                event = 'markerplacer:resetMarkerLocation',
                args = markerIndex,
                icon = 'sync-alt',
            },  
            {
                title = locale('delete_marker'),
                event = 'markerplacer:deleteMarker',
                args = markerIndex,
                icon = 'trash-alt',
            }
        },
        onBack = function()
            lib.showContext('marker_context_menu')
        end
    })
    lib.showContext(('marker_%d_context'):format(markerIndex))
end

--- Event handler to toggle debug mode.
RegisterNetEvent('markerplacer:toggleDebug', function()
    debugMode = not debugMode
    refreshMainMenu()
    lib.showContext('marker_context_menu')
end)

--- Event handler to name a marker.
---@param markerIndex number The index of the marker in the markers table.
RegisterNetEvent('markerplacer:nameMarker', function(markerIndex)
    local marker = markers[markerIndex]
    local name = lib.inputDialog(locale('name_marker_input'), {
        {type = 'input', label = locale('marker_name'), default = marker.name or '', required = true}
    })
    if name then
        marker.name = name[1]
        markers[markerIndex] = marker
        lib.callback.await('markerplacer:syncMarkers', false, markers)
    end
    refreshMainMenu()
    reopenMarkerMenu(markerIndex)
end)

--- Event handler to add or edit text to a marker. 
--- Based on CustomDrawText3D(x, y, z, text, r, g, b, a, scale, fontStyle, toggleRect), using select list if you want to edit the text
        -- Font 0 is Chalet - London 1960
        -- Font 1 is Sign Painter - House Script
        -- Font 2 no idea, some sort of slab serif type
        -- Font 4-6 is Chalet Comprimé - Cologne 1960
        -- Font 7 is a slightly modified version of the classic Pricedown

--- @param markerIndex number The index of the marker in the markers table.
RegisterNetEvent('markerplacer:textMarker', function(markerIndex)
    local fontOptions = {
        {label = '#1 London 1960', value = 0},
        {label = '#2 House Script', value = 1},
        {label = '#3 House Script 2', value = 2},
        {label = '#4 Slab Serif', value = 3},
        {label = '#5 Cologne 1960', value = 4},
        {label = '#6 Classic Pricedown', value = 7},
    }

    local marker = markers[markerIndex]
    local text = lib.inputDialog(locale('text_marker'), {
        {type = 'input', label = locale('marker_text'), default = marker.text or ''},
        {type = 'color', label = locale('text_color'), default = marker.textcolor and ('rgba(%d, %d, %d, %d)'):format(marker.textcolor.r, marker.textcolor.g, marker.textcolor.b, marker.textcolor.a) or 'rgba(255, 255, 255, 255)', format = 'rgba', required = true},
        {type = 'slider', label = locale('text_size'), default = marker.textsize or 0.35, min = 0.01, max = 0.99, step = 0.01, precision = 2},
        {type = 'select', label = locale('font_style'), default = marker.textfont or 0, options = fontOptions},
        {type = 'checkbox', label = locale('toggle_rect'), checked = marker.togglerect or false},
        {type = 'number', label = locale('text_vectorz'), default = marker.textvectorz and marker.textvectorz or (marker.vector.z or 0), placeholder = locale('vectorz_placeholder'), required = true, precision = 2, step = 0.1},
    })
    if text then
        local r, g, b, a = string.match(text[2], 'rgba%((%d+),%s*(%d+),%s*(%d+),%s*(%d+)%)')
        marker.text = text[1]
        marker.textcolor = {
            r = tonumber(r) or 255,
            g = tonumber(g) or 255,
            b = tonumber(b) or 255,
            a = tonumber(a) or 255,
        }
        marker.textsize = text[3]
        marker.textfont = text[4]
        marker.togglerect = text[5]
        marker.textvectorz = text[6]
        
        markers[markerIndex] = marker
        lib.callback.await('markerplacer:syncMarkers', false, markers)
    end
    refreshMainMenu()
    reopenMarkerMenu(markerIndex)
end)


--- Event handler to open the marker menu.
---@param markerIndex number The index of the marker in the markers table.
RegisterNetEvent('markerplacer:openMarkerMenu', function(markerIndex)
    reopenMarkerMenu(markerIndex)
end)

--- Event handler to show the main marker menu.
RegisterNetEvent('markerplacer:showMainMenu', function()
    refreshMainMenu()
    lib.showContext('marker_context_menu')
end)

--- Event handler to teleport the player to a specific marker.
---@param markerIndex number The index of the marker in the markers table.
RegisterNetEvent('markerplacer:teleportToMarker', function(markerIndex)
    local marker = markers[markerIndex]
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, marker.vector.x, marker.vector.y, marker.vector.z, true, true, true)
    lib.notify({
        title = locale('teleport_success'),
        description = locale('teleport_success_desc'):format(markerIndex),
        type = 'success'
    })
    reopenMarkerMenu(markerIndex)
end)

--- Event handler to reset a marker's location to the player's current location.
---@param markerIndex number The index of the marker in the markers table.
RegisterNetEvent('markerplacer:resetMarkerLocation', function(markerIndex)
    local marker = markers[markerIndex]
    local coords = GetEntityCoords(PlayerPedId())
    marker.vector = {x = coords.x, y = coords.y, z = coords.z}
    markers[markerIndex] = marker
    lib.callback.await('markerplacer:syncMarkers', false, markers)
    reopenMarkerMenu(markerIndex)
end)

--- Event handler to delete a marker.
---@param markerIndex number The index of the marker in the markers table.
RegisterNetEvent('markerplacer:deleteMarker', function(markerIndex)
    table.remove(markers, markerIndex)
    lib.callback.await('markerplacer:syncMarkers', false, markers)
    refreshMainMenu()
    lib.showContext('marker_context_menu')
end)

--- Thread that continuously draws markers and handles debug information.
Citizen.CreateThread(function()
    while true do
        local sleep = 1000 -- Default sleep time
        local playerPed = cache.ped
        local playerCoords = GetEntityCoords(playerPed)

        for i, v in pairs(markers) do
            if v.show then
                local distance = #(playerCoords - vector3(tonumber(v.vector.x), tonumber(v.vector.y), tonumber(v.vector.z)))

                if distance < (tonumber(v.range) or 100.0) then
                    sleep = 0 

                    DrawMarker(
                        tonumber(v.marker) or 1,
                        tonumber(v.vector.x), tonumber(v.vector.y), tonumber(v.vector.z),
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        tonumber(v.scale) + 0.0, tonumber(v.scale) + 0.0, tonumber(v.scale) + 0.0,
                        tonumber(v.r) or 255, tonumber(v.g) or 255, tonumber(v.b) or 255, tonumber(v.alpha) or 255,
                        v.bobUpAndDown, v.faceCamera, 2, v.rotate, nil, nil, nil
                    )

                    if v.text and v.text ~= '' then
                        CustomDrawText3D(
                            tonumber(v.vector.x), tonumber(v.vector.y), v.textvectorz and tonumber(v.textvectorz) + 1.0 or tonumber(v.vector.z) + 1.0, 
                            v.text, 
                            v.textcolor and tonumber(v.textcolor.r) or 255, v.textcolor and tonumber(v.textcolor.g) or 255, v.textcolor and tonumber(v.textcolor.b) or 255,
                            tonumber(v.alpha) or 255,
                            tonumber(v.textsize) or 0.35, 
                            tonumber(v.textfont) or 4,
                            v.togglerect or false
                        )
                        -- DrawText3D(tonumber(v.vector.x), tonumber(v.vector.y), tonumber(v.vector.z) + 1.0, v.text)
                    end

                    if debugMode then
                        DrawText3D(tonumber(v.vector.x), tonumber(v.vector.y), tonumber(v.vector.z) + 1.0, ('ID: %d'):format(i))
                    end
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)


--- Draws 3D text at the specified coordinates.
---@param x number X coordinate.
---@param y number Y coordinate.
---@param z number Z coordinate.
---@param text string The text to display.
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local pX, pY, pZ = table.unpack(GetGameplayCamCoords())

    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 75)
    end
end

--- Draws 3D text at the specified coordinates with all custom parameters to edit in dialog

function CustomDrawText3D(x, y, z, text, r, g, b, a, scale, fontStyle, toggleRect)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local pX, pY, pZ = table.unpack(GetGameplayCamCoords())

    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(fontStyle)
        SetTextProportional(1)
        SetTextEntry("STRING")
        SetTextColour(r, g, b, a)
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        if toggleRect then
            local factor = (string.len(text)) / ((370 * 0.35) / scale)
            DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 75)
        end
    end
end

--- Receives the markers from the server and refreshes the menu.
---@param serverMarkers table The markers data from the server.
RegisterNetEvent('markerplacer:receiveMarkers', function(serverMarkers)
    markers = serverMarkers
    refreshMainMenu()
end)

--- Event handler to request markers when the player is loaded.
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local serverMarkers = lib.callback.await('markerplacer:requestMarkers', false)
    if serverMarkers then
        markers = serverMarkers
        refreshMainMenu()
    end
end)

--- Event handler to request markers when the resource starts.
---@param resourceName string The name of the resource being started.
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        local serverMarkers = lib.callback.await('markerplacer:requestMarkers', false)
        if serverMarkers then
            markers = serverMarkers
            refreshMainMenu()
        end
    end
end)
