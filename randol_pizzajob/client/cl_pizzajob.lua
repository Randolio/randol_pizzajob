local QBCore = exports['qb-core']:GetCoreObject()
local Hired = false
local HasPizza = false
local DeliveriesCount = 0
local Delivered = false
local PizzaDelivered = false
local ownsVan = false
local activeOrder = false

CreateThread(function()
    local pizzajobBlip = AddBlipForCoord(vector3(Config.BossCoords.x, Config.BossCoords.y, Config.BossCoords.z)) 
    SetBlipSprite(pizzajobBlip, 267)
    SetBlipAsShortRange(pizzajobBlip, true)
    SetBlipScale(pizzajobBlip, 0.8)
    SetBlipColour(pizzajobBlip, 2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Pizza Job")
    EndTextCommandSetBlipName(pizzajobBlip)
end)

function ClockInPed()

    if not DoesEntityExist(pizzaBoss) then

        RequestModel(Config.BossModel) while not HasModelLoaded(Config.BossModel) do Wait(0) end

        pizzaBoss = CreatePed(0, Config.BossModel, Config.BossCoords, false, false)
        
        SetEntityAsMissionEntity(pizzaBoss)
        SetPedFleeAttributes(pizzaBoss, 0, 0)
        SetBlockingOfNonTemporaryEvents(pizzaBoss, true)
        SetEntityInvincible(pizzaBoss, true)
        FreezeEntityPosition(pizzaBoss, true)
        loadAnimDict("amb@world_human_leaning@female@wall@back@holding_elbow@idle_a")        
        TaskPlayAnim(pizzaBoss, "amb@world_human_leaning@female@wall@back@holding_elbow@idle_a", "idle_a", 8.0, 1.0, -1, 01, 0, 0, 0, 0)

        exports['qb-target']:AddTargetEntity(pizzaBoss, { 
            options = {
                { 
                    type = "client",
                    event = "randol_pizzajob:client:startJob",
                    icon = "fa-solid fa-pizza-slice",
                    label = "Start Work",
                    canInteract = function()
                        return not Hired
                    end,
                },
                { 
                    type = "client",
                    event = "randol_pizzajob:client:finishWork",
                    icon = "fa-solid fa-pizza-slice",
                    label = "Finish Work",
                    canInteract = function()
                        return Hired
                    end,
                },
            }, 
            distance = 1.5, 
        })
    end
end

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() == resource then
        PlayerJob = QBCore.Functions.GetPlayerData().job
        ClockInPed()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    ClockInPed()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    exports['qb-target']:RemoveZone("deliverZone")
    RemoveBlip(JobBlip)
    Hired = false
    HasPizza = false
    DeliveriesCount = 0
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
        DeliveriesCount = 0
        Delivered = false
        PizzaDelivered = false
        ownsVan = false
        activeOrder = false
        DeletePed(pizzaBoss)  
	end 
end)

CreateThread(function()
    DecorRegister("pizza_job", 1)
end)

function PullOutVehicle()
    if ownsVan then
        QBCore.Functions.Notify("You already have a work vehicle! Go and collect it or end your job.", "error")
    else
        local coords = Config.VehicleSpawn
        QBCore.Functions.SpawnVehicle(Config.Vehicle, function(pizzaCar)
            SetVehicleNumberPlateText(pizzaCar, "PIZZA"..tostring(math.random(1000, 9999)))
            SetVehicleColours(pizzaCar, 111, 111)
            SetVehicleDirtLevel(pizzaCar, 1)
            DecorSetFloat(pizzaCar, "pizza_job", 1)
            TaskWarpPedIntoVehicle(PlayerPedId(), pizzaCar, -1)
            TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(pizzaCar))
            SetVehicleEngineOn(pizzaCar, true, true)
            exports[Config.FuelScript]:SetFuel(pizzaCar, 100.0)
            exports['qb-target']:AddTargetEntity(pizzaCar, {
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
        end, coords, true)
        Hired = true
        ownsVan = true
        NextDelivery()
    end
end


RegisterNetEvent('randol_pizzajob:client:startJob', function()
    if not Hired then
        PullOutVehicle()
    end
end)


RegisterNetEvent('randol_pizzajob:client:deliverPizza', function()
    if HasPizza and Hired and not PizzaDelivered then
        TriggerEvent('animations:client:EmoteCommandStart', {"knock"})
        PizzaDelivered = true
        QBCore.Functions.Progressbar("knock", "Delivering pizza", 7000, false, false, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function()
            DeliveriesCount = DeliveriesCount + 1
            RemoveBlip(JobBlip)
            exports['qb-target']:RemoveZone("deliverZone")
            HasPizza = false
            activeOrder = false
            PizzaDelivered = false
            DetachEntity(prop, 1, 1)
            DeleteObject(prop)
            Wait(1000)
            ClearPedSecondaryTask(PlayerPedId())
            QBCore.Functions.Notify("Pizza Delivered. Please wait for your next delivery!", "success") 

            if Config.PayEveryStop then
                TriggerServerEvent('randol_pizzajob:server:PayEveryStop')
            end
            
            SetTimeout(5000, function()    
                NextDelivery()
            end)
        end)
    else
        QBCore.Functions.Notify("You need the pizza from the car dummy.", "error") 
    end
end)


function loadAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		RequestAnimDict(dict)
		Wait(0)
	end
end

function TakePizza()
    local player = PlayerPedId()
    local pos = GetEntityCoords(player)
    if not IsPedInAnyVehicle(player, false) then
        local ad = "anim@heists@box_carry@"
        local prop_name = 'prop_pizza_box_01'
        if DoesEntityExist(player) and not IsEntityDead(player) then
            if not HasPizza then
                if #(pos - vector3(newDelivery.x, newDelivery.y, newDelivery.z)) < 30.0 then
                    loadAnimDict(ad)
                    local x,y,z = table.unpack(GetEntityCoords(player))
                    prop = CreateObject(GetHashKey(prop_name), x, y, z+0.2,  true,  true, true)
                    AttachEntityToEntity(prop, player, GetPedBoneIndex(player, 60309), 0.2, 0.08, 0.2, -45.0, 290.0, 0.0, true, true, false, true, 1, true)
                    TaskPlayAnim(player, ad, "idle", 3.0, -8, -1, 63, 0, 0, 0, 0 )
                    HasPizza = true
                else
                    QBCore.Functions.Notify("You're not close enough to the customer's house!", "error")
                end
            end
        end
    end
end


function NextDelivery()
    if not activeOrder then
        newDelivery = Config.JobLocs[math.random(1, #Config.JobLocs)]

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
        exports['qb-target']:AddCircleZone("deliverZone", vector3(newDelivery.x, newDelivery.y, newDelivery.z), 1.3,{ name = "deliverZone", debugPoly = false, useZ=true, }, { options = { { type = "client", event = "randol_pizzajob:client:deliverPizza", icon = "fa-solid fa-pizza-slice", label = "Deliver Pizza"}, }, distance = 1.5 })
        activeOrder = true
        QBCore.Functions.Notify("You have a new delivery!", "success")
    end
end

RegisterNetEvent('randol_pizzajob:client:finishWork', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local veh = QBCore.Functions.GetClosestVehicle()
    local finishspot = vector3(Config.BossCoords.x, Config.BossCoords.y, Config.BossCoords.z)
    if #(pos - finishspot) < 10.0 then
        if Hired then
            if DecorExistOn((veh), "pizza_job") then
                QBCore.Functions.DeleteVehicle(veh)
                RemoveBlip(JobBlip)
                Hired = false
                HasPizza = false
                ownsVan = false
                activeOrder = false
                if DeliveriesCount > 0 then
                    TriggerServerEvent('randol_pizzajob:server:Payment', DeliveriesCount)
                else
                    QBCore.Functions.Notify("You didn't complete any deliveries so you weren't paid.", "error")
                end
                DeliveriesCount = 0
            else
                QBCore.Functions.Notify("You must return your work vehicle to get paid.", "error")
                return
            end
        end
    end
end)

