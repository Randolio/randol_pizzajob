local Config = lib.require('config')
local isHired, holdingPizza, pizzaDelivered, activeOrder = false, false, false, false
local pizzaProp, pizzaBoss, startZone

local pizzajobBlip = AddBlipForCoord(vec3(Config.BossCoords.x, Config.BossCoords.y, Config.BossCoords.z)) 
SetBlipSprite(pizzajobBlip, 267)
SetBlipAsShortRange(pizzajobBlip, true)
SetBlipScale(pizzajobBlip, 0.6)
SetBlipColour(pizzajobBlip, 2)
BeginTextCommandSetBlipName('STRING')
AddTextComponentString('Pizza Job')
EndTextCommandSetBlipName(pizzajobBlip)

local function doEmote(bool)
    if bool then
        local model = `prop_pizza_box_02`
        lib.requestModel(model, 2000)
        local coords = GetEntityCoords(cache.ped)
        pizzaProp = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
        AttachEntityToEntity(pizzaProp, cache.ped, GetPedBoneIndex(cache.ped, 28422), 0.0100,-0.1000, -0.1590, 20.0000007, 0.0, 0.0, true, true, false, true, 0, true)
        lib.requestAnimDict('anim@heists@box_carry@', 2000)
        TaskPlayAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 5.0, 5.0, -1, 51, 0, 0, 0, 0)
        SetModelAsNoLongerNeeded(model)
    else
        DetachEntity(cache.ped, true, false)
        DeleteEntity(pizzaProp)
        pizzaProp = nil
        ClearPedTasksImmediately(cache.ped)
    end
end

local function resetJob()
    exports['qb-target']:RemoveZone('deliverZone')
    RemoveBlip(JobBlip)
    isHired = false
    holdingPizza = false
    pizzaDelivered = false
    activeOrder = false
    if DoesEntityExist(pizzaBoss) then
        exports['qb-target']:RemoveTargetEntity(pizzaBoss, {'Take Pizza', 'Return Pizza'})
        DeleteEntity(pizzaBoss)
        pizzaBoss = nil
    end
    if startZone then startZone:remove() startZone = nil end
end

local function TakePizza()
    if IsPedInAnyVehicle(cache.ped, false) or IsEntityDead(cache.ped) or holdingPizza then
        return
    end
    
    local pos = GetEntityCoords(cache.ped)

    if #(pos - vec3(currentDelivery.x, currentDelivery.y, currentDelivery.z)) >= 30.0 then
        return DoNotification('You\'re not close enough to the customer\'s house!', 'error')
    end
    
    doEmote(true)
    holdingPizza = true
end

local function PullOutVehicle(netid, data)
    local pizzaCar = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netid) then
            return NetToVeh(netid)
        end
    end, 'Could not load entity in time.', 1000)

    if pizzaCar == 0 then
        return DoNotification('Error spawning the vehicle.', 'error')
    end

    SetVehicleNumberPlateText(pizzaCar, 'PIZZA'..tostring(math.random(1000, 9999)))
    SetVehicleColours(pizzaCar, 111, 111)
    SetVehicleDirtLevel(pizzaCar, 1)
    handleVehicleKeys(pizzaCar)
    SetVehicleEngineOn(pizzaCar, true, true)
    isHired = true
    NextDelivery(data)
    Wait(500)
    if Config.FuelScript.enable then
        exports[Config.FuelScript.script]:SetFuel(pizzaCar, 100.0)
    else
        Entity(pizzaCar).state.fuel = 100
    end
    exports['qb-target']:AddTargetEntity(pizzaCar, {
        options = {
            {
                icon = 'fa-solid fa-pizza-slice',
                label = 'Take Pizza',
                action = function(entity) 
                    TakePizza() 
                end,
                canInteract = function() 
                    return isHired and activeOrder and not holdingPizza
                end,
                
            },
            {
                icon = 'fa-solid fa-pizza-slice',
                label = 'Return Pizza',
                action = function(entity) 
                    doEmote(false)
                    holdingPizza = false
                end,
                canInteract = function() 
                    return isHired and activeOrder and holdingPizza
                end,
                
            },
        },
        distance = 2.5
    })
end

local function finishWork()
    local ped = cache.ped
    local pos = GetEntityCoords(ped)

    local finishspot = vec3(Config.BossCoords.x, Config.BossCoords.y, Config.BossCoords.z)
    if #(pos - finishspot) > 10.0 or not isHired then return end

    RemoveBlip(JobBlip)
    isHired, holdingPizza, activeOrder = false, false, false
    lib.callback.await('randol_pizzajob:server:clockOut', false)
    DoNotification('You ended your shift.', 'success')
end

local function yeetPed()
    if DoesEntityExist(pizzaBoss) then
        exports['qb-target']:RemoveTargetEntity(pizzaBoss, {'Take Pizza', 'Return Pizza'})
        DeleteEntity(pizzaBoss)
        pizzaBoss = nil
    end
end

local function spawnPed()
    if DoesEntityExist(pizzaBoss) then return end
    
    lib.requestModel(Config.BossModel, 1000)
    pizzaBoss = CreatePed(0, Config.BossModel, Config.BossCoords, false, false)
    SetEntityAsMissionEntity(pizzaBoss)
    SetPedFleeAttributes(pizzaBoss, 0, 0)
    SetBlockingOfNonTemporaryEvents(pizzaBoss, true)
    SetEntityInvincible(pizzaBoss, true)
    FreezeEntityPosition(pizzaBoss, true)
    lib.requestAnimDict('amb@world_human_leaning@female@wall@back@holding_elbow@idle_a', 1000)        
    TaskPlayAnim(pizzaBoss, 'amb@world_human_leaning@female@wall@back@holding_elbow@idle_a', 'idle_a', 8.0, 1.0, -1, 01, 0, 0, 0, 0)
    exports['qb-target']:AddTargetEntity(pizzaBoss, { 
        options = {
            {
                icon = 'fa-solid fa-pizza-slice',
                label = 'Start Work',
                action = function()
                    local netid, data = lib.callback.await('randol_pizzajob:server:spawnVehicle', false)
                    if netid and data then
                        PullOutVehicle(netid, data)
                    end
                end,
                canInteract = function()
                    return not isHired
                end,
            },
            {
                icon = 'fa-solid fa-pizza-slice',
                label = 'Finish Work',
                action = function()
                    finishWork()
                end,
                canInteract = function()
                    return isHired
                end,
            },
        }, 
        distance = 1.5, 
    })
end

local function deliverPizza()
    if holdingPizza and isHired and not pizzaDelivered then
        lib.requestAnimDict('timetable@jimmy@doorknock@', 1000)
        TaskPlayAnim(cache.ped, 'timetable@jimmy@doorknock@', 'knockdoor_idle', 3.0, 1.0, -1, 49, 0, true, true, true)
        pizzaDelivered = true
        if lib.progressCircle({
            duration = 7000,
            position = 'bottom',
            label = 'Delivering pizza',
            useWhileDead = true,
            canCancel = false,
            disable = { move = true, car = true, mouse = false, combat = true, },
        }) then
            local success, data = lib.callback.await('randol_pizzajob:server:Payment', false)
            if not success then return end
            RemoveBlip(JobBlip)
            exports['qb-target']:RemoveZone('deliverZone')
            holdingPizza = false
            activeOrder = false
            pizzaDelivered = false
            doEmote(false)
            if data then
                NextDelivery(data)
            end
        end
    else
        DoNotification('You need the pizza from the car dummy.', 'error') 
    end
end

function NextDelivery(data)
    if activeOrder then return end
    currentDelivery = data.current
    JobBlip = AddBlipForCoord(currentDelivery.x, currentDelivery.y, currentDelivery.z)
    SetBlipSprite(JobBlip, 1)
    SetBlipDisplay(JobBlip, 4)
    SetBlipScale(JobBlip, 0.8)
    SetBlipFlashes(JobBlip, true)
    SetBlipAsShortRange(JobBlip, true)
    SetBlipColour(JobBlip, 2)
    SetBlipRoute(JobBlip, true)
    SetBlipRouteColour(JobBlip, 2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Next Customer')
    EndTextCommandSetBlipName(JobBlip)
    exports['qb-target']:AddCircleZone('deliverZone', vec3(currentDelivery.x, currentDelivery.y, currentDelivery.z), 1.3,{
        name = 'deliverZone', 
        debugPoly = false, 
        useZ=true, 
    }, { options = {
        { 
            icon = 'fa-solid fa-pizza-slice', 
            label = 'Deliver Pizza',
            action = function() 
                deliverPizza()
            end,
        },}, 
        distance = 1.5 
    })
    activeOrder = true
    DoNotification('You have a new delivery!', 'success')
end

local function startJobPoint()
    startZone = lib.points.new({
        coords = Config.BossCoords.xyz,
        distance = 50,
        onEnter = spawnPed,
        onExit = yeetPed,
    })
end

function OnPlayerLoaded()
    startJobPoint()
end

function OnPlayerUnload()
    resetJob()
end

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource or not hasPlyLoaded() then return end
    startJobPoint()
end)

AddEventHandler('onResourceStop', function(resourceName) 
    if GetCurrentResourceName() ~= resourceName then return end
    resetJob()
end)
