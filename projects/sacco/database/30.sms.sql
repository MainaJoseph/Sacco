----SMS
---sms folders table
CREATE TABLE folders (
	folder_id				serial primary key,
	org_id					integer references orgs,
	folder_name				varchar(25) unique,
	details					text
);
CREATE INDEX folders_org_id ON folders (org_id);
INSERT INTO folders (folder_id, folder_name) VALUES (0, 'Outbox');
INSERT INTO folders (folder_id, folder_name) VALUES (1, 'Draft');
INSERT INTO folders (folder_id, folder_name) VALUES (2, 'Sent');
INSERT INTO folders (folder_id, folder_name) VALUES (3, 'Inbox');
INSERT INTO folders (folder_id, folder_name) VALUES (4, 'Action');

CREATE TABLE sms (
	sms_id					serial primary key,
	entity_id				integer references entitys,
	member_id 				integer references members,
	folder_id 				integer references folders,
	org_id					integer references orgs,

	sms_number				varchar(25),
	---- sms_numbers				text,
	sms_time				timestamp default now(),
	sent					boolean default false not null,

	is_groupsms				boolean default false not null,
	
	message					text,
	details					text
);
CREATE INDEX sms_entity_id ON sms (entity_id);
CREATE INDEX sms_org_id ON sms (org_id);
CREATE INDEX sms_folder_id ON sms (folder_id);
CREATE INDEX sms_member_id ON sms (member_id);

---SMS CONFIGURATION
CREATE TABLE sms_configs (
	sms_config_id 		serial primary key,
	org_id 				integer references orgs,
	use_key_id 			integer references use_keys,

	sms_config_name 	varchar(120),
	is_active 			boolean default false not null,
	sms_template 		text,

	details 			text
);
CREATE INDEX sms_configs_org_id ON sms_configs (org_id);
CREATE INDEX sms_configs_use_keys ON sms_configs (use_key_id);

---SMS GROUPS
CREATE TABLE sms_group (
	sms_group_id 		serial primary key,
	org_id 				integer references orgs,
	sms_group_name 		varchar(120),

	details 			text
);
CREATE INDEX sms_group_org_id ON sms_group (org_id);

ALTER TABLE sms ADD sms_group_id 			integer references sms_group;
CREATE INDEX sms_sms_group_id ON sms (sms_group_id);

---SMS GROUP MEMBERS
CREATE TABLE sms_group_members (
	sms_group_member_id 	serial primary key,
	sms_group_id   			integer references sms_group,
	org_id 					integer references orgs,
	member_id 				integer references members,

	narrative 				varchar(120),
	details 				text
);
CREATE INDEX sms_group_members_org_id ON sms_group_members (org_id);
CREATE INDEX sms_group_members_member_id ON sms_group_members (member_id);
CREATE INDEX sms_group_members_sms_group_id ON sms_group_members (sms_group_id);

---group sms holding table before insert to sms table
CREATE TABLE group_sms_details (
	group_sms_detail_id 	serial primary key,
	sms_group_id 			integer references sms_group,
	sms_group_member_id 	integer references sms_group_members,
	org_id 					integer references orgs,

	message 				text
);
CREATE INDEX group_sms_details_sms_group_id ON group_sms_details (sms_group_id);
CREATE INDEX group_sms_details_sms_group_member_id ON group_sms_details (sms_group_member_id);
CREATE INDEX group_sms_details_org_id ON group_sms_details (org_id);
---===================================================
---               VIEWS
--======================================================

CREATE OR REPLACE VIEW vw_member_sms AS 
	SELECT sms.sms_id, sms.entity_id, sms.org_id, sms.sms_number, sms.sms_time, sms.sent, 
		sms.message, sms.details, sms.folder_id, sms.member_id, members.person_title, members.member_name, 
		members.identification_number, members.identification_type, members.member_email, members.address, 
		members.town, members.zip_code, members.nationality
	FROM members 
		INNER JOIN sms ON members.member_id = sms.member_id;

CREATE OR REPLACE VIEW vw_sms_group_members AS 
SELECT members.person_title, members.member_name, members.member_email, members.telephone_number, sms_group.sms_group_name, 
sms_group_members.sms_group_member_id, sms_group_members.org_id, sms_group_members.member_id, sms_group_members.narrative, 
sms_group_members.details,sms_group_members.sms_group_id
FROM members 
INNER JOIN sms_group_members ON members.member_id = sms_group_members.member_id
INNER JOIN sms_group ON sms_group.sms_group_id = sms_group_members.sms_group_id;

---===================================================
---               FUNCTIONS
--======================================================
----SMS insert trigger
CREATE OR REPLACE FUNCTION ins_sms() RETURNS trigger AS $$
DECLARE
	v_telephone_number 		varchar(20);
	v_member_entity_id 		integer;
	reca 					RECORD;
BEGIN
	
	IF (TG_OP = 'INSERT')THEN		
		--- member sms
		IF((NEW.member_id is not null) AND (NEW.is_groupsms = false) AND (NEW.sms_group_id is null)) THEN
			SELECT telephone_number INTO v_telephone_number
			FROM members
			WHERE member_id = NEW.member_id;

			SELECT entity_id INTO v_member_entity_id
			FROM entitys
			WHERE member_id = NEW.member_id;

			NEW.sms_number := v_telephone_number;
			NEW.entity_id := v_member_entity_id;
			NEW.folder_id := 0;
		END IF;

		-- IF(NEW.is_groupsms = true) THEN
		-- 	----group sms
		-- SELECT sms_group_id, member_id INTO reca
		-- FROM sms_group_members
		-- WHERE sms_group_id = NEW.sms_group_id;
		
		-- 	SELECT telephone_number INTO v_telephone_number
		-- 	FROM members
		-- 	WHERE member_id = reca.member_id;

		-- 	SELECT entity_id INTO v_member_entity_id
		-- 	FROM entitys
		-- 	WHERE member_id = reca.member_id;

		-- 	NEW.sms_number := v_telephone_number;
		-- 	NEW.entity_id := v_member_entity_id;
		-- 	NEW.folder_id := 0;
		-- END IF;

	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_sms BEFORE INSERT OR UPDATE ON sms
    FOR EACH ROW EXECUTE PROCEDURE ins_sms();

-----sms group members
CREATE OR REPLACE FUNCTION ins_sms_group_members() RETURNS trigger AS $$
DECLARE
	v_member_id 		integer;
BEGIN
	
	IF (TG_OP = 'INSERT')THEN
		SELECT member_id INTO v_member_id
		FROM sms_group_members 
		WHERE (org_id = NEW.org_id) AND (member_id = NEW.member_id);

		IF (v_member_id is not null) THEN
			RAISE EXCEPTION 'Member Already Exists in the Group SMS';
		END IF;

	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_sms_group_members BEFORE INSERT OR UPDATE ON sms_group_members
    FOR EACH ROW EXECUTE PROCEDURE ins_sms_group_members();
---SYSTEM SMS 
CREATE OR REPLACE FUNCTION sms_module(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg							varchar(120);
	reca 						RECORD;
	v_org_name					varchar(120);
	v_message 					text;
	v_template 					text;
	
BEGIN
	---sms member login credentials
	IF($3 = '1')THEN
		SELECT members.member_id, members.member_name, members.telephone_number,entitys.entity_id, entitys.user_name, entitys.first_password,entitys.org_id INTO reca
		FROM entitys
		INNER JOIN members ON members.member_id = entitys.member_id
		WHERE entitys.entity_id = $1::int;

		SELECT org_name INTO v_org_name FROM orgs WHERE org_id = reca.org_id;

		SELECT sms_template INTO v_template FROM sms_configs WHERE use_key_id = 300 AND org_id = reca.org_id;

		SELECT (replace(replace(replace(replace(sms_template, ' {{member_name}}', reca.member_name), ' {{user_name}}', reca.user_name), '{{first_password}}', reca.first_password), '{{sacco_name}}', v_org_name)) INTO v_message
		FROM sms_configs WHERE use_key_id = 300 AND org_id = 0;

		---v_message := 'Dear '||reca.member_name||' your username is: '||reca.user_name||' and password: '||reca.first_password|| '  From ' ||v_org_name;

		INSERT INTO sms (folder_id,entity_id, org_id, sms_number, message) VALUES
		(0,reca.entity_id, reca.org_id, reca.telephone_number,v_message);

		msg := 'Login Credentials, SMS Sent... ';
	
	END IF;

	IF($3 = '2')THEN
		UPDATE sms_configs SET is_active = true WHERE sms_config_id = $1::int AND is_active = false;
		msg := 'SMS Module Activated ';	
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;
