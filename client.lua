local RSGCore = exports['rsg-core']:GetCoreObject()
local isMoving = false
local movingObject = nil
objectCoords = nil
local isRelocating = false
local buildings = {}
local loadedBuildings = {}
gizmoData = nil
local RENDER_DISTANCE = 150

function getModelNameFromHash(hash)
    return Config.modelHashes[tonumber(hash)] or "unknown_model"
end

function GetPlayerDistanceFromCoords(x, y, z)
	local playerPos = GetEntityCoords(PlayerPedId())
	local playerVector = vector3(playerPos.x, playerPos.y, playerPos.z)
	local posVector = vector3(x, y, z)
	return #(playerVector - posVector)
end

function GetConstructionModels()
    local models = {}
    for model, _ in pairs(Config.Constructions) do
        table.insert(models, model)
    end
    return models
end

function GetDoorModels()
    local models = {}
    for model, _ in pairs(Config.Doors) do
        table.insert(models, model)
    end
    return models
end


function finishPlacement()
    if movingObject --[[ and gizmoData ]] then
        local coords = GetEntityCoords(movingObject)
        local rotation = GetEntityRotation(movingObject)
        local mod = getModelNameFromHash(GetEntityModel(movingObject))
        -- print('Guardando objeto: ' .. mod..' con Modelo: '..GetEntityModel(movingObject))
        DeleteEntity(movingObject)
        TriggerServerEvent('rsg-build:saveObject', {
            model = mod,
            x = coords.x,
            y = coords.y,
            z = coords.z,
            rot_x = rotation.x,
            rot_y = rotation.y,
            rot_z = rotation.z,
            item = Config.Constructions[mod]
        })
        movingObject = nil
        isMoving = false
        objectCoords = nil
        -- gizmoData = nil -- Resetea gizmoData
    end
end

function cancelRelocation()
    if movingObject then
        DeleteEntity(movingObject)
        restoreObjectState()
        objectCoords = nil
        -- gizmoData = nil -- Resetea gizmoData

    end
end

function restoreObjectState()
    FreezeEntityPosition(movingObject, true)
    SetEntityAlpha(movingObject, 255, false)
    isMoving = false
    isRelocating = false
    movingObject = nil

end

function loadBuilding(id, building)
    if IsModelValid(building.model) then
        RequestModel(building.model)
        while not HasModelLoaded(building.model) do
            Citizen.Wait(10)
        end
        local ox, oy, oz, orx, ory, orz = tonumber(building.x), tonumber(building.y), tonumber(building.z), tonumber( building.rot_x), tonumber(building.rot_y), tonumber(building.rot_z)
        local spawned = CreateObjectNoOffset(building.model, building.x, building.y, building.z, false, false, false)
        SetEntityCollision(spawned, false, false)
        Citizen.Wait(1)
        SetEntityCoords(spawned, ox, oy, oz, false, true, false, false)
        SetEntityRotation(spawned, orx, ory, orz)
        FreezeEntityPosition(spawned, true)
        SetEntityCollision(spawned, true, false)

        loadedBuildings[id] = spawned
        SetModelAsNoLongerNeeded(building.model)


    end
end

function unloadBuilding(id)
    if loadedBuildings[id] and DoesEntityExist(loadedBuildings[id]) then
        DeleteEntity(loadedBuildings[id])
        loadedBuildings[id] = nil
    end
end

RegisterNetEvent('rsg-build:useItem')
AddEventHandler('rsg-build:useItem', function(objectModel)
    -- print("Usando item de construcción: " .. objectModel)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    if movingObject and DoesEntityExist(movingObject) then
        DeleteEntity(movingObject)
    end

    RequestModel(objectModel)
    while not HasModelLoaded(objectModel) do
        Wait(10)
    end

    movingObject = CreateObjectNoOffset(objectModel, coords.x, coords.y + 2.0, coords.z - 1.0, true, true, false)
    SetEntityAlpha(movingObject, 170, false)
    SetEntityCollision(movingObject, false, false)
    FreezeEntityPosition(movingObject, false)
    isMoving = true
end)

RegisterNetEvent('rsg-build:deleteObject')
AddEventHandler('rsg-build:deleteObject', function(data)
    local entity = data.entity
    local destroy = data.args.destroy -- Obtener el argumento destroy

    if destroy then
        -- Verificar si el jugador tiene dinamita
        local hasItem = RSGCore.Functions.HasItem('weapon_thrown_dynamite', 1)
        if not hasItem then
            lib.notify({ title = 'Error', description = 'Necesitas una dinamita', type = 'error', duration = 5000 })
            return
        end
    end
    -- print('Preparando para eliminar objeto: ' .. entity)
    if DoesEntityExist(entity) then
        -- print('Objeto existe: ' .. entity)
        local coords = GetEntityCoords(entity)
        local rot = GetEntityRotation(entity)
        local model = GetEntityModel(entity)
        local mod = getModelNameFromHash(model)
        local item = Config.Constructions[getModelNameFromHash(model)]
        -- print('Request Eliminando objeto: ' .. entity..' Modelo: '..mod..'Item: '..item)
        TriggerServerEvent('rsg-build:removeObject', coords, rot, mod, entity, item, destroy)
        -- Citizen.Wait(1000)
    end
end)

RegisterNetEvent('rsg-build:toggleDoor')
AddEventHandler('rsg-build:toggleDoor', function(data)
    local entity = data.entity
    -- print('Toggle Door: ' .. entity)
    if DoesEntityExist(entity) then
        -- print('Objeto existe: ' .. entity)
        local coords = GetEntityCoords(entity)
        local rot = GetEntityRotation(entity)
        local model = GetEntityModel(entity)
        local mod = getModelNameFromHash(model)
        local item = Config.Constructions[getModelNameFromHash(model)]
        -- print('Request Alternar objeto: ' .. entity..' Modelo: '..mod..'Item: '..item)
        TriggerServerEvent('rsg-build:ToggleDoor', coords, rot, mod, entity, item)
        
        -- Citizen.Wait(1000)
    end
end)

RegisterNetEvent('rsg-build:client:xadvice')
AddEventHandler('rsg-build:client:xadvice', function(id)
    lib.notify({ title = 'Alerta', description = 'Aléjate, esto va a explotar', type = 'info', duration = 5000 })
end)

RegisterNetEvent('rsg-build:client:removeObject')
AddEventHandler('rsg-build:client:removeObject', function(entity, id, xplode)
    -- print('Eliminando final objeto: ' .. buildings[id]..' ID: '..id)
    if loadedBuildings[id] and DoesEntityExist(loadedBuildings[id]) then
        if xplode then
            Citizen.Wait(4000)
            local ped_coords = GetEntityCoords(loadedBuildings[id])
            Citizen.InvokeNative(0x7D6F58F69DA92530, ped_coords.x, ped_coords.y, ped_coords.z, 25, 1.0, false, false, true)
        end
        DeleteEntity(loadedBuildings[id])
        loadedBuildings[id] = nil
    end
    buildings[id] = nil
    -- print('Total construcciones: '..#buildings)
end)

RegisterNetEvent('rsg-build:spawnSavedObjects')  ----- LOAD OBJ TABLE INSTEAD
AddEventHandler('rsg-build:spawnSavedObjects', function(objects)
    for i = 1, #objects do
        local obj = objects[i]
        local ox, oy, oz, orx, ory, orz = tonumber(obj.x), tonumber(obj.y), tonumber(obj.z), tonumber( obj.rot_x), tonumber(obj.rot_y), tonumber(obj.rot_z)
        local obid = obj.id
        -- print('Obteniendo ID: '..obid)
        local model = obj.model
            if not buildings[obid] then
                buildings[obid] = {
                    model = model,
                    x = ox,
                    y = oy,
                    z = oz,
                    rot_x = orx,
                    rot_y = ory,
                    rot_z = orz
                }
            end
    end
    -- print('Agregando construcciones : ' .. #objects)
end)

Citizen.CreateThread(function() ----- BUILDING CONTROLS
    while true do
        Citizen.Wait(0)
        if isMoving and movingObject then
            if not objectCoords then
                objectCoords = GetEntityCoords(movingObject)
            end
            DrawTextPrompt("Mover: ↑ ↓ ← → [SPACE][G] / Rotar: +[SHIFT] / Abortar:[BACKSPACE] / Ok:[ENTER]")

            if IsControlPressed(0, RSGCore.Shared.Keybinds['SPACEBAR']) and not IsControlPressed(0, RSGCore.Shared.Keybinds['SHIFT']) then
                objectCoords = objectCoords + vector3(0, 0, 0.02)
            elseif IsControlPressed(0, RSGCore.Shared.Keybinds['G']) and not IsControlPressed(0, RSGCore.Shared.Keybinds['SHIFT']) then
                objectCoords = objectCoords - vector3(0, 0, 0.02)
            elseif IsControlPressed(0, RSGCore.Shared.Keybinds['LEFT']) and not IsControlPressed(0, RSGCore.Shared.Keybinds['SHIFT']) then
                objectCoords = objectCoords + vector3(-0.02, 0, 0)
            elseif IsControlPressed(0, RSGCore.Shared.Keybinds['RIGHT']) and not IsControlPressed(0, RSGCore.Shared.Keybinds['SHIFT']) then
                objectCoords = objectCoords + vector3(0.02, 0, 0)
            elseif IsControlPressed(0, RSGCore.Shared.Keybinds['UP']) and not IsControlPressed(0, RSGCore.Shared.Keybinds['SHIFT']) then
                objectCoords = objectCoords + vector3(0, 0.02, 0)
            elseif IsControlPressed(0, RSGCore.Shared.Keybinds['DOWN']) and not IsControlPressed(0, RSGCore.Shared.Keybinds['SHIFT']) then
                objectCoords = objectCoords - vector3(0, 0.02, 0)
            end

            SetEntityCoords(movingObject, objectCoords)

            if IsControlPressed(0, RSGCore.Shared.Keybinds['SHIFT']) and IsControlPressed(0, RSGCore.Shared.Keybinds['LEFT']) then
                SetEntityRotation(movingObject, GetEntityRotation(movingObject) + vector3(0, 0, 0.5))
            elseif IsControlPressed(0, RSGCore.Shared.Keybinds['SHIFT']) and IsControlPressed(0, RSGCore.Shared.Keybinds['RIGHT']) then
                SetEntityRotation(movingObject, GetEntityRotation(movingObject) - vector3(0, 0, 0.5))
            elseif IsControlPressed(0, RSGCore.Shared.Keybinds['SHIFT']) and IsControlPressed(0, RSGCore.Shared.Keybinds['G']) then
                SetEntityRotation(movingObject, GetEntityRotation(movingObject) + vector3(0.5, 0, 0))
            elseif IsControlPressed(0, RSGCore.Shared.Keybinds['SHIFT']) and IsControlPressed(0, RSGCore.Shared.Keybinds['SPACEBAR']) then
                SetEntityRotation(movingObject, GetEntityRotation(movingObject) - vector3(0.5, 0, 0))
            elseif IsControlPressed(0, RSGCore.Shared.Keybinds['SHIFT']) and IsControlPressed(0, RSGCore.Shared.Keybinds['UP']) then
                SetEntityRotation(movingObject, GetEntityRotation(movingObject) + vector3(0, 0.5, 0))
            elseif IsControlPressed(0, RSGCore.Shared.Keybinds['SHIFT']) and IsControlPressed(0, RSGCore.Shared.Keybinds['DOWN']) then
                SetEntityRotation(movingObject, GetEntityRotation(movingObject) - vector3(0, 0.5, 0))
            end
            -- DrawTextPrompt("Abortar:[BACKSPACE] / Ok:[ENTER]")
            if IsControlJustPressed(0, RSGCore.Shared.Keybinds['ENTER']) then
                    finishPlacement()
            end
            if IsControlJustPressed(0, RSGCore.Shared.Keybinds['BACKSPACE']) then
                cancelRelocation()
            end
        end
    end
end)

function DrawTextPrompt(text)
    SetTextFontForCurrentCommand(0)
    SetTextScale(0.35, 0.35)
    SetTextColor(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    DisplayText(CreateVarString(10, "LITERAL_STRING", text), 0.5, 0.9)
end



Citizen.CreateThread(function()  ----- INITIAL LOAD
        Citizen.Wait(9000)
        TriggerServerEvent('rsg-build:requestObjects')
        exports['rsg-target']:AddTargetModel(GetConstructionModels(), {
            options = {
                {
                    event = 'rsg-build:deleteObject',
                    type = 'client',
                    icon = 'fas fa-trash',
                    label = 'Eliminar construcción',
                    args = { destroy = false }
                },
                {
                    event = 'rsg-build:deleteObject',
                    -- event = 'rsg-build:destroyObject',
                    type = 'client',
                    icon = 'fas fa-trash',
                    label = 'Destruir construcción',
                    args = { destroy = true }
                },
            },
            distance = 10.0
        })
        exports['rsg-target']:AddTargetModel(GetDoorModels(), {
            options = {
                {
                    event = 'rsg-build:toggleDoor',
                    type = 'client',
                    icon = 'fa-solid fa-link',
                    label = 'Alternar'
                },
            },
            distance = 10.0
        })
end)

Citizen.CreateThread(function()  ------- DYNAMIC LOAD
    while true do
        Citizen.Wait(1000) -- Verificar cada segundo para optimizar el rendimiento

        local playerCoords = GetEntityCoords(PlayerPedId())

        for id, building in pairs(buildings) do
            local distance = #(playerCoords - vector3(building.x, building.y, building.z))

            if distance <= RENDER_DISTANCE then
                -- Si la construcción está dentro del rango y no está cargada
                if not loadedBuildings[id] then
                    loadBuilding(id, building)
                end
            else
                -- Si la construcción está fuera del rango y está cargada
                if loadedBuildings[id] then
                    unloadBuilding(id)
                end
            end
        end
    end
end)

RegisterNetEvent('rsg-build:client:offall')
AddEventHandler('rsg-build:client:offall', function()
    print('Apagando construcciones')
    for id, build in pairs(loadedBuildings) do
        if build then
            -- print('construcción: '..build)
            if DoesEntityExist(build) then
                -- print('Eliminando construcción: '..build)
                DeleteEntity(build)
            else
                -- print('Construcción no existe: '..build)
            end
        end
    end
    -- Limpiar la tabla buildings
    loadedBuildings = {}
    buildings = {}
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    print('Apagando construcciones')

    loadedBuildings = loadedBuildings or {}
    buildings = buildings or {}

    for id, build in pairs(loadedBuildings) do
        if build then
            -- print('construcción: '..build)
            if DoesEntityExist(build) then
                -- print('Eliminando construcción: '..build)
                DeleteEntity(build)
            else
                -- print('Construcción no existe: '..build)
            end
        end
    end
    -- Limpiar la tabla buildings
    loadedBuildings = {}
    buildings = {}

end)