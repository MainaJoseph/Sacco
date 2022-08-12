
ALTER TABLE orgs ADD member_limit integer default 100 not null;
--ALTER TABLE orgs ADD accounts_limit integer default 100 not null;
--ALTER TABLE orgs ADD activity_limit integer default 1000 not null;

CREATE TABLE subscriptions (
	subscription_id			serial primary key,
	entity_id				integer references entitys,
	org_id					integer references orgs,

	business_name			varchar(50),
	business_address		varchar(100),
	city					varchar(30),
	number_of_members		float not null,
	country_id				char(2) references sys_countrys,
	telephone				varchar(50),
	website					varchar(120),
	
	primary_contact			varchar(120),
	job_title				varchar(120),
	primary_email			varchar(120),
	confirm_email			varchar(120),

	system_key				varchar(64),
	subscribed				boolean,
	subscribed_date			timestamp,
	
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	application_date		timestamp default now(),
	action_date				timestamp,
	
	details					text
);
CREATE INDEX subscriptions_entity_id ON subscriptions(entity_id);
CREATE INDEX subscriptions_country_id ON subscriptions(country_id);
CREATE INDEX subscriptions_org_id ON subscriptions(org_id);

CREATE TABLE applicants (
	applicant_id			serial primary key,
	member_id				integer references members,
	org_id					integer references orgs,
	business_account		integer default 0 not null,
	
	person_title			varchar(7),
	applicant_name			varchar(150) not null,
	identification_number	varchar(50) not null,
	identification_type		varchar(50) not null,
	
	member_email			varchar(50) not null,
	telephone_number		varchar(20) not null,
	telephone_number2		varchar(20),
	
	address					varchar(50),
	town					varchar(50),
	zip_code				varchar(50),
	
	date_of_birth			date not null,
	gender					varchar(1),
	nationality				char(2) references sys_countrys,
	marital_status 			varchar(2),
	picture_file			varchar(32),

	employed				boolean default true not null,
	self_employed			boolean default false not null,
	employer_name			varchar(120),
	monthly_salary			real,
	monthly_net_income		real,
	
	annual_turnover			real,
	annual_net_income		real,
	
	employer_address		text,
	introduced_by			varchar(100),
	
	entity_id				integer references entitys,
	application_date		timestamp default now() not null,
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,

	details					text,
	
	UNIQUE (org_id, identification_number)
);
CREATE INDEX applicants_member_id ON applicants(member_id);
CREATE INDEX applicants_entity_id ON applicants(entity_id);
CREATE INDEX applicants_org_id ON applicants(org_id);


CREATE VIEW vw_subscriptions AS
	SELECT sys_countrys.sys_country_id, sys_countrys.sys_country_name,
		entitys.entity_id, entitys.entity_name,
		orgs.org_id, orgs.org_name, 
		
		subscriptions.subscription_id, subscriptions.business_name, 
		subscriptions.business_address, subscriptions.city, subscriptions.number_of_members, subscriptions.country_id, 
		subscriptions.telephone, subscriptions.website, subscriptions.primary_contact, subscriptions.job_title, 
		subscriptions.primary_email, subscriptions.approve_status, subscriptions.workflow_table_id, 
		subscriptions.application_date, subscriptions.action_date, 
		subscriptions.system_key, subscriptions.subscribed, subscriptions.subscribed_date,
		subscriptions.details
	FROM subscriptions INNER JOIN sys_countrys ON subscriptions.country_id = sys_countrys.sys_country_id
		LEFT JOIN entitys ON subscriptions.entity_id = entitys.entity_id
		LEFT JOIN orgs ON subscriptions.org_id = orgs.org_id;	
		

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON subscriptions
    FOR EACH ROW EXECUTE PROCEDURE upd_action();
    
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON applicants
    FOR EACH ROW EXECUTE PROCEDURE upd_action();    

CREATE OR REPLACE FUNCTION ins_subscriptions() RETURNS trigger AS $$
DECLARE
	v_entity_id				integer;
	v_entity_type_id		integer;
	v_org_id				integer;
	v_currency_id			integer;
	v_member_id			integer;
	v_account_number		varchar(32);
	v_product_id			integer;
	v_department_id			integer;
	v_bank_id				integer;
	v_deposit_account		integer;
	v_tax_type_id			integer;
	v_workflow_id			integer;
	v_org_suffix			char(2);
	myrec 					RECORD;
BEGIN

	IF (TG_OP = 'INSERT') THEN
		SELECT entity_id INTO v_entity_id
		FROM entitys WHERE lower(trim(user_name)) = lower(trim(NEW.primary_email));

		IF(v_entity_id is null)THEN
			NEW.entity_id := nextval('entitys_entity_id_seq');
			INSERT INTO entitys (entity_id, org_id, use_key_id, entity_type_id, entity_name, User_name, primary_email,  function_role, first_password)
			VALUES (NEW.entity_id, 0, 5, 5, NEW.primary_contact, lower(trim(NEW.primary_email)), lower(trim(NEW.primary_email)), 'subscription', null);
		
			INSERT INTO sys_emailed (sys_email_id, org_id, table_id, table_name)
			VALUES (4, 0, NEW.entity_id, 'subscription');
		
			NEW.approve_status := 'Completed';
		ELSE
			RAISE EXCEPTION 'You already have an account, login and request for services';
		END IF;
	ELSIF(NEW.approve_status = 'Approved')THEN

		NEW.org_id := nextval('orgs_org_id_seq');
		v_member_id := nextval('members_member_id_seq');
		v_deposit_account := nextval('deposit_accounts_deposit_account_id_seq');
		INSERT INTO orgs(org_id, currency_id, org_name, org_full_name, org_sufix, default_country_id, logo)
		VALUES(NEW.org_id, 1, NEW.business_name, NEW.business_name, NEW.org_id, NEW.country_id, 'logo.png');
		----NEW ORG/SACCO ADDRESSES
		INSERT INTO address (address_name, sys_country_id, table_name, table_id, premises, town, phone_number, website, is_default) 
		VALUES (NEW.business_name, NEW.country_id, 'orgs', NEW.org_id, NEW.business_address, NEW.city, NEW.telephone, NEW.website, true);
		--- CURRENCY
		v_currency_id := nextval('currency_currency_id_seq');
		INSERT INTO currency (org_id, currency_id, currency_name, currency_symbol) VALUES (NEW.org_id, v_currency_id, 'Default Currency', 'DC');
		UPDATE orgs SET currency_id = v_currency_id WHERE org_id = NEW.org_id;
		---CURRENCY RATES
		INSERT INTO currency_rates (org_id, currency_id, exchange_rate) VALUES (NEW.org_id, v_currency_id, 1);

		---- ENTITY TYPES
		INSERT INTO entity_types (org_id, entity_type_name, entity_role, use_key_id)
		SELECT NEW.org_id, entity_type_name, entity_role, use_key_id
		FROM entity_types WHERE org_id = 1;

		-----NEXT OF KINS TYPE
		INSERT INTO kin_types (org_id, kin_type_name)
		SELECT NEW.org_id, kin_type_name
		FROM kin_types WHERE org_id = 1;

		---SACCO POSITIONS
		INSERT INTO position_levels (org_id,position_level_name,narrative)
		SELECT NEW.org_id,position_level_name,narrative
		FROM position_levels
		WHERE org_id = 1;

		---SYS SMS CONFIGURATIONS
		INSERT INTO sms_configs(org_id,use_key_id,sms_config_name,is_active,sms_template)
		SELECT NEW.org_id,use_key_id,sms_config_name,is_active,sms_template
		FROM sms_configs
		WHERE org_id = 1;

		---USER LEVELS FOR SACCO
		INSERT INTO sys_access_levels (use_key_id, org_id, sys_access_level_name, access_tag) VALUES
		(0, NEW.org_id, 'Subscription', 'subscription'),
		(0, NEW.org_id, 'admin', 'admin'),
		(1, NEW.org_id, 'Staff', 'staff'),
		(2, NEW.org_id, 'Client', 'client'),
		(4, NEW.org_id, 'Applicants', 'applicant'),
		(100, NEW.org_id, 'Members', 'members'),
		(100, NEW.org_id, 'Service Desk Module', 'service_desk'),

		(0, NEW.org_id, 'Operations Module', 'operations'),
		(0, NEW.org_id, 'configurations Module', 'configurations'),
		(0, NEW.org_id, 'Loans Module', 'loans'),
		(0, NEW.org_id, 'Processing Module', 'processing'),
		(0, NEW.org_id, 'Transaction Module', 'transactions'),
		(0, NEW.org_id, 'Sacco Report Module', 'sacco_reports');

		---ISSUES LEVEL
		INSERT INTO issue_levels(org_id, issue_level_name)
		SELECT NEW.org_id, issue_level_name
		FROM issue_levels
		WHERE org_id = 1;

		---ISSUE TYPES
		INSERT INTO issue_types (org_id, issue_type_name)
		SELECT NEW.org_id, issue_type_name
		FROM issue_types
		WHERE org_id = 1;

		-----LOCATION AND DEPARTMENT DEFAULT DATA
		INSERT INTO locations (org_id, location_name) VALUES (NEW.org_id, 'Head Office');
		INSERT INTO departments (org_id, department_name) VALUES (NEW.org_id, 'Board of Directors');

		----TAX TYPES
		FOR myrec IN SELECT tax_type_id, use_key_id, tax_type_name, formural, tax_relief, 
			tax_type_order, in_tax, linear, percentage, employer, employer_ps, active,
			account_number, employer_account
			FROM tax_types WHERE org_id = 1 AND ((sys_country_id is null) OR (sys_country_id = NEW.country_id))
			ORDER BY tax_type_id 
		LOOP
			v_tax_type_id := nextval('tax_types_tax_type_id_seq');
			INSERT INTO tax_types (org_id, tax_type_id, use_key_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, currency_id, account_number, employer_account)
			VALUES (NEW.org_id, v_tax_type_id, myrec.use_key_id, myrec.tax_type_name, myrec.formural, myrec.tax_relief, myrec.tax_type_order, myrec.in_tax, myrec.linear, myrec.percentage, myrec.employer, myrec.employer_ps, myrec.active, v_currency_id, myrec.account_number, myrec.employer_account);
			
			INSERT INTO tax_rates (org_id, tax_type_id, tax_range, tax_rate)
			SELECT NEW.org_id,  v_tax_type_id, tax_range, tax_rate
			FROM tax_rates
			WHERE org_id = 1 and tax_type_id = myrec.tax_type_id;
		END LOOP;

		------BANKS AND BANK BRANCHS
		v_bank_id := nextval('banks_bank_id_seq');
		INSERT INTO banks (org_id, bank_id, bank_name) VALUES (NEW.org_id, v_bank_id, 'Cash');
		INSERT INTO bank_branch (org_id, bank_id, bank_branch_name) VALUES (NEW.org_id, v_bank_id, 'Cash');

		----TRANSACTION COUNTERS
		INSERT INTO transaction_counters(transaction_type_id, org_id, document_number)
		SELECT transaction_type_id, NEW.org_id, 1
		FROM transaction_types;	
		
		----ACCOUNT CLASSES
		INSERT INTO account_class (org_id, account_class_no, chat_type_id, chat_type_name, account_class_name)
		SELECT NEW.org_id, account_class_no, chat_type_id, chat_type_name, account_class_name
		FROM account_class
		WHERE org_id = 1;
		----ACCOUNT TYPES
		INSERT INTO account_types (org_id, account_class_id, account_type_no, account_type_name)
		SELECT a.org_id, a.account_class_id, b.account_type_no, b.account_type_name
		FROM account_class a INNER JOIN vw_account_types b ON a.account_class_no = b.account_class_no
		WHERE (a.org_id = NEW.org_id) AND (b.org_id = 1);
		----ACCOUNTS
		INSERT INTO accounts (org_id, account_type_id, account_no, account_name)
		SELECT a.org_id, a.account_type_id, b.account_no, b.account_name
		FROM account_types a INNER JOIN vw_accounts b ON a.account_type_no = b.account_type_no
		WHERE (a.org_id = NEW.org_id) AND (b.org_id = 1);
		-----DEFAULT ACCOUNTS
		INSERT INTO default_accounts (org_id, use_key_id, account_id)
		SELECT c.org_id, a.use_key_id, c.account_id
		FROM default_accounts a INNER JOIN accounts b ON a.account_id = b.account_id
			INNER JOIN accounts c ON b.account_no = c.account_no
		WHERE (a.org_id = 1) AND (c.org_id = NEW.org_id);
		---ITEM CATEGORIES
		INSERT INTO item_category (org_id, item_category_name) VALUES (NEW.org_id, 'Services');
		INSERT INTO item_category (org_id, item_category_name) VALUES (NEW.org_id, 'Goods');
		INSERT INTO item_units (org_id, item_unit_name) VALUES (NEW.org_id, 'Each');
		
		SELECT entity_type_id INTO v_entity_type_id
		FROM entity_types 
		WHERE (org_id = NEW.org_id) AND (use_key_id = 0);
				
		UPDATE entitys SET org_id = NEW.org_id, entity_type_id = v_entity_type_id, function_role='subscription,admin,manager'
		WHERE entity_id = NEW.entity_id;
		
		UPDATE entity_subscriptions SET org_id = NEW.org_id, entity_type_id = v_entity_type_id
		WHERE entity_id = NEW.entity_id;
		
		INSERT INTO collateral_types (org_id, collateral_type_name) VALUES (NEW.org_id, 'Property Title Deed');

		---ACCOUNT TYPES
		INSERT INTO activity_types (cr_account_id, dr_account_id, use_key_id, org_id, activity_type_name, is_active, activity_type_no)
		SELECT dra.account_id, cra.account_id, vw_activity_types.use_key_id, NEW.org_id, 
			vw_activity_types.activity_type_name, vw_activity_types.is_active, vw_activity_types.activity_type_no
		FROM vw_activity_types
			INNER JOIN accounts dra ON vw_activity_types.dr_account_no = dra.account_no
			INNER JOIN accounts cra ON vw_activity_types.cr_account_no = cra.account_no
		WHERE (dra.org_id = NEW.org_id) AND (cra.org_id = NEW.org_id) AND (vw_activity_types.org_id = 1)
		ORDER BY vw_activity_types.activity_type_id;
		
		v_account_number := '4' || lpad(NEW.org_id::varchar, 2, '0')  || lpad(v_member_id::varchar, 4, '0');

		INSERT INTO interest_methods (activity_type_id, org_id, interest_method_name, reducing_balance, reducing_payments, formural, interest_method_no, account_number)
		SELECT oa.activity_type_id, oa.org_id, interest_methods.interest_method_name, 
			interest_methods.reducing_balance, interest_methods.reducing_payments, 
			interest_methods.formural, interest_methods.interest_method_no,
			v_account_number || lpad((v_deposit_account + 3)::varchar, 2, '0') 
		FROM interest_methods INNER JOIN activity_types ON interest_methods.activity_type_id = activity_types.activity_type_id
			INNER JOIN activity_types oa ON activity_types.activity_type_no = oa.activity_type_no
		WHERE (activity_types.org_id = 1) AND (oa.org_id = NEW.org_id)
		ORDER BY interest_methods.interest_method_id;

		---PENALTY METHODS
		INSERT INTO penalty_methods(activity_type_id, org_id, penalty_method_name, formural, penalty_method_no, account_number)
		SELECT oa.activity_type_id, oa.org_id, penalty_methods.penalty_method_name, 
			penalty_methods.formural, penalty_methods.penalty_method_no,
			v_account_number || lpad((v_deposit_account + 4)::varchar, 2, '0') 
		FROM penalty_methods INNER JOIN activity_types ON penalty_methods.activity_type_id = activity_types.activity_type_id
			INNER JOIN activity_types oa ON activity_types.activity_type_no = oa.activity_type_no
		WHERE (activity_types.org_id = 1) AND (oa.org_id = NEW.org_id)
		ORDER BY penalty_methods.penalty_method_id;

		---PRODUCTS
		INSERT INTO products(interest_method_id, penalty_method_id, activity_frequency_id, 
			currency_id, org_id, product_name, description, loan_account, 
			is_active, interest_rate, min_opening_balance, lockin_period_frequency, 
			minimum_balance, maximum_balance, minimum_day, maximum_day, minimum_trx, 
			maximum_trx, maximum_repayments, product_no,  approve_status)
		SELECT interest_methods.interest_method_id, penalty_methods.penalty_method_id, vw_products.activity_frequency_id, 
			v_currency_id, NEW.org_id, vw_products.product_name, vw_products.description, vw_products.loan_account, 
			vw_products.is_active, vw_products.interest_rate, vw_products.min_opening_balance, vw_products.lockin_period_frequency, 
			vw_products.minimum_balance, vw_products.maximum_balance, vw_products.minimum_day, vw_products.maximum_day, vw_products.minimum_trx, 
			vw_products.maximum_trx, vw_products.maximum_repayments, vw_products.product_no, vw_products.approve_status
		FROM vw_products INNER JOIN interest_methods ON vw_products.interest_method_no = interest_methods.interest_method_no
			INNER JOIN penalty_methods ON vw_products.penalty_method_no = penalty_methods.penalty_method_no
		WHERE (vw_products.org_id = 1) 
			AND (interest_methods.org_id = NEW.org_id) AND (penalty_methods.org_id = NEW.org_id)
		ORDER BY vw_products.product_id;
		
		---ACCOUNT DEFINATIONS
		INSERT INTO account_definations(product_id, activity_type_id, charge_activity_id, 
			activity_frequency_id, org_id, account_defination_name, start_date, 
			end_date, fee_amount, fee_ps, has_charge, is_active, account_number)
		SELECT products.product_id, activity_types.activity_type_id, charge_activity.activity_type_id, 
			ad.activity_frequency_id, NEW.org_id, ad.account_defination_name, 
			ad.start_date, ad.end_date, ad.fee_amount, 
			ad.fee_ps, ad.has_charge, ad.is_active, 
			v_account_number || lpad((v_deposit_account + ad.account_number::integer)::varchar, 2, '0')
		FROM vw_account_definations as ad INNER JOIN products ON ad.product_no = products.product_no
			INNER JOIN activity_types ON ad.activity_type_no = activity_types.activity_type_no
			INNER JOIN activity_types as charge_activity ON ad.charge_activity_no = charge_activity.activity_type_no
		WHERE (ad.org_id = 1) 
			AND (products.org_id = NEW.org_id) AND (activity_types.org_id = NEW.org_id) AND (charge_activity.org_id = NEW.org_id);

		SELECT product_id INTO v_product_id
		FROM products WHERE (product_no = 0) AND (org_id = NEW.org_id);
		
		INSERT INTO members (member_id, org_id, business_account, member_name, identification_number, identification_type, member_email, telephone_number, date_of_birth, nationality, approve_status)
		VALUES (v_member_id, NEW.org_id, 2, NEW.business_name, '0', 'Org', NEW.primary_email, NEW.telephone, current_date, NEW.country_id, 'Approved');

		INSERT INTO deposit_accounts (member_id, product_id, org_id, is_active, approve_status, narrative, minimum_balance) VALUES 
		(v_member_id, v_product_id, NEW.org_id, true, 'Approved', 'Deposits', -100000000000),
		(v_member_id, v_product_id, NEW.org_id, true, 'Approved', 'Charges', -100000000000),
		(v_member_id, v_product_id, NEW.org_id, true, 'Approved', 'Interest', -100000000000),
		(v_member_id, v_product_id, NEW.org_id, true, 'Approved', 'Penalty', -100000000000),
		(v_member_id, v_product_id, NEW.org_id, true, 'Approved', 'Shares', -100000000000);
		
		INSERT INTO workflows (link_copy, org_id, source_entity_id, workflow_name, table_name, approve_email, reject_email) 
		SELECT aa.workflow_id, cc.org_id, cc.entity_type_id, aa.workflow_name, aa.table_name, aa.approve_email, aa.reject_email
		FROM workflows aa INNER JOIN entity_types bb ON aa.source_entity_id = bb.entity_type_id
			INNER JOIN entity_types cc ON bb.use_key_id = cc.use_key_id
		WHERE aa.org_id = 1 AND cc.org_id = NEW.org_id
		ORDER BY aa.workflow_id;

		INSERT INTO workflow_phases (org_id, workflow_id, approval_entity_id, approval_level, return_level, 
			escalation_days, escalation_hours, required_approvals, advice, notice, 
			phase_narrative, advice_email, notice_email) 
		SELECT bb.org_id, bb.workflow_id, dd.entity_type_id, aa.approval_level, aa.return_level, 
			aa.escalation_days, aa.escalation_hours, aa.required_approvals, aa.advice, aa.notice, 
			aa.phase_narrative, aa.advice_email, aa.notice_email
		FROM workflow_phases aa INNER JOIN workflows bb ON aa.workflow_id = bb.link_copy
			INNER JOIN entity_types cc ON aa.approval_entity_id = cc.entity_type_id
			INNER JOIN entity_types dd ON cc.use_key_id = dd.use_key_id
		WHERE aa.org_id = 1 AND bb.org_id = NEW.org_id AND dd.org_id = NEW.org_id;
		
		INSERT INTO sys_emails (org_id, use_type, sys_email_name, title, details)
		SELECT NEW.org_id, use_type, sys_email_name, title, details
		FROM sys_emails
		WHERE org_id = 1;

		INSERT INTO sys_emailed (sys_email_id, org_id, table_id, table_name)
		VALUES (5, NEW.org_id, NEW.entity_id, 'subscription');
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_subscriptions BEFORE INSERT OR UPDATE ON subscriptions
    FOR EACH ROW EXECUTE PROCEDURE ins_subscriptions();
    
    
CREATE OR REPLACE FUNCTION ins_applicants() RETURNS trigger AS $$
DECLARE
	v_member_id			integer;
BEGIN

	IF (TG_OP = 'INSERT') THEN
		NEW.approve_status := 'Completed';
	ELSIF(NEW.approve_status = 'Approved')THEN
		SELECT member_id INTO v_member_id
		FROM members WHERE (identification_number = NEW.identification_number);
		
		IF(v_member_id is null)THEN
			v_member_id := nextval('members_member_id_seq');
			INSERT INTO members(member_id, org_id, business_account, person_title, 
				member_name, identification_number, identification_type, member_email, 
				telephone_number, telephone_number2, address, town, zip_code, 
				date_of_birth, gender, nationality, marital_status, picture_file, 
				employed, self_employed, employer_name, employer_address, introduced_by,
				details)
			VALUES (v_member_id, NEW.org_id, NEW.business_account, NEW.person_title, 
				NEW.member_name, NEW.identification_number, NEW.identification_type, NEW.member_email, 
				NEW.telephone_number, NEW.telephone_number2, NEW.address, NEW.town, NEW.zip_code, 
				NEW.date_of_birth, NEW.gender, NEW.nationality, NEW.marital_status, NEW.picture_file, 
				NEW.employed, NEW.self_employed, NEW.employer_name, NEW.employer_address, NEW.introduced_by,
				NEW.details);
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_applicants BEFORE INSERT OR UPDATE ON applicants
    FOR EACH ROW EXECUTE PROCEDURE ins_applicants();


-- CREATE OR REPLACE FUNCTION ins_accounts_limit() RETURNS trigger AS $$
-- DECLARE
-- 	v_deposit_accounts		integer;
-- 	v_accounts_limit		integer;
-- BEGIN

-- 	SELECT count(deposit_account_id) INTO v_deposit_accounts
-- 	FROM deposit_accounts
-- 	WHERE (org_id = NEW.org_id);
	
-- 	SELECT accounts_limit INTO v_accounts_limit
-- 	FROM orgs
-- 	WHERE (org_id = NEW.org_id);
	
-- 	IF(v_deposit_accounts > v_accounts_limit)THEN
-- 		RAISE EXCEPTION 'You have reached the maximum staff limit, request for a quite for more';
-- 	END IF;

-- 	RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER ins_accounts_limit BEFORE INSERT ON deposit_accounts
--     FOR EACH ROW EXECUTE PROCEDURE ins_accounts_limit();

	
-- CREATE OR REPLACE FUNCTION ins_activity_limit() RETURNS trigger AS $$
-- DECLARE
-- 	v_account_activitys			integer;
-- 	v_activity_limit			integer;
-- BEGIN

-- 	SELECT count(account_activity_id) INTO v_account_activitys
-- 	FROM account_activity
-- 	WHERE (org_id = NEW.org_id);
	
-- 	SELECT activity_limit INTO v_activity_limit
-- 	FROM orgs
-- 	WHERE (org_id = NEW.org_id);
	
-- 	IF(v_account_activitys > v_activity_limit)THEN
-- 		RAISE EXCEPTION 'You have reached the maximum transaction limit, request for a quite for more';
-- 	END IF;

-- 	RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER ins_activity_limit BEFORE INSERT ON account_activity
--     FOR EACH ROW EXECUTE PROCEDURE ins_activity_limit();


CREATE OR REPLACE FUNCTION ins_member_limit() RETURNS trigger AS $$
DECLARE
	v_member_count			integer;
	v_member_limit			integer;
BEGIN

	SELECT count(member_id) INTO v_member_count
	FROM members
	WHERE (org_id = NEW.org_id);
	
	SELECT member_limit INTO v_member_limit
	FROM orgs
	WHERE (org_id = NEW.org_id);
	
	IF(v_member_count > v_member_limit)THEN
		RAISE EXCEPTION 'You have reached the maximum transaction limit, request for a quite for more';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_member_limit BEFORE INSERT ON members
    FOR EACH ROW EXECUTE PROCEDURE ins_member_limit();
