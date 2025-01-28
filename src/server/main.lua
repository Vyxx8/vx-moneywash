local cooldowns = {}
local currentTaxRate = Cfg.Options.TaxRate

local function setPlayerCooldown(source)
    if not Cfg.Options.Cooldown then return end
    local identifier = GetPlayerIdentifier(source)
    cooldowns[identifier] = true
    SetTimeout(Cfg.Options.Cooldown * 60000, function()
        cooldowns[identifier] = false
    end)
end

local function givePlayerWashedMoney(source, amount)
    local taxRate = currentTaxRate
    local finalAmount = math.ceil(amount - (amount * taxRate / 100))
    
    if Cfg.Server.Inventory == 'ox' then
        exports.ox_inventory:AddItem(source, 'money', finalAmount)
    else
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            Player.Functions.AddMoney('cash', finalAmount)
        end
    end
    
    SendWebhook(source, _L('money_wash'), amount, finalAmount, taxRate)
    TriggerClientEvent('QBCore:Notify', source, _L('washed_money', amount, finalAmount, taxRate), 'success')
end

RegisterNetEvent('vx_moneywash:startWashingMoney', function(src, amount, metadata)
    local src = src or source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local player = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(player)
    local identifier = Player.PlayerData.citizenid
    local distance = #(Cfg.Options.Location - playerCoords)
    
    if distance > 5.0 then 
        DropPlayer(src, _L('cheater')) 
        return 
    end
    
    if cooldowns[identifier] then 
        DropPlayer(src, _L('cheater')) 
        return 
    end

    if Cfg.Options.Currency == 'markedbills' then
        local markedbills = Player.Functions.GetItemByName('markedbills')
        if not markedbills then return end
        
        local removed = Player.Functions.RemoveItem('markedbills', 1, markedbills.slot)
        if not removed then 
            debug('[DEBUG] - Error removing markedbills from player:', GetPlayerName(src)) 
            return 
        end
        
        setPlayerCooldown(src)
        local washAmount = markedbills.info and markedbills.info.worth or amount
        givePlayerWashedMoney(src, washAmount)
        debug('[DEBUG] - Markedbills washed successfully for player:', GetPlayerName(src), 'Amount:', washAmount)
        return
    end

    local removed = Player.Functions.RemoveItem(Cfg.Options.Currency, amount, nil, nil, true)
    if not removed then 
        debug('[DEBUG] - Error removing currency from player:', GetPlayerName(src)) 
        return 
    end

    setPlayerCooldown(src)
    givePlayerWashedMoney(src, amount)
    debug('[DEBUG] - Money washed successfully for player:', GetPlayerName(src), 'Amount:', amount)
end)

lib.callback.register('vx_moneywash:getPlayerCooldown', function(source)
    if not Cfg.Options.Cooldown then return false end
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return true end
    local identifier = Player.PlayerData.citizenid
    return cooldowns[identifier] or false
end)

lib.callback.register('vx_moneywash:getTaxRate', function()
    return currentTaxRate
end)

if Cfg.Options.DynamicTax then
    CreateThread(function()
        while true do
            Wait(Cfg.Options.DynamicTimer * 60000)
            currentTaxRate = math.random(Cfg.Options.DynamicRange[1], Cfg.Options.DynamicRange[2])
            debug('[DEBUG] - Tax Rate Updated:', currentTaxRate)
        end
    end)
end