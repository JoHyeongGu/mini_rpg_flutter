-- before using this file, use as folllows: 
-- run before using this: mysql -uroot -pbitnami < create_db.sql
-- usage: mysql -uminirpg -pminirpg minirpg < populated_db.sql

use minirpg;
drop database if exists minirpg;
create database minirpg;
use minirpg;

CREATE TABLE user (
	user_id	VARCHAR(50)	NOT NULL,
	password	VARCHAR(255)	NOT NULL,
	email	VARCHAR(255)	NOT NULL UNIQUE,
	last_accessed_char INT NULL,
	last_accessed_at	TIMESTAMP	NOT NULL	DEFAULT NOW(),
	modified_at	TIMESTAMP	NULL	DEFAULT NOW(),
	created_at	TIMESTAMP	NULL	DEFAULT NOW(),
	deleted_at	TIMESTAMP	NULL	COMMENT '(soft delete) not null: Deleted User',
    
	PRIMARY KEY (user_id)
);

CREATE TABLE character_class (
	class_id	INT	NOT NULL AUTO_INCREMENT,
	include_class	INT	NULL	COMMENT 'null: parent class, not null: child class',
	name	VARCHAR(50)	NOT NULL,
	color	VARCHAR(20)	NOT NULL,
	open_flag	BOOLEAN	NULL	DEFAULT true,

	PRIMARY KEY (class_id),
    FOREIGN KEY (include_class) REFERENCES character_class(class_id)
);

CREATE TABLE stat (
	stat_id	INT	NOT NULL AUTO_INCREMENT,
	hp	INT	NULL	DEFAULT 0,
	atk	INT	NULL	DEFAULT 0,
	def	INT	NULL	DEFAULT 0,
	speed	INT	NULL	DEFAULT 0,
	atk_range	INT	NULL	DEFAULT 0,
	atk_speed	INT	NULL	DEFAULT 0,

	PRIMARY KEY (stat_id)
);

CREATE TABLE class_stat (
	stat_id	INT	NOT NULL,
	class_id	INT	NOT NULL,
	level	INT	NOT NULL,

	PRIMARY KEY (stat_id, class_id, level),
    FOREIGN KEY (stat_id) REFERENCES stat(stat_id),
    FOREIGN KEY (class_id) REFERENCES character_class(class_id)
);

CREATE TABLE character_list (
	char_id	INT	NOT NULL AUTO_INCREMENT,
	user_id	VARCHAR(50)	NOT NULL,
	class_id	INT	NOT NULL,
	nickname	VARCHAR(50)	NOT NULL UNIQUE,
	gender	ENUM('none', 'male', 'female')	NULL	DEFAULT 'none',
	level	INT	NULL	DEFAULT 1,
	coin	INT	NULL	DEFAULT 0,
	exp	INT	NULL	DEFAULT 0,
	hp	INT	NOT NULL,
	stat_id INT NOT NULL,
	created_at	TIMESTAMP	NULL	DEFAULT NOW(),
	deleted_at	TIMESTAMP	NULL	COMMENT 'soft delete',

	PRIMARY KEY (char_id),
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (class_id) REFERENCES character_class(class_id),
    FOREIGN KEY (stat_id) REFERENCES stat(stat_id)
);

ALTER TABLE user ADD CONSTRAINT fk_user_last_char
FOREIGN KEY (last_accessed_char) REFERENCES character_list(char_id);

CREATE TABLE max_exp (
	class_id	INT	NOT NULL,
	level	INT	NOT NULL,
	exp	INT	NOT NULL,

	PRIMARY KEY (class_id, level),
    FOREIGN KEY (class_id) REFERENCES character_class(class_id)
);

CREATE TABLE skill (
	skill_id	INT	NOT NULL	AUTO_INCREMENT,
	class_id	INT	NOT NULL,
	level	INT	NULL	DEFAULT 0,
	name	VARCHAR(50)	NOT NULL,
	description	VARCHAR(255)	NULL,
	img	VARCHAR(50)	NULL,
	cooltime	INT	NULL	DEFAULT 0,
	target	ENUM('self', 'enemy')	NULL	DEFAULT 'enemy',
	target_count	INT	NULL	DEFAULT 1,
	type	ENUM('damage', 'heal', 'buff')	NULL	DEFAULT 'damage',
	stat_id	INT	NULL,

	PRIMARY KEY (skill_id),
	FOREIGN KEY (class_id) REFERENCES character_class(class_id),
	FOREIGN KEY (stat_id) REFERENCES stat(stat_id)
);

CREATE TABLE item (
	item_id	INT	NOT NULL AUTO_INCREMENT,
	type	VARCHAR(50)	NOT NULL	COMMENT 'weapon, armor, consumable, magic item, ...',
	name	VARCHAR(50)	NOT NULL,
	description	VARCHAR(255)	NULL,
	img	VARCHAR(50)	NULL,
	effect_value	INT	NULL	DEFAULT 0	COMMENT 'value of effect',
	
	PRIMARY KEY (item_id)
);

CREATE TABLE inventory (
	char_id	INT	NOT NULL,
	item_id	INT	NOT NULL,
	count	INT	NULL	DEFAULT 1,
	equip_flag	BOOLEAN	NULL	DEFAULT false,

	PRIMARY KEY (char_id, item_id),
    FOREIGN KEY (char_id) REFERENCES character_list(char_id),
    FOREIGN KEY (item_id) REFERENCES item(item_id)
);

CREATE TABLE shop (
	item_id	INT	NOT NULL,
	price	INT	NULL	DEFAULT 0,
	sale_flag	BOOLEAN NULL	DEFAULT true,

	PRIMARY KEY (item_id),
    FOREIGN KEY (item_id) REFERENCES item(item_id)
);

CREATE TABLE npc (
	npc_id	INT	NOT NULL AUTO_INCREMENT,
	name	VARCHAR(50)	NOT NULL,
	career	VARCHAR(50)	NULL,
	entity_img	VARCHAR(50)	NULL,
	detail_img	VARCHAR(50)	NULL,

	PRIMARY KEY (npc_id)
);

CREATE TABLE quest (
	quest_id	INT	NOT NULL AUTO_INCREMENT,
	npc_id	INT	NOT NULL,
	npc_talk	TEXT	NULL,
	need_count	INT	NULL	DEFAULT 10,
	reward_coin	INT	NULL	DEFAULT 0,
	reward_exp	INT	NULL	DEFAULT 0,
	
	PRIMARY KEY (quest_id),
    FOREIGN KEY (npc_id) REFERENCES npc(npc_id)
);

CREATE TABLE accept_quest (
	char_id	INT	NOT NULL,
	quest_id	INT	NOT NULL,
	accepted_at TIMESTAMP NULL DEFAULT NOW(),
	completed_at TIMESTAMP NULL,
	
	PRIMARY KEY (char_id, quest_id),
    FOREIGN KEY (char_id) REFERENCES character_list(char_id),
    FOREIGN KEY (quest_id) REFERENCES quest(quest_id)
);

CREATE TABLE world (
	entity_type	ENUM('player', 'npc')	NULL	DEFAULT 'player',
	entity_id	INT	NOT NULL,
	x_pos	INT	NOT NULL,
	y_pos	INT	NOT NULL,
	spawn_flag	BOOLEAN	NULL	DEFAULT true,
	
	PRIMARY KEY (entity_type, entity_id)
);

-- Basic Character Classes
-- Warrior
INSERT INTO character_class (class_id, include_class, name, color) VALUES (1, NULL, 'warrior','FF3636');
INSERT INTO max_exp (class_id, level, exp) VALUES 
(1, 1, 50), (1, 5, 100), (1, 10, 300), (1, 15, 500), (1, 30, 1000), (1, 60, 3000);
-- Mage
INSERT INTO character_class (class_id, include_class, name, color) VALUES (2, NULL, 'mage','008CFF');
INSERT INTO max_exp (class_id, level, exp) VALUES 
(2, 1, 50), (2, 5, 150), (2, 10, 500), (2, 15, 700), (2, 30, 1200), (2, 60, 3000);
-- Ranger
INSERT INTO character_class (class_id, include_class, name, color) VALUES (3, NULL, 'ranger','28FF1C');
INSERT INTO max_exp (class_id, level, exp) VALUES 
(3, 1, 30), (3, 5, 50), (3, 10, 150), (3, 15, 450), (3, 30, 900), (3, 60, 3000);
-- Supporter
INSERT INTO character_class (class_id, include_class, name, color) VALUES (4, NULL, 'supporter','FFED27');
INSERT INTO max_exp (class_id, level, exp) VALUES 
(4, 1, 30), (4, 5, 50), (4, 10, 100), (4, 15, 700), (4, 30, 1000), (4, 60, 3000);

-- Detail Character Classes
-- Knight
INSERT INTO character_class (class_id, include_class, name, color) VALUES (5, 1, 'knight','FF8833');
INSERT INTO stat (hp, atk, def, speed, atk_range, atk_speed) VALUES
(500, 50, 30, 20, 1, 10),
(1200, 120, 60, 18, 1, 8),
(2500, 200, 100, 15, 1, 5);
INSERT INTO class_stat (class_id, stat_id, level) VALUES
(5, 1, 10), (5, 2, 30), (5, 3, 60);
INSERT INTO stat (atk) VALUES (40);
INSERT INTO stat (def, speed) VALUES (100, -3);
INSERT INTO stat (atk) VALUES (500);
INSERT INTO skill (class_id, level, name, description, img, cooltime, target, target_count, type, stat_id) VALUES
(5, 10, 'Shield Attack', 'Effect Stuns enemy', 'bash.png', 10, 'enemy', 3, 'damage', 4), 
(5, 30, 'Guardian Aura', 'Buffs allies', 'aura.png', 60, 'self', 1, 'buff', 5), 
(5, 60, 'Heroic Charge', 'High-damage dash', 'charge.png', 30, 'enemy', 1, 'damage', 6);

-- Berserker
INSERT INTO character_class (class_id, include_class, name, color) VALUES (6, 1, 'berserker','BC0003');
INSERT INTO stat (hp, atk, def, speed, atk_range, atk_speed) VALUES
(450, 70, 20, 25, 3, 12),
(1100, 150, 40, 22, 3, 10),
(2400, 280, 80, 18, 3, 6);
INSERT INTO class_stat (class_id, stat_id, level) VALUES
(6, 7, 10), (6, 8, 30), (6, 9, 60);
INSERT INTO stat (atk) VALUES (100);
INSERT INTO stat (hp) VALUES (300);
INSERT INTO stat (atk) VALUES (600);
INSERT INTO skill (class_id, level, name, description, img, cooltime, target, target_count, type, stat_id) VALUES
(6, 10, 'Rage Strike', 'Powerful hit', 'rage.png', 8, 'enemy', 5, 'damage', 10), 
(6, 30, 'Bloodthirst', 'Heals on hit', 'blood.png', 50, 'self', 1, 'heal', 11), 
(6, 60, 'Berserk Fury', 'Massive damage', 'fury.png', 40, 'enemy', 3, 'damage', 12);

-- Necromancer
INSERT INTO character_class (class_id, include_class, name, color) VALUES (7, 2, 'necromancer','4935FF');
INSERT INTO stat (hp, atk, def, speed, atk_range, atk_speed) VALUES
(300, 40, 10, 15, 5, 15),
(800, 90, 30, 14, 5, 12),
(2000, 170, 60, 12, 5, 8);
INSERT INTO class_stat (class_id, stat_id, level) VALUES
(7, 13, 10), (7, 14, 30), (7, 15, 60);
INSERT INTO stat (atk) VALUES (100);
INSERT INTO stat (atk) VALUES (200);
INSERT INTO stat (atk) VALUES (400);
INSERT INTO skill (class_id, level, name, description, img, cooltime, target, target_count, type, stat_id) VALUES
(7, 10, 'Raise Skeleton', 'Summon minion', 'skel.png', 30, 'self', 1, 'buff', 16), 
(7, 30, 'Bone Spear', 'Piercing skill', 'spear.png', 20, 'enemy', 5, 'damage', 17), 
(7, 60, 'Death Nova', 'AoE damage', 'nova.png', 60, 'enemy', 10, 'damage', 18);

-- Blood Mage
INSERT INTO character_class (class_id, include_class, name, color) VALUES (8, 2, 'blood mage','AE00FF');
INSERT INTO max_exp (class_id, level, exp) VALUES (8, 30, 1500);
INSERT INTO stat (hp, atk, def, speed, atk_range, atk_speed) VALUES
(320, 30, 15, 18, 5, 12),
(750, 70, 35, 17, 5, 10),
(1600, 120, 70, 14, 7, 7);
INSERT INTO class_stat (class_id, stat_id, level) VALUES
(8, 19, 10), (8, 20, 30), (8, 21, 60);
INSERT INTO stat (hp) VALUES (300);
INSERT INTO stat (atk) VALUES (150);
INSERT INTO stat (atk) VALUES (700);
INSERT INTO skill (class_id, level, name, description, img, cooltime, target, target_count, type, stat_id) VALUES
(8, 10, 'Life Expansion', 'Leech HP', 'drain.png', 12, 'self', 1, 'buff', 22), 
(8, 30, 'Dark Pact', 'Boost power', 'pact.png', 50, 'self', 1, 'buff', 23), 
(8, 60, 'Blood Storm', 'AoE bleed', 'storm.png', 60, 'enemy', 5, 'damage', 24);

-- Sniper
INSERT INTO character_class (class_id, include_class, name, color) VALUES (9, 3, 'sniper','00FF99');
INSERT INTO stat (hp, atk, def, speed, atk_range, atk_speed) VALUES
(400, 45, 25, 22, 7, 14),
(950, 95, 45, 20, 7, 10),
(2100, 180, 90, 17, 7, 7);
INSERT INTO class_stat (class_id, stat_id, level) VALUES
(9, 25, 10), (9, 26, 30), (9, 27, 60);
INSERT INTO stat (atk_range) VALUES (15);
INSERT INTO stat (atk) VALUES (1000);
INSERT INTO stat (atk) VALUES (300);
INSERT INTO skill (class_id, level, name, description, img, cooltime, target, target_count, type, stat_id) VALUES
(9, 10, 'Snipe Shot', 'Long-range shot', 'snipe.png', 12, 'self', 1, 'buff', 28), 
(9, 30, 'Headshot', 'Critical strike', 'headshot.png', 40, 'enemy', 1, 'damage', 29), 
(9, 60, 'Rain of Arrows', 'AoE attack', 'rain.png', 60, 'enemy', 5, 'damage', 30);

-- Archer
INSERT INTO character_class (class_id, include_class, name, color) VALUES (10, 3, 'archer','B2FF00');
INSERT INTO stat (hp, atk, def, speed, atk_range, atk_speed) VALUES
(380, 35, 20, 24, 6, 15),
(900, 90, 40, 21, 6, 11),
(2000, 160, 80, 18, 7, 8);
INSERT INTO class_stat (class_id, stat_id, level) VALUES
(10, 31, 10), (10, 32, 30), (10, 33, 60);
INSERT INTO stat (atk) VALUES (300);
INSERT INTO stat (atk) VALUES (450);
INSERT INTO stat (speed) VALUES (30);
INSERT INTO skill (class_id, level, name, description, img, cooltime, target, target_count, type, stat_id) VALUES
(10, 10, 'Quick Shot', 'Fast arrow', 'quick.png', 5, 'enemy', 1, 'damage', 34), 
(10, 30, 'Rainfall', 'Multiple arrows', 'rain2.png', 45, 'enemy', 3, 'damage', 35), 
(10, 60, 'Piercing Volley', 'Penetrates armor', 'volley.png', 50, 'self', 5, 'buff', 36);

-- Plaladin
INSERT INTO character_class (class_id, include_class, name, color) VALUES (11, 4, 'paladin','FFC527');
INSERT INTO stat (hp, atk, def, speed, atk_range, atk_speed) VALUES
(550, 60, 40, 15, 2, 9),
(1300, 130, 60, 13, 2, 7),
(2600, 220, 120, 10, 2, 5);
INSERT INTO class_stat (class_id, stat_id, level) VALUES
(11, 37, 10), (11, 38, 30), (11, 39, 60);
INSERT INTO stat (hp, def) VALUES (500, 100);
INSERT INTO stat (atk) VALUES (200);
INSERT INTO stat (hp) VALUES (500);
INSERT INTO skill (class_id, level, name, description, img, cooltime, target, target_count, type, stat_id) VALUES
(11, 10, 'Holy Shield', 'Defense buff', 'hshield.png', 20, 'self', 1, 'buff', 40), 
(11, 30, 'Divine Strike', 'Smite enemy', 'divines.png', 30, 'enemy', 1, 'damage', 41), 
(11, 60, 'Guardian Light', 'Heal allies', 'light.png', 60, 'self', 5, 'heal', 42);

-- Medic
INSERT INTO character_class (class_id, include_class, name, color) VALUES (12, 4, 'medic','EFFF76');
INSERT INTO stat (hp, atk, def, speed, atk_range, atk_speed) VALUES
(300, 30, 20, 20, 2, 12),
(800, 80, 50, 18, 2, 9),
(1800, 140, 80, 15, 6, 6);
INSERT INTO class_stat (class_id, stat_id, level) VALUES
(12, 43, 10), (12, 44, 30), (12, 45, 60);
INSERT INTO stat (hp) VALUES (150);
INSERT INTO stat (hp) VALUES (300);
INSERT INTO stat (hp) VALUES (1000);
INSERT INTO skill (class_id, level, name, description, img, cooltime, target, target_count, type, stat_id) VALUES
(12, 10, 'Heal', 'Restores HP', 'heal.png', 15, 'self', 1, 'heal', 46), 
(12, 30, 'Group Heal', 'AoE heal', 'group_heal.png', 50, 'self', 5, 'heal', 47), 
(12, 60, 'Resurrection', 'Revive ally', 'resurrect.png', 120, 'self', 1, 'heal', 48);

-- Items
INSERT INTO item (type, name, description, img, effect_value) VALUES
('weapon', 'Dagger', 'Quick melee weapon', 'dagger.png', 15);
INSERT INTO shop (item_id, price, sale_flag) VALUES (1, 500, false);

INSERT INTO item (type, name, description, img, effect_value) VALUES
('weapon', 'Poison Dagger', 'Adds poison damage', 'poison_dag.png', 25);
INSERT INTO shop (item_id, price) VALUES (2, 1000);

INSERT INTO item (type, name, description, img, effect_value) VALUES
('weapon', 'Lightning Staff', 'Basic lightning weapon', 'light_staff.png', 30);
INSERT INTO shop (item_id, price) VALUES (3, 1200);

INSERT INTO item (type, name, description, img, effect_value) VALUES
('armor', 'Wooden Shield', 'Basic shield', 'shield.png', 10);
INSERT INTO shop (item_id, price) VALUES (4, 800);

INSERT INTO item (type, name, description, img, effect_value) VALUES
('armor', 'Mystic Robe', 'Increases magic defense', 'robe.png', 20);
INSERT INTO shop (item_id, price) VALUES (5, 600);

INSERT INTO item (type, name, description, img, effect_value) VALUES
('consumable', 'Health Potion', 'Restores 200 HP', 'potion.png', 200);
INSERT INTO shop (item_id, price) VALUES (6, 800);

INSERT INTO item (type, name, description, img, effect_value) VALUES
('consumable', 'Elixir', 'Fully restores HP/MP', 'elixir.png', 1000);
INSERT INTO shop (item_id, price) VALUES (7, 1500);

INSERT INTO item (type, name, description, img, effect_value) VALUES
('magic item', 'Spell Book', 'Random spell each use', 'spellbook.png', 0);
INSERT INTO shop (item_id, price) VALUES (8, 2000);

INSERT INTO item (type, name, description, img, effect_value) VALUES
('magic item', 'Endless Pockets', 'Extra slot', 'endo_pockets.png', 0);
INSERT INTO shop (item_id, price) VALUES (9, 1700);

-- Insert NPCs
INSERT INTO npc (name, career, entity_img, detail_img) VALUES
('Mr.Seo', 'First NPC', 'mr_seo.png', 'mr_seo_detail.png');
INSERT INTO quest (npc_id, npc_talk, need_count, reward_coin, reward_exp) VALUES
(1, 'Hi guy, You have to take 10 coins to grow yourself.', 10, 50, 60);
INSERT INTO quest (npc_id, npc_talk, need_count, reward_coin, reward_exp) VALUES
(1, "Hi guy, I think you can take 50 coins, Let's do it!", 50, 550, 500);
INSERT INTO world (entity_type, entity_id, x_pos, y_pos) VALUES
('npc', 1, 544, 424);

INSERT INTO npc (name, career, entity_img, detail_img) VALUES
('Mr.Jo', 'Developer', 'mr_jo.png', 'mr_jo_detail.png');
INSERT INTO quest (npc_id, npc_talk, need_count, reward_coin, reward_exp) VALUES
(2, 'Hello World, If collect_coins.count is 30, I will give you more coin.', 30, 500, 100);
INSERT INTO world (entity_type, entity_id, x_pos, y_pos) VALUES
('npc', 2, 1028, 2305);

INSERT INTO npc (name, career, entity_img, detail_img) VALUES
('Mr.Kim', 'Man', 'mr_kim.png', 'mr_kim_detail.png');
INSERT INTO quest (npc_id, npc_talk, need_count, reward_coin, reward_exp) VALUES
(3, 'Give me 5 coin.', 5, 200, 800);
INSERT INTO world (entity_type, entity_id, x_pos, y_pos) VALUES
('npc', 3, 2515, 445);