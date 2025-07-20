-- Configuration file for Panda Trucking Job
-- config.lua

Config = {}

-- Version Information
Config.Version = '2.1.0'
Config.Debug = false

-- Job Configuration
Config.Job = {
    name = "trucker",
    label = "Trucker",
    grades = {
        [0] = { name = "driver", label = "Driver", payment = 50, xpRequired = 0 },
        [1] = { name = "experienced", label = "Experienced Driver", payment = 75, xpRequired = 250 },
        [2] = { name = "veteran", label = "Veteran Driver", payment = 100, xpRequired = 750 },
        [3] = { name = "senior", label = "Senior Driver", payment = 125, xpRequired = 1500 },
        [4] = { name = "supervisor", label = "Supervisor", payment = 150, xpRequired = 3000 }
    }
}

-- Location Configuration
Config.Locations = {
    JobCenter = {
        coords = vector3(153.93, -3211.93, 5.91), -- Docks area
        heading = 271.42
    },
    
    TruckSpawn = {
        coords = vector3(164.12, -3204.12, 5.91),
        heading = 271.42
    },
    
    TrailerSpawn = {
        coords = vector3(174.23, -3204.23, 5.91),
        heading = 271.42
    }
}

-- Vehicle Configuration
Config.Vehicles = {
    trucks = {
        {model = "phantom", label = "Phantom"},
        {model = "hauler", label = "Hauler"},
        {model = "packer", label = "Packer"},
        {model = "phantom2", label = "Phantom Custom"}
    },
    trailers = {
        {model = "trailers", label = "Box Trailer"},
        {model = "trailers2", label = "Log Trailer"},
        {model = "trailers3", label = "Container Trailer"},
        {model = "trailers4", label = "Empty Trailer"}
    }
}

-- Delivery Locations
Config.DeliveryLocations = {
    {
        name = "Los Santos Port",
        coords = vector3(-330.39, -2471.24, 7.30),
        payment = {min = 500, max = 800},
        description = "Deliver cargo to the busy Los Santos port"
    },
    {
        name = "Sandy Shores Warehouse",
        coords = vector3(1994.85, 3779.85, 32.18),
        payment = {min = 600, max = 900},
        description = "Long haul to Sandy Shores industrial area"
    },
    {
        name = "Paleto Bay Industrial",
        coords = vector3(-378.15, 6062.15, 31.50),
        payment = {min = 700, max = 1000},
        description = "Remote delivery to Paleto Bay"
    },
    {
        name = "LSIA Cargo Terminal",
        coords = vector3(-1027.84, -2747.84, 13.76),
        payment = {min = 450, max = 750},
        description = "Airport cargo delivery"
    },
    {
        name = "Davis Industrial",
        coords = vector3(33.85, -2672.85, 6.03),
        payment = {min = 400, max = 650},
        description = "Local Davis area delivery"
    },
    {
        name = "El Burro Heights Storage",
        coords = vector3(1201.23, -3253.45, 5.53),
        payment = {min = 550, max = 750},
        description = "Storage facility in El Burro Heights"
    }
}

-- Experience and Leveling System
Config.Experience = {
    enabled = true, -- Enable experience system
    xpPerDelivery = {min = 15, max = 35}, -- XP gained per delivery
    bonusXpLongDistance = {min = 10, max = 20}, -- Bonus XP for long deliveries (>5km)
    bonusXpPerfectDelivery = 15, -- Bonus XP for deliveries without damage
    xpRequirements = { -- XP required for each grade
        [0] = 0,      -- Driver
        [1] = 250,    -- Experienced Driver
        [2] = 750,    -- Veteran Driver  
        [3] = 1500,   -- Senior Driver
        [4] = 3000    -- Supervisor
    },
    -- XP multipliers based on delivery distance
    distanceMultipliers = {
        {distance = 1000, multiplier = 1.0}, -- Under 1km
        {distance = 3000, multiplier = 1.2}, -- 1-3km
        {distance = 5000, multiplier = 1.5}, -- 3-5km
        {distance = 999999, multiplier = 2.0} -- Over 5km
    }
}

-- Wasabi CarLock Integration Settings
Config.CarLock = {
    enabled = true, -- Set to false to disable Wasabi CarLock integration
    autoLockDistance = 50.0, -- Distance to auto-lock vehicle
    autoUnlockDistance = 10.0, -- Distance to auto-unlock vehicle
    lockDelay = 5000, -- Delay in ms before auto-locking
}

-- Fuel Integration (LegacyFuel, ps-fuel, etc.)
Config.Fuel = {
    enabled = true, -- Set to false to disable fuel integration
    startingFuel = 100.0, -- Starting fuel percentage for spawned trucks
    system = "LegacyFuel" -- Options: "LegacyFuel", "ps-fuel", "ox_fuel"
}

-- Notification Settings
Config.Notifications = {
    type = "qb", -- Options: "qb", "okokNotify", "mythic_notify"
    duration = 5000 -- Duration in milliseconds
}

-- Print configuration on load
if Config.Debug then
    print('^2[PANDA TRUCKING CONFIG]^7 Configuration loaded successfully!')
    print('^2[PANDA TRUCKING CONFIG]^7 Version: ' .. Config.Version)
    print('^2[PANDA TRUCKING CONFIG]^7 XP System: ' .. (Config.Experience.enabled and 'Enabled' or 'Disabled'))
    print('^2[PANDA TRUCKING CONFIG]^7 CarLock Integration: ' .. (Config.CarLock.enabled and 'Enabled' or 'Disabled'))
end