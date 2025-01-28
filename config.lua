Cfg = {}

Cfg.Server = {
    Language = 'en', -- 'es', 'fr'
    Debug = false,
    VersionCheck = false,
    Inventory = 'qs', -- 'qb', 'ox', 'qs' (Choose your inventory system)
    Target = 'qb',    -- 'qb', 'ox' (Choose your target system)
}

Cfg.Options = {
    Blip = {
        Enabled = false,                         -- Blip visibility (true: enabled, false: disabled)
        Sprite = 500,                           -- Blip sprite (https://docs.fivem.net/docs/game-references/blips/)
        Scale = 0.8,                            -- Blip scale (0.0 - 1.0)
        Color = 1,                              -- Blip color
        Label = 'Money Wash',                   -- Blip label
    },
    Location = vec3(1116.79, -3195.49, -41.40), -- Money wash location. (vector4)
    PedModel = 'a_m_m_og_boss_01',              -- Ped model (https://docs.fivem.net/docs/game-references/ped-models/)
    PedHeading = 265.89,                        -- Ped heading (0.0 - 360.0)

    Currency = 'markedbills',                   -- Currency item (supports items or qb-core 'markedbills')
    TaxRate = 10,                               -- Tax rate. (0 - 100) if DynamicTax is enabled, this value will be ignored.
    DynamicTax = false,                          -- Changing tax rate (true: enabled, false: disabled)
    DynamicTimer = 60,                          -- Tax rate change timer (minutes)
    DynamicRange = { 15, 35 },                  -- Range for changing tax rate { min, max }
    WashTime = 10,                              -- Wash time (seconds)
    MinWash = 1,                                -- Minimum amount of money that can be washed, does not apply when Currency = 'markedbills'
    MaxWash = 10000,                            -- Maximum amount of money that can be washed, does not apply when Currency = 'markedbills'
    Cooldown = 30,                              -- Player cooldown time (minutes, false: disabled)

    Teleporter = {
        Enabled = true,                                       -- Teleporter (true: enabled, false: disabled)
        Entrance = vec4(1841.55, 3928.56, 33.74, 14.6),    -- Teleporter entrance (vector4)
        Exit = vec4(1138.0793, -3199.1890, -39.6656, 180.42), -- Teleporter exit (vector4)
        EnterTime = 5500,
        ExitTime = 5500,                                      -- (1000 = 1 second)
        FadeTime = 750,                                        -- Screen fade time in ms
    },
}

Cfg.Webhook = {
    Enabled = false,            -- Webhook Logs (true: enabled, false: disabled)
    Url = 'YOUR_WEBHOOK_HERE', -- Webhook URL
}
