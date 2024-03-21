if not lib.checkDependency('ND_Core', '2.0.0') then return end

NDCore = {}

lib.load('@ND_Core.init')

function GetPlayer(id)
    return NDCore.getPlayer(id)
end

function DoNotification(src, text, nType)
    TriggerClientEvent('ox_lib:notify', src, { type = nType, description = text })
end

function AddMoney(Player, moneyType, amount)
    Player.addMoney(moneyType, amount)
end

function handleExploit(id, reason)
    DropPlayer(id, 'You were dropped from the server.')
    print(('[^3WARNING^7] Player: ^5%s^7 Attempted to exploit randol_pizzajob!'):format(id))
end

AddEventHandler("ND:characterUnloaded", function(src, character)
    ServerOnLogout(src)
end)
