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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Panda Trucking Player Statistics v2.1.0';

-- Create delivery logs table for admin monitoring
CREATE TABLE IF NOT EXISTS `panda_trucking_delivery_logs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `player_name` varchar(100) NOT NULL,
    `delivery_location` varchar(100) NOT NULL,
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
    KEY `idx_payment` (`payment_amount`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Panda Trucking Delivery Logs v2.1.0';

-- Insert version information
INSERT INTO `panda_trucking_stats` (`citizenid`, `deliveries_completed`, `total_earnings`, `experience_points`, `current_grade`)
VALUES ('VERSION_2.1.0_NO_TABLET', 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `updated_at` = CURRENT_TIMESTAMP;

-- Create indexes for better performance
ALTER TABLE `panda_trucking_stats` ADD INDEX `idx_grade` (`current_grade`);
ALTER TABLE `panda_trucking_delivery_logs` ADD INDEX `idx_player_name` (`player_name`);