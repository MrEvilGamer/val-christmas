local Framework = nil
if Config.Framework == 'qbcore' then
    Framework = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'qbox' then
    Framework = exports['qbx-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    Framework = exports['es_extended']:getSharedObject()
end

local function sendDiscordLog(playerName, playerId, rewardTable)
    if not Config.Webhook or Config.Webhook == '' then return end
    local embed = {
        {
            title = "Christmas Tree Claimed",
            color = 65280,
            description = ("**Player:** %s\n**ID:** %s\n**Rewards:**\n%s"):format(playerName, playerId, table.concat(rewardTable, '\n')),
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }
    }
    PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({embeds = embed}), {['Content-Type'] = 'application/json'})
end

local lastRewardClaim = {}
local claimedTree = {}

RegisterNetEvent('val-christmas:reward', function(treeId)
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

    local now = os.time()
    if lastRewardClaim[src] and now - lastRewardClaim[src] < (Config.RewardCooldown or 60) then
        print((GetPlayerName and GetPlayerName(src) or tostring(src)) .. " tried to exploit val-christmas:reward (cooldown)")
        return
    end
    lastRewardClaim[src] = now

    if treeId then
        claimedTree[src] = claimedTree[src] or {}
        if claimedTree[src][treeId] then
            print((GetPlayerName and GetPlayerName(src) or tostring(src)) .. " tried to exploit val-christmas:reward (tree double claim)")
            return
        end
        claimedTree[src][treeId] = true
    end

    local rewardLog = {}
    for reward, details in pairs(Config.Rewards) do
        if type(reward) == 'string' and type(details) == 'table' and details.min and details.max and details.chance then
            local chance = math.random(1, 100)
            if chance <= details.chance then
                local amount = math.random(details.min, details.max)
                if amount < details.min or amount > details.max then
                    print(('Exploit attempt: %s tried to claim invalid amount for %s'):format(GetPlayerName(src) or src, reward))
                    return
                end
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
                    table.insert(rewardLog, ("%s x%d"):format(reward, amount))
                    if Config.Framework == 'qbcore' and Framework.Functions and Framework.Functions.Notify then
                        TriggerClientEvent('QBCore:Notify', source, "You received " .. amount .. "x " .. reward .. "!", "success")
                    elseif Config.Framework == 'qbox' then
                        TriggerClientEvent('QBCore:Notify', source, "You received " .. amount .. "x " .. reward .. "!", "success")
                    elseif Config.Framework == 'esx' then
                        TriggerClientEvent('esx:showNotification', source, "You received " .. amount .. "x " .. reward .. "!")
                    else
                        print("You received " .. amount .. "x " .. reward .. "!")
                    end
                else
                    print("Player or Player.Functions is nil")
                end
            end
        else
            print(('Invalid reward config for %s, skipping'):format(tostring(reward)))
        end
    end
    if #rewardLog > 0 then
        local playerName = GetPlayerName and GetPlayerName(src) or tostring(src)
        sendDiscordLog(playerName, src, rewardLog)
    end
end)
