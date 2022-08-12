

ALTER TABLE entitys ADD	attention		varchar(50);
ALTER TABLE entitys ADD credit_limit real default 0;

ALTER TABLE orgs ADD 	org_client_id			integer references entitys;
ALTER TABLE orgs ADD 	payroll_payable			boolean default true not null;
ALTER TABLE orgs ADD 	cert_number				varchar(50);
ALTER TABLE orgs ADD	vat_number				varchar(50);
ALTER TABLE orgs ADD	enforce_budget			boolean default true not null;
ALTER TABLE orgs ADD	invoice_footer			text;

UPDATE orgs SET letter_head = 'logo.png' WHERE org_id = 0;

CREATE TABLE holidays (
	holiday_id				serial primary key,
	org_id					integer references orgs,
	holiday_name			varchar(50) not null,
	holiday_date			date,
	details					text
);
CREATE INDEX holidays_org_id ON holidays (org_id);
CREATE INDEX holidays_holiday_date ON holidays (holiday_date);

CREATE TABLE industry (
	industry_id				serial primary key,
	org_id					integer references orgs,
	industry_name			varchar(50) not null,
	details					text
);
CREATE INDEX industry_org_id ON industry(org_id);

CREATE TABLE banks (
	bank_id					serial primary key,
	sys_country_id			char(2) references sys_countrys,
	org_id					integer references orgs,
	bank_name				varchar(50) not null,
	bank_code				varchar(25),
	swift_code				varchar(25),
	sort_code				varchar(25),
	narrative				varchar(240)
);
CREATE INDEX banks_org_id ON banks (org_id);

CREATE TABLE bank_branch (
	bank_branch_id			serial primary key,
	bank_id					integer references banks,
	org_id					integer references orgs,
	bank_branch_name		varchar(50) not null,
	bank_branch_code		varchar(50),
	narrative				varchar(240),
	UNIQUE(bank_id, bank_branch_name)
);
CREATE INDEX branch_bankid ON bank_branch (bank_id);
CREATE INDEX bank_branch_org_id ON bank_branch (org_id);

CREATE TABLE departments (
	department_id			serial primary key,
	ln_department_id		integer references departments,
	org_id					integer references orgs,
	department_name			varchar(120),
	department_account		varchar(50),
	function_code			varchar(50),
	active					boolean default true not null,
	petty_cash				boolean default false not null,
	cost_center				boolean default true not null,
	revenue_center			boolean default true not null,
	description				text,
	duties					text,
	reports					text,
	details					text
);
CREATE INDEX departments_ln_department_id ON departments (ln_department_id);
CREATE INDEX departments_org_id ON departments (org_id);

CREATE TABLE fiscal_years (
	fiscal_year_id			serial primary key,
	fiscal_year				varchar(9) not null,
	org_id					integer references orgs,
	fiscal_year_start		date not null,
	fiscal_year_end			date not null,
	submission_date			date,
	year_opened				boolean default true not null,
	year_closed				boolean default false not null,
	details					text,
	
	UNIQUE(fiscal_year, org_id)
);
CREATE INDEX fiscal_years_org_id ON fiscal_years (org_id);

CREATE TABLE periods (
	period_id				serial primary key,
	fiscal_year_id			integer references fiscal_years,
	org_id					integer references orgs,
	start_date				date not null,
	end_date				date not null,
	opened					boolean default false not null,
	activated				boolean default false not null,
	closed					boolean default false not null,

	--- payroll details
	overtime_rate			float default 1 not null,
	per_diem_tax_limit		float default 2000 not null,
	is_posted				boolean default false not null,
	loan_approval			boolean default false not null,
	gl_payroll_account		varchar(32),
	gl_advance_account		varchar(32),

    entity_id 				integer references entitys,
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,

	details					text,
	UNIQUE(org_id, start_date)
);
CREATE INDEX periods_fiscal_year_id ON periods (fiscal_year_id);
CREATE INDEX periods_org_id ON periods (org_id);

--- Views
CREATE VIEW vw_curr_orgs AS
	SELECT currency.currency_id as base_currency_id, currency.currency_name as base_currency_name, 
		currency.currency_symbol as base_currency_symbol,
		orgs.org_id, orgs.org_name, orgs.is_default, orgs.is_active, orgs.logo, 
		orgs.cert_number, orgs.pin, orgs.vat_number, orgs.invoice_footer,
		orgs.details
	FROM orgs INNER JOIN currency ON orgs.currency_id = currency.currency_id;

DROP VIEW vw_entitys;
DROP VIEW vw_orgs;
	
CREATE VIEW vw_orgs AS
	SELECT orgs.org_id, orgs.org_name, orgs.is_default, orgs.is_active, orgs.logo, 
		orgs.org_full_name, orgs.pin, orgs.pcc, orgs.details,
		orgs.cert_number, orgs.vat_number, orgs.invoice_footer,
		
		currency.currency_id, currency.currency_name, currency.currency_symbol,

		vw_org_address.org_sys_country_id, vw_org_address.org_sys_country_name,
		vw_org_address.org_address_id, vw_org_address.org_table_name,
		vw_org_address.org_post_office_box, vw_org_address.org_postal_code,
		vw_org_address.org_premises, vw_org_address.org_street, vw_org_address.org_town,
		vw_org_address.org_phone_number, vw_org_address.org_extension,
		vw_org_address.org_mobile, vw_org_address.org_fax, vw_org_address.org_email, vw_org_address.org_website
	FROM orgs INNER JOIN currency ON orgs.currency_id = currency.currency_id
		LEFT JOIN vw_org_address ON orgs.org_id = vw_org_address.org_table_id;

CREATE VIEW vw_entitys AS
	SELECT vw_orgs.org_id, vw_orgs.org_name, vw_orgs.is_default as org_is_default, vw_orgs.is_active as org_is_active, 
		vw_orgs.logo as org_logo, vw_orgs.cert_number as org_cert_number, vw_orgs.pin as org_pin, 
		vw_orgs.vat_number as org_vat_number, vw_orgs.invoice_footer as org_invoice_footer,
		vw_orgs.org_sys_country_id, vw_orgs.org_sys_country_name, 
		vw_orgs.org_address_id, vw_orgs.org_table_name,
		vw_orgs.org_post_office_box, vw_orgs.org_postal_code, 
		vw_orgs.org_premises, vw_orgs.org_street, vw_orgs.org_town, 
		vw_orgs.org_phone_number, vw_orgs.org_extension, 
		vw_orgs.org_mobile, vw_orgs.org_fax, vw_orgs.org_email, vw_orgs.org_website,
		
		addr.address_id, addr.address_name,
		addr.sys_country_id, addr.sys_country_name, addr.table_name, addr.is_default,
		addr.post_office_box, addr.postal_code, addr.premises, addr.street, addr.town, 
		addr.phone_number, addr.extension, addr.mobile, addr.fax, addr.email, addr.website,
		
		entity_types.entity_type_id, entity_types.entity_type_name, entity_types.entity_role, 
		
		entitys.entity_id, entitys.use_key_id, entitys.entity_name, entitys.user_name, entitys.super_user, entitys.entity_leader, 
		entitys.date_enroled, entitys.is_active, entitys.entity_password, entitys.first_password, 
		entitys.function_role, entitys.attention, entitys.primary_email, entitys.primary_telephone,
		entitys.credit_limit

	FROM (entitys LEFT JOIN vw_address_entitys as addr ON entitys.entity_id = addr.table_id)
		INNER JOIN vw_orgs ON entitys.org_id = vw_orgs.org_id
		INNER JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id;

CREATE VIEW vw_bank_branch AS
	SELECT sys_countrys.sys_country_id, sys_countrys.sys_country_code, sys_countrys.sys_country_name,
		banks.bank_id, banks.bank_name, banks.bank_code, banks.swift_code,  banks.sort_code,
		bank_branch.bank_branch_id, bank_branch.org_id, bank_branch.bank_branch_name, 
		bank_branch.bank_branch_code, bank_branch.narrative,
		(banks.bank_name || ', ' || bank_branch.bank_branch_name) as bank_branch_disp
	FROM bank_branch INNER JOIN banks ON bank_branch.bank_id = banks.bank_id
		LEFT JOIN sys_countrys ON banks.sys_country_id = sys_countrys.sys_country_id;
		
CREATE VIEW vw_departments AS
	SELECT departments.ln_department_id, p_departments.department_name as ln_department_name, 
		departments.department_id, departments.org_id, departments.department_name, departments.active, 
		departments.function_code, departments.petty_cash, departments.cost_center, departments.revenue_center,
		departments.description, departments.duties, departments.reports, departments.details
	FROM departments LEFT JOIN departments as p_departments ON departments.ln_department_id = p_departments.department_id;

CREATE VIEW vw_periods AS
	SELECT fiscal_years.fiscal_year_id, fiscal_years.fiscal_year, fiscal_years.fiscal_year_start, 
		fiscal_years.fiscal_year_end, fiscal_years.submission_date, fiscal_years.year_opened, fiscal_years.year_closed,

		periods.period_id, periods.org_id, 
		periods.start_date, periods.end_date, periods.opened, periods.activated, periods.closed, 
		periods.overtime_rate, periods.per_diem_tax_limit, periods.is_posted, 
		periods.gl_payroll_account, periods.gl_advance_account, periods.details,

		date_part('month', periods.start_date) as month_id, to_char(periods.start_date, 'YYYY') as period_year, 
		to_char(periods.start_date, 'Month') as period_month, to_char(periods.start_date, 'YYYY, Month') as period_disp, 
		(trunc((date_part('month', periods.start_date)-1)/3)+1) as quarter, 
		(trunc((date_part('month', periods.start_date)-1)/6)+1) as semister,
		to_char(periods.start_date, 'YYYYMM') as period_code
		
	FROM periods LEFT JOIN fiscal_years ON periods.fiscal_year_id = fiscal_years.fiscal_year_id
	ORDER BY periods.start_date;

CREATE VIEW vw_period_year AS
	SELECT org_id, period_year
	FROM vw_periods
	GROUP BY org_id, period_year
	ORDER BY period_year;

CREATE VIEW vw_period_quarter AS
	SELECT org_id, quarter
	FROM vw_periods
	GROUP BY org_id, quarter
	ORDER BY quarter;

CREATE VIEW vw_period_semister AS
	SELECT org_id, semister
	FROM vw_periods
	GROUP BY org_id, semister
	ORDER BY semister;

CREATE VIEW vw_period_month AS
	SELECT org_id, month_id, period_year, period_month
	FROM vw_periods
	GROUP BY org_id, month_id, period_year, period_month
	ORDER BY month_id, period_year, period_month;
	
CREATE OR REPLACE FUNCTION add_periods(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_org_id			integer;
	v_period_id			integer;
	msg					varchar(120);
BEGIN

	SELECT org_id INTO v_org_id
	FROM fiscal_years
	WHERE (fiscal_year_id = $1::int);
	
	UPDATE periods SET fiscal_year_id = fiscal_years.fiscal_year_id
	FROM fiscal_years WHERE (fiscal_years.fiscal_year_id = $1::int)
		AND (fiscal_years.fiscal_year_start <= start_date) AND (fiscal_years.fiscal_year_end >= end_date);
	
	SELECT period_id INTO v_period_id
	FROM periods
	WHERE (fiscal_year_id = $1::int) AND (org_id = v_org_id);
	
	IF(v_period_id is null)THEN
		INSERT INTO periods (fiscal_year_id, org_id, start_date, end_date)
		SELECT $1::int, v_org_id, period_start, CAST(period_start + CAST('1 month' as interval) as date) - 1
		FROM (SELECT CAST(generate_series(fiscal_year_start, fiscal_year_end, '1 month') as date) as period_start
			FROM fiscal_years WHERE fiscal_year_id = $1::int) as a;
		msg := 'Months for the year generated';
	ELSE
		msg := 'Months year already created';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION close_periods(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 					varchar(120);
BEGIN
	
	IF(v_period_id is null)THEN
		INSERT INTO periods (fiscal_year_id, org_id, start_date, end_date)
		SELECT $1::int, v_org_id, period_start, CAST(period_start + CAST('1 month' as interval) as date) - 1
		FROM (SELECT CAST(generate_series(fiscal_year_start, fiscal_year_end, '1 month') as date) as period_start
			FROM fiscal_years WHERE fiscal_year_id = $1::int) as a;
		msg := 'Months for the year generated';
	ELSE
		msg := 'Months year already created';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ins_periods() RETURNS trigger AS $$
DECLARE
	year_close 		BOOLEAN;
BEGIN
	SELECT year_closed INTO year_close
	FROM fiscal_years
	WHERE (fiscal_year_id = NEW.fiscal_year_id);

	IF(year_close = true)THEN
		RAISE EXCEPTION 'The year is closed not transactions are allowed.';
	END IF;
	IF(NEW.start_date > NEW.end_date)THEN
		RAISE EXCEPTION 'The starting date has to be before the ending date.';
	END IF;
	
	IF(TG_OP = 'UPDATE')THEN    
		IF (OLD.closed = true) AND (NEW.closed = false) THEN
			NEW.approve_status := 'Draft';
		END IF;
	ELSE
		IF(NEW.gl_payroll_account is null)THEN NEW.gl_payroll_account := get_default_account(27, NEW.org_id); END IF;
		IF(NEW.gl_advance_account is null)THEN NEW.gl_advance_account := get_default_account(28, NEW.org_id); END IF;
	END IF;

	IF (NEW.approve_status = 'Approved') THEN
		NEW.opened = false;
		NEW.activated = false;
		NEW.closed = true;
	END IF;


	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_periods BEFORE INSERT OR UPDATE ON periods
	FOR EACH ROW EXECUTE PROCEDURE ins_periods();
    
CREATE OR REPLACE FUNCTION open_periods(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_org_id			integer;
	v_period_id			integer;
	msg					varchar(120);
BEGIN

	IF ($3 = '1') THEN
		UPDATE periods SET opened = true WHERE period_id = $1::int;
		msg := 'Period Opened';
	ELSIF ($3 = '2') THEN
		UPDATE periods SET closed = true WHERE period_id = $1::int;
		msg := 'Period Closed';
	ELSIF ($3 = '3') THEN
		UPDATE periods SET activated = true WHERE period_id = $1::int;
		msg := 'Period Activated';
	ELSIF ($3 = '4') THEN
		UPDATE periods SET activated = false WHERE period_id = $1::int;
		msg := 'Period De-activated';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;


------------Hooks to approval trigger
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON periods
    FOR EACH ROW EXECUTE PROCEDURE upd_action();


------------- Base data

INSERT INTO banks (org_id, bank_id, bank_name) VALUES 
(0, 0, 'Cash');

INSERT INTO bank_branch (org_id, bank_branch_id, bank_id, bank_branch_name) VALUES 
(0, 0, 0, 'Cash');

INSERT INTO departments (org_id, department_id, ln_department_id, department_name) VALUES 
(0, 0, 0, 'Board of Directors'); 

