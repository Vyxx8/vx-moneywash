QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerEvent('vx_moneywash:onConnect')
end)

function debug(...)
    if Cfg.Server.Debug then
        local args = {...}
        local text = ''
        for i, v in ipairs(args) do
            text = text .. tostring(v) .. ' '
        end
        print('^3[r_moneywash:DEBUG]^0 ' .. text)
    end
end

if Cfg.Server.Debug then
    CreateThread(function()
        while true do
            Wait(1000)
            local ped = cache.ped
            local coords = GetEntityCoords(ped)
            DrawText3D(coords.x, coords.y, coords.z + 1.0, string.format(
                'Coords: vector4(%s, %s, %s, %s)', 
                math.round(coords.x, 4), 
                math.round(coords.y, 4), 
                math.round(coords.z, 4),
                math.round(GetEntityHeading(ped), 4)
            ))
        end
    end)
end

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function math.round(num, decimals)
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end