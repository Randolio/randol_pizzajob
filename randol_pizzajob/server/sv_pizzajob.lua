local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('randol_pizzajob:server:Payment', function(jobsDone)
	local src = source
    local payment = Config.Payment * jobsDone
	local Player = QBCore.Functions.GetPlayer(source)
    jobsDone = tonumber(jobsDone)
    if jobsDone > 0 then
        Player.Functions.AddMoney("cash", payment)
        TriggerClientEvent("QBCore:Notify", source, "You received $"..payment, "success")
    end
end)

RegisterServerEvent('randol_pizzajob:server:PayEveryStop', function()
    local src = source
    local payment = Config.PayEveryStopAmount or 5

    local Player = QBCore.Functions.GetPlayer(source)

    Player.Functions.AddMoney("cash", payment)
    TriggerClientEvent("QBCore:Notify", source, "You were tipped $"..payment, "success")
end)