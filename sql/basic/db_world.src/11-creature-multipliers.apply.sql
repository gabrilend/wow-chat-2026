-- MARKER_E026_APPLY basic-creature-multipliers

CREATE TABLE IF NOT EXISTS `basic_creature_multipliers` (
  `entry`   int unsigned NOT NULL DEFAULT 0 COMMENT 'creature template, or 0 for a map row',
  `map_id`  int unsigned NOT NULL DEFAULT 0 COMMENT 'instance map for a map row, else 0',
  `melee`   float        NOT NULL DEFAULT 1,
  `spell`   float        NOT NULL DEFAULT 1,
  `heal`    float        NOT NULL DEFAULT 1,
  `health`  float        NOT NULL DEFAULT 1,
  `comment` varchar(255) DEFAULT NULL COMMENT 'who, and why this value',
  PRIMARY KEY (`entry`, `map_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155i: per-creature and per-map damage, healing and health multipliers (basic)';

