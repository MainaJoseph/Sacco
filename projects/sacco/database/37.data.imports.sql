------- sacco data imports
---MEMBERS DATA IMPORT
CREATE TABLE member_imports (
	member_import_id			serial primary key,
	org_id						varchar(150),
	entity_id 					varchar(150),
	
	person_title				varchar(150),
	member_name					varchar(150),
	identification_number		varchar(150),
	identification_type			varchar(150),	
	member_email				varchar(150),
	telephone_number			varchar(120),	
	
	date_of_birth				varchar(150),
	gender						varchar(100),
	marital_status 				varchar(102),

	entry_date   				varchar(150),
	address						varchar(150),
	zip_code					varchar(150),
	town						varchar(150)	
);

----  member imports
CREATE OR REPLACE FUNCTION member_imports(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg							varchar(120);
	
BEGIN
	---- deleting member import record
	IF($3 = '1')THEN
		DELETE FROM member_imports WHERE member_import_id = $1::integer;
		msg := 'Import Record Deleted';	
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

----MEMBER IMPORT TRIGGER BOFORE INSERT OR UPDATE	
CREATE OR REPLACE FUNCTION ins_member_imports() RETURNS trigger AS $$
DECLARE
	msg			RECORD;

BEGIN

	IF((TG_OP = 'INSERT'))THEN
		UPDATE member_imports SET org_id = NEW.org_id;		
	END IF;
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_member_imports AFTER INSERT ON member_imports
	FOR EACH ROW EXECUTE PROCEDURE ins_member_imports();
