local entities = {}

local function AddBlip(coords, options)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, options.Sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, options.Scale)
    SetBlipColour(blip, options.Color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(options.Label)
    EndTextCommandSetBlipName(blip)
    return blip
end

local function PlayAnim(ped, dict, anim, duration, flag, speed)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
    TaskPlayAnim(ped, dict, anim, speed or 8.0, -8.0, duration, flag, 0, false, false, false)
    RemoveAnimDict(dict)
end

local function CreateProp(model, coords, heading, network)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    local prop = CreateObject(hash, coords.x, coords.y, coords.z, network, false, false)
    SetEntityHeading(prop, heading)
    SetModelAsNoLongerNeeded(hash)
    return prop
end

local function Notify(msg, type)
    QBCore.Functions.Notify(msg, type)
end

local Target = {
    ['qb'] = {
        addTargetEntity = function(entity, options)
            if not DoesEntityExist(entity) then return end
            exports['qb-target']:AddTargetEntity(entity, {
                options = options,
                distance = 2.0
            })
        end,
        
        removeTargetEntity = function(entity)
            if not DoesEntityExist(entity) then return end
            exports['qb-target']:RemoveTargetEntity(entity)
        end,
        
        addBoxZone = function(name, coords, length, width, options)
            exports['qb-target']:AddBoxZone(name, coords, length, width, options.data, options.options)
        end
    },
    
    ['ox'] = {
        addTargetEntity = function(entity, options)
            if not DoesEntityExist(entity) then return end
            exports.ox_target:addLocalEntity(entity, options)
        end,
        
        removeTargetEntity = function(entity)
            if not DoesEntityExist(entity) then return end
            exports.ox_target:removeLocalEntity(entity)
        end,
        
        addBoxZone = function(name, coords, length, width, options)
            exports.ox_target:addBoxZone({
                coords = coords,
                size = vec3(length, width, 2.0),
                rotation = options.data.heading,
                debug = options.data.debugPoly,
                options = options.options
            })
        end
    }
}

local function AddTargetEntity(entity, options)
    if Cfg.Server.Target == 'ox' then
        local oxOptions = {}
        for _, option in ipairs(options) do
            table.insert(oxOptions, {
                name = option.event,
                icon = option.icon,
                label = option.label,
                onSelect = function()
                    TriggerEvent(option.event)
                end,
                canInteract = option.canInteract
            })
        end
        options = oxOptions
    end
    
    Target[Cfg.Server.Target].addTargetEntity(entity, options)
end

local function RemoveTargetEntity(entity)
    Target[Cfg.Server.Target].removeTargetEntity(entity)
end

local function taskNpcGiveEnvelope()
    PlayAnim(entities.npc, 'mp_common', 'givetake1_a', 1000, 0, 0.0)
    PlayAnim(cache.ped, 'mp_common', 'givetake1_a', 1000, 0, 0.0)
    SetTimeout(1000, function()
        AttachEntityToEntity(entities.envelope, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
        PlayAnim(cache.ped, 'melee@holster', 'holster', 1000, 0, 0.0)
        SetTimeout(750, function()
            DeleteEntity(entities.envelope)
            PlayPedAmbientSpeechNative(entities.npc, 'GENERIC_THANKS', 'SPEECH_PARAMS_FORCE')
            debug('[DEBUG] - Envelope given, player paid??')
        end)
    end)
end

lib.callback.register('vx_moneywash:startWashingProgressBar', function()
    SetTimeout(750, function()
        PlayAnim(entities.npc, 'anim@amb@casino@peds@',
            'amb_world_human_leaning_male_wall_back_texting_idle_a', -1, 0, 0.0)
        CreateThread(function()
            Wait(100)
            while true do
                if not IsEntityPlayingAnim(entities.npc, 'anim@amb@casino@peds@', 'amb_world_human_leaning_male_wall_back_texting_idle_a', 3) then
                    PlayAnim(entities.npc, 'anim@amb@casino@peds@', 'amb_world_human_leaning_male_wall_back_texting_idle_a', -1, 0, 0.0)
                    break
                end
                Wait(0)
            end
        end)
    end)
    if lib.progressCircle({
            duration = Cfg.Options.WashTime * 1000,
            label = _L('counting_money'),
            position = 'bottom',
            canCancel = false,
            disable = { move = true, combat = true }
        }) then
        PlayAnim(entities.npc, 'melee@holster', 'holster', 750, 0, 0.0)
        SetTimeout(500, function()
            local envelopeProp = 'prop_cash_envelope_01'
            entities.envelope = CreateProp(envelopeProp, Cfg.Options.Location, 0.0, false)
            AttachEntityToEntity(entities.envelope, entities.npc, GetPedBoneIndex(entities.npc, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
            DeleteEntity(entities.cash)
            taskNpcGiveEnvelope()
        end)
        debug('[DEBUG] - Money counted, giving envelope')
        return true
    else
        return false
    end
end)

local function taskGiveNpcMoney(amount, metadata)
    local cashProp = 'prop_anim_cash_pile_02'
    entities.cash = CreateProp(cashProp, Cfg.Options.Location, 0.0, false)
    AttachEntityToEntity(entities.cash, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
    
    if lib.progressCircle({
        duration = 2000,
        label = _L('giving_money'),
        position = 'bottom',
        canCancel = false,
        anim = { dict = 'mp_common', clip = 'givetake1_a' },
        disable = { move = true, combat = true }
    }) then
        PlayAnim(cache.ped, 'mp_common', 'givetake1_a', 1000, 0, 0.0)
        PlayAnim(entities.npc, 'mp_common', 'givetake1_a', 1000, 0, 0.0)
        TriggerServerEvent('vx_moneywash:startWashingMoney', cache.serverId, amount, metadata)
        debug('[DEBUG] - Money given, starting exchange')
        SetTimeout(750, function()
            AttachEntityToEntity(entities.cash, entities.npc, GetPedBoneIndex(entities.npc, 28422), 0, 0, 0, 168.93, -83.80, 76.29, true, true, false, true, 2, true)
        end)
    end
end

local function giveExchangeOffer(amount, metadata)
    local taxRate = lib.callback.await('vx_moneywash:getTaxRate', false)
    local given = amount if metadata then given = metadata.worth end
    local offer = math.ceil(given - (given * taxRate / 100))
    local confirm = lib.alertDialog({
        header = _L('money_wash'),
        content = _L('taxed_offer', offer, taxRate),
        centered = true,
        cancel = true
    })
    if confirm == 'cancel' then return PlayPedAmbientSpeechNative(entities.npc, 'GENERIC_INSULT_MED', 'SPEECH_PARAMS_FORCE') end
    taskGiveNpcMoney(amount, metadata)
    debug('[DEBUG] - Exchange Offer Accepted')
end

local function buildMarkedBillsMenu()
    local options = {}
    ClearPedTasks(entities.npc)
    PlayPedAmbientSpeechNative(entities.npc, 'GENERIC_HOWS_IT_GOING', 'SPEECH_PARAMS_FORCE')
    
    local playerInventory = lib.callback.await('vx_moneywash:getPlayerInventory', false)
    debug('[DEBUG] - Player Inventory:', json.encode(playerInventory))
    
    if not playerInventory then 
        debug('[DEBUG] - No inventory found')
        return Notify(_L('not_enough_money'), 'error') 
    end

    for _, item in pairs(playerInventory) do
        if item.name == Cfg.Options.Currency then
            if item.metadata and item.metadata.worth then
                table.insert(options, {
                    title = item.label,
                    description = _L('marked_worth', item.metadata.worth),
                    icon = 'fas fa-money-bill-wave',
                    iconColor = '#fa5252',
                    onSelect = function()
                        giveExchangeOffer(item.count, item.metadata)
                    end,
                })
            else
                table.insert(options, {
                    title = item.label or Cfg.Options.Currency,
                    description = _L('marked_worth', item.count),
                    icon = 'fas fa-money-bill-wave',
                    iconColor = '#fa5252',
                    onSelect = function()
                        giveExchangeOffer(item.count)
                    end,
                })
            end
            debug('[DEBUG] - Added item to menu:', item.name, item.count, json.encode(item.metadata or {}))
        end
    end

    if #options == 0 then
        debug('[DEBUG] - No valid items found')
        return Notify(_L('not_enough_money'), 'error')
    end

    lib.registerContext({
        id = 'moneywash_markedbills',
        title = _L('money_wash'),
        options = options
    })
    
    lib.showContext('moneywash_markedbills')
    debug('[DEBUG] - Marked Bills Menu Created with', #options, 'options')
end

local function openMoneyWashInput()
    local playerCash = lib.callback.await('vx_moneywash:getInventoryItem', false, Cfg.Options.Currency)
    debug('[DEBUG] - Player Cash:', json.encode(playerCash))
    
    if not playerCash then 
        debug('[DEBUG] - No cash found')
        return Notify(_L('not_enough_money'), 'error') 
    end

    local amount = playerCash.count or (playerCash.metadata and playerCash.metadata.worth)
    if not amount or amount < Cfg.Options.MinWash then
        debug('[DEBUG] - Not enough money:', amount)
        return Notify(_L('not_enough_money'), 'error')
    end

    local maxAmount = amount
    if maxAmount > Cfg.Options.MaxWash then 
        maxAmount = Cfg.Options.MaxWash 
    end

    debug('[DEBUG] - Opening input dialog with max amount:', maxAmount)
    
    PlayPedAmbientSpeechNative(entities.npc, 'GENERIC_HOWS_IT_GOING', 'SPEECH_PARAMS_FORCE')
    
    local input = lib.inputDialog(_L('money_wash'), {
        {
            type = 'number',
            label = _L('wash_amount'),
            description = string.format('Min: $%s | Max: $%s', Cfg.Options.MinWash, maxAmount),
            icon = 'dollar-sign',
            required = true,
            min = Cfg.Options.MinWash,
            max = maxAmount
        },
    })

    if not input or not input[1] then return end
    local amount = tonumber(input[1])
    
    if amount < Cfg.Options.MinWash then
        return Notify(_L('not_enough_money'), 'error')
    end
    
    if amount > maxAmount then
        return Notify(_L('not_enough_money'), 'error')
    end

    -- Get current tax rate to show in confirmation
    local taxRate = lib.callback.await('vx_moneywash:getTaxRate', false)
    local finalAmount = math.ceil(amount - (amount * taxRate / 100))

    local confirm = lib.alertDialog({
        header = _L('money_wash'),
        content = _L('taxed_offer', finalAmount, taxRate),
        centered = true,
        cancel = true
    })

    if confirm == 'confirm' then
        TriggerServerEvent('vx_moneywash:startWashingMoney', cache.serverId, amount)
    else
        PlayPedAmbientSpeechNative(entities.npc, 'GENERIC_INSULT_MED', 'SPEECH_PARAMS_FORCE')
    end
end

local function enterMoneyWash(door, coords)
    TaskAchieveHeading(cache.ped, door.w, 500)
    SetTimeout(500, function()
        if lib.progressCircle({
                duration = Cfg.Options.Teleporter.EnterTime,
                label = _L('entering_moneywash'),
                position = 'bottom',
                canCancel = true,
                anim = { dict = 'timetable@jimmy@doorknock@', clip = 'knockdoor_idle' },
                disable = { move = true, combat = true, }
            }) then
            DoScreenFadeOut(Cfg.Options.Teleporter.FadeTime)
            Wait(Cfg.Options.Teleporter.FadeTime + 50)
            StartPlayerTeleport(cache.playerId, coords.x, coords.y, coords.z, coords.w - 180, false, true, true)
            Wait(300)
            DoScreenFadeIn(math.floor(Cfg.Options.Teleporter.FadeTime / 2))
        end
    end)
end

local function exitMoneyWash(door, coords)
    TaskAchieveHeading(cache.ped, door.w, 500)
    SetTimeout(500, function()
        if lib.progressCircle({
                duration = Cfg.Options.Teleporter.ExitTime,
                label = _L('exiting_moneywash'),
                position = 'bottom',
                canCancel = true,
                anim = { dict = 'mp_common', clip = 'givetake1_a' },
                disable = { move = true, combat = true }
            }) then
            DoScreenFadeOut(Cfg.Options.Teleporter.FadeTime)
            Wait(Cfg.Options.Teleporter.FadeTime + 50)
            StartPlayerTeleport(cache.playerId, coords.x, coords.y, coords.z, coords.w - 180, false, true, true)
            Wait(300)
            DoScreenFadeIn(math.floor(Cfg.Options.Teleporter.FadeTime / 2))
        end
    end)
end

RegisterNetEvent('vx_moneywash:onConnect', function()
    if Cfg.Options.Blip.Enabled and not entities.blip then
        local location = Cfg.Options.Location
        if Cfg.Options.Teleporter.Enabled then location = Cfg.Options.Teleporter.Entrance.xyz end
        entities.blip = AddBlip(location, Cfg.Options.Blip)
        debug('[DEBUG] - Blip Created')
    end
    
    if Cfg.Options.Teleporter.Enabled then
        if Cfg.Server.Target == 'qb' then
            -- QB-Target format for teleporter
            exports['qb-target']:AddBoxZone("moneywash_entrance", 
                vector3(Cfg.Options.Teleporter.Entrance.x, Cfg.Options.Teleporter.Entrance.y, Cfg.Options.Teleporter.Entrance.z),
                1.0, 1.0, {
                    name = "moneywash_entrance",
                    heading = Cfg.Options.Teleporter.Entrance.w,
                    debugPoly = false,
                    minZ = Cfg.Options.Teleporter.Entrance.z - 1.0,
                    maxZ = Cfg.Options.Teleporter.Entrance.z + 1.0,
                }, {
                    options = {
                        {
                            type = "client",
                            event = "vx_moneywash:enterWash",
                            icon = 'fas fa-door-open',
                            label = _L('enter_moneywash'),
                        },
                    },
                    distance = 1.5
                })

            exports['qb-target']:AddBoxZone("moneywash_exit", 
                vector3(Cfg.Options.Teleporter.Exit.x, Cfg.Options.Teleporter.Exit.y, Cfg.Options.Teleporter.Exit.z),
                1.0, 1.0, {
                    name = "moneywash_exit",
                    heading = Cfg.Options.Teleporter.Exit.w,
                    debugPoly = false,
                    minZ = Cfg.Options.Teleporter.Exit.z - 1.0,
                    maxZ = Cfg.Options.Teleporter.Exit.z + 1.0,
                }, {
                    options = {
                        {
                            type = "client",
                            event = "vx_moneywash:exitWash",
                            icon = 'fas fa-door-open',
                            label = _L('exit_moneywash'),
                        },
                    },
                    distance = 1.5
                })
        else
            -- OX Target format for teleporter
            exports.ox_target:addBoxZone({
                coords = vector3(Cfg.Options.Teleporter.Entrance.x, Cfg.Options.Teleporter.Entrance.y, Cfg.Options.Teleporter.Entrance.z),
                size = vec3(1.0, 1.0, 2.0),
                rotation = Cfg.Options.Teleporter.Entrance.w,
                debug = false,
                options = {
                    {
                        name = 'enter_wash',
                        icon = 'fas fa-door-open',
                        label = _L('enter_moneywash'),
                        onSelect = function()
                            enterMoneyWash(Cfg.Options.Teleporter.Entrance, Cfg.Options.Teleporter.Exit)
                        end
                    }
                }
            })

            exports.ox_target:addBoxZone({
                coords = vector3(Cfg.Options.Teleporter.Exit.x, Cfg.Options.Teleporter.Exit.y, Cfg.Options.Teleporter.Exit.z),
                size = vec3(1.0, 1.0, 2.0),
                rotation = Cfg.Options.Teleporter.Exit.w,
                debug = false,
                options = {
                    {
                        name = 'exit_wash',
                        icon = 'fas fa-door-open',
                        label = _L('exit_moneywash'),
                        onSelect = function()
                            exitMoneyWash(Cfg.Options.Teleporter.Exit, Cfg.Options.Teleporter.Entrance)
                        end
                    }
                }
            })
        end
        
        debug('[DEBUG] - Teleporter Created')
    end
end)

-- Add these events for QB-Target teleporter
RegisterNetEvent('vx_moneywash:enterWash', function()
    enterMoneyWash(Cfg.Options.Teleporter.Entrance, Cfg.Options.Teleporter.Exit)
end)

RegisterNetEvent('vx_moneywash:exitWash', function()
    exitMoneyWash(Cfg.Options.Teleporter.Exit, Cfg.Options.Teleporter.Entrance)
end)

local locPoint = lib.points.new({ coords = Cfg.Options.Location, distance = 30 })

local function CreateNPC(model, coords, heading)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    local ped = CreatePed(4, hash, coords.x, coords.y, coords.z, heading, false, true)
    SetEntityHeading(ped, heading)
    SetModelAsNoLongerNeeded(hash)
    return ped
end

function locPoint:onEnter()
    entities.npc = CreateNPC(Cfg.Options.PedModel, Cfg.Options.Location, Cfg.Options.PedHeading)
    while not DoesEntityExist(entities.npc) do Wait(0) end
    
    SetEntityInvincible(entities.npc, true)
    FreezeEntityPosition(entities.npc, true)
    SetBlockingOfNonTemporaryEvents(entities.npc, true)
    
    TaskStartScenarioInPlace(entities.npc, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    
    -- Fix QB-Target options format
    if Cfg.Server.Target == 'qb' then
        exports['qb-target']:AddTargetEntity(entities.npc, {
            options = {
                {
                    type = "client",
                    event = "vx_moneywash:washMoney",
                    icon = 'fas fa-money-bill-wave',
                    label = _L('wash_money'),
                }
            },
            distance = 2.0
        })
    else
        -- OX Target format
        exports.ox_target:addLocalEntity(entities.npc, {
            {
                name = 'wash_money',
                icon = 'fas fa-money-bill-wave',
                label = _L('wash_money'),
                onSelect = function()
                    TriggerEvent('vx_moneywash:washMoney')
                end
            }
        })
    end
    
    debug('[DEBUG] - NPC Created')
end

function locPoint:onExit()
    for _, entity in pairs(entities) do
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
    RemoveTargetEntity(entities.npc)
    debug('[DEBUG] - NPC Removed')
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerEvent('vx_moneywash:onConnect')
end)

AddEventHandler('onResourceStart', function(resource)
    if (GetCurrentResourceName() == resource) then
        TriggerEvent('vx_moneywash:onConnect')
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if (GetCurrentResourceName() == resource) then
        if entities.blip and DoesBlipExist(entities.blip) then RemoveBlip(entities.blip) end
        for _, entity in pairs(entities) do
            if DoesEntityExist(entity) then DeleteEntity(entity) end
        end
    end
end)

RegisterNetEvent('vx_moneywash:washMoney', function()
    local onCooldown = lib.callback.await('vx_moneywash:getPlayerCooldown', false)
    if onCooldown then 
        Notify(_L('on_cooldown'), 'info') 
        return 
    end
    if Cfg.Options.Currency == 'markedbills' then 
        buildMarkedBillsMenu() 
        return 
    end
    openMoneyWashInput()
end)