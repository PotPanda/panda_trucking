fx_version 'cerulean'
game 'gta5'

author 'Panda Development'
description 'Panda Trucking Job with Wasabi CarLock Integration and XP System'
version '2.1.0'

-- Version Information
panda_trucking_version = '2.1.0'
panda_trucking_build = '20250719'
panda_trucking_author = 'PotPanda Development'

-- Dependencies
dependencies {
    'qb-core',
    'wasabi_carlock' -- Optional
}

-- Shared scripts
shared_scripts {
    'config.lua',
    'version.lua'
}

-- Client scripts
client_scripts {
    'client.lua'
}

-- Server scripts
server_scripts {
    '@oxmysql/lib/MySQL.lua', -- or '@mysql-async/lib/MySQL.lua' depending on your setup
    'server.lua'
}

lua54 'yes'