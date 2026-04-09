-- #########################################################
-- Local patch: Relocate logout texts BEFORE wait_for_attack
-- -1 suffix: support beam, holding apart yet equal
--
-- Fixes upstream migration ordering bug:
--   03_14 wants IDs 1740-1742 for wait_for_attack_*
--   03_26 relocates bot_not_your_master (1740→1743)
--   But 03_26 runs AFTER 03_14, causing conflict
--
-- This patch runs at 03_13 (before 03_14), doing the
-- relocation early so both can coexist.
-- #########################################################

-- Clear old positions (if they exist with these names)
DELETE FROM ai_playerbot_texts WHERE name IN ('bot_not_your_master', 'bot_rndbot_no_logout');
DELETE FROM ai_playerbot_texts_chance WHERE name IN ('bot_not_your_master', 'bot_rndbot_no_logout');

-- Clear by ID too (in case names differ but IDs conflict)
DELETE FROM ai_playerbot_texts WHERE id IN (1740, 1741);

-- Relocate to new IDs (1743, 1744) with full translations
-- Matches upstream 2026_03_26 content

INSERT INTO `ai_playerbot_texts`
    (`id`, `name`, `text`, `say_type`, `reply_type`,
     `text_loc1`, `text_loc2`, `text_loc3`, `text_loc4`,
     `text_loc5`, `text_loc6`, `text_loc7`, `text_loc8`)
VALUES (
    1743,
    'bot_not_your_master',
    "You are not my master!",
    0, 0,
    -- koKR
    "당신은 내 주인이 아닙니다!",
    -- frFR
    "Tu n'es pas mon maître !",
    -- deDE
    "Du bist nicht mein Meister!",
    -- zhCN
    "你不是我的主人！",
    -- zhTW
    "你不是我的主人！",
    -- esES
    "¡No eres mi amo!",
    -- esMX
    "¡No eres mi amo!",
    -- ruRU
    "Ты не мой хозяин!");

INSERT INTO ai_playerbot_texts_chance (name, probability) VALUES ('bot_not_your_master', 100);

INSERT INTO `ai_playerbot_texts`
    (`id`, `name`, `text`, `say_type`, `reply_type`,
     `text_loc1`, `text_loc2`, `text_loc3`, `text_loc4`,
     `text_loc5`, `text_loc6`, `text_loc7`, `text_loc8`)
VALUES (
    1744,
    'bot_rndbot_no_logout',
    "You can't command me to logout!",
    0, 0,
    -- koKR
    "당신은 나에게 로그아웃을 명령할 수 없습니다!",
    -- frFR
    "Tu ne peux pas m'ordonner de me déconnecter !",
    -- deDE
    "Du kannst mir nicht befehlen, mich auszuloggen!",
    -- zhCN
    "你不能命令我下线！",
    -- zhTW
    "你不能命令我登出！",
    -- esES
    "¡No puedes ordenarme que cierre sesión!",
    -- esMX
    "¡No puedes ordenarme que cierre sesión!",
    -- ruRU
    "Ты не можешь приказать мне выйти из игры!");

INSERT INTO ai_playerbot_texts_chance (name, probability) VALUES ('bot_rndbot_no_logout', 100);
