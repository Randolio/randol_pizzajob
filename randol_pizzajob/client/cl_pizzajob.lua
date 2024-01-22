local QBCore = exports['qb-core']:GetCoreObject()
local Hired = false
local HasPizza = false
local Delivered = false
local PizzaDelivered = false
local ownsVan = false
local activeOrder = false
local PizzaConfig = {
    BossModel = `u_m_y_party_01`,
    BossCoords = vector4(538.35, 101.8, 95.54, 164.05), -- The Blip also uses these coords.
    Vehicle = `surge`,
    VehicleSpawn = vector4(535.3, 95.58, 96.32, 159.15),
}

DecorRegister("pizza_job", 1)

local function doEmote(emote)
    TriggerEvent('animations:client:EmoteCommandStart', {emote}) -- Adapt to whatever emote resource you use.
end

local function TakePizza()
    local player = cache.ped
    local pos = GetEntityCoords(player)
    if not IsPedInAnyVehicle(player, false) then
        if DoesEntityExist(player) and not IsEntityDead(player) then
            if not HasPizza then
                if #(pos - vector3(newDelivery.x, newDelivery.y, newDelivery.z)) < 30.0 then
                    doEmote("carrypizza")
                    HasPizza = true
                else
                    QBCore.Functions.Notify("You're not close enough to the customer's house!", "error")
                end
            end
        end
    end
end

local function PullOutVehicle()
    if ownsVan then
        QBCore.Functions.Notify("You already have a work vehicle! Go and collect it or end your job.", "error")
        return
    end
    local coords = PizzaConfig.VehicleSpawn
    QBCore.Functions.SpawnVehicle(PizzaConfig.Vehicle, function(pizzaCar)
        SetVehicleNumberPlateText(pizzaCar, "PIZZA"..tostring(math.random(1000, 9999)))
        SetVehicleColours(pizzaCar, 111, 111)
        SetVehicleDirtLevel(pizzaCar, 1)
        DecorSetFloat(pizzaCar, "pizza_job", 1)
        TaskWarpPedIntoVehicle(cache.ped, pizzaCar, -1)
        TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(pizzaCar))
        SetVehicleEngineOn(pizzaCar, true, true)
        SetVehicleFuelLevel(pizzaCar, 100)
        tempVeh = pizzaCar
    end, coords, true)
    Hired = true
    ownsVan = true
    NextDelivery()
    Wait(500)
    exports['qb-target']:AddTargetEntity(tempVeh, {
        options = {
            {
                icon = "fa-solid fa-pizza-slice",
                label = "Take Pizza",
                action = function(entity) TakePizza() end,
                canInteract = function() 
                    return Hired and activeOrder and not HasPizza
                end,
                
            },
        },
        distance = 2.5
    })
end

local function finishWork()
    local ped = cache.ped
    local pos = GetEntityCoords(ped)
    local veh = GetPlayersLastVehicle()
    local finishspot = vector3(PizzaConfig.BossCoords.x, PizzaConfig.BossCoords.y, PizzaConfig.BossCoords.z)
    if #(pos - finishspot) < 10.0 then
        if Hired then
            if DecorExistOn((veh), "pizza_job") then
                QBCore.Functions.DeleteVehicle(veh)
            end
            RemoveBlip(JobBlip)
            Hired = false
            HasPizza = false
            ownsVan = false
            activeOrder = false
            lib.callback.await('randol_pizzajob:server:clockOut', false)
            QBCore.Functions.Notify("You ended your shift.", "success")
        end
    end
end

local function PizzaClockIn()
    if DoesEntityExist(pizzaBoss) then return end
    lib.requestModel(PizzaConfig.BossModel, 1000)
    pizzaBoss = CreatePed(0, PizzaConfig.BossModel, PizzaConfig.BossCoords, false, false)
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
                    PullOutVehicle()
                end,
                canInteract = function()
                    return not Hired
                end,
            },
            {
                icon = "fa-solid fa-pizza-slice",
                label = "Finish Work",
                action = function()
                    finishWork()
                end,
                canInteract = function()
                    return Hired
                end,
            },
        }, 
        distance = 1.5, 
    })
    local pizzajobBlip = AddBlipForCoord(vector3(PizzaConfig.BossCoords.x, PizzaConfig.BossCoords.y, PizzaConfig.BossCoords.z)) 
    SetBlipSprite(pizzajobBlip, 267)
    SetBlipAsShortRange(pizzajobBlip, true)
    SetBlipScale(pizzajobBlip, 0.6)
    SetBlipColour(pizzajobBlip, 2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Pizza Job")
    EndTextCommandSetBlipName(pizzajobBlip)
end

local function deliverPizza()
    if HasPizza and Hired and not PizzaDelivered then
        lib.requestAnimDict('timetable@jimmy@doorknock@', 1000)
        TaskPlayAnim(cache.ped, 'timetable@jimmy@doorknock@', 'knockdoor_idle', 3.0, 1.0, -1, 49, 0, true, true, true)
        PizzaDelivered = true
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
                HasPizza = false
                activeOrder = false
                PizzaDelivered = false
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
    if not activeOrder then
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
        exports['qb-target']:AddCircleZone("deliverZone", vector3(newDelivery.x, newDelivery.y, newDelivery.z), 1.3,{
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
end

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() == resource then
        PlayerJob = QBCore.Functions.GetPlayerData().job
        PizzaClockIn()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PizzaClockIn()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    exports['qb-target']:RemoveZone("deliverZone")
    RemoveBlip(JobBlip)
    Hired = false
    HasPizza = false
    Delivered = false
    PizzaDelivered = false
    ownsVan = false
    activeOrder = false  
    DeletePed(pizzaBoss)
end)

AddEventHandler('onResourceStop', function(resourceName) 
	if GetCurrentResourceName() == resourceName then
        exports['qb-target']:RemoveZone("deliverZone")
        RemoveBlip(JobBlip)
        Hired = false
        HasPizza = false
        Delivered = false
        PizzaDelivered = false
        ownsVan = false
        activeOrder = false
        DeletePed(pizzaBoss)  
	end 
end)
