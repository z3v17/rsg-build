local RSGCore = exports['rsg-core']:GetCoreObject()
-- lib.locale()
local sbuilds = {}

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    MySQL.Async.fetchAll('SELECT * FROM construcciones', {}, function(objects)
        sbuilds = objects
        -- print("[rsg_construction] Se han cargado " .. #sbuilds .. " construcciones desde la base de datos.")
    end)
end)

local function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function formatNumber(num)
    num = tonumber(num)
    if not num then return 0.00 end
    return string.format("%.2f", num)
end

function getModelNameFromHash(hash)
    return Config.modelHashes[tonumber(hash)] or "unknown_model"
end

for model, itemName in pairs(Config.Constructions) do
    RSGCore.Functions.CreateUseableItem(itemName, function(source, item)
        local src = source
        -- print('Objeto de construccion, modelo: '..model)
        TriggerClientEvent('rsg-build:useItem', src, model)
    end)
end

RegisterServerEvent('rsg-build:saveObject')
AddEventHandler('rsg-build:saveObject', function(objectData)
    local src = source
    local xPlayer = RSGCore.Functions.GetPlayer(src)

    if not xPlayer then return end

    local owner = xPlayer.PlayerData.citizenid
    local query = [[INSERT INTO construcciones (model, x, y, z, rot_x, rot_y, rot_z, owner) VALUES (?, ?, ?, ?, ?, ?, ?, ?)]]
    local x = formatNumber(round(objectData.x, 2))
    local y = formatNumber(round(objectData.y, 2))
    local z = formatNumber(round(objectData.z, 2))
    local rx = formatNumber(round(objectData.rot_x, 2))
    local ry = formatNumber(round(objectData.rot_y, 2))
    local rz = formatNumber(round(objectData.rot_z, 2))

    MySQL.insert(query,{
        objectData.model,x,y,z,rx,ry,rz,owner
    }, function(insertId)
        if insertId then
            -- print("Construcción guardada con ID: " .. insertId)
            local item = objectData.item
            -- print("Objeto de construcción: " .. item)
            xPlayer.Functions.RemoveItem(item, 1)
            TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], "remove")
            objectData.id = insertId
            sbuilds[insertId] = objectData
            TriggerClientEvent('rsg-build:spawnSavedObjects', -1, {objectData})
        else
            -- print("Error al guardar construcción")
        end
    end)
end)

RegisterNetEvent('rsg-build:removeObject')
AddEventHandler('rsg-build:removeObject', function(coords, rot, model, entity, item, destroy)
    local src = source
    local xPlayer = RSGCore.Functions.GetPlayer(src)
    if not xPlayer then return end

    local person = xPlayer.PlayerData.citizenid
    local x = formatNumber(round(coords.x, 2))
    local y = formatNumber(round(coords.y, 2))
    local z = formatNumber(round(coords.z, 2))
    local rx = formatNumber(round(rot.x, 2))
    local ry = formatNumber(round(rot.y, 2))
    local rz = formatNumber(round(rot.z, 2))
    -- print("Eliminando construcción: " .. model .. " en " .. x .. ", " .. y .. ", " .. z)
    local isAdmin = RSGCore.Functions.HasPermission(src, 'admin')
    MySQL.query('SELECT id, owner FROM construcciones WHERE model = ? AND x = ? AND y = ? AND z = ?',{model, x, y, z--[[ , rx, ry, rz ]]}, function(result)
        if result and #result > 0 then
            local id = result[1].id
            -- print("Construcción encontrada para eliminar. ID: " .. id)
            -- print("Propietario: " ..result[1].owner..'solicitud: '..person)
            if not destroy then
                if result[1].owner == person or isAdmin then
                    -- print("owner confirmado: " .. person)
                    MySQL.query('DELETE FROM construcciones WHERE id = ?', {id})
                    TriggerClientEvent('rsg-build:client:removeObject', -1, entity,id, false)
                    -- print("Objeto de construcción: " .. item)
                    xPlayer.Functions.AddItem(item, 1)
                    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], "add")
                    sbuilds[id] = nil
                else
                    -- print("No tiene permisos para eliminar esta construcción.")
                end
            else
                local dynam = "weapon_thrown_dynamite"
                xPlayer.Functions.RemoveItem(dynam, 1)
                TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[dynam], "remove")
                MySQL.query('DELETE FROM construcciones WHERE id = ?', {id})
                TriggerClientEvent('rsg-build:client:removeObject', -1, entity,id,true)
                TriggerClientEvent('rsg-build:client:xadvice', src, id)
                -- print("Objeto de construcción: " .. item)
                sbuilds[id] = nil
            end
        else
            -- print("No se encontró la construcción para eliminar.")
        end
    end)
end)

RegisterNetEvent('rsg-build:ToggleDoor')
AddEventHandler('rsg-build:ToggleDoor', function(coords, rot, model, entity, item)
    local src = source
    local xPlayer = RSGCore.Functions.GetPlayer(src)
    if not xPlayer then return end

    local person = xPlayer.PlayerData.citizenid
    local x = formatNumber(round(coords.x, 2))
    local y = formatNumber(round(coords.y, 2))
    local z = formatNumber(round(coords.z, 2))
    local rx = formatNumber(round(rot.x, 2))
    local ry = formatNumber(round(rot.y, 2))
    local rz = formatNumber(round(rot.z, 2))
    -- print("Alternando puerta: " .. model .. " en " .. x .. ", " .. y .. ", " .. z)

    MySQL.query('SELECT id, owner, state FROM construcciones WHERE model = ? AND x = ? AND y = ? AND z = ?', {model, x, y, z}, function(result)
        if result and #result > 0 then
            local id = result[1].id
            local currentState = result[1].state
            local newState = currentState == 1 and 0 or 1 -- Alterna el estado
            -- print("Construcción encontrada para alternar. ID: " .. id)
            -- print("Propietario: " .. result[1].owner .. ' solicitud: ' .. person)
            if result[1].owner == person then
                -- print("owner confirmado: " .. person)
                MySQL.query('DELETE FROM construcciones WHERE id = ?', {id})
                TriggerClientEvent('rsg-build:client:removeObject', -1, entity, id, false)
                sbuilds[id] = nil

                local newRz = newState == 1 and (rz + 90) % 360 or (rz - 90) % 360

                local newDoorData = {
                    model = model,
                    x = x,
                    y = y,
                    z = z,
                    rot_x = rx,
                    rot_y = ry,
                    rot_z = newRz,
                    owner = person,
                    state = newState
                }

                MySQL.insert('INSERT INTO construcciones (model, x, y, z, rot_x, rot_y, rot_z, owner, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                    newDoorData.model, newDoorData.x, newDoorData.y, newDoorData.z, newDoorData.rot_x, newDoorData.rot_y, newDoorData.rot_z, newDoorData.owner, newDoorData.state
                }, function(insertId)
                    if insertId then
                        -- print("Puerta alternada y guardada con ID: " .. insertId)
                        newDoorData.id = insertId
                        sbuilds[insertId] = newDoorData
                        TriggerClientEvent('rsg-build:spawnSavedObjects', -1, {newDoorData})
                    else
                        -- print("Error al alternar la puerta")
                    end
                end)
            else
                -- print("No tiene permisos para alternar esta construcción.")
            end
        else
            -- print("No se encontró la construcción para alternar.")
        end
    end)
end)

RegisterNetEvent('rsg-build:sendToDiscord')
AddEventHandler('rsg-build:sendToDiscord', function(title, message)
    local discordWebhook = "TU_WEBHOOK_DE_DISCORD_AQUI"
    if discordWebhook == "" then return end
    
    local embed = {
        {
            ['title'] = title,
            ['description'] = message,
            ['color'] = 16711680,
            ['footer'] = {
                ['text'] = os.date("%Y-%m-%d %H:%M:%S")
            }
        }
    }
    PerformHttpRequest(discordWebhook, function(err, text, headers) end, 'POST', json.encode({username = "RSG Construction Logs", embeds = embed}), { ['Content-Type'] = 'application/json' })
end)

RegisterCommand('offallbuilds', function()
    TriggerClientEvent('rsg-build:client:offall', -1)
end, true)

RegisterNetEvent('rsg-build:requestObjects')
AddEventHandler('rsg-build:requestObjects', function()
    local src = source
    MySQL.query('SELECT * FROM construcciones', {}, function(objects)
        sbuilds = objects
        TriggerClientEvent('rsg-build:spawnSavedObjects', src, sbuilds)
    end)

end)