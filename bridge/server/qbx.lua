if GetResourceState('qbx_core') ~= 'started' then return end


function GetPlayer(id)
    return exports.qbx_core:GetPlayer(id)
end

function DoNotification(src, text, nType)
    exports.qbx_core:Notify(src, text, nType)
end

function AddMoney(Player, moneyType, amount)
    Player.Functions.AddMoney(moneyType, amount, "cargo-delivery")
end

function handleExploit(id, reason)
    exports.qbx_core:ExploitBan(id, reason)
end

RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(source)
    ServerOnLogout(source)
end)