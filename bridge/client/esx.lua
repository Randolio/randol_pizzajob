if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports['es_extended']:getSharedObject()

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    ESX.PlayerLoaded = true
    OnPlayerLoaded()
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    ESX.PlayerLoaded = false
    OnPlayerUnload()
end)

function handleVehicleKeys(veh)
    -- not sure if ESX use a keys system??
end

function hasPlyLoaded()
    return ESX.PlayerLoaded
end

function DoNotification(text, nType)
    ESX.ShowNotification(text, nType)
end
