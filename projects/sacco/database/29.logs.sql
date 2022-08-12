---Project Database File

CREATE SCHEMA logs;

CREATE TABLE logs.lg_members (
	lg_member_id			serial primary key,
	member_id				integer,
	entity_id 				integer,
	org_id					integer references orgs,
	business_account		integer default 0 not null,
	
	person_title			varchar(7),
	member_name			varchar(150) not null,
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
	
	application_date		timestamp default now() not null,
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,

	details					text,
	
	created					timestamp default now() not null
);

CREATE TABLE logs.lg_deposit_accounts (
	lg_deposit_account_id	serial primary key,
	deposit_account_id		integer,
	member_id				integer,
	product_id 				integer,
	activity_frequency_id	integer,
	entity_id 				integer,
	org_id					integer references orgs,

	is_active				boolean default false not null,
	account_number			varchar(32) not null,
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
	
	details					text,
	
	created					timestamp default now() not null
);

CREATE TABLE logs.lg_loans (
	lg_loan_id				serial primary key,
	loan_id					integer,
	member_id				integer,
	product_id	 			integer,
	activity_frequency_id	integer,
	entity_id 				integer,
	org_id					integer references orgs,

	account_number			varchar(32) not null,
	disburse_account		varchar(32) not null,
	principal_amount		real not null,
	interest_rate			real not null,
	repayment_amount		real not null,
	repayment_period		integer not null,

	disbursed_date			date,
	matured_date			date,
	expected_matured_date	date,
	expected_repayment		real,
	
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,	
	
	details					text,
	
	created					timestamp default now() not null
);

CREATE TABLE logs.lg_guarantees (
	lg_guarantee_id			serial primary key,
	guarantee_id			integer,
	loan_id					integer,
	member_id				integer,
	entity_id 				integer,
	org_id					integer,
	
	guarantee_amount		real not null,
	guarantee_accepted		boolean default false not null,
	accepted_date			timestamp,
	
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,	
	
	details					text,
	
	created					timestamp default now() not null
);

CREATE TABLE logs.lg_collaterals (
	lg_collateral_id		serial primary key,
	collateral_id			integer,
	loan_id					integer,
	collateral_type_id		integer,
	entity_id 				integer,
	org_id					integer references orgs,
	
	collateral_amount		real not null,
	collateral_received		boolean default false not null,
	collateral_released		boolean default false not null,
	
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,	
	
	details					text,
	
	created					timestamp default now() not null
);

CREATE TABLE logs.lg_commodity_trades (
	lg_commodity_trade_id	serial primary key,
	commodity_trade_id		integer references commodity_trades,
	deposit_account_id		integer,
	transfer_account_id		integer,
	commodity_id			integer,
	entity_id				integer,
	use_key_id				integer,
	org_id					integer references orgs,

	transfer_account_no		varchar(32),
	link_activity_id		integer,
	unit_debit				real,
	unit_credit				real,
	price					real,
	trade_date				date,

	application_date		timestamp,
	approve_status			varchar(16),
	workflow_table_id		integer,
	action_date				timestamp,

	details					text,
	
	created					timestamp default now() not null
);

CREATE TABLE logs.lg_account_activity (
	lg_account_activity_id	serial primary key,
	account_activity_id		integer references account_activity,
	deposit_account_id		integer,
	transfer_account_id		integer,
	activity_type_id		integer,
	activity_frequency_id	integer,
	activity_status_id		integer,
	commodity_trade_id		integer,
	period_id				integer,
	entity_id 				integer,
	loan_id					integer,
	transfer_loan_id		integer,
	org_id					integer references orgs,
	
	link_activity_id		integer not null,
	transfer_link_id		integer,
	deposit_account_no		varchar(32),
	transfer_account_no		varchar(32),
	activity_date			date default current_date not null,
	value_date				date not null,
	
	account_credit			real,
	account_debit			real,
	balance					real,
	exchange_rate			real,
	
	invert_rate				boolean,
	trading_rate			real,
	mean_rate				real,
	
	application_date		timestamp,
	approve_status			varchar(16),
	workflow_table_id		integer,
	action_date				timestamp,	
	details					text,
	
	created					timestamp default now() not null
);


CREATE OR REPLACE FUNCTION log_members() RETURNS trigger AS $$
BEGIN
	INSERT INTO logs.lg_members(member_id, entity_id, org_id, business_account, person_title, 
		member_name, identification_number, identification_type, member_email, 
		telephone_number, telephone_number2, address, town, zip_code, 
		date_of_birth, gender, nationality, marital_status, picture_file, 
		employed, self_employed, employer_name, monthly_salary, monthly_net_income, 
		annual_turnover, annual_net_income, employer_address, introduced_by, 
		application_date, approve_status, workflow_table_id, action_date, details)
	VALUES (OLD.member_id, OLD.entity_id, OLD.org_id, OLD.business_account, OLD.person_title,
		OLD.member_name, OLD.identification_number, OLD.identification_type, OLD.member_email,
		OLD.telephone_number, OLD.telephone_number2, OLD.address, OLD.town, OLD.zip_code,
		OLD.date_of_birth, OLD.gender, OLD.nationality, OLD.marital_status, OLD.picture_file,
		OLD.employed, OLD.self_employed, OLD.employer_name, OLD.monthly_salary, OLD.monthly_net_income,
		OLD.annual_turnover, OLD.annual_net_income, OLD.employer_address, OLD.introduced_by,
		OLD.application_date, OLD.approve_status, OLD.workflow_table_id, OLD.action_date, OLD.details);
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_members AFTER UPDATE OR DELETE ON members
	FOR EACH ROW EXECUTE PROCEDURE log_members();
	
CREATE OR REPLACE FUNCTION log_deposit_accounts() RETURNS trigger AS $$
BEGIN
	INSERT INTO logs.lg_deposit_accounts(deposit_account_id, member_id, product_id, activity_frequency_id, 
		entity_id, org_id, is_active, account_number, narrative, opening_date, 
		last_closing_date, credit_limit, minimum_balance, maximum_balance, 
		interest_rate, lockin_period_frequency, lockedin_until_date, 
		application_date, approve_status, workflow_table_id, action_date, details)
	VALUES (OLD.deposit_account_id, OLD.member_id, OLD.product_id, OLD.activity_frequency_id,
		OLD.entity_id, OLD.org_id, OLD.is_active, OLD.account_number, OLD.narrative, OLD.opening_date,
		OLD.last_closing_date, OLD.credit_limit, OLD.minimum_balance, OLD.maximum_balance,
		OLD.interest_rate, OLD.lockin_period_frequency, OLD.lockedin_until_date,
		OLD.application_date, OLD.approve_status, OLD.workflow_table_id, OLD.action_date, OLD.details);
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_deposit_accounts AFTER UPDATE OR DELETE ON deposit_accounts
	FOR EACH ROW EXECUTE PROCEDURE log_deposit_accounts();
	
CREATE OR REPLACE FUNCTION log_loans() RETURNS trigger AS $$
BEGIN
	INSERT INTO logs.lg_loans(loan_id, member_id, product_id, activity_frequency_id, entity_id, 
		org_id, account_number, disburse_account, principal_amount, interest_rate, 
		repayment_amount, repayment_period, disbursed_date, matured_date, 
		expected_matured_date, expected_repayment, application_date, 
		approve_status, workflow_table_id, action_date, details)
	VALUES(OLD.loan_id, OLD.member_id, OLD.product_id, OLD.activity_frequency_id, OLD.entity_id,
		OLD.org_id, OLD.account_number, OLD.disburse_account, OLD.principal_amount, OLD.interest_rate,
		OLD.repayment_amount, OLD.repayment_period, OLD.disbursed_date, OLD.matured_date,
		OLD.expected_matured_date, OLD.expected_repayment, OLD.application_date,
		OLD.approve_status, OLD.workflow_table_id, OLD.action_date, OLD.details);
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_loans AFTER UPDATE OR DELETE ON loans
	FOR EACH ROW EXECUTE PROCEDURE log_loans();
	
CREATE OR REPLACE FUNCTION log_guarantees() RETURNS trigger AS $$
BEGIN
	INSERT INTO logs.lg_guarantees(guarantee_id, loan_id, member_id, entity_id, org_id, guarantee_amount, 
		guarantee_accepted, accepted_date, application_date, approve_status, 
		workflow_table_id, action_date, details)
	VALUES(OLD.guarantee_id, OLD.loan_id, OLD.member_id, OLD.entity_id, OLD.org_id, OLD.guarantee_amount,
		OLD.guarantee_accepted, OLD.accepted_date, OLD.application_date, OLD.approve_status,
		OLD.workflow_table_id, OLD.action_date, OLD.details);
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_guarantees AFTER UPDATE OR DELETE ON guarantees
	FOR EACH ROW EXECUTE PROCEDURE log_guarantees();
	
CREATE OR REPLACE FUNCTION log_collaterals() RETURNS trigger AS $$
BEGIN
	INSERT INTO logs.lg_collaterals(collateral_id, loan_id, collateral_type_id, entity_id, org_id, 
		collateral_amount, collateral_received, collateral_released, 
		application_date, approve_status, workflow_table_id, action_date, details)
	VALUES (OLD.collateral_id, OLD.loan_id, OLD.collateral_type_id, OLD.entity_id, OLD.org_id,
		OLD.collateral_amount, OLD.collateral_received, OLD.collateral_released,
		OLD.application_date, OLD.approve_status, OLD.workflow_table_id, OLD.action_date, OLD.details);
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_collaterals AFTER UPDATE OR DELETE ON collaterals
	FOR EACH ROW EXECUTE PROCEDURE log_collaterals();
	
CREATE OR REPLACE FUNCTION log_commodity_trades() RETURNS trigger AS $$
BEGIN
	INSERT INTO logs.lg_commodity_trades(commodity_trade_id, deposit_account_id, transfer_account_id, 
		commodity_id, entity_id, use_key_id, org_id, transfer_account_no, 
		link_activity_id, unit_debit, unit_credit, price, trade_date, 
		application_date, approve_status, workflow_table_id, action_date, details)
	VALUES (OLD.commodity_trade_id, OLD.deposit_account_id, OLD.transfer_account_id, 
		OLD.commodity_id, OLD.entity_id, OLD.use_key_id, OLD.org_id, OLD.transfer_account_no, 
		OLD.link_activity_id, OLD.unit_debit, OLD.unit_credit, OLD.price, OLD.trade_date, 
		OLD.application_date, OLD.approve_status, OLD.workflow_table_id, OLD.action_date, OLD.details);
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_commodity_trades AFTER UPDATE OR DELETE ON commodity_trades
	FOR EACH ROW EXECUTE PROCEDURE log_commodity_trades();
	
CREATE OR REPLACE FUNCTION log_account_activity() RETURNS trigger AS $$
BEGIN
	INSERT INTO log.lg_account_activity_log(account_activity_id, deposit_account_id, 
		transfer_account_id, activity_type_id, activity_frequency_id, 
		activity_status_id, commodity_trade_id, period_id, entity_id,
		loan_id, transfer_loan_id, org_id, link_activity_id, deposit_account_no, 
		transfer_link_id, transfer_account_no, activity_date, value_date, account_credit, 
		account_debit, balance, exchange_rate, invert_rate, trading_rate, mean_rate,
		application_date, approve_status, 
		workflow_table_id, action_date, details)
    VALUES (OLD.account_activity_id, OLD.deposit_account_id, 
		OLD.transfer_account_id, OLD.activity_type_id, OLD.activity_frequency_id, 
		OLD.activity_status_id, OLD.commodity_trade_id, OLD.period_id, OLD.entity_id,
		OLD.loan_id, OLD.transfer_loan_id, OLD.org_id, OLD.link_activity_id, OLD.deposit_account_no, 
		OLD.transfer_link_id, OLD.transfer_account_no, OLD.activity_date, OLD.value_date, OLD.account_credit, 
		OLD.account_debit, OLD.balance, OLD.exchange_rate, OLD.invert_rate, OLD.trading_rate, OLD.mean_rate,
		OLD.application_date, OLD.approve_status, 
		OLD.workflow_table_id, OLD.action_date, OLD.details);
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_account_activity AFTER UPDATE OR DELETE ON account_activity
	FOR EACH ROW EXECUTE PROCEDURE log_account_activity();


