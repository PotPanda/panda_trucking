-- Panda Trucking Job Script for QBCore with Wasabi CarLock Integration
-- Created by: Panda Development
-- Version: 2.1.0 (No Tablet Version)

local QBCore = exports['qb-core']:GetCoreObject()
local currentTruck = nil
local currentTrailer = nil
local currentJob = nil
local jobBlip = nil
local truckBlip = nil
local deliveryBlip = nil
local isOnJob = false
local jobStarted = false
local startCoords = nil
local startTime = nil
local vehicleDamage = 0
local playerXP = 0
local playerGrade = 0

-- Utility Functions
local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local pX, pY, pZ = table.unpack(GetGameplayCamCoords())
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

local function ShowNotification(msg, type)
    if type == "success" then
        QBCore.Functions.Notify(msg, 'success', 5000)
    elseif type == "error" then
        QBCore.Functions.Notify(msg, 'error', 5000)
    elseif type == "info" then
        QBCore.Functions.Notify(msg, 'primary', 5000)
    else
        QBCore.Functions.Notify(msg, 'primary', 5000)
    end
end

local function GetRandomDeliveryLocation()
    return Config.DeliveryLocations[math.random(1, #Config.DeliveryLocations)]
end

-- XP System Functions
local function UpdatePlayerXP()
    QBCore.Functions.TriggerCallback('panda-trucking:server:getPlayerXP', function(data)
        if data then
            playerXP = data.xp or 0
            playerGrade = data.grade or 0
        end
    end)
end

local function CalculateDistance(coord1, coord2)
    return #(coord1 - coord2)
end

local function GetXPMultiplier(distance)
    for _, multiplier in ipairs(Config.Experience.distanceMultipliers) do
        if distance <= multiplier.distance then
            return multiplier.multiplier
        end
    end
    return 1.0
end

local function CalculateXPGain(deliveryData)
    local baseXP = math.random(Config.Experience.xpPerDelivery.min, Config.Experience.xpPerDelivery.max)
    local distance = deliveryData.distance or 0
    local damage = deliveryData.damage or 0
    local timeTaken = deliveryData.timeTaken or 0
    
    -- Distance multiplier
    local distanceMultiplier = GetXPMultiplier(distance)
    local xpGain = math.floor(baseXP * distanceMultiplier)
    
    -- Long distance bonus
    if distance > 5000 then
        local bonusXP = math.random(Config.Experience.bonusXpLongDistance.min, Config.Experience.bonusXpLongDistance.max)
        xpGain = xpGain + bonusXP
    end
    
    -- Perfect delivery bonus (no damage)
    if damage < 100 then
        xpGain = xpGain + Config.Experience.bonusXpPerfectDelivery
    end
    
    -- Time efficiency bonus (if delivered quickly)
    if timeTaken > 0 and timeTaken < 300 then -- Under 5 minutes
        xpGain = xpGain + 10
    end
    
    return xpGain
end

local function CheckForGradeUp(newXP)
    local currentGrade = playerGrade
    local nextGrade = currentGrade + 1
    
    if Config.Job.grades[nextGrade] and newXP >= Config.Job.grades[nextGrade].xpRequired then
        return nextGrade
    end
    
    return currentGrade
end

local function ShowXPProgress()
    local currentGrade = playerGrade
    local nextGrade = currentGrade + 1
    local currentXP = playerXP
    
    if Config.Job.grades[nextGrade] then
        local xpNeeded = Config.Job.grades[nextGrade].xpRequired
        local xpProgress = currentXP
        local xpRemaining = xpNeeded - currentXP
        
        local progressText = string.format("XP: %d | Grade: %s | Next: %d XP remaining", 
            currentXP, Config.Job.grades[currentGrade].label, xpRemaining)
        
        ShowNotification(progressText, "info")
    else
        ShowNotification(string.format("XP: %d | Grade: %s (MAX LEVEL)", currentXP, Config.Job.grades[currentGrade].label), "success")
    end
end

-- Wasabi CarLock Integration Functions
local function LockVehicle(vehicle)
    if vehicle and DoesEntityExist(vehicle) then
        if Config.CarLock.enabled then
            -- Check if wasabi_carlock is available and use proper export
            local success, error = pcall(function()
                if GetResourceState('wasabi_carlock') == 'started' then
                    exports.wasabi_carlock:ToggleLock(vehicle)
                    ShowNotification("Vehicle locked securely", "info")
                    return true
                end
                return false
            end)
            
            if not success then
                -- Fallback to native lock
                SetVehicleDoorsLocked(vehicle, 2)
                ShowNotification("Vehicle locked", "info")
            end
        else
            -- Use native lock when CarLock is disabled
            SetVehicleDoorsLocked(vehicle, 2)
            ShowNotification("Vehicle locked", "info")
        end
    end
end

local function UnlockVehicle(vehicle)
    if vehicle and DoesEntityExist(vehicle) then
        if Config.CarLock.enabled then
            -- Check if wasabi_carlock is available
            local success, error = pcall(function()
                if GetResourceState('wasabi_carlock') == 'started' then
                    -- Check if vehicle is locked first
                    local lockStatus = GetVehicleDoorLockStatus(vehicle)
                    if lockStatus == 2 or lockStatus == 3 or lockStatus == 4 then
                        exports.wasabi_carlock:ToggleLock(vehicle)
                    end
                    ShowNotification("Vehicle unlocked", "info")
                    return true
                end
                return false
            end)
            
            if not success then
                -- Fallback to native unlock
                SetVehicleDoorsLocked(vehicle, 1)
                ShowNotification("Vehicle unlocked", "info")
            end
        else
            -- Use native unlock when CarLock is disabled
            SetVehicleDoorsLocked(vehicle, 1)
            ShowNotification("Vehicle unlocked", "info")
        end
    end
end

local function SetVehicleOwnership(vehicle, player)
    if vehicle and DoesEntityExist(vehicle) and Config.CarLock.enabled then
        local success, error = pcall(function()
            if GetResourceState('wasabi_carlock') == 'started' then
                -- Wasabi CarLock automatically handles ownership when using ToggleLock
                -- No separate SetVehicleOwner export needed
                return true
            end
            return false
        end)
        
        if success then
            if Config.Debug then
                print('^2[PANDA TRUCKING]^7 Vehicle ownership set via Wasabi CarLock')
            end
        else
            if Config.Debug then
                print('^3[PANDA TRUCKING]^7 Wasabi CarLock not available, using native locking')
            end
        end
    end
end

-- Job Functions
local function CreateJobBlip()
    if jobBlip then
        RemoveBlip(jobBlip)
    end
    
    jobBlip = AddBlipForCoord(Config.Locations.JobCenter.coords.x, Config.Locations.JobCenter.coords.y, Config.Locations.JobCenter.coords.z)
    SetBlipSprite(jobBlip, 477)
    SetBlipDisplay(jobBlip, 4)
    SetBlipScale(jobBlip, 0.8)
    SetBlipColour(jobBlip, 5)
    SetBlipAsShortRange(jobBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Panda Trucking Job")
    EndTextCommandSetBlipName(jobBlip)
end

local function SpawnTruck()
    local playerPed = PlayerPedId()
    local truckModel = Config.Vehicles.trucks[math.random(1, #Config.Vehicles.trucks)].model
    
    QBCore.Functions.LoadModel(truckModel)
    
    currentTruck = CreateVehicle(truckModel, Config.Locations.TruckSpawn.coords.x, Config.Locations.TruckSpawn.coords.y, Config.Locations.TruckSpawn.coords.z, Config.Locations.TruckSpawn.heading, true, false)
    SetEntityAsMissionEntity(currentTruck, true, true)
    SetVehicleOnGroundProperly(currentTruck)
    SetVehicleEngineOn(currentTruck, true, true, false)
    SetVehicleNumberPlateText(currentTruck, "PANDA" .. math.random(10, 99))
    
    -- Set fuel to full
    if Config.Fuel.enabled then
        local success, error = pcall(function()
            if GetResourceState('LegacyFuel') == 'started' and Config.Fuel.system == "LegacyFuel" then
                exports['LegacyFuel']:SetFuel(currentTruck, Config.Fuel.startingFuel)
            elseif GetResourceState('ps-fuel') == 'started' and Config.Fuel.system == "ps-fuel" then
                exports['ps-fuel']:SetFuel(currentTruck, Config.Fuel.startingFuel)
            elseif GetResourceState('ox_fuel') == 'started' and Config.Fuel.system == "ox_fuel" then
                Entity(currentTruck).state.fuel = Config.Fuel.startingFuel
            end
        end)
        
        if not success and Config.Debug then
            print('^3[PANDA TRUCKING]^7 Fuel system not available or error setting fuel')
        end
    end
    
    -- Set vehicle ownership using corrected function
    local playerId = GetPlayerServerId(PlayerId())
    SetVehicleOwnership(currentTruck, playerId)
    
    -- Unlock vehicle initially
    UnlockVehicle(currentTruck)
    
    -- Create truck blip
    if truckBlip then
        RemoveBlip(truckBlip)
    end
    truckBlip = AddBlipForEntity(currentTruck)
    SetBlipSprite(truckBlip, 477)
    SetBlipColour(truckBlip, 3)
    SetBlipScale(truckBlip, 0.7)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Your Panda Truck")
    EndTextCommandSetBlipName(truckBlip)
    
    ShowNotification("Your truck has been spawned. Get in to start working!", "success")
end

local function SpawnTrailer()
    local trailerModel = Config.Vehicles.trailers[math.random(1, #Config.Vehicles.trailers)].model
    
    QBCore.Functions.LoadModel(trailerModel)
    
    currentTrailer = CreateVehicle(trailerModel, Config.Locations.TrailerSpawn.coords.x, Config.Locations.TrailerSpawn.coords.y, Config.Locations.TrailerSpawn.coords.z, Config.Locations.TrailerSpawn.heading, true, false)
    SetEntityAsMissionEntity(currentTrailer, true, true)
    SetVehicleOnGroundProperly(currentTrailer)
    
    ShowNotification("Trailer spawned! Attach it to your truck to begin delivery.", "success")
end

local function StartDeliveryJob()
    currentJob = GetRandomDeliveryLocation()
    startCoords = GetEntityCoords(PlayerPedId())
    startTime = GetGameTimer()
    vehicleDamage = 0
    
    -- Store initial vehicle health for damage calculation
    if currentTruck then
        vehicleDamage = 1000 - GetVehicleEngineHealth(currentTruck)
    end
    
    -- Create delivery blip
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
    end
    
    deliveryBlip = AddBlipForCoord(currentJob.coords.x, currentJob.coords.y, currentJob.coords.z)
    SetBlipSprite(deliveryBlip, 501)
    SetBlipDisplay(deliveryBlip, 4)
    SetBlipScale(deliveryBlip, 0.8)
    SetBlipColour(deliveryBlip, 2)
    SetBlipRoute(deliveryBlip, true)
    SetBlipRouteColour(deliveryBlip, 2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("🚛 Delivery: " .. currentJob.name)
    EndTextCommandSetBlipName(deliveryBlip)
    
    isOnJob = true
    jobStarted = true
    ShowNotification("🚛 Delivery job started! Head to: " .. currentJob.name, "success")
    ShowNotification("💰 Payment: $" .. currentJob.payment.min .. " - $" .. currentJob.payment.max, "info")
end

local function CompleteDelivery()
    if not currentJob then return end
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    local jobGrade = PlayerData.job.grade.level
    local basePayment = math.random(currentJob.payment.min, currentJob.payment.max)
    local gradeMultiplier = Config.Job.grades[jobGrade].payment / 50 -- Base multiplier
    local finalPayment = math.floor(basePayment * gradeMultiplier)
    
    -- Calculate delivery data for XP
    local endTime = GetGameTimer()
    local timeTaken = (endTime - startTime) / 1000 -- Convert to seconds
    local distance = CalculateDistance(startCoords, currentJob.coords)
    local finalVehicleDamage = currentTruck and (1000 - GetVehicleEngineHealth(currentTruck)) or 0
    local totalDamage = finalVehicleDamage - vehicleDamage
    
    local deliveryData = {
        distance = distance,
        timeTaken = timeTaken,
        damage = totalDamage,
        location = currentJob.name
    }
    
    -- Calculate XP if system is enabled
    local xpGained = 0
    if Config.Experience.enabled then
        xpGained = CalculateXPGain(deliveryData)
    end
    
    -- Send to server for processing
    TriggerServerEvent('panda-trucking:server:completeDelivery', {
        payment = finalPayment,
        xp = xpGained,
        deliveryData = deliveryData
    })
    
    -- Clean up blips
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
    
    -- Lock vehicle after delivery for security
    if currentTruck then
        LockVehicle(currentTruck)
        Citizen.Wait(2000) -- Wait 2 seconds then unlock
        UnlockVehicle(currentTruck)
    end
    
    currentJob = nil
    isOnJob = false
    
    ShowNotification("✅ Delivery completed! Return to base for another job.", "success")
end

local function EndJob()
    -- Clean up vehicles
    if currentTruck and DoesEntityExist(currentTruck) then
        DeleteEntity(currentTruck)
        currentTruck = nil
    end
    
    if currentTrailer and DoesEntityExist(currentTrailer) then
        DeleteEntity(currentTrailer)
        currentTrailer = nil
    end
    
    -- Clean up blips
    if truckBlip then
        RemoveBlip(truckBlip)
        truckBlip = nil
    end
    
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
    
    currentJob = nil
    isOnJob = false
    jobStarted = false
    
    ShowNotification("👋 Job ended. Thanks for working with Panda Trucking!", "info")
end

-- Enhanced Job Menu
local function ShowJobMenu()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local gradeInfo = Config.Job.grades[PlayerData.job.grade.level]
    
    local menuOptions = {
        {
            header = "🐼 Panda Trucking",
            isMenuHeader = true,
        },
        {
            header = "📊 Your Info",
            txt = "Grade: " .. gradeInfo.label .. " | XP: " .. playerXP .. " | Deliveries Completed",
            isMenuHeader = true,
        }
    }
    
    if not jobStarted then
        table.insert(menuOptions, {
            header = "🚛 Start Trucking Job",
            txt = "Spawn truck and trailer to begin working",
            params = {
                event = "panda-trucking:client:startJob"
            }
        })
    else
        table.insert(menuOptions, {
            header = "🛑 End Job",
            txt = "Return vehicles and end your shift",
            params = {
                event = "panda-trucking:client:endJob"
            }
        })
        
        if currentTruck and isOnJob then
            table.insert(menuOptions, {
                header = "📍 Current Delivery",
                txt = "Destination: " .. (currentJob and currentJob.name or "None"),
                isMenuHeader = true,
            })
        end
    end
    
    table.insert(menuOptions, {
        header = "📈 Check XP Progress",
        txt = "View your experience and progression",
        params = {
            event = "panda-trucking:client:checkXP"
        }
    })
    
    table.insert(menuOptions, {
        header = "❌ Close Menu",
        params = {
            event = "qb-menu:closeMenu"
        }
    })
    
    exports['qb-menu']:openMenu(menuOptions)
end

-- Main Thread
Citizen.CreateThread(function()
    CreateJobBlip()
    
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Job Center Interaction
        local jobCenterDist = #(playerCoords - Config.Locations.JobCenter.coords)
        if jobCenterDist < 10.0 then
            DrawMarker(1, Config.Locations.JobCenter.coords.x, Config.Locations.JobCenter.coords.y, Config.Locations.JobCenter.coords.z - 1.0, 0, 0, 0, 0, 0, 0, 2.0, 2.0, 1.0, 255, 107, 53, 100, false, true, 2, false, false, false, false)
            
            if jobCenterDist < 3.0 then
                DrawText3D(Config.Locations.JobCenter.coords.x, Config.Locations.JobCenter.coords.y, Config.Locations.JobCenter.coords.z, "🐼 [E] Panda Trucking Job")
                
                if IsControlJustPressed(0, 38) then -- E key
                    local PlayerData = QBCore.Functions.GetPlayerData()
                    if PlayerData.job.name ~= Config.Job.name then
                        ShowNotification("❌ You need to be a trucker to work here!", "error")
                    else
                        UpdatePlayerXP() -- Update XP when opening menu
                        ShowJobMenu()
                    end
                end
            end
        end
        
        -- Check if player is in truck and trailer is attached
        if currentTruck and IsPedInVehicle(playerPed, currentTruck, false) then
            if not isOnJob and IsVehicleAttachedToTrailer(currentTruck) then
                if jobStarted and not currentJob then
                    StartDeliveryJob()
                end
            end
        end
        
        -- Delivery completion check
        if isOnJob and currentJob then
            local deliveryDist = #(playerCoords - currentJob.coords)
            if deliveryDist < 15.0 then
                DrawMarker(1, currentJob.coords.x, currentJob.coords.y, currentJob.coords.z - 1.0, 0, 0, 0, 0, 0, 0, 5.0, 5.0, 2.0, 76, 175, 80, 100, false, true, 2, false, false, false, false)
                
                if deliveryDist < 5.0 and currentTruck and IsPedInVehicle(playerPed, currentTruck, false) and IsVehicleAttachedToTrailer(currentTruck) then
                    DrawText3D(currentJob.coords.x, currentJob.coords.y, currentJob.coords.z, "📦 [E] Complete Delivery")
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        CompleteDelivery()
                    end
                end
            end
        end
    end
end)

-- Vehicle Security Thread (Wasabi CarLock Integration)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000) -- Check every 5 seconds
        
        if currentTruck and DoesEntityExist(currentTruck) then
            local playerPed = PlayerPedId()
            
            -- If player is not in truck and is far away, lock it
            if not IsPedInVehicle(playerPed, currentTruck, false) then
                local truckCoords = GetEntityCoords(currentTruck)
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(playerCoords - truckCoords)
                
                if distance > Config.CarLock.autoLockDistance then
                    LockVehicle(currentTruck)
                elseif distance < Config.CarLock.autoUnlockDistance then
                    UnlockVehicle(currentTruck)
                end
            end
        end
    end
end)

-- Events
RegisterNetEvent('panda-trucking:client:deliveryComplete', function(data)
    ShowNotification("💰 You earned $" .. data.payment .. " and " .. data.xp .. " XP!", "success")
    
    if data.gradeUp then
        ShowNotification("🎉 PROMOTION! You are now a " .. data.newGradeLabel .. "!", "success")
        playerGrade = data.newGrade
    end
    
    playerXP = data.newXP
    
    -- Show XP progress after a short delay
    Citizen.SetTimeout(2000, function()
        ShowXPProgress()
    end)
end)

RegisterNetEvent('panda-trucking:client:updateXP', function(data)
    playerXP = data.xp or 0
    playerGrade = data.grade or 0
end)

RegisterNetEvent('panda-trucking:client:startJob', function()
    SpawnTruck()
    SpawnTrailer()
    exports['qb-menu']:closeMenu()
end)

RegisterNetEvent('panda-trucking:client:endJob', function()
    EndJob()
    exports['qb-menu']:closeMenu()
end)

RegisterNetEvent('panda-trucking:client:checkXP', function()
    ShowXPProgress()
    exports['qb-menu']:closeMenu()
end)

-- Commands
RegisterCommand('truckxp', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData.job.name == Config.Job.name then
        UpdatePlayerXP()
        Citizen.SetTimeout(500, function()
            ShowXPProgress()
        end)
    else
        ShowNotification("❌ You must be a trucker to check XP!", "error")
    end
end)

RegisterCommand('pandatruckversion', function()
    if PandaTrucking and PandaTrucking.Version then
        print('^0[^2PANDA TRUCKING^0] ^7Client Version: ^2' .. PandaTrucking.Version.current .. '^0')
        ShowNotification("🐼 Panda Trucking v" .. PandaTrucking.Version.current, "info")
    end
end)

-- Startup message
Citizen.CreateThread(function()
    Citizen.Wait(2000)
    if PandaTrucking and PandaTrucking.Version then
        print('^0[^2PANDA TRUCKING^0] ^7Client script loaded successfully! Version: ^2' .. PandaTrucking.Version.current .. '^0')
        
        -- Check for optional dependencies
        if GetResourceState('wasabi_carlock') == 'started' then
            print('^0[^2PANDA TRUCKING^0] ^2✓ Wasabi CarLock detected and integrated^0')
        else
            print('^0[^2PANDA TRUCKING^0] ^3⚠ Wasabi CarLock not found - using native vehicle locking^0')
        end
        
        local fuelSystem = nil
        if GetResourceState('LegacyFuel') == 'started' then
            fuelSystem = 'LegacyFuel'
        elseif GetResourceState('ps-fuel') == 'started' then
            fuelSystem = 'ps-fuel'
        elseif GetResourceState('ox_fuel') == 'started' then
            fuelSystem = 'ox_fuel'
        end
        
        if fuelSystem then
            print('^0[^2PANDA TRUCKING^0] ^2✓ Fuel system detected: ' .. fuelSystem .. '^0')
        else
            print('^0[^2PANDA TRUCKING^0] ^3⚠ No fuel system detected^0')
        end
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        EndJob()
        if jobBlip then
            RemoveBlip(jobBlip)
        end
    end
end)