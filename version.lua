-- Panda Trucking Version System
-- version.lua

PandaTrucking = {}
PandaTrucking.Version = {
    current = '2.1.0',
    build = '20250719',
    author = 'PotPanda Development',
    name = 'Panda Trucking Job System',
    description = 'Advanced trucking job with XP system (No Tablet Version)'
}

-- Version checking function
function PandaTrucking.Version.Print()
    print('^0[^2PANDA TRUCKING^0] ^7========================^0')
    print('^0[^2PANDA TRUCKING^0] ^3' .. PandaTrucking.Version.name .. '^0')
    print('^0[^2PANDA TRUCKING^0] ^7Version: ^2' .. PandaTrucking.Version.current .. '^0')
    print('^0[^2PANDA TRUCKING^0] ^7Build: ^2' .. PandaTrucking.Version.build .. '^0')
    print('^0[^2PANDA TRUCKING^0] ^7Author: ^2' .. PandaTrucking.Version.author .. '^0')
    print('^0[^2PANDA TRUCKING^0] ^7Description: ^3' .. PandaTrucking.Version.description .. '^0')
    print('^0[^2PANDA TRUCKING^0] ^7========================^0')
end

-- Check for updates (placeholder function)
function PandaTrucking.Version.CheckForUpdates()
    print('^0[^2PANDA TRUCKING^0] ^7Checking for updates...^0')
    Citizen.SetTimeout(2000, function()
        print('^0[^2PANDA TRUCKING^0] ^2No updates available. You are running the latest version.^0')
    end)
end

-- Features list
PandaTrucking.Features = {
    'XP-Based Progression System',
    'Wasabi CarLock Security System',
    'Real-time Statistics Tracking',
    'Admin Management Tools',
    'Grade-based Payment System',
    'Dynamic Delivery Routes',
    'In-Game Job Interface'
}

function PandaTrucking.Version.PrintFeatures()
    print('^0[^2PANDA TRUCKING^0] ^7Loaded Features:^0')
    for i, feature in ipairs(PandaTrucking.Features) do
        print('^0[^2PANDA TRUCKING^0] ^7  • ^3' .. feature .. '^0')
    end
end