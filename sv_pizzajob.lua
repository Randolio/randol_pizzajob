local Server = lib.require('sv_config')
local players = {}

local function createPizzaVehicle(source)
    local veh = CreateVehicle(Server.Vehicle, Server.VehicleSpawn.x, Server.VehicleSpawn.y, Server.VehicleSpawn.z, Server.VehicleSpawn.w, true, true)
    local ped = GetPlayerPed(source)

    while not DoesEntityExist(veh) do Wait(0) end 

    while GetVehiclePedIsIn(ped, false) ~= veh do
        TaskWarpPedIntoVehicle(ped, veh, -1)
        Wait(0)
    end

    return NetworkGetNetworkIdFromEntity(veh)
end

lib.callback.register('randol_pizzajob:server:spawnVehicle', function(source)
    if players[source] then return false end

    local src = source
    local netid = createPizzaVehicle(src)

    local generatedLocs = {}
    local addedLocs = {}
    
    while #generatedLocs < Server.Deliveries do
        local index = math.random(#Server.Locations)

        if not addedLocs[index] then
            local randomLoc = Server.Locations[index]
            generatedLocs[#generatedLocs + 1] = randomLoc
            addedLocs[index] = true
        end
    end
    

    local currentLocIndex = math.random(#generatedLocs)
    local currentLoc = generatedLocs[currentLocIndex]
    table.remove(generatedLocs, currentLocIndex)

    local payout = math.random(Server.Payout.min, Server.Payout.max)

    players[src] = {
        entity = NetworkGetEntityFromNetworkId(netid),
        locations = generatedLocs,
        payment = payout,
        current = currentLoc,
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

    if not players[src] or #(pos - players[src].current) > 5.0 then
        handleExploit(src, 'Exploiting Pizza Job.')
        return false
    end
    
    AddMoney(Player, Server.Account, players[src].payment)

    if #players[src].locations == 0 then
        DoNotification(src, ('You received $%s. No more deliveries left, return the vehicle.'):format(players[src].payment))
        return true
    end
    
    DoNotification(src, ('You received $%s. Deliveries left: %s'):format(players[src].payment, #players[src].locations))
    local index = math.random(#players[src].locations)
    local newLoc = players[src].locations[index]
    local payout = math.random(Server.Payout.min, Server.Payout.max)
    table.remove(players[src].locations, index)

    players[src].current = newLoc
    players[src].payment = payout

    return true, players[src]
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
