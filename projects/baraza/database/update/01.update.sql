
CREATE TABLE use_keys (
	use_key_id				integer primary key,
	use_key_name			varchar(32) not null,
	use_function			integer
);

INSERT INTO use_keys (use_key_id, use_key_name, use_function) VALUES 
(0, 'System Admins', 0),
(1, 'Staff', 0),
(2, 'Client', 0),
(3, 'Supplier', 0),
(4, 'Applicant', 0),
(5, 'Subscription', 0);

ALTER  TABLE entity_types ADD use_key_id			integer references use_keys;
CREATE INDEX entity_types_use_key_id ON entity_types (use_key_id);

ALTER  TABLE entitys ADD use_key_id			integer references use_keys;
CREATE INDEX entitys_use_key_id ON entitys (use_key_id);

ALTER  TABLE orgs ADD 	logo					varchar(50);
ALTER  TABLE orgs ADD 	letter_head				varchar(50);
ALTER  TABLE orgs ADD 	email_from				varchar(120);
ALTER  TABLE orgs ADD 	web_logos				boolean default false not null;

CREATE TABLE sys_languages (
	sys_language_id			serial primary key,
	sys_language_name		varchar(50) not null unique
);


CREATE TABLE sys_translations (
	sys_translation_id		serial primary key,
	sys_language_id			integer references sys_languages,
	org_id					integer references orgs,
	reference				varchar(64) not null,
	title					varchar(320) not null,

	UNIQUE(sys_language_id, org_id, reference)
);
CREATE INDEX sys_translations_sys_language_id ON sys_translations (sys_language_id);
CREATE INDEX sys_translations_org_id ON sys_translations (org_id);

CREATE TABLE sys_access_levels (
	sys_access_level_id		serial primary key,
	use_key_id				integer references use_keys,
	sys_country_id			char(2) references sys_countrys,
	org_id					integer references orgs,
	sys_access_level_name	varchar(64) not null,
	access_tag				varchar(32) not null,
	acess_details			text,
	UNIQUE(org_id, sys_access_level_name)
);
CREATE INDEX sys_access_levels_use_key_id ON sys_access_levels (use_key_id);
CREATE INDEX sys_access_levels_sys_country_id ON sys_access_levels (sys_country_id);
CREATE INDEX sys_access_levels_org_id ON sys_access_levels (org_id);

CREATE TABLE sys_access_entitys (
	sys_access_entity_id	serial primary key,
	sys_access_level_id		integer not null references sys_access_levels,
	entity_id				integer not null references entitys,
	org_id					integer references orgs,
	narrative				varchar(320),
	UNIQUE(sys_access_level_id, entity_id)
);
CREATE INDEX sys_access_entitys_sys_access_level_id ON sys_access_entitys (sys_access_level_id);
CREATE INDEX sys_access_entitys_entity_id ON sys_access_entitys (entity_id);
CREATE INDEX sys_access_entitys_org_id ON sys_access_entitys (org_id);

ALTER  TABLE entitys ADD sys_language_id			integer references sys_languages;
CREATE INDEX entitys_sys_language_id ON entitys (sys_language_id);

CREATE VIEW vw_sys_access_entitys AS
	SELECT sys_access_levels.sys_access_level_id, sys_access_levels.use_key_id,
		sys_access_levels.sys_access_level_name, sys_access_levels.access_tag,
		entitys.entity_id, entitys.entity_name, 
		sys_access_entitys.org_id, sys_access_entitys.sys_access_entity_id, 
		sys_access_entitys.narrative
	FROM sys_access_entitys INNER JOIN sys_access_levels ON sys_access_entitys.sys_access_level_id = sys_access_levels.sys_access_level_id
		INNER JOIN entitys ON sys_access_entitys.entity_id = entitys.entity_id;



INSERT INTO sys_languages (sys_language_id, sys_language_name) VALUES
(0, 'English');


	
CREATE OR REPLACE FUNCTION upd_access_level(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_org_id				integer;
	v_sys_access_entity_id	integer;
	msg						varchar(120);
BEGIN

	IF($3 = '1')THEN
		SELECT org_id INTO v_org_id FROM entitys WHERE (entity_id = $4::int);
		
		SELECT sys_access_entity_id INTO v_sys_access_entity_id
		FROM sys_access_entitys
		WHERE (entity_id = $4::int) AND (sys_access_level_id = $1::int);
		
		IF(v_sys_access_entity_id is null)THEN
			INSERT INTO sys_access_entitys (entity_id, sys_access_level_id, org_id)
			VALUES ($4::int, $1::int, v_org_id);
			
			msg := 'Granted access level';
		ELSE
			msg := 'Access level already granted';
		END IF;
	ELSIF($3 = '2')THEN
		DELETE FROM sys_access_entitys WHERE sys_access_level_id = $1::int;
		
		msg := 'Rovoked access level';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_sys_login(varchar(120)) RETURNS integer AS $$
DECLARE
	v_sys_login_id			integer;
	v_entity_id				integer;
BEGIN
	SELECT entity_id INTO v_entity_id
	FROM entitys WHERE user_name = $1;

	v_sys_login_id := nextval('sys_logins_sys_login_id_seq');

	INSERT INTO sys_logins (sys_login_id, entity_id)
	VALUES (v_sys_login_id, v_entity_id);

	return v_sys_login_id;
END;
$$ LANGUAGE plpgsql;

