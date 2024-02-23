local Config = lib.require('shared')
local WORKERS = {}
local PIZZA_PAYOUT = { min = 105, max = 135, }
local PIZZA_LOCATIONS = { -- Random delivery houses.
    vec3(224.11, 513.52, 140.92),
    vec3(57.51, 449.71, 147.03),
    vec3(-297.81, 379.83, 112.1),
    vec3(-595.78, 393.0, 101.88),
    vec3(-842.68, 466.85, 87.6),
    vec3(-1367.36, 610.73, 133.88),
    vec3(944.44, -463.19, 61.55),
    vec3(970.42, -502.5, 62.14),
    vec3(1099.5, -438.65, 67.79),
    vec3(1229.6, -725.41, 60.96),
    vec3(288.05, -1094.98, 29.42),
    vec3(-32.35, -1446.46, 31.89),
    vec3(-34.29, -1847.21, 26.19),
    vec3(130.59, -1853.27, 25.23),
    vec3(192.2, -1883.3, 25.06),
    vec3(348.64, -1820.87, 28.89),
    vec3(427.28, -1842.14, 28.46),
    vec3(291.48, -1980.15, 21.6),
    vec3(279.87, -2043.67, 19.77),
    vec3(1297.25, -1618.04, 54.58),
    vec3(1381.98, -1544.75, 57.11),
    vec3(1245.4, -1626.85, 53.28),
    vec3(315.09, -128.31, 69.98),
}

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
    local veh = CreateVehicleServerSetter(Config.Vehicle, 'automobile', Config.VehicleSpawn.x, Config.VehicleSpawn.y, Config.VehicleSpawn.z, Config.VehicleSpawn.w)
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

    return netid
end)

lib.callback.register('randol_pizzajob:server:getLocation', function(source)
    if WORKERS[source] then return false end

    local src = source
    local newDelivery = PIZZA_LOCATIONS[math.random(#PIZZA_LOCATIONS)]

    WORKERS[src] = {
        location = newDelivery,
        payment = math.random(PIZZA_PAYOUT.min, PIZZA_PAYOUT.max),
    }

    return newDelivery
end)

lib.callback.register('randol_pizzajob:server:clockOut', function(source, netid)
    local src = source
    if WORKERS[src] then
        WORKERS[src] = nil
        local ent = NetworkGetEntityFromNetworkId(netid)
        if DoesEntityExist(ent) and Entity(ent).state.pizzaCar then
            Entity(ent).state:set('pizzaCar', nil, true)
            DeleteEntity(ent)
        end
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
    WORKERS[src] = nil
    return true
end)

AddEventHandler("playerDropped", function()
    local src = source
    if WORKERS[src] then
        WORKERS[src] = nil
    end
end)

RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(source)
    if WORKERS[source] then
        WORKERS[source] = nil
    end
end)
