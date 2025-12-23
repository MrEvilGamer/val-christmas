
local Framework = nil
if Config.Framework == 'qbcore' then
    Framework = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'qbox' then
    Framework = exports['qbx-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    Framework = exports['es_extended']:getSharedObject() or ESX
end

RegisterNetEvent('val-christmas:reward', function()
    local src = source
    local Player = nil
    if Config.Framework == 'qbcore' then
        Player = Framework.Functions.GetPlayer(src)
    elseif Config.Framework == 'qbox' then
        Player = Framework.Player.GetPlayerFromId(src)
    elseif Config.Framework == 'esx' then
        Player = Framework.GetPlayerFromId and Framework.GetPlayerFromId(src) or (Framework.GetPlayerFromId and Framework.GetPlayerFromId(src))
    end
    if not Player then return end
    for reward, details in pairs(Config.Rewards) do
        local chance = math.random(1, 100)
        if chance <= details.chance then
            local amount = math.random(details.min, details.max)
            if Player then
                if Config.Inventory == 'ox_inventory' then
                    exports.ox_inventory:AddItem(src, reward, amount)
                else
                    if Config.Framework == 'esx' and Player.addInventoryItem then
                        Player.addInventoryItem(reward, amount)
                    elseif Player.Functions and Player.Functions.AddItem then
                        Player.Functions.AddItem(reward, amount)
                    elseif Player.AddItem then -- for Qbox
                        Player.AddItem(reward, amount)
                    end
                end
                if Config.Framework == 'qbcore' and Framework.Functions and Framework.Functions.Notify then
                    TriggerClientEvent('QBCore:Notify', source, "You received " .. amount .. "x " .. reward .. "!", "success")
                elseif Config.Framework == 'qbox' then
                    TriggerClientEvent('QBCore:Notify', source, "You received " .. amount .. "x " .. reward .. "!", "success") -- Replace with Qbox notify if available
                elseif Config.Framework == 'esx' then
                    TriggerClientEvent('esx:showNotification', source, "You received " .. amount .. "x " .. reward .. "!")
                else
                    print("You received " .. amount .. "x " .. reward .. "!")
                end
            else
                print("Player or Player.Functions is nil")
            end
        end
    end
end)