if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports['es_extended']:getSharedObject()

function GetPlayer(id)
    return ESX.GetPlayerFromId(id)
end

function DoNotification(src, text, nType)
    TriggerClientEvent('esx:showNotification', src, text, nType)
end

function AddMoney(xPlayer, moneyType, amount)
    local account = moneyType == 'cash' and 'money' or moneyType
    xPlayer.addAccountMoney(account, amount, "pizza-job")
end

function handleExploit(id, reason)
    DropPlayer(id, 'You were dropped from the server.')
    print(('[^3WARNING^7] Player: ^5%s^7 Attempted to exploit randol_pizzajob!'):format(id))
end

AddEventHandler('esx:playerLogout', function(playerId)
    ServerOnLogout(playerId)
end)
