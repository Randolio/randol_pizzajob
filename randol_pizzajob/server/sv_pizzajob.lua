local QBCore = exports['qb-core']:GetCoreObject()

local checkForJobNumber = true -- This setting allows tracking how many jobs the player has completed. 
local maximumJobs = 30 -- Maximum ammount based of number of JobLocations | For Security purposes keep in server-side
local timeoutTime = 60 -- Time in seconds how long the player will be in timeout
local inTimeout = {}

RegisterServerEvent('randol_pizzajob:server:Payment', function(jobsDone)
    local src = source
    local payment = Config.Payment * jobsDone
    local Player = QBCore.Functions.GetPlayer(source)

    if not src then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - vector3(Config.BossCoords.x, Config.BossCoords.y, Config.BossCoords.z)) < 10.0 then
    jobsDone = tonumber(jobsDone)

    if inTimeout[src] then DropPlayer(src, 'Exploiting - Was in timeout') return end
    if checkForJobNumber == true then
        if jobsDone > 30 then DropPlayer(src, 'Exploiting') return end -- You can replace DropPlayer with your ban resource exports
    end
    
    Player.Functions.AddMoney("cash", payment)
    TriggerClientEvent("QBCore:Notify", source, "You received $"..payment, "success")
    inTimeout[src] = true

    SetTimeout(timeoutTime * 1000, function()
        inTimeout[src] = nil
    end)
end)

