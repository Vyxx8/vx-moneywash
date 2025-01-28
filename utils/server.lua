QBCore = exports['qb-core']:GetCoreObject()

-- Inventory Handler
local Inventory = {
    ['qb'] = {
        getItem = function(source, item)
            local Player = QBCore.Functions.GetPlayer(source)
            if not Player then return false end
            local item = Player.Functions.GetItemByName(item)
            
            if item and item.name == 'markedbills' and item.info then
                item.metadata = item.info  
                item.metadata.worth = item.info.worth
            end
            
            debug('[DEBUG] - QB GetItem:', json.encode(item or 'no item found'))
            return item
        end,
        
        removeItem = function(source, item, amount, metadata)
            local Player = QBCore.Functions.GetPlayer(source)
            if not Player then return false end
            
            local info = metadata
            if item == 'markedbills' and metadata and metadata.worth then
                info = {
                    worth = metadata.worth
                }
            end
            
            debug('[DEBUG] - QB RemoveItem:', item, amount, json.encode(info or {}))
            return Player.Functions.RemoveItem(item, amount, false, info)
        end,
        
        addItem = function(source, item, amount, metadata)
            local Player = QBCore.Functions.GetPlayer(source)
            if not Player then return false end
            
            local info = metadata
            if item == 'markedbills' and metadata and metadata.worth then
                info = {
                    worth = metadata.worth
                }
            end
            
            debug('[DEBUG] - QB AddItem:', item, amount, json.encode(info or {}))
            return Player.Functions.AddItem(item, amount, false, info)
        end,
        
        getInventory = function(source)
            local Player = QBCore.Functions.GetPlayer(source)
            if not Player then return {} end
        
            local items = Player.PlayerData.items
            if items then
                for _, item in pairs(items) do
                    if item.name == 'markedbills' and item.info then
                        item.metadata = item.info
                        item.metadata.worth = item.info.worth
                    end
                end
            end
            
            debug('[DEBUG] - QB GetInventory:', json.encode(items or {}))
            return items
        end
    },
    
    ['ox'] = {
        getItem = function(source, item)
            return exports.ox_inventory:GetItem(source, item)
        end,
        
        removeItem = function(source, item, amount, metadata)
            return exports.ox_inventory:RemoveItem(source, item, amount, metadata)
        end,
        
        addItem = function(source, item, amount, metadata)
            return exports.ox_inventory:AddItem(source, item, amount, metadata)
        end,
        
        getInventory = function(source)
            return exports.ox_inventory:GetInventory(source)
        end
    },
    
    ['qs'] = {
        getItem = function(source, item)
            return exports['qs-inventory']:GetItem(source, item)
        end,
        
        removeItem = function(source, item, amount, metadata)
            return exports['qs-inventory']:RemoveItem(source, item, amount, metadata)
        end,
        
        addItem = function(source, item, amount, metadata)
            return exports['qs-inventory']:AddItem(source, item, amount, metadata)
        end,
        
        getInventory = function(source)
            return exports['qs-inventory']:GetInventory(source)
        end
    }
}

local function GetItem(source, item)
    return Inventory[Cfg.Server.Inventory].getItem(source, item)
end

local function RemoveItem(source, item, amount, metadata)
    return Inventory[Cfg.Server.Inventory].removeItem(source, item, amount, metadata)
end

local function AddItem(source, item, amount, metadata)
    return Inventory[Cfg.Server.Inventory].addItem(source, item, amount, metadata)
end

local function GetInventory(source)
    return Inventory[Cfg.Server.Inventory].getInventory(source)
end

local function AddMoney(source, amount)
    if Cfg.Server.Inventory == 'ox' then
        return exports.ox_inventory:AddItem(source, 'money', amount)
    else
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        return Player.Functions.AddMoney('cash', amount)
    end
end

lib.callback.register('vx_moneywash:getInventoryItem', function(source, item)
    return GetItem(source, item)
end)

lib.callback.register('vx_moneywash:getPlayerInventory', function(source)
    return GetInventory(source)
end)

function SendWebhook(src, event, ...)
    if not Cfg.Webhook.Enabled then return end
    local name = '' 
    if src > 0 then 
        name = GetPlayerName(src) 
    end
    
    local identifier = ''
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        identifier = Player.PlayerData.citizenid
    end
    
    PerformHttpRequest(Cfg.Webhook.Url, function(err, text, headers)
    end, 'POST', json.encode({
        username = 'Resource Logs',
        avatar_url = 'https://i.ibb.co/z700S5H/square.png',
        embeds = {
            {
                color = 0x2C1B47,
                title = event,
                author = {
                    name = GetCurrentResourceName(),
                    icon_url = 'https://i.ibb.co/z700S5H/square.png',
                    url = 'https://discord.gg/r-scripts'
                },
                thumbnail = {
                    url = 'https://i.ibb.co/z700S5H/square.png'
                },
                fields = {
                    { name = _L('player_id'),  value = src,        inline = true },
                    { name = _L('username'),   value = name,       inline = true },
                    { name = _L('identifier'), value = identifier, inline = false },
                    { name = _L('description'), value = _L('description_text', name, ...), inline = false},
                },
                timestamp = os.date('!%Y-%m-%dT%H:%M:%S'),
                footer = {
                    text = 'r_scripts',
                    icon_url = 'https://i.ibb.co/z700S5H/square.png',
                },
            }
        }
    }), { ['Content-Type'] = 'application/json' })
end

local function checkVersion()
    if not Cfg.Server.VersionCheck then return end
    local url = 'https://api.github.com/repos/Vyxx8/vx-moneywash/releases'
    local current = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
    PerformHttpRequest(url, function(err, text, headers)
        if err == 200 then
            local data = json.decode(text)
            local latest = data.tag_name
            if latest ~= current then
                print('[^3WARNING^0] '.. _L('update', GetCurrentResourceName()))
                print('[^3WARNING^0] https://github.com/Vyxx8/vx-moneywash/releases ^0')
            end
        end
    end, 'GET', '', { ['Content-Type'] = 'application/json' })
    SetTimeout(3600000, checkVersion)
end

function debug(...)
    if Cfg.Server.Debug then
        local args = {...}
        local text = ''
        for i, v in ipairs(args) do
            text = text .. tostring(v) .. ' '
        end
        print('^3[vx_moneywash:DEBUG]^0 ' .. text)
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        print('------------------------------')
        print(_L('version', resourceName, GetResourceMetadata(resourceName, 'version', 0)))
        if Cfg.Server.Debug then
            print('^3[DEBUG MODE ENABLED]^0')
            print('^3[INVENTORY]^0: ' .. Cfg.Server.Inventory)
        end
        print('------------------------------')
        checkVersion()
    end
end)