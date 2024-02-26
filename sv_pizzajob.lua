local Server = lib.require('sv_config')
local players = {}

local function createPizzaVehicle(source)
    local veh = CreateVehicleServerSetter(Server.Vehicle, 'automobile', Server.VehicleSpawn.x, Server.VehicleSpawn.y, Server.VehicleSpawn.z, Server.VehicleSpawn.w)
    local ped = GetPlayerPed(source)

    while not DoesEntityExist(veh) do Wait(10) end 

    while GetVehiclePedIsIn(ped, false) ~= veh do
        TaskWarpPedIntoVehicle(ped, veh, -1)
        Wait(100)
    end

    return NetworkGetNetworkIdFromEntity(veh)
end

lib.callback.register('randol_pizzajob:server:spawnVehicle', function(source)
    if players[source] then return false end

    local src = source
    local netid = createPizzaVehicle(src)

    local newDelivery = Server.Locations[math.random(#Server.Locations)]
    local payout = math.random(Server.Payout.min, Server.Payout.max)

    players[src] = {
        entity = NetworkGetEntityFromNetworkId(netid),
        location = newDelivery,
        payment = payout,
    }

    return netid, players[src]
end)

lib.callback.register('randol_pizzajob:server:clockOut', function(source)
    local src = source
    if players[src] then
        local ent = players[src].entity
        if DoesEntityExist(ent) then
            DeleteEntity(ent)
        end
        players[src] = nil
        return true
    end
    return false
end)

lib.callback.register('randol_pizzajob:server:Payment', function(source)
    local src = source
    local Player = GetPlayer(src)
    local pos = GetEntityCoords(GetPlayerPed(src))

    if not players[src] or #(pos - players[src].location) > 10.0 then
        handleExploit(src, 'Exploiting Pizza Job.')
        return false
    end
    
    AddMoney(Player, Server.Account, players[src].payment)	
    DoNotification(src, ('You received $%s. Please wait for your next delivery!'):format(players[src].payment), "success")

    CreateThread(function()
        local vehicle = players[src].entity
        players[src] = nil

        Wait(Server.Timeout)

        local newDelivery = Server.Locations[math.random(#Server.Locations)]
        local payout = math.random(Server.Payout.min, Server.Payout.max)

        players[src] = {
            entity = vehicle,
            location = newDelivery,
            payment = payout,
        }

        TriggerClientEvent("randol_pizajob:client:generatedLocation", src, players[src])
    end)

    return true
end)

AddEventHandler("playerDropped", function()
    local src = source
    if players[src] then
        local ent = players[src].entity
        if DoesEntityExist(ent) then
            DeleteEntity(ent)
        end
        players[src] = nil
    end
end)

function ServerOnLogout(source)
    if players[source] then
        local ent = players[src].entity
        if DoesEntityExist(ent) then
            DeleteEntity(ent)
        end
        players[source] = nil
    end
end
