local Config = lib.require('shared')
local isHired = false
local holdingPizza = false
local Delivered = false
local pizzaDelivered = false
local activeOrder = false

local function doEmote(emote)
    TriggerEvent('animations:client:EmoteCommandStart', {emote}) -- Adapt to whatever emote resource you use.
end

local function resetJob()
    exports['qb-target']:RemoveZone("deliverZone")
    RemoveBlip(JobBlip)
    isHired = false
    holdingPizza = false
    Delivered = false
    pizzaDelivered = false
    activeOrder = false
    DeletePed(pizzaBoss)  
end

local function TakePizza()
    if IsPedInAnyVehicle(cache.ped, false) or not DoesEntityExist(cache.ped) or IsEntityDead(cache.ped) or holdingPizza then
        return
    end
    
    local pos = GetEntityCoords(cache.ped)

    if #(pos - vec3(newDelivery.x, newDelivery.y, newDelivery.z)) >= 30.0 then
        return QBCore.Functions.Notify("You're not close enough to the customer's house!", "error")
    end
    
    doEmote("carrypizza")
    holdingPizza = true
end

local function PullOutVehicle(netid)
    local pizzaCar = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netid) then
            return NetToVeh(netid)
        end
    end, 'Could not load entity in time.', 1000)

    if pizzaCar == 0 then
        return QBCore.Functions.Notify("Error spawning the vehicle.", "error")
    end

    SetVehicleNumberPlateText(pizzaCar, "PIZZA"..tostring(math.random(1000, 9999)))
    SetVehicleColours(pizzaCar, 111, 111)
    SetVehicleDirtLevel(pizzaCar, 1)
    TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(pizzaCar))
    SetVehicleEngineOn(pizzaCar, true, true)
    isHired = true
    NextDelivery()
    Wait(500)
    if Config.FuelScript.enable then
        exports[Config.FuelScript.script]:SetFuel(pizzaCar, 100.0)
    else
        Entity(pizzaCar).state.fuel = 100
    end
    exports['qb-target']:AddTargetEntity(pizzaCar, {
        options = {
            {
                icon = "fa-solid fa-pizza-slice",
                label = "Take Pizza",
                action = function(entity) TakePizza() end,
                canInteract = function() 
                    return isHired and activeOrder and not holdingPizza
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

    local veh = GetPlayersLastVehicle()
    RemoveBlip(JobBlip)
    isHired, holdingPizza, activeOrder = false, false, false
    lib.callback.await('randol_pizzajob:server:clockOut', false, NetworkGetNetworkIdFromEntity(veh))
    QBCore.Functions.Notify("You ended your shift.", "success")
end

local function PizzaClockIn()
    if DoesEntityExist(pizzaBoss) then return end
    
    lib.requestModel(Config.BossModel, 1000)
    pizzaBoss = CreatePed(0, Config.BossModel, Config.BossCoords, false, false)
    SetEntityAsMissionEntity(pizzaBoss)
    SetPedFleeAttributes(pizzaBoss, 0, 0)
    SetBlockingOfNonTemporaryEvents(pizzaBoss, true)
    SetEntityInvincible(pizzaBoss, true)
    FreezeEntityPosition(pizzaBoss, true)
    lib.requestAnimDict("amb@world_human_leaning@female@wall@back@holding_elbow@idle_a", 1000)        
    TaskPlayAnim(pizzaBoss, "amb@world_human_leaning@female@wall@back@holding_elbow@idle_a", "idle_a", 8.0, 1.0, -1, 01, 0, 0, 0, 0)
    exports['qb-target']:AddTargetEntity(pizzaBoss, { 
        options = {
            {
                icon = "fa-solid fa-pizza-slice",
                label = "Start Work",
                action = function()
                    local netid = lib.callback.await('randol_pizzajob:server:spawnVehicle', false)
                    if netid then
                        PullOutVehicle(netid)
                    end
                end,
                canInteract = function()
                    return not isHired
                end,
            },
            {
                icon = "fa-solid fa-pizza-slice",
                label = "Finish Work",
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
    local pizzajobBlip = AddBlipForCoord(vec3(Config.BossCoords.x, Config.BossCoords.y, Config.BossCoords.z)) 
    SetBlipSprite(pizzajobBlip, 267)
    SetBlipAsShortRange(pizzajobBlip, true)
    SetBlipScale(pizzajobBlip, 0.6)
    SetBlipColour(pizzajobBlip, 2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Pizza Job")
    EndTextCommandSetBlipName(pizzajobBlip)
end

local function deliverPizza()
    if holdingPizza and isHired and not pizzaDelivered then
        lib.requestAnimDict('timetable@jimmy@doorknock@', 1000)
        TaskPlayAnim(cache.ped, 'timetable@jimmy@doorknock@', 'knockdoor_idle', 3.0, 1.0, -1, 49, 0, true, true, true)
        pizzaDelivered = true
        QBCore.Functions.Progressbar("knock", "Delivering pizza", 7000, false, false, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function()
            local success = lib.callback.await('randol_pizzajob:server:Payment', false)
            if success then
                Wait(100)
                RemoveBlip(JobBlip)
                exports['qb-target']:RemoveZone("deliverZone")
                holdingPizza = false
                activeOrder = false
                pizzaDelivered = false
                doEmote("c")
                SetTimeout(5000, function()    
                    NextDelivery()
                end)
            end
        end)
    else
        QBCore.Functions.Notify("You need the pizza from the car dummy.", "error") 
    end
end

function NextDelivery()
    if activeOrder then return end

    newDelivery = lib.callback.await('randol_pizzajob:server:getLocation', false)
    JobBlip = AddBlipForCoord(newDelivery.x, newDelivery.y, newDelivery.z)
    SetBlipSprite(JobBlip, 1)
    SetBlipDisplay(JobBlip, 4)
    SetBlipScale(JobBlip, 0.8)
    SetBlipFlashes(JobBlip, true)
    SetBlipAsShortRange(JobBlip, true)
    SetBlipColour(JobBlip, 2)
    SetBlipRoute(JobBlip, true)
    SetBlipRouteColour(JobBlip, 2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Next Customer")
    EndTextCommandSetBlipName(JobBlip)
    exports['qb-target']:AddCircleZone("deliverZone", vec3(newDelivery.x, newDelivery.y, newDelivery.z), 1.3,{
        name = "deliverZone", 
        debugPoly = false, 
        useZ=true, 
    }, { options = {
        { 
            icon = "fa-solid fa-pizza-slice", 
            label = "Deliver Pizza",
            action = function() 
                deliverPizza()
            end,
        },}, 
        distance = 1.5 
    })
    activeOrder = true
    QBCore.Functions.Notify("You have a new delivery!", "success")
end

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    PizzaClockIn()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PizzaClockIn()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    resetJob()
end)

AddEventHandler('onResourceStop', function(resourceName) 
    if GetCurrentResourceName() ~= resourceName then return end
    resetJob()
end)
