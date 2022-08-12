---Project Database File
---locations table
CREATE TABLE locations ( 
	location_id				serial primary key,
	org_id					integer references orgs,
	location_name			varchar(50),
	details					text
);
CREATE INDEX locations_org_id ON locations(org_id);

---members table
CREATE TABLE members (
	member_id					serial primary key,
	entity_id 					integer references entitys,
	org_id						integer references orgs,
	business_account			integer default 0 not null,
	
	person_title				varchar(7),
	member_name					varchar(150) not null,
	identification_number		varchar(50) not null,
	identification_type			varchar(50) not null,
	
	member_email				varchar(50) not null,
	telephone_number			varchar(20) not null,
	telephone_number2			varchar(20),
	
	address						varchar(50),
	town						varchar(50),
	zip_code					varchar(50),
	
	date_of_birth				date not null,
	gender						varchar(1),
	nationality					char(2) references sys_countrys,
	marital_status 				varchar(2),
	picture_file				varchar(32),

	entry_date   				date default now(),

	employed					boolean default true not null,
	self_employed				boolean default false not null,
	employer_name				varchar(120),
	monthly_salary				real,
	monthly_net_income			real,	
	annual_turnover				real,
	annual_net_income			real,
	
	employer_address			text,
	introduced_by				varchar(100),

	is_active					boolean default true not null,
	
	terminated					boolean default false not null,
	terminate_date				timestamp,
	terminate_status			varchar(100) default 'N/A' not null,
	terminate_application_date 	timestamp,
	
	application_date			timestamp default now() not null,
	approve_status				varchar(16) default 'Draft' not null,
	workflow_table_id			integer,
	action_date					timestamp,

	details						text,
	
	UNIQUE (org_id, identification_number)
);
CREATE INDEX members_entity_id ON members(entity_id);
CREATE INDEX members_org_id ON members(org_id);

----entitys
ALTER TABLE entitys ADD 	member_id		integer references members;
CREATE INDEX entitys_member_id ON entitys(member_id);


---commodity types table
CREATE TABLE commodity_types (
	commodity_type_id		serial primary key,
	org_id					integer references orgs,
	commodity_type_name		varchar(50) not null,
	details					text,
	
	UNIQUE(org_id, commodity_type_name)
);
CREATE INDEX commodity_types_org_id ON commodity_types(org_id);

---commoditys table
CREATE TABLE commoditys (
	commodity_id			serial primary key,
	commodity_type_id		integer references commodity_types,
	org_id					integer references orgs,
	commodity_name			varchar(50) not null,
	commodity_account		varchar(32) not null,
	current_price			real default 0 not null,
	details					text,
	
	UNIQUE(org_id, commodity_name)
);
CREATE INDEX commoditys_commodity_type_id ON commoditys(commodity_type_id);
CREATE INDEX commoditys_org_id ON commoditys(org_id);

---activity frequency reference table
CREATE TABLE activity_frequency (
	activity_frequency_id	integer primary key,
	activity_frequency_name	varchar(50) not null unique
);

---activity status reference table
CREATE TABLE activity_status (
	activity_status_id		integer primary key,
	activity_status_name	varchar(50) not null unique
);

---activity types table
CREATE TABLE activity_types (
	activity_type_id		serial primary key,
	dr_account_id			integer not null references accounts,
	cr_account_id			integer not null references accounts,
	use_key_id				integer not null references use_keys,
	org_id					integer references orgs,
	activity_type_name		varchar(120) not null,
	is_active				boolean default true not null,
	activity_type_no		integer,
	details					text,
	UNIQUE(org_id, activity_type_name)
);
CREATE INDEX activity_types_dr_account_id ON activity_types(dr_account_id);
CREATE INDEX activity_types_cr_account_id ON activity_types(cr_account_id);
CREATE INDEX activity_types_use_key_id ON activity_types(use_key_id);
CREATE INDEX activity_types_org_id ON activity_types(org_id);

---interest methods table
CREATE TABLE interest_methods (
	interest_method_id		serial primary key,
	activity_type_id		integer not null references activity_types,
	org_id					integer references orgs,
	interest_method_name	varchar(120) not null,
	reducing_balance		boolean not null default false,
	reducing_payments		boolean not null default false,
	formural				varchar(320),
	account_number			varchar(32),
	interest_method_no		integer,
	details					text,
	UNIQUE(org_id, interest_method_name)
);
CREATE INDEX interest_methods_activity_type_id ON interest_methods(activity_type_id);
CREATE INDEX interest_methods_org_id ON interest_methods(org_id);

---penalty methods table
CREATE TABLE penalty_methods (
	penalty_method_id		serial primary key,
	activity_type_id		integer not null references activity_types,
	org_id					integer references orgs,
	penalty_method_name		varchar(120) not null,
	formural				varchar(320),
	account_number			varchar(32),
	penalty_method_no		integer,
	details					text,
	UNIQUE(org_id, penalty_method_name)
);
CREATE INDEX penalty_methods_activity_type_id ON penalty_methods(activity_type_id);
CREATE INDEX penalty_methods_org_id ON penalty_methods(org_id);

--- products table
CREATE TABLE products (
	product_id				serial primary key,
	interest_method_id 		integer references interest_methods,
	penalty_method_id		integer references penalty_methods,
	activity_frequency_id	integer references activity_frequency,
	currency_id				integer references currency,
	entity_id 				integer references entitys,
	org_id					integer references orgs,
	product_name			varchar(120) not null,
	description				varchar(320),
	loan_account			boolean default true not null,
	is_active				boolean default true not null,
	
	interest_rate			real not null,
	min_opening_balance		real default 0 not null,
	lockin_period_frequency real,
	minimum_balance			real,
	maximum_balance			real,
	minimum_day				real,
	maximum_day				real,
	minimum_trx				real,
	maximum_trx				real,
	maximum_repayments		integer default 100 not null,
	less_initial_fee		boolean default false not null,
	product_no				integer,
	
	application_date		timestamp default now() not null,
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	
	details					text,
	UNIQUE(org_id, product_name)
);
CREATE INDEX products_interest_method_id ON products(interest_method_id);
CREATE INDEX products_activity_frequency_id ON products(activity_frequency_id);
CREATE INDEX products_currency_id ON products(currency_id);
CREATE INDEX products_entity_id ON products(entity_id);
CREATE INDEX products_org_id ON products(org_id);

---account definations table
CREATE TABLE account_definations (
	account_defination_id	serial primary key,
	product_id 				integer not null references products,
	activity_type_id		integer not null references activity_types,
	charge_activity_id		integer not null references activity_types,
	activity_frequency_id	integer not null references activity_frequency,
	org_id					integer references orgs,
	account_defination_name	varchar(50) not null,
	start_date				date not null,
	end_date				date,
	fee_amount				real default 0 not null,
	fee_ps					real default 0 not null,
	has_charge				boolean default false not null,
	is_active				boolean default false not null,
	account_number			varchar(32) not null,
	details					text,
	
	UNIQUE(product_id, activity_type_id)
);
CREATE INDEX account_definations_product_id ON account_definations(product_id);
CREATE INDEX account_definations_activity_type_id ON account_definations(activity_type_id);
CREATE INDEX account_definations_charge_activity_id ON account_definations(charge_activity_id);
CREATE INDEX account_definations_activity_frequency_id ON account_definations(activity_frequency_id);
CREATE INDEX account_definations_org_id ON account_definations(org_id);

---deposit accounts table
CREATE TABLE deposit_accounts (
	deposit_account_id		serial primary key,
	member_id				integer references members,
	product_id 				integer references products,
	activity_frequency_id	integer references activity_frequency,
	entity_id 				integer references entitys,
	org_id					integer references orgs,

	is_active				boolean default false not null,
	account_number			varchar(32) not null unique,
	narrative				varchar(120),
	opening_date			date default current_date not null,
	last_closing_date		date,
	
	credit_limit			real,
	minimum_balance			real,
	maximum_balance			real,
	
	interest_rate			real not null,
	lockin_period_frequency	real,
	lockedin_until_date		date,

	application_date		timestamp default now() not null,
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	
	details					text
);
CREATE INDEX deposit_accounts_member_id ON deposit_accounts(member_id);
CREATE INDEX deposit_accounts_product_id ON deposit_accounts(product_id);
CREATE INDEX deposit_accounts_activity_frequency_id ON deposit_accounts(activity_frequency_id);
CREATE INDEX deposit_accounts_entity_id ON deposit_accounts(entity_id);
CREATE INDEX deposit_accounts_org_id ON deposit_accounts(org_id);

---accounts notes table
CREATE TABLE account_notes (
	account_note_id			serial primary key,
	deposit_account_id		integer references deposit_accounts,
	org_id					integer references orgs,
	comment_date			timestamp default now() not null,
	narrative				varchar(320) not null,
	note					text not null
);
CREATE INDEX account_notes_deposit_account_id ON account_notes(deposit_account_id);
CREATE INDEX account_notes_org_id ON account_notes(org_id);

---beneficiary transfer table
CREATE TABLE transfer_beneficiary (
	transfer_beneficiary_id	serial primary key,
	member_id				integer references members,
	deposit_account_id		integer references deposit_accounts,
	entity_id 				integer references entitys,
	org_id					integer references orgs,
	
	beneficiary_name		varchar(150) not null,
	account_number			varchar(32) not null,
	allow_transfer			boolean default true not null,
	
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,	
	
	details					text,
	
	UNIQUE(member_id, deposit_account_id)
);
CREATE INDEX transfer_beneficiary_member_id ON transfer_beneficiary(member_id);
CREATE INDEX transfer_beneficiary_deposit_account_id ON transfer_beneficiary(deposit_account_id);
CREATE INDEX transfer_beneficiary_entity_id ON transfer_beneficiary(entity_id);
CREATE INDEX transfer_beneficiary_org_id ON transfer_beneficiary(org_id);

---commodity trade table
CREATE TABLE commodity_trades (
	commodity_trade_id		serial primary key,
	deposit_account_id		integer references deposit_accounts,
	transfer_account_id		integer references deposit_accounts,
	commodity_id			integer references commoditys,
	entity_id				integer references entitys,
	use_key_id				integer not null references use_keys,
	org_id					integer references orgs,

	transfer_account_no		varchar(32),
	link_activity_id		integer not null,
	unit_debit				real default 0 not null,
	unit_credit				real default 0 not null,
	price					real default 0 not null,
	trade_date				date not null,

	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,

	details					text
);
CREATE INDEX commodity_trades_deposit_account_id ON commodity_trades(deposit_account_id);
CREATE INDEX commodity_trades_transfer_account_id ON commodity_trades(transfer_account_id);
CREATE INDEX commodity_trades_commodity_id ON commodity_trades(commodity_id);
CREATE INDEX commodity_trades_entity_id ON commodity_trades(entity_id);
CREATE INDEX commodity_trades_use_key_id ON commodity_trades(use_key_id);
CREATE INDEX commodity_trades_org_id ON commodity_trades(org_id);

---account activity table
CREATE TABLE account_activity (
	account_activity_id		serial primary key,
	deposit_account_id		integer references deposit_accounts,
	transfer_account_id		integer references deposit_accounts,
	activity_type_id		integer references activity_types,
	activity_frequency_id	integer references activity_frequency,
	activity_status_id		integer references activity_status,
	commodity_trade_id		integer references commodity_trades,
	period_id				integer references periods,
	entity_id 				integer references entitys,
	org_id					integer references orgs,
	
	link_activity_id		integer not null,
	transfer_link_id		integer,
	deposit_account_no		varchar(32),
	transfer_account_no		varchar(32),
	activity_date			date default current_date not null,
	value_date				date not null,
	
	account_credit			real default 0 not null,
	account_debit			real default 0 not null,
	balance					real not null,
	exchange_rate			real default 1 not null,
	
	invert_rate				boolean default false not null,
	trading_rate			real default 1 not null,
	mean_rate				real default 1 not null,
	
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	
	details					text
);
CREATE INDEX account_activity_deposit_account_id ON account_activity(deposit_account_id);
CREATE INDEX account_activity_transfer_account_id ON account_activity(transfer_account_id);
CREATE INDEX account_activity_activity_frequency_id ON account_activity(activity_frequency_id);
CREATE INDEX account_activity_activity_status_id ON account_activity(activity_status_id);
CREATE INDEX account_activity_activity_type_id ON account_activity(activity_type_id);
CREATE INDEX account_activity_link_activity_id ON account_activity(link_activity_id);
CREATE INDEX account_activity_entity_id ON account_activity(entity_id);
CREATE INDEX account_activity_org_id ON account_activity(org_id);

CREATE SEQUENCE link_activity_id_seq START 101;

ALTER TABLE gls ADD account_activity_id		integer references account_activity;
CREATE INDEX gls_account_activity_id ON gls (account_activity_id);

---transfer activity table
CREATE TABLE transfer_activity (
	transfer_activity_id	serial primary key,
	transfer_beneficiary_id	integer references transfer_beneficiary,
	deposit_account_id		integer references deposit_accounts,
	activity_type_id		integer references activity_types,
	activity_frequency_id	integer references activity_frequency,
	entity_id 				integer references entitys,
	account_activity_id		integer references account_activity,
	org_id					integer references orgs,
	
	transfer_amount			real not null,
	
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	
	details					text
);
CREATE INDEX transfer_activity_transfer_beneficiary_id ON transfer_activity(transfer_beneficiary_id);
CREATE INDEX transfer_activity_deposit_account_id ON transfer_activity(deposit_account_id);
CREATE INDEX transfer_activity_activity_type_id ON transfer_activity(activity_type_id);
CREATE INDEX transfer_activity_activity_frequency_id ON transfer_activity(activity_frequency_id);
CREATE INDEX transfer_activity_entity_id ON transfer_activity(entity_id);
CREATE INDEX transfer_activity_account_activity_id ON transfer_activity(account_activity_id);
CREATE INDEX transfer_activity_org_id ON transfer_activity(org_id);

---block chains table
CREATE TABLE block_chains (
	block_chain_id			serial primary key,
	org_id					integer references orgs,
	link_activity_id		integer not null,
	block_data				text,
	block_hash				text,
	previous_hash			text
);
CREATE INDEX block_chains_org_id ON block_chains(org_id);


---mpesa transaction table
CREATE TABLE mpesa_trxs (
	mpesa_trx_id			serial primary key,
	org_id					integer references orgs,
	mpesa_id				integer,
	mpesa_orig				varchar(50),
	mpesa_dest				varchar(50),
	mpesa_tstamp			timestamp,
	mpesa_text				varchar(320),
	mpesa_code				varchar(50),
	mpesa_acc				varchar(50),
	mpesa_msisdn			varchar(50),
	mpesa_trx_date			date,
	mpesa_trx_time			time,
	mpesa_amt				real,
	mpesa_sender			varchar(50),
	mpesa_pick_time			timestamp default now()
);
CREATE INDEX mpesa_trxs_org_id ON mpesa_trxs (org_id);

---mpesa api table
CREATE TABLE mpesa_api (
	mpesa_api_id			serial primary key,
	org_id					integer references orgs,
	TransactionType			varchar(32),
	TransID					varchar(32),
	TransTime				varchar(16),
	TransAmount				real,
	BusinessShortCode		varchar(16),
	BillRefNumber			varchar(64),
	InvoiceNumber			varchar(64),
	OrgAccountBalance		real,
	ThirdPartyTransID		varchar(64),
	MSISDN					varchar(16),
	FirstName				varchar(64),
	MiddleName 				varchar(64),
	LastName				varchar(64),
	TransactionTime			timestamp,

	created					timestamp default current_timestamp not null,
	narrative				varchar(240),
	in_words				varchar(320),
	is_picked				boolean,
	picked_account			varchar(64)
);
CREATE INDEX mpesa_api_org_id ON mpesa_api (org_id);

---kin types table
CREATE TABLE kin_types (
	kin_type_id				serial primary key,
	org_id					integer references orgs,
	spouse					boolean default false not null,
	kin_type_name			varchar(50),
	details					text
);
CREATE INDEX kin_types_org_id ON kin_types(org_id);

---next of kin table
CREATE TABLE kins (
	kin_id					serial primary key,
	member_id				integer references members,
	kin_type_id				integer references kin_types,
	org_id					integer references orgs,
	full_names				varchar(120),
	date_of_birth			date,
	identification			varchar(50),
	identification_type		varchar(50),
	emergency_contact		boolean default false not null,
	beneficiary				boolean default false not null,
	beneficiary_ps			real,
	details					text,

	UNIQUE (org_id, identification)
);
CREATE INDEX kins_member_id ON kins (member_id);
CREATE INDEX kins_kin_type_id ON kins (kin_type_id);
CREATE INDEX kins_org_id ON kins(org_id);

--===========================New updates=========================================
-----SACCO OFFICIALS
CREATE TABLE position_levels (
	position_level_id 		serial primary key,
	org_id 					integer references orgs,

	position_level_name 	varchar(150) not null,

	narrative 				varchar(225),
	details 				text
);
CREATE INDEX position_levels_org_id ON position_levels (org_id);

---SACCO OFFICILAS
CREATE TABLE sacco_officials (
	sacco_official_id 		serial primary key,
	position_level_id 		integer references position_levels,
	org_id 					integer references orgs,
	member_id 				integer references members,

	start_date 				date not null,
	end_date 				date,
	term_limit 				integer,
	is_active 				boolean default true not null,

	narrative 				varchar(225),
	details 				text
);
CREATE INDEX sacco_officials_position_level_id ON sacco_officials (position_level_id);
CREATE INDEX sacco_officials_org_id ON sacco_officials (org_id);
CREATE INDEX sacco_officials_member_id ON sacco_officials (member_id);


---SACCO OFFICIALS VIEW
CREATE OR REPLACE VIEW vw_sacco_officials AS
	SELECT position_levels.position_level_name,sacco_officials.sacco_official_id,sacco_officials.position_level_id,
	sacco_officials.org_id,sacco_officials.member_id,sacco_officials.start_date,sacco_officials.end_date,
	sacco_officials.term_limit,sacco_officials.is_active,sacco_officials.narrative,sacco_officials.details,

	members.member_name,members.identification_number,members.identification_type,members.member_email,
	members.telephone_number,members.telephone_number2,members.address,members.town,members.zip_code,entitys.entity_id
		FROM sacco_officials
			INNER JOIN position_levels ON position_levels.position_level_id = sacco_officials.position_level_id
			INNER JOIN members ON members.member_id = sacco_officials.member_id
			INNER JOIN entitys ON entitys.member_id = sacco_officials.member_id;

---===========================================================================================
---VIEWS

CREATE OR REPLACE VIEW vw_commoditys AS
	SELECT commodity_types.commodity_type_id, commodity_types.commodity_type_name,
		orgs.org_id, orgs.org_name,orgs.letter_head,
		commoditys.commodity_id, commoditys.commodity_name, commoditys.commodity_account, 
		commoditys.current_price, commoditys.details
	FROM commoditys INNER JOIN commodity_types ON commoditys.commodity_type_id = commodity_types.commodity_type_id
		INNER JOIN orgs ON commoditys.org_id = orgs.org_id;

CREATE OR REPLACE VIEW vw_activity_types AS
	SELECT orgs.org_name,orgs.letter_head,activity_types.dr_account_id, dra.account_no as dr_account_no, 
		dra.account_name as dr_account_name,activity_types.cr_account_id, cra.account_no as cr_account_no, 
		cra.account_name as cr_account_name,use_keys.use_key_id, use_keys.use_key_name, 
		activity_types.org_id, activity_types.activity_type_id, activity_types.activity_type_name, 
		activity_types.is_active, activity_types.activity_type_no, activity_types.details
	FROM activity_types INNER JOIN vw_accounts dra ON activity_types.dr_account_id = dra.account_id
		INNER JOIN vw_accounts cra ON activity_types.cr_account_id = cra.account_id
		INNER JOIN use_keys ON activity_types.use_key_id = use_keys.use_key_id
		INNER JOIN orgs ON activity_types.org_id = orgs.org_id;
		
CREATE OR REPLACE VIEW vw_interest_methods AS
	SELECT activity_types.activity_type_id, activity_types.activity_type_name, activity_types.use_key_id,
		interest_methods.org_id, interest_methods.interest_method_id, interest_methods.interest_method_name, 
		interest_methods.reducing_balance, interest_methods.formural, interest_methods.account_number, 
		interest_methods.interest_method_no, interest_methods.details,orgs.org_name,orgs.letter_head
	FROM interest_methods 
		INNER JOIN activity_types ON interest_methods.activity_type_id = activity_types.activity_type_id
		INNER JOIN orgs ON interest_methods.org_id = orgs.org_id;
	
CREATE OR REPLACE VIEW vw_penalty_methods AS
	SELECT activity_types.activity_type_id, activity_types.activity_type_name, activity_types.use_key_id,
		penalty_methods.org_id, penalty_methods.penalty_method_id, penalty_methods.penalty_method_name, 
		penalty_methods.formural, penalty_methods.account_number, penalty_methods.penalty_method_no,
		penalty_methods.details,orgs.org_name,orgs.letter_head
	FROM penalty_methods 
		INNER JOIN activity_types ON penalty_methods.activity_type_id = activity_types.activity_type_id
		INNER JOIN orgs ON penalty_methods.org_id = orgs.org_id;

CREATE OR REPLACE VIEW vw_products AS
	SELECT activity_frequency.activity_frequency_id, activity_frequency.activity_frequency_name, 
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		vw_interest_methods.interest_method_id, vw_interest_methods.interest_method_name, 
		vw_interest_methods.reducing_balance, vw_interest_methods.interest_method_no,
		penalty_methods.penalty_method_id, penalty_methods.penalty_method_name, penalty_methods.penalty_method_no,
		products.org_id, products.product_id, products.product_name, products.description, 
		products.loan_account, products.is_active, products.interest_rate, 
		products.min_opening_balance, products.lockin_period_frequency, 
		products.minimum_balance, products.maximum_balance, products.minimum_day, products.maximum_day,
		products.minimum_trx, products.maximum_trx, products.maximum_repayments, products.product_no, 
		products.application_date, products.approve_status, products.workflow_table_id, products.action_date,
		products.details, vw_interest_methods.org_name,vw_interest_methods.letter_head
	FROM products INNER JOIN activity_frequency ON products.activity_frequency_id = activity_frequency.activity_frequency_id
		INNER JOIN currency ON products.currency_id = currency.currency_id
		INNER JOIN vw_interest_methods ON products.interest_method_id = vw_interest_methods.interest_method_id
		INNER JOIN penalty_methods ON products.penalty_method_id = penalty_methods.penalty_method_id;

CREATE OR REPLACE VIEW vw_account_definations AS
	SELECT products.product_id, products.product_name, products.product_no,
		vw_activity_types.activity_type_id, vw_activity_types.activity_type_name, vw_activity_types.activity_type_no,
		vw_activity_types.use_key_id, vw_activity_types.use_key_name,
		account_definations.charge_activity_id, charge_activitys.activity_type_name as charge_activity_name,
		charge_activitys.activity_type_no as charge_activity_no,
		activity_frequency.activity_frequency_id, activity_frequency.activity_frequency_name, 
		account_definations.org_id, account_definations.account_defination_id, account_definations.account_defination_name, 
		account_definations.start_date, account_definations.end_date, account_definations.is_active, 
		account_definations.account_number, account_definations.fee_amount, account_definations.fee_ps, 
		account_definations.has_charge, account_definations.details
	FROM account_definations INNER JOIN vw_activity_types ON account_definations.activity_type_id = vw_activity_types.activity_type_id
		INNER JOIN products ON account_definations.product_id = products.product_id
		INNER JOIN activity_frequency ON account_definations.activity_frequency_id = activity_frequency.activity_frequency_id
		LEFT JOIN activity_types charge_activitys ON account_definations.charge_activity_id = charge_activitys.activity_type_id;

CREATE OR REPLACE VIEW vw_deposit_balance AS
	SELECT cb.deposit_account_id, cb.current_balance, COALESCE(ab.c_balance, 0) as cleared_balance,
		COALESCE(uc.u_credit, 0) as unprocessed_credit
	FROM 
		(SELECT deposit_account_id, sum(account_credit - account_debit) as current_balance
			FROM account_activity GROUP BY deposit_account_id) cb
	LEFT JOIN
		(SELECT deposit_account_id, sum(account_credit - account_debit) as c_balance
			FROM account_activity WHERE activity_status_id < 3
			GROUP BY deposit_account_id) ab
		ON cb.deposit_account_id = ab.deposit_account_id
	LEFT JOIN
		(SELECT deposit_account_id, sum(account_credit) as u_credit
			FROM account_activity WHERE activity_status_id > 2
			GROUP BY deposit_account_id) uc
		ON cb.deposit_account_id = uc.deposit_account_id;

CREATE OR REPLACE VIEW vw_deposit_accounts AS
	SELECT members.member_id, members.member_name, members.business_account,
		vw_products.product_id, vw_products.product_name, vw_products.product_no,
		vw_products.currency_id, vw_products.currency_name, vw_products.currency_symbol,
		activity_frequency.activity_frequency_id, activity_frequency.activity_frequency_name, 
		orgs.org_id, orgs.org_name,orgs.letter_head,
		deposit_accounts.deposit_account_id, deposit_accounts.is_active, 
		deposit_accounts.account_number, deposit_accounts.narrative, deposit_accounts.last_closing_date, 
		deposit_accounts.credit_limit, deposit_accounts.minimum_balance, deposit_accounts.maximum_balance, 
		deposit_accounts.interest_rate, deposit_accounts.lockin_period_frequency, deposit_accounts.opening_date,
		deposit_accounts.lockedin_until_date, deposit_accounts.application_date, deposit_accounts.approve_status, 
		deposit_accounts.workflow_table_id, deposit_accounts.action_date, deposit_accounts.details,
		
		vw_deposit_balance.current_balance, vw_deposit_balance.cleared_balance, vw_deposit_balance.unprocessed_credit,
		(vw_deposit_balance.cleared_balance - vw_deposit_balance.unprocessed_credit) AS available_balance
	FROM deposit_accounts INNER JOIN members ON deposit_accounts.member_id = members.member_id
		INNER JOIN vw_products ON deposit_accounts.product_id = vw_products.product_id
		INNER JOIN activity_frequency ON deposit_accounts.activity_frequency_id = activity_frequency.activity_frequency_id
		INNER JOIN orgs ON deposit_accounts.org_id = orgs.org_id
		LEFT JOIN vw_deposit_balance ON deposit_accounts.deposit_account_id = vw_deposit_balance.deposit_account_id;

CREATE OR REPLACE VIEW vw_entity_accounts AS
	SELECT vw_deposit_accounts.member_id, vw_deposit_accounts.member_name, vw_deposit_accounts.business_account,
		vw_deposit_accounts.product_id, vw_deposit_accounts.product_name, vw_deposit_accounts.letter_head,
		vw_deposit_accounts.currency_id, vw_deposit_accounts.currency_name, vw_deposit_accounts.currency_symbol,
		vw_deposit_accounts.activity_frequency_id, vw_deposit_accounts.activity_frequency_name, 
		vw_deposit_accounts.org_id, vw_deposit_accounts.deposit_account_id, vw_deposit_accounts.is_active, 
		vw_deposit_accounts.account_number, vw_deposit_accounts.narrative, vw_deposit_accounts.last_closing_date, 
		vw_deposit_accounts.credit_limit, vw_deposit_accounts.minimum_balance, vw_deposit_accounts.maximum_balance, 
		vw_deposit_accounts.interest_rate, vw_deposit_accounts.lockin_period_frequency, vw_deposit_accounts.opening_date,
		vw_deposit_accounts.lockedin_until_date, vw_deposit_accounts.application_date, vw_deposit_accounts.approve_status, 
		vw_deposit_accounts.workflow_table_id, vw_deposit_accounts.action_date, vw_deposit_accounts.details,
		
		vw_deposit_accounts.current_balance, vw_deposit_accounts.cleared_balance, 
		vw_deposit_accounts.unprocessed_credit,	vw_deposit_accounts.available_balance,
		entitys.entity_id, entitys.user_name, entitys.entity_name,
		(vw_deposit_accounts.product_name || ', ' || vw_deposit_accounts.account_number || ', ' ||
			vw_deposit_accounts.currency_symbol || ', ' || 
			trim(to_char(COALESCE(vw_deposit_accounts.available_balance, 0), '999,999,999,999'))) as deposit_account_disp,
		vw_deposit_accounts.product_no
		
	FROM vw_deposit_accounts INNER JOIN entitys ON vw_deposit_accounts.member_id = entitys.member_id;
	
CREATE OR REPLACE VIEW vw_transfer_beneficiary AS
	SELECT vw_deposit_accounts.member_id, vw_deposit_accounts.member_name, vw_deposit_accounts.business_account,
		vw_deposit_accounts.product_id, vw_deposit_accounts.product_name, 
		vw_deposit_accounts.currency_id, vw_deposit_accounts.currency_name, vw_deposit_accounts.currency_symbol,
		vw_deposit_accounts.activity_frequency_id, vw_deposit_accounts.activity_frequency_name, 
		vw_deposit_accounts.deposit_account_id, vw_deposit_accounts.is_active, 
		vw_deposit_accounts.approve_status as account_status, 
		
		transfer_beneficiary.member_id as account_member_id,
		transfer_beneficiary.org_id, transfer_beneficiary.transfer_beneficiary_id, 
		transfer_beneficiary.beneficiary_name, transfer_beneficiary.account_number, transfer_beneficiary.allow_transfer,
		transfer_beneficiary.application_date, transfer_beneficiary.approve_status, 
		transfer_beneficiary.workflow_table_id, transfer_beneficiary.action_date, 
		transfer_beneficiary.details,vw_deposit_accounts.letter_head
	FROM transfer_beneficiary INNER JOIN vw_deposit_accounts ON transfer_beneficiary.deposit_account_id = vw_deposit_accounts.deposit_account_id;

CREATE OR REPLACE VIEW vw_transfer_activity AS
	SELECT vw_transfer_beneficiary.transfer_beneficiary_id, vw_transfer_beneficiary.member_name as beneficiary_name, 
		vw_transfer_beneficiary.account_number as beneficiary_account_number,
	
		vw_deposit_accounts.deposit_account_id, vw_deposit_accounts.product_id, vw_deposit_accounts.product_name, 
		vw_deposit_accounts.member_id, vw_deposit_accounts.account_number,
		vw_deposit_accounts.currency_id, vw_deposit_accounts.currency_name, vw_deposit_accounts.currency_symbol,
		
		activity_frequency.activity_frequency_id, activity_frequency.activity_frequency_name, 
		activity_types.activity_type_id, activity_types.activity_type_name, 
		  
		transfer_activity.org_id, transfer_activity.transfer_activity_id, 
		transfer_activity.account_activity_id, transfer_activity.entity_id,
		transfer_activity.transfer_amount, transfer_activity.application_date, transfer_activity.approve_status, 
		transfer_activity.workflow_table_id, transfer_activity.action_date, transfer_activity.details,vw_deposit_accounts.letter_head
	
	FROM transfer_activity INNER JOIN vw_transfer_beneficiary ON transfer_activity.transfer_beneficiary_id = vw_transfer_beneficiary.transfer_beneficiary_id
		INNER JOIN vw_deposit_accounts ON transfer_activity.deposit_account_id = vw_deposit_accounts.deposit_account_id
		INNER JOIN activity_frequency ON transfer_activity.activity_frequency_id = activity_frequency.activity_frequency_id
		INNER JOIN activity_types ON transfer_activity.activity_type_id = activity_types.activity_type_id;

CREATE OR REPLACE VIEW vw_account_notes AS
	SELECT vw_deposit_accounts.member_id, vw_deposit_accounts.member_name, 
		vw_deposit_accounts.product_id, vw_deposit_accounts.product_name, 
		vw_deposit_accounts.deposit_account_id, vw_deposit_accounts.is_active, 
		vw_deposit_accounts.account_number, vw_deposit_accounts.last_closing_date,
		account_notes.org_id, account_notes.account_note_id, account_notes.comment_date, 
		account_notes.narrative, account_notes.note,vw_deposit_accounts.letter_head
	FROM account_notes INNER JOIN vw_deposit_accounts ON account_notes.deposit_account_id = vw_deposit_accounts.deposit_account_id;

CREATE OR REPLACE VIEW vw_commodity_trades AS
	SELECT vw_deposit_accounts.member_id, vw_deposit_accounts.member_name, vw_deposit_accounts.business_account,
		vw_deposit_accounts.product_id, vw_deposit_accounts.product_name, 
		vw_deposit_accounts.currency_id, vw_deposit_accounts.currency_name, vw_deposit_accounts.currency_symbol,
		vw_deposit_accounts.activity_frequency_id, vw_deposit_accounts.activity_frequency_name, 
		vw_deposit_accounts.deposit_account_id, vw_deposit_accounts.account_number, vw_deposit_accounts.is_active, 
		
		commoditys.commodity_id, commoditys.commodity_name, 
		entitys.entity_id, entitys.entity_name,
		orgs.org_id, orgs.org_name, orgs.letter_head,
		
		commodity_trades.commodity_trade_id, commodity_trades.unit_debit, commodity_trades.unit_credit, commodity_trades.price, 
		commodity_trades.trade_date, commodity_trades.application_date, commodity_trades.approve_status, 
		commodity_trades.workflow_table_id, commodity_trades.action_date, commodity_trades.details,
		
		(commodity_trades.unit_debit * commodity_trades.price) as trade_debit,
		(commodity_trades.unit_credit * commodity_trades.price) as trade_credit
	FROM commodity_trades INNER JOIN vw_deposit_accounts ON commodity_trades.deposit_account_id = vw_deposit_accounts.deposit_account_id
		INNER JOIN commoditys ON commodity_trades.commodity_id = commoditys.commodity_id
		INNER JOIN entitys ON commodity_trades.entity_id = entitys.entity_id
		INNER JOIN orgs ON commodity_trades.org_id = orgs.org_id;

CREATE OR REPLACE VIEW vw_commodity_summary AS
	SELECT vw_deposit_accounts.member_id, vw_deposit_accounts.member_name, vw_deposit_accounts.business_account,
		vw_deposit_accounts.product_id, vw_deposit_accounts.product_name, 
		vw_deposit_accounts.currency_id, vw_deposit_accounts.currency_name, vw_deposit_accounts.currency_symbol,
		vw_deposit_accounts.deposit_account_id, vw_deposit_accounts.account_number, vw_deposit_accounts.is_active, 
		
		commoditys.commodity_id, commoditys.commodity_name, 
		orgs.org_id, orgs.org_name,
		
		sum(commodity_trades.unit_credit - commodity_trades.unit_debit) as total_units,
		sum((commodity_trades.unit_credit - commodity_trades.unit_debit) * commodity_trades.price) as total_value,
		vw_deposit_accounts.letter_head
		
	FROM commodity_trades INNER JOIN vw_deposit_accounts ON commodity_trades.deposit_account_id = vw_deposit_accounts.deposit_account_id
		INNER JOIN commoditys ON commodity_trades.commodity_id = commoditys.commodity_id
		INNER JOIN orgs ON commodity_trades.org_id = orgs.org_id
	
	GROUP BY vw_deposit_accounts.member_id, vw_deposit_accounts.member_name, vw_deposit_accounts.business_account,
		vw_deposit_accounts.product_id, vw_deposit_accounts.product_name, 
		vw_deposit_accounts.currency_id, vw_deposit_accounts.currency_name, vw_deposit_accounts.currency_symbol,
		vw_deposit_accounts.deposit_account_id, vw_deposit_accounts.account_number, vw_deposit_accounts.is_active, 
		
		commoditys.commodity_id, commoditys.commodity_name, 
		orgs.org_id, orgs.org_name,vw_deposit_accounts.letter_head;
		
CREATE OR REPLACE VIEW vw_account_activity AS
	SELECT vw_deposit_accounts.member_id, vw_deposit_accounts.member_name, vw_deposit_accounts.business_account,
		vw_deposit_accounts.product_id, vw_deposit_accounts.product_name, 
		vw_deposit_accounts.deposit_account_id, vw_deposit_accounts.is_active, 
		vw_deposit_accounts.account_number, vw_deposit_accounts.last_closing_date,
		vw_deposit_accounts.currency_id, vw_deposit_accounts.currency_name, vw_deposit_accounts.currency_symbol,
		vw_activity_types.activity_type_id, vw_activity_types.activity_type_name, 
		vw_activity_types.dr_account_id, vw_activity_types.dr_account_no, vw_activity_types.dr_account_name,
		vw_activity_types.cr_account_id, vw_activity_types.cr_account_no, vw_activity_types.cr_account_name,
		vw_activity_types.use_key_id, vw_activity_types.use_key_name, 
		activity_frequency.activity_frequency_id, activity_frequency.activity_frequency_name, 
		activity_status.activity_status_id, activity_status.activity_status_name,
		
		account_activity.transfer_account_id, trnf_accounts.account_number as trnf_account_number,
		trnf_accounts.member_id as trnf_member_id, trnf_accounts.member_name as trnf_member_name,
		trnf_accounts.product_id as trnf_product_id,  trnf_accounts.product_name as trnf_product_name,
		
		vw_periods.period_id, vw_periods.start_date, vw_periods.end_date, vw_periods.fiscal_year_id, vw_periods.fiscal_year,
		
		account_activity.org_id, account_activity.account_activity_id, account_activity.activity_date, 
		account_activity.value_date, account_activity.transfer_account_no, account_activity.transfer_link_id,
		account_activity.account_credit, account_activity.account_debit, account_activity.balance, 
		account_activity.exchange_rate, account_activity.application_date, account_activity.approve_status, 
		account_activity.workflow_table_id, account_activity.action_date, account_activity.details,
		
		(account_activity.account_credit * account_activity.exchange_rate) as base_credit,
		(account_activity.account_debit * account_activity.exchange_rate) as base_debit,
		vw_deposit_accounts.product_no,vw_deposit_accounts.letter_head
	FROM account_activity INNER JOIN vw_deposit_accounts ON account_activity.deposit_account_id = vw_deposit_accounts.deposit_account_id
		INNER JOIN vw_activity_types ON account_activity.activity_type_id = vw_activity_types.activity_type_id
		INNER JOIN activity_frequency ON account_activity.activity_frequency_id = activity_frequency.activity_frequency_id
		INNER JOIN activity_status ON account_activity.activity_status_id = activity_status.activity_status_id
		LEFT JOIN vw_periods ON account_activity.period_id = vw_periods.period_id
		LEFT JOIN vw_deposit_accounts trnf_accounts ON account_activity.transfer_account_id =  trnf_accounts.deposit_account_id;

---members view
CREATE OR REPLACE VIEW member_details_p AS
SELECT  
	orgs.org_id,orgs.org_name,(sys_countrys.sys_country_name) AS nationality, 
	members.member_id, members.business_account, members.person_title,members.member_name, members.identification_number,members.identification_type, members.member_email, 
	members.telephone_number, members.telephone_number2, members.address,members.town, members.zip_code, members.date_of_birth, 
	CASE members.gender WHEN 'M' THEN 'Male'::text
			    WHEN 'F' THEN 'Female'::text
			    ELSE 'N/A'::text
			    END AS gender, 
	CASE members.marital_status WHEN 'M' THEN 'Married'::text
				    WHEN 'S' THEN 'Single'::text
				    WHEN 'D' THEN 'Divorced'::text
				    WHEN 'W' THEN 'Widowed'::text
				    WHEN 'X' THEN 'Separated'::text
				    ELSE 'N/A'::text
				    END AS marital_status,
	members.picture_file, members.employed,members.self_employed, members.employer_name, 
	members.monthly_salary, members.monthly_net_income, members.annual_turnover, members.annual_net_income,members.employer_address, 
	members.introduced_by, members.application_date, members.approve_status, members.workflow_table_id, members.action_date, 
	members.details,entitys.entity_id,members.is_active, orgs.letter_head
FROM members
	INNER JOIN entitys ON members.member_id = entitys.member_id
	INNER JOIN orgs ON members.org_id = orgs.org_id
	INNER JOIN sys_countrys ON members.nationality = sys_countrys.sys_country_id;

CREATE OR REPLACE VIEW vw_kins AS
	SELECT orgs.org_name,orgs.letter_head,
		members.member_id, members.member_name, entitys.entity_id,
		kin_types.kin_type_id, kin_types.kin_type_name, kin_types.spouse,
		kins.org_id, kins.kin_id, kins.full_names, kins.date_of_birth, kins.identification, kins.identification_type, 
		kins.emergency_contact, kins.beneficiary, kins.beneficiary_ps, kins.details
	FROM kins INNER JOIN members ON kins.member_id = members.member_id
	INNER JOIN entitys ON kins.member_id = entitys.member_id
	INNER JOIN kin_types ON kins.kin_type_id = kin_types.kin_type_id
	INNER JOIN orgs ON orgs.org_id = kins.org_id;

---getting the members contribution account number
CREATE OR REPLACE VIEW vw_trx_contrib AS
 SELECT aa.member_id,aa.member_name, aa.org_id, aa.deposit_account_id, aa.account_number AS trx_accno, aa.product_id, aa.product_no, 
 aa.product_name, 
    ab.account_number AS transfer_account_no
     FROM vw_deposit_accounts aa
     LEFT JOIN ( SELECT vw_deposit_accounts.member_id,
            vw_deposit_accounts.account_number
           FROM vw_deposit_accounts
          WHERE vw_deposit_accounts.product_no = 2) ab ON aa.member_id::text = ab.member_id::text
          WHERE aa.product_no = 1;

CREATE OR REPLACE VIEW vw_kins_p AS
	SELECT members.member_id, members.member_name,orgs.org_name,orgs.letter_head,
		kin_types.kin_type_id, kin_types.kin_type_name, kin_types.spouse,
		kins.org_id, kins.kin_id, kins.full_names, kins.date_of_birth, kins.identification, kins.identification_type, 
		kins.emergency_contact, kins.beneficiary, kins.beneficiary_ps, kins.details
	FROM kins INNER JOIN members ON kins.member_id = members.member_id	
	INNER JOIN kin_types ON kins.kin_type_id = kin_types.kin_type_id
	INNER JOIN orgs ON orgs.org_id = kins.org_id;

CREATE OR REPLACE VIEW vw_kins_member AS
	SELECT members.member_id, members.member_name,orgs.org_name,orgs.letter_head,
		kin_types.kin_type_id, kin_types.kin_type_name, kin_types.spouse,
		kins.org_id, kins.kin_id, kins.full_names, kins.date_of_birth, kins.identification, kins.identification_type, 
		kins.emergency_contact, kins.beneficiary, kins.beneficiary_ps, kins.details,entitys.entity_id
	FROM kins 
	INNER JOIN members ON kins.member_id = members.member_id	
	INNER JOIN kin_types ON kins.kin_type_id = kin_types.kin_type_id
	INNER JOIN orgs ON orgs.org_id = kins.org_id
	INNER JOIN entitys ON entitys.member_id = kins.member_id;

------------Hooks to approval trigger
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON members
	FOR EACH ROW EXECUTE PROCEDURE upd_action();
    
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON products
	FOR EACH ROW EXECUTE PROCEDURE upd_action();

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON deposit_accounts
	FOR EACH ROW EXECUTE PROCEDURE upd_action();
	
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON transfer_beneficiary
	FOR EACH ROW EXECUTE PROCEDURE upd_action();
    
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON account_activity
	FOR EACH ROW EXECUTE PROCEDURE upd_action();
	
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON commodity_trades
	FOR EACH ROW EXECUTE PROCEDURE upd_action();


