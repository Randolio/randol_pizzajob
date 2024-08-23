if GetResourceState('qbx_core') ~= 'started' then return end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    OnPlayerLoaded()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    OnPlayerUnload()
end)

function handleVehicleKeys(veh)
    TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(veh))
end

function hasPlyLoaded()
    return LocalPlayer.state.isLoggedIn
end

function DoNotification(text, nType)
    exports.qbx_core:Notify(text, nType)
end
