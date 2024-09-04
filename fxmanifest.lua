fx_version 'cerulean'
use_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

description 'A marker management system for FiveM, allowing players to create, edit, and manage markers in-game. Includes support for localization and integration with the QBCore framework.'

author 'Murai Dev'

shared_scripts {
    '@ox_lib/init.lua', -- Initialize Ox Lib for locale and other shared functionality
}

client_scripts {
    'client.lua', -- Client-side script for marker management and user interface
}

server_scripts {
    'server.lua', -- Server-side script for marker management and data synchronization
}

files {
    'locales/*.json', -- Include all locale files in the locales directory
}

dependencies {
    'ox_lib', -- Dependency for localization and utility functions
    'qb-core' -- Dependency for core framework functions and integration
}
