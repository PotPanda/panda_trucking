-- Panda Trucking Database Schema - FIXED VERSION
-- Version: 2.1.1 - Handles existing installations
-- Compatible with MySQL 5.7+ and MariaDB 10.2+

-- Create panda trucking statistics table
CREATE TABLE IF NOT EXISTS `panda_trucking_stats` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `deliveries_completed` int(11) DEFAULT 0,
    `total_earnings` int(11) DEFAULT 0,
    `total_distance` float DEFAULT 0.0,
    `experience_points` int(11) DEFAULT 0,
    `current_grade` int(11) DEFAULT 0,
    `last_delivery` timestamp NULL DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizenid` (`citizenid`),
    INDEX `idx_experience` (`experience_points`),
    INDEX `idx_deliveries` (`deliveries_completed`),
    INDEX `idx_earnings` (`total_earnings`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Panda Trucking Player Statistics v2.1.1';

-- Add new columns if they don't exist (for existing installations)
SET @sql = 'SELECT COUNT(*) INTO @col_exists FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = "panda_trucking_stats" AND COLUMN_NAME = "perfect_deliveries"';
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add perfect_deliveries column if it doesn't exist
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `panda_trucking_stats` ADD COLUMN `perfect_deliveries` int(11) DEFAULT 0 AFTER `current_grade`', 'SELECT "perfect_deliveries column already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add fastest_delivery_time column if it doesn't exist
SET @sql = 'SELECT COUNT(*) INTO @col_exists FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = "panda_trucking_stats" AND COLUMN_NAME = "fastest_delivery_time"';
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(@col_exists = 0, 'ALTER TABLE `panda_trucking_stats` ADD COLUMN `fastest_delivery_time` int(11) DEFAULT NULL AFTER `perfect_deliveries`', 'SELECT "fastest_delivery_time column already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add longest_delivery_distance column if it doesn't exist
SET @sql = 'SELECT COUNT(*) INTO @col_exists FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = "panda_trucking_stats" AND COLUMN_NAME = "longest_delivery_distance"';
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(@col_exists = 0, 'ALTER TABLE `panda_trucking_stats` ADD COLUMN `longest_delivery_distance` float DEFAULT 0.0 AFTER `fastest_delivery_time`', 'SELECT "longest_delivery_distance column already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add favorite_route column if it doesn't exist
SET @sql = 'SELECT COUNT(*) INTO @col_exists FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = "panda_trucking_stats" AND COLUMN_NAME = "favorite_route"';
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(@col_exists = 0, 'ALTER TABLE `panda_trucking_stats` ADD COLUMN `favorite_route` varchar(100) DEFAULT NULL AFTER `longest_delivery_distance`', 'SELECT "favorite_route column already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Create delivery logs table for admin monitoring
CREATE TABLE IF NOT EXISTS `panda_trucking_delivery_logs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `player_name` varchar(100) NOT NULL,
    `delivery_location` varchar(100) NOT NULL,
    `pickup_location` varchar(100) DEFAULT 'Panda Trucking HQ',
    `payment_amount` int(11) NOT NULL,
    `distance_traveled` float DEFAULT 0.0,
    `completion_time` int(11) DEFAULT 0,
    `truck_model` varchar(50) DEFAULT NULL,
    `trailer_model` varchar(50) DEFAULT NULL,
    `timestamp` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `timestamp` (`timestamp`),
    KEY `idx_location` (`delivery_location`),
    KEY `idx_payment` (`payment_amount`),
    KEY `idx_player_name` (`player_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Panda Trucking Delivery Logs v2.1.1';

-- Add new columns to delivery logs if they don't exist
SET @sql = 'SELECT COUNT(*) INTO @col_exists FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = "panda_trucking_delivery_logs" AND COLUMN_NAME = "xp_gained"';
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(@col_exists = 0, 'ALTER TABLE `panda_trucking_delivery_logs` ADD COLUMN `xp_gained` int(11) DEFAULT 0 AFTER `payment_amount`', 'SELECT "xp_gained column already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add vehicle_damage column if it doesn't exist
SET @sql = 'SELECT COUNT(*) INTO @col_exists FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = "panda_trucking_delivery_logs" AND COLUMN_NAME = "vehicle_damage"';
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(@col_exists = 0, 'ALTER TABLE `panda_trucking_delivery_logs` ADD COLUMN `vehicle_damage` float DEFAULT 0.0 AFTER `trailer_model`', 'SELECT "vehicle_damage column already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add perfect_delivery column if it doesn't exist
SET @sql = 'SELECT COUNT(*) INTO @col_exists FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = "panda_trucking_delivery_logs" AND COLUMN_NAME = "perfect_delivery"';
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(@col_exists = 0, 'ALTER TABLE `panda_trucking_delivery_logs` ADD COLUMN `perfect_delivery` tinyint(1) DEFAULT 0 AFTER `vehicle_damage`', 'SELECT "perfect_delivery column already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add delivery_grade column if it doesn't exist
SET @sql = 'SELECT COUNT(*) INTO @col_exists FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = "panda_trucking_delivery_logs" AND COLUMN_NAME = "delivery_grade"';
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(@col_exists = 0, 'ALTER TABLE `panda_trucking_delivery_logs` ADD COLUMN `delivery_grade` int(11) DEFAULT 0 AFTER `perfect_delivery`', 'SELECT "delivery_grade column already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add server_id column if it doesn't exist
SET @sql = 'SELECT COUNT(*) INTO @col_exists FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = "panda_trucking_delivery_logs" AND COLUMN_NAME = "server_id"';
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(@col_exists = 0, 'ALTER TABLE `panda_trucking_delivery_logs` ADD COLUMN `server_id` int(11) DEFAULT NULL AFTER `delivery_grade`', 'SELECT "server_id column already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Create achievements table for future expansion
CREATE TABLE IF NOT EXISTS `panda_trucking_achievements` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `achievement_id` varchar(50) NOT NULL,
    `achievement_name` varchar(100) NOT NULL,
    `achievement_description` text DEFAULT NULL,
    `unlocked_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `progress` int(11) DEFAULT 0,
    `completed` tinyint(1) DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `achievement_id` (`achievement_id`),
    UNIQUE KEY `unique_citizen_achievement` (`citizenid`, `achievement_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Panda Trucking Achievements System v2.1.1';

-- Create indexes for better performance if they don't exist
SET @sql = 'SELECT COUNT(*) INTO @index_exists FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = "panda_trucking_stats" AND INDEX_NAME = "idx_grade"';
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(@index_exists = 0, 'ALTER TABLE `panda_trucking_stats` ADD INDEX `idx_grade` (`current_grade`)', 'SELECT "idx_grade already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add more indexes
SET @sql = 'SELECT COUNT(*) INTO @index_exists FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = "panda_trucking_stats" AND INDEX_NAME = "idx_last_delivery"';
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(@index_exists = 0, 'ALTER TABLE `panda_trucking_stats` ADD INDEX `idx_last_delivery` (`last_delivery`)', 'SELECT "idx_last_delivery already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Now create the leaderboard view with proper column checks
DROP VIEW IF EXISTS `panda_trucking_leaderboard`;

CREATE VIEW `panda_trucking_leaderboard` AS
SELECT 
    pts.citizenid,
    pts.deliveries_completed,
    pts.total_earnings,
    pts.experience_points,
    pts.current_grade,
    COALESCE(pts.perfect_deliveries, 0) as perfect_deliveries,
    pts.fastest_delivery_time,
    COALESCE(pts.longest_delivery_distance, 0.0) as longest_delivery_distance,
    pts.last_delivery,
    RANK() OVER (ORDER BY pts.experience_points DESC) as xp_rank,
    RANK() OVER (ORDER BY pts.deliveries_completed DESC) as delivery_rank,
    RANK() OVER (ORDER BY pts.total_earnings DESC) as earnings_rank
FROM panda_trucking_stats pts
WHERE pts.deliveries_completed > 0
ORDER BY pts.experience_points DESC;

-- Insert version information
INSERT INTO `panda_trucking_stats` (`citizenid`, `deliveries_completed`, `total_earnings`, `experience_points`, `current_grade`)
VALUES ('VERSION_2.1.1_FIXED', 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE 
    `updated_at` = CURRENT_TIMESTAMP,
    `citizenid` = 'VERSION_2.1.1_FIXED';

-- Sample achievements data
INSERT INTO `panda_trucking_achievements` (`citizenid`, `achievement_id`, `achievement_name`, `achievement_description`, `completed`) VALUES
('SAMPLE_ACHIEVEMENTS', 'first_delivery', 'First Delivery', 'Complete your first trucking delivery', 0),
('SAMPLE_ACHIEVEMENTS', 'experienced_driver', 'Experienced Driver', 'Reach Driver Grade 1', 0),
('SAMPLE_ACHIEVEMENTS', 'veteran_trucker', 'Veteran Trucker', 'Complete 50 deliveries', 0),
('SAMPLE_ACHIEVEMENTS', 'perfect_streak', 'Perfect Streak', 'Complete 10 perfect deliveries in a row', 0),
('SAMPLE_ACHIEVEMENTS', 'long_haul', 'Long Haul Master', 'Complete a delivery over 10km', 0),
('SAMPLE_ACHIEVEMENTS', 'speed_demon', 'Speed Demon', 'Complete a delivery in under 3 minutes', 0)
ON DUPLICATE KEY UPDATE `achievement_name` = VALUES(`achievement_name`);

-- Create stored procedures for common operations
DELIMITER //

DROP PROCEDURE IF EXISTS `GetPlayerTruckingStats` //
CREATE PROCEDURE `GetPlayerTruckingStats`(IN player_citizenid VARCHAR(50))
BEGIN
    SELECT * FROM panda_trucking_stats WHERE citizenid = player_citizenid;
END //

DROP PROCEDURE IF EXISTS `GetTopTruckers` //
CREATE PROCEDURE `GetTopTruckers`(IN limit_count INT)
BEGIN
    SELECT 
        citizenid,
        deliveries_completed,
        total_earnings,
        experience_points,
        current_grade,
        COALESCE(perfect_deliveries, 0) as perfect_deliveries
    FROM panda_trucking_stats 
    WHERE deliveries_completed > 0
    ORDER BY experience_points DESC 
    LIMIT limit_count;
END //

DROP PROCEDURE IF EXISTS `GetRecentDeliveries` //
CREATE PROCEDURE `GetRecentDeliveries`(IN limit_count INT)
BEGIN
    SELECT 
        player_name,
        delivery_location,
        payment_amount,
        COALESCE(xp_gained, 0) as xp_gained,
        distance_traveled,
        completion_time,
        COALESCE(perfect_delivery, 0) as perfect_delivery,
        timestamp
    FROM panda_trucking_delivery_logs 
    ORDER BY timestamp DESC 
    LIMIT limit_count;
END //

DELIMITER ;

-- Performance optimization: Update table statistics
ANALYZE TABLE panda_trucking_stats;
ANALYZE TABLE panda_trucking_delivery_logs;
ANALYZE TABLE panda_trucking_achievements;

-- Success message
SELECT 'Panda Trucking Database v2.1.1 FIXED - Updated successfully!' as 'Installation Status';
SELECT 'All existing data preserved, new columns added safely!' as 'Update Status';