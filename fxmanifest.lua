---@diagnostic disable: undefined-global
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vx-moneywash'
description 'Phantoms money washing script'
author 'ProneZ, Vyxx'
version '1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'utils/shared.lua',
    'locales/*.lua',
    'config.lua',
}

server_scripts {
    'utils/server.lua',
    'src/server/*.lua',
}

client_scripts {
    'utils/client.lua',
    'src/client/*.lua',
}


dependencies {
    'ox_lib',
    'qb-core'
}