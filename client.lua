
local Framework = nil
if Config.Framework == 'qbcore' then
    Framework = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'qbox' then
    Framework = exports['qbx-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    Framework = exports['es_extended']:getSharedObject()
end

local modelLoaded = false
local createdTrees = {}

CreateThread(function()
    RequestModel(GetHashKey(Config.Tree))

    while not HasModelLoaded(GetHashKey(Config.Tree)) do
        Wait(500)
    end

    modelLoaded = true

    local checkInterval = 10000
    while true do
        Wait(checkInterval)

        if LocalPlayer.state['isLoggedIn'] then
            checkInterval = Config.TreeSpawnInterval

            local randomIndex = math.random(1, #Config.TreeLocs)
            local v = Config.TreeLocs[randomIndex]

            if not createdTrees[randomIndex] or (createdTrees[randomIndex] and createdTrees[randomIndex].lastCreated and GetGameTimer() - createdTrees[randomIndex].lastCreated > Config.TreeSpawnInterval) then
                if modelLoaded then
                    TriggerEvent("InteractSound_CL:PlayOnOne", 'christmas', 0.6)

                    if Config.OxLib then
                        lib.notify({
                            title = 'Notification',
                            description = Config.Notify,
                            type = 'inform'
                        })
                    else
                        if Config.Framework == 'esx' and Framework and Framework.ShowNotification then
                            Framework.ShowNotification(Config.Notify)
                        elseif Framework and Framework.Functions and Framework.Functions.Notify then
                            Framework.Functions.Notify(Config.Notify)
                        else
                            print('Notification: ' .. Config.Notify)
                        end
                    end

                    local prop = CreateObject(GetHashKey(Config.Tree), v.x, v.y, v.z - 1, false, false, false)
                    SetEntityAsMissionEntity(prop, false, false)
                    Wait(500)
                    PlaceObjectOnGroundProperly(prop)
                    Wait(1000)
                    FreezeEntityPosition(prop)

                    local blip = AddBlipForCoord(v.x, v.y, v.z)
                    SetBlipSprite(blip, 123)
                    SetBlipColour(blip, 0)
                    SetBlipScale(blip, 0.7)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString("Christmas Tree")
                    EndTextCommandSetBlipName(blip)

                    createdTrees[randomIndex] = {
                        prop = prop,
                        blip = blip,
                        lastCreated = GetGameTimer()
                    }

                    if Config.Target == 'qb' then
                        exports['qb-target']:AddBoxZone("christmas_" .. randomIndex, vector3(v.x, v.y, v.z), 3, 3, {
                            name = "christmas_" .. randomIndex,
                            heading = 350,
                            debugPoly = false,
                            minZ = v.z - 1.5,
                            maxZ = v.z + 1.5
                        }, {
                            options = {
                                {
                                    type = "client",
                                    event = "christmas:interact",
                                    icon = "fas fa-tree",
                                    label = "Interact with Christmas Tree",
                                    args = { index = randomIndex }
                                }
                            },
                            distance = 2.5
                        })
                    elseif Config.Target == 'ox' then
                        exports['ox_target']:addBoxZone({
                            name = "christmas_" .. randomIndex,
                            coords = vector3(v.x, v.y, v.z),
                            size = vec3(3.0, 3.0, 3.0),
                            rotation = 350,
                            debug = false,
                            options = {
                                {
                                    type = "client",
                                    event = "christmas:interact",
                                    icon = "fas fa-tree",
                                    label = "Interact with Christmas Tree",
                                    args = { index = randomIndex }
                                }
                            }
                        })
                    end
                end
            end
        end
    end
end)

RegisterNetEvent("christmas:interact", function(data)
    local treeIndex = data.args and data.args.index
    if not treeIndex then
        print("^1Error: Tree index is missing or nil.^7")
        return
    end

    local treeData = createdTrees[treeIndex]
    if treeData then
        if Config.OxLib then
            lib.progressBar({
                duration = 10000,                -- Time in milliseconds
                label = "Searching the tree...", -- Text to display
                useWhileDead = false,            -- Allow when player is dead
                canCancel = true,                -- Allow canceling
                disable = {
                    move = true,                 -- Disable player movement
                    car = true,                  -- Disable vehicle movement
                    combat = true,               -- Disable combat
                    mouse = false                -- Allow mouse input
                },
                anim = {
                    dict = "amb@prop_human_bum_bin@base",
                    clip = "base",
                    flag = 49
                }
            })
                :next(function(finished)
                    if finished then
                        ClearPedTasks(PlayerPedId())

                        if DoesEntityExist(treeData.prop) then
                            DeleteObject(treeData.prop)
                        end

                        RemoveBlip(treeData.blip)

                        if Config.Target == 'qb' then
                            exports['qb-target']:RemoveZone("christmas_" .. treeIndex)
                        elseif Config.Target == 'ox' then
                            exports['ox_target']:removeZone("christmas_" .. treeIndex)
                        end

                        createdTrees[treeIndex] = nil

                        TriggerServerEvent('val-christmas:reward', treeIndex)
                    else
                        ClearPedTasks(PlayerPedId())
                    end
                end)
        else
            if Config.Framework == 'esx' then
                Wait(10000)
                ClearPedTasks(PlayerPedId())
                if DoesEntityExist(treeData.prop) then
                    DeleteObject(treeData.prop)
                end
                RemoveBlip(treeData.blip)
                if Config.Target == 'qb' then
                    exports['qb-target']:RemoveZone("christmas_" .. treeIndex)
                elseif Config.Target == 'ox' then
                    exports['ox_target']:removeZone("christmas_" .. treeIndex)
                end
                createdTrees[treeIndex] = nil
                TriggerServerEvent('val-christmas:reward', treeIndex)
            elseif Framework and Framework.Functions and Framework.Functions.Progressbar then
                Framework.Functions.Progressbar("search_tree", "Searching the tree...", 10000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true
            }, {
                animDict = "amb@prop_human_bum_bin@base",
                anim = "base",
                flags = 49
                }, {}, {}, function()
                ClearPedTasks(PlayerPedId())

                if DoesEntityExist(treeData.prop) then
                    DeleteObject(treeData.prop)
                end

                RemoveBlip(treeData.blip)

                if Config.Target == 'qb' then
                    exports['qb-target']:RemoveZone("christmas_" .. treeIndex)
                elseif Config.Target == 'ox' then
                    exports['ox_target']:removeZone("christmas_" .. treeIndex)
                end

                createdTrees[treeIndex] = nil

                TriggerServerEvent('val-christmas:reward', treeIndex)
            end, function()
                ClearPedTasks(PlayerPedId())
            end)
            else
                -- fallback if no framework progressbar
                Wait(10000)
                ClearPedTasks(PlayerPedId())
                if DoesEntityExist(treeData.prop) then
                    DeleteObject(treeData.prop)
                end
                RemoveBlip(treeData.blip)
                if Config.Target == 'qb' then
                    exports['qb-target']:RemoveZone("christmas_" .. treeIndex)
                elseif Config.Target == 'ox' then
                    exports['ox_target']:removeZone("christmas_" .. treeIndex)
                end
                createdTrees[treeIndex] = nil
                TriggerServerEvent('val-christmas:reward', treeIndex)
            end
        end
    end
end)
