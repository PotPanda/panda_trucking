-- Server-side script for Panda Trucking Job
-- server.lua
-- Version: 2.1.0 (No Tablet Version)

local QBCore = exports['qb-core']:GetCoreObject()

-- Startup version check
Citizen.CreateThread(function()
    Citizen.Wait(1000)
    if PandaTrucking and PandaTrucking.Version then
        PandaTrucking.Version.Print()
        PandaTrucking.Version.PrintFeatures()
        PandaTrucking.Version.CheckForUpdates()
    else
        print('^1[PANDA TRUCKING]^7 ERROR: Version system not loaded!^0')
    end
    
    -- Ensure MySQL is available
    if MySQL == nil then
        print('^1[PANDA TRUCKING]^7 WARNING: MySQL not found! XP system will not work properly.^0')
    else
        print('^2[PANDA TRUCKING]^7 MySQL connection established successfully!^0')
    end
end)

-- Helper Functions
function GetPlayerTruckingData(citizenid)
    local result = MySQL.Sync.fetchAll('SELECT * FROM panda_trucking_stats WHERE citizenid = ?', {citizenid})
    if result[1] then
        return result[1]
    else
        -- Create new entry
        MySQL.Sync.execute('INSERT INTO panda_trucking_stats (citizenid, deliveries_completed, total_earnings, experience_points, current_grade) VALUES (?, ?, ?, ?, ?)', {
            citizenid, 0, 0, 0, 0
        })
        return {
            citizenid = citizenid,
            deliveries_completed = 0,
            total_earnings = 0,
            experience_points = 0,
            current_grade = 0
        }
    end
end

local function UpdatePlayerTruckingData(citizenid, data)
    MySQL.Sync.execute('UPDATE panda_trucking_stats SET deliveries_completed = ?, total_earnings = ?, experience_points = ?, current_grade = ?, last_delivery = NOW() WHERE citizenid = ?', {
        data.deliveries_completed,
        data.total_earnings,
        data.experience_points,
        data.current_grade,
        citizenid
    })
end

local function LogDelivery(citizenid, playerName, deliveryData, payment, xpGained)
    MySQL.Sync.execute('INSERT INTO panda_trucking_delivery_logs (citizenid, player_name, delivery_location, payment_amount, distance_traveled, completion_time, truck_model, trailer_model) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        citizenid,
        playerName,
        deliveryData.location or 'Unknown',
        payment,
        deliveryData.distance or 0,
        deliveryData.timeTaken or 0,
        deliveryData.truckModel or 'Unknown',
        deliveryData.trailerModel or 'Unknown'
    })
end

local function CheckGradeUp(currentGrade, newXP)
    local nextGrade = currentGrade + 1
    if Config.Job.grades[nextGrade] and newXP >= Config.Job.grades[nextGrade].xpRequired then
        return nextGrade
    end
    return currentGrade
end

-- Server Events
RegisterServerEvent('panda-trucking:server:completeDelivery', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local payment = data.payment or 500
    local xpGained = data.xp or 0
    
    -- Validate payment amount (prevent exploits)
    if payment < 100 or payment > 3000 then
        payment = 500 -- Default safe amount
    end
    
    if xpGained < 0 or xpGained > 100 then
        xpGained = 25 -- Default safe XP
    end
    
    -- Get current trucking data
    local truckingData = GetPlayerTruckingData(citizenid)
    
    -- Update stats
    truckingData.deliveries_completed = truckingData.deliveries_completed + 1
    truckingData.total_earnings = truckingData.total_earnings + payment
    truckingData.experience_points = truckingData.experience_points + xpGained
    
    -- Check for grade up
    local currentGrade = truckingData.current_grade
    local newGrade = CheckGradeUp(currentGrade, truckingData.experience_points)
    local gradeUp = newGrade > currentGrade
    
    if gradeUp then
        truckingData.current_grade = newGrade
        -- Update player job grade
        Player.Functions.SetJob('trucker', newGrade)
    end
    
    -- Add money to player
    Player.Functions.AddMoney('cash', payment, 'panda-trucking-delivery')
    
    -- Update database
    UpdatePlayerTruckingData(citizenid, truckingData)
    
    -- Log the delivery
    LogDelivery(citizenid, playerName, data.deliveryData, payment, xpGained)
    
    -- Log the transaction
    print(('[PANDA TRUCKING] Player %s (%s) completed delivery - $%d, %d XP'):format(playerName, citizenid, payment, xpGained))
    
    if gradeUp then
        print(('[PANDA TRUCKING] Player %s promoted to grade %d (%s)'):format(playerName, newGrade, Config.Job.grades[newGrade].label))
    end
    
    -- Trigger client event with all data
    TriggerClientEvent('panda-trucking:client:deliveryComplete', src, {
        payment = payment,
        xp = xpGained,
        newXP = truckingData.experience_points,
        gradeUp = gradeUp,
        newGrade = newGrade,
        newGradeLabel = gradeUp and Config.Job.grades[newGrade].label or nil
    })
end)

-- Callback to get player XP data
QBCore.Functions.CreateCallback('panda-trucking:server:getPlayerXP', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb(nil)
        return 
    end
    
    local citizenid = Player.PlayerData.citizenid
    local truckingData = GetPlayerTruckingData(citizenid)
    
    cb({
        xp = truckingData.experience_points,
        grade = truckingData.current_grade,
        deliveries = truckingData.deliveries_completed,
        earnings = truckingData.total_earnings
    })
end)

-- Admin Commands
QBCore.Commands.Add('addtruckxp', 'Add XP to player (Admin Only)', {{name = 'id', help = 'Player ID'}, {name = 'xp', help = 'XP Amount'}}, true, function(source, args)
    local src = source
    local targetId = tonumber(args[1])
    local xpAmount = tonumber(args[2]) or 0
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        return
    end
    
    if xpAmount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid XP amount', 'error')
        return
    end
    
    local citizenid = TargetPlayer.PlayerData.citizenid
    local truckingData = GetPlayerTruckingData(citizenid)
    
    -- Add XP
    truckingData.experience_points = truckingData.experience_points + xpAmount
    
    -- Check for grade up
    local currentGrade = truckingData.current_grade
    local newGrade = CheckGradeUp(currentGrade, truckingData.experience_points)
    local gradeUp = newGrade > currentGrade
    
    if gradeUp then
        truckingData.current_grade = newGrade
        TargetPlayer.Functions.SetJob('trucker', newGrade)
    end
    
    -- Update database
    UpdatePlayerTruckingData(citizenid, truckingData)
    
    -- Notify admin
    TriggerClientEvent('QBCore:Notify', src, 'Added ' .. xpAmount .. ' XP to ' .. TargetPlayer.PlayerData.charinfo.firstname, 'success')
    
    -- Notify target player
    TriggerClientEvent('panda-trucking:client:updateXP', targetId, {
        xp = truckingData.experience_points,
        grade = truckingData.current_grade
    })
    
    if gradeUp then
        TriggerClientEvent('QBCore:Notify', targetId, '🎉 PROMOTION! You are now a ' .. Config.Job.grades[newGrade].label .. '!', 'success')
    end
    
    TriggerClientEvent('QBCore:Notify', targetId, '🎁 You received ' .. xpAmount .. ' XP from an admin!', 'success')
end, 'admin')

QBCore.Commands.Add('truckstats', 'Check player trucking stats (Admin Only)', {{name = 'id', help = 'Player ID'}}, true, function(source, args)
    local src = source
    local targetId = tonumber(args[1])
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        return
    end
    
    local citizenid = TargetPlayer.PlayerData.citizenid
    local truckingData = GetPlayerTruckingData(citizenid)
    
    local statsMessage = string.format(
        '%s Trucking Stats: XP: %d | Grade: %s (%d) | Deliveries: %d | Earnings: $%d',
        TargetPlayer.PlayerData.charinfo.firstname,
        truckingData.experience_points,
        Config.Job.grades[truckingData.current_grade].label,
        truckingData.current_grade,
        truckingData.deliveries_completed,
        truckingData.total_earnings
    )
    
    TriggerClientEvent('chat:addMessage', src, {
        color = {255, 107, 53},
        multiline = true,
        args = {"[PANDA TRUCKING STATS]", statsMessage}
    })
end, 'admin')

QBCore.Commands.Add('resettruckdata', 'Reset player trucking data (Admin Only)', {{name = 'id', help = 'Player ID'}}, true, function(source, args)
    local src = source
    local targetId = tonumber(args[1])
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        return
    end
    
    local citizenid = TargetPlayer.PlayerData.citizenid
    
    -- Reset trucking data
    MySQL.Sync.execute('UPDATE panda_trucking_stats SET deliveries_completed = 0, total_earnings = 0, experience_points = 0, current_grade = 0 WHERE citizenid = ?', {citizenid})
    
    -- Reset job grade
    TargetPlayer.Functions.SetJob('trucker', 0)
    
    TriggerClientEvent('QBCore:Notify', src, '🔄 Reset trucking data for ' .. TargetPlayer.PlayerData.charinfo.firstname, 'success')
    TriggerClientEvent('QBCore:Notify', targetId, '🔄 Your trucking data has been reset by an admin', 'info')
    
    print(('[PANDA TRUCKING] Admin %s reset trucking data for player %s'):format(GetPlayerName(src), TargetPlayer.PlayerData.charinfo.firstname))
end, 'admin')

QBCore.Commands.Add('pandatruckversion', 'Check Panda Trucking version', {}, false, function(source, args)
    local src = source
    if PandaTrucking and PandaTrucking.Version then
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 107, 53},
            multiline = true,
            args = {"[PANDA TRUCKING]", "🐼 Server Version: " .. PandaTrucking.Version.current .. " | Build: " .. PandaTrucking.Version.build}
        })
    end
end)