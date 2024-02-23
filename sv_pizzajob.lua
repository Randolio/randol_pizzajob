local Server = lib.require('sv_config')
local WORKERS = {}

local function ExploitPizza(id, reason)
    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        GetPlayerName(id),
        QBCore.Functions.GetIdentifier(id, 'license'),
        QBCore.Functions.GetIdentifier(id, 'discord'),
        QBCore.Functions.GetIdentifier(id, 'ip'),
        reason,
        2147483647,
        'randol_pizzajob'
    })
    DropPlayer(id, 'You were banned from the server for exploiting.')
end

local function createPizzaVehicle(source)
    local veh = CreateVehicleServerSetter(Server.Vehicle, 'automobile', Server.VehicleSpawn.x, Server.VehicleSpawn.y, Server.VehicleSpawn.z, Server.VehicleSpawn.w)
    local ped = GetPlayerPed(source)

    while not DoesEntityExist(veh) do Wait(10) end 

    while GetVehiclePedIsIn(ped, false) ~= veh do
        TaskWarpPedIntoVehicle(ped, veh, -1)
        Wait(100)
    end

    Entity(veh).state:set('pizzaCar', true, true)
    return NetworkGetNetworkIdFromEntity(veh)
end

lib.callback.register('randol_pizzajob:server:spawnVehicle', function(source)
    if WORKERS[source] then return false end

    local src = source
    local netid = createPizzaVehicle(src)
    local newDelivery = Server.Locations[math.random(#Server.Locations)]

    WORKERS[src] = {
        entity = NetworkGetEntityFromNetworkId(netid),
        location = newDelivery,
        payment = math.random(Server.Payout.min, Server.Payout.max),
    }

    return netid, WORKERS[src]
end)

lib.callback.register('randol_pizzajob:server:clockOut', function(source)
    local src = source
    if WORKERS[src] then
        local ent = WORKERS[src].entity
        if DoesEntityExist(ent) and Entity(ent).state.pizzaCar then
            Entity(ent).state:set('pizzaCar', nil, true)
            DeleteEntity(ent)
        end
        WORKERS[src] = nil
        return true
    end
    return false
end)

lib.callback.register('randol_pizzajob:server:Payment', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local pos = GetEntityCoords(GetPlayerPed(src))
    local location = WORKERS[src].location
    if not WORKERS[src] or #(pos - location) > 10.0 then
        ExploitPizza(src, 'Exploiting Pizza Job.')
        return false
    end
    Player.Functions.AddMoney('bank', WORKERS[src].payment)	
    TriggerClientEvent("QBCore:Notify", src, "You received $"..WORKERS[src].payment..". Please wait for your next delivery!", "success")

    local newDelivery = Server.Locations[math.random(#Server.Locations)]
    WORKERS[src].location = newDelivery
    WORKERS[src].payment = math.random(Server.Payout.min, Server.Payout.max)

    CreateThread(function()
        Wait(5000)
        TriggerClientEvent("randol_pizajob:client:generatedLocation", src, WORKERS[src])
    end)
    return true
end)

AddEventHandler("playerDropped", function()
    local src = source
    if WORKERS[src] then
        local ent = WORKERS[src].entity
        if DoesEntityExist(ent) and Entity(ent).state.pizzaCar then
            Entity(ent).state:set('pizzaCar', nil, true)
            DeleteEntity(ent)
        end
        WORKERS[src] = nil
    end
end)

RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(source)
    if WORKERS[source] then
        local ent = WORKERS[src].entity
        if DoesEntityExist(ent) and Entity(ent).state.pizzaCar then
            Entity(ent).state:set('pizzaCar', nil, true)
            DeleteEntity(ent)
        end
        WORKERS[source] = nil
    end
end)
