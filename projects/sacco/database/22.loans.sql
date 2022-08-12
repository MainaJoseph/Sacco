---Project Database File
-----Loans table
CREATE TABLE loans (
	loan_id					serial primary key,
	member_id				integer references members,
	product_id	 			integer references products,
	activity_frequency_id	integer references activity_frequency,
	entity_id 				integer references entitys,
	org_id					integer references orgs,

	account_number			varchar(32) not null unique,
	disburse_account		varchar(32) not null,
	principal_amount		real not null,
	interest_rate			real not null,
	repayment_amount		real not null,
	repayment_period		integer not null,

	disbursed_date			date,
	matured_date			date,
	expected_matured_date	date,
	expected_repayment		real,

	loan_status				varchar(50) default 'Draft' not null, ---Draft --> Pending --> Active --> Settled or Defaulted
	is_active 				boolean default false not null,

	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,

	is_guaranteed 			boolean default true not null,
	is_collateral 			boolean default false not null,	
	
	details					text
);
CREATE INDEX loans_member_id ON loans(member_id);
CREATE INDEX loans_product_id ON loans(product_id);
CREATE INDEX loans_activity_frequency_id ON loans(activity_frequency_id);
CREATE INDEX loans_entity_id ON loans(entity_id);
CREATE INDEX loans_org_id ON loans(org_id);

---guarantees table
CREATE TABLE guarantees (
	guarantee_id			serial primary key,
	loan_id					integer references loans,
	member_id				integer references members,
	entity_id 				integer references entitys,
	org_id					integer references orgs,
	
	guarantee_amount		real not null,
	guarantee_accepted		boolean default false not null,
	accepted_date			timestamp,
	
	is_active				boolean default false not null, --active after accepting and until the loan is settled

	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,	
	
	details					text
);
CREATE INDEX guarantees_loan_id ON guarantees(loan_id);
CREATE INDEX guarantees_member_id ON guarantees(member_id);
CREATE INDEX guarantees_entity_id ON guarantees(entity_id);
CREATE INDEX guarantees_org_id ON guarantees(org_id);

----collateral types table
CREATE TABLE collateral_types (
	collateral_type_id		serial primary key,
	org_id					integer references orgs,
	collateral_type_name	varchar(50) not null,
	details					text,
	UNIQUE(org_id, collateral_type_name)
);
CREATE INDEX collateral_types_org_id ON collateral_types(org_id);

----collaterals
CREATE TABLE collaterals (
	collateral_id			serial primary key,
	loan_id					integer references loans,
	collateral_type_id		integer references collateral_types,
	entity_id 				integer references entitys,
	org_id					integer references orgs,
	
	collateral_amount		real not null,
	collateral_received		boolean default false not null,
	collateral_released		boolean default false not null,
	
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,	
	
	details					text
);
CREATE INDEX collaterals_loan_id ON collaterals(loan_id);
CREATE INDEX collaterals_collateral_type_id ON collaterals(collateral_type_id);
CREATE INDEX collaterals_entity_id ON collaterals(entity_id);
CREATE INDEX collaterals_org_id ON collaterals(org_id);

---loan notes
CREATE TABLE loan_notes (
	loan_note_id			serial primary key,
	loan_id					integer references loans,
	org_id					integer references orgs,
	comment_date			timestamp default now() not null,
	narrative				varchar(320) not null,
	note					text not null
);
CREATE INDEX loan_notes_loan_id ON loan_notes(loan_id);
CREATE INDEX loan_notes_org_id ON loan_notes(org_id);

ALTER TABLE account_activity ADD loan_id integer references loans;
ALTER TABLE account_activity ADD transfer_loan_id integer references loans;
CREATE INDEX account_activity_loan_id ON account_activity(loan_id);
CREATE INDEX account_activity_transfer_loan_id ON account_activity(transfer_loan_id);


----loan balance view
CREATE OR REPLACE VIEW vw_loan_balance AS
	SELECT cb.loan_id, cb.loan_balance, COALESCE(ab.a_balance, 0) as actual_balance,
		COALESCE(li.l_intrest, 0) as loan_intrest, COALESCE(lp.l_penalty, 0) as loan_penalty
	FROM 
		(SELECT loan_id, sum((account_debit - account_credit) * exchange_rate) as loan_balance
			FROM account_activity GROUP BY loan_id) cb
	LEFT JOIN
		(SELECT loan_id, sum((account_debit - account_credit) * exchange_rate) as a_balance
			FROM account_activity WHERE activity_status_id < 3 GROUP BY loan_id) ab
		ON cb.loan_id = ab.loan_id
	LEFT JOIN
		(SELECT loan_id, sum((account_debit - account_credit) * exchange_rate) as l_intrest
			FROM account_activity INNER JOIN activity_types ON account_activity.activity_type_id = activity_types.activity_type_id
			WHERE (activity_types.use_key_id = 105) GROUP BY loan_id) li
		ON cb.loan_id = li.loan_id
	LEFT JOIN
		(SELECT loan_id, sum((account_debit - account_credit) * exchange_rate) as l_penalty
			FROM account_activity INNER JOIN activity_types ON account_activity.activity_type_id = activity_types.activity_type_id
			WHERE (activity_types.use_key_id = 106) GROUP BY loan_id) lp
		ON cb.loan_id = lp.loan_id;

----loans view
CREATE OR REPLACE VIEW vw_loans AS
	SELECT members.member_id, members.member_name, members.business_account,
		vw_products.product_id, vw_products.product_name, 
		vw_products.currency_id, vw_products.currency_name, vw_products.currency_symbol,
		activity_frequency.activity_frequency_id, activity_frequency.activity_frequency_name, 
		loans.org_id, loans.loan_id, loans.account_number, loans.principal_amount, loans.interest_rate, 
		loans.repayment_amount, loans.disbursed_date, loans.expected_matured_date, loans.matured_date, 
		loans.repayment_period, loans.expected_repayment, loans.disburse_account, loans.loan_status,
		loans.application_date, loans.approve_status, loans.workflow_table_id, loans.action_date, loans.details,
		loans.is_collateral, loans.is_guaranteed,

		vw_loan_balance.loan_balance, vw_loan_balance.actual_balance, 
		(vw_loan_balance.actual_balance - vw_loan_balance.loan_balance) as committed_balance, vw_products.letter_head,
		loans.is_active
	FROM loans INNER JOIN members ON loans.member_id = members.member_id
		INNER JOIN vw_products ON loans.product_id = vw_products.product_id
		INNER JOIN activity_frequency ON loans.activity_frequency_id = activity_frequency.activity_frequency_id
		LEFT JOIN vw_loan_balance ON loans.loan_id = vw_loan_balance.loan_id;

---member loans view		
CREATE OR REPLACE VIEW vw_entity_loans AS
	SELECT vw_loans.member_id, vw_loans.member_name, vw_loans.business_account,
		vw_loans.product_id, vw_loans.product_name, vw_loans.loan_status,
		vw_loans.currency_id, vw_loans.currency_name, vw_loans.currency_symbol,
		vw_loans.activity_frequency_id, vw_loans.activity_frequency_name, 
		vw_loans.org_id, vw_loans.loan_id, vw_loans.account_number, vw_loans.principal_amount, vw_loans.interest_rate, 
		vw_loans.repayment_amount, vw_loans.disbursed_date, vw_loans.expected_matured_date, vw_loans.matured_date, 
		vw_loans.repayment_period, vw_loans.expected_repayment, vw_loans.disburse_account,
		vw_loans.application_date, vw_loans.approve_status, vw_loans.workflow_table_id, vw_loans.action_date, vw_loans.details,
		vw_loans.is_guaranteed, vw_loans.is_collateral,
		vw_loans.loan_balance, vw_loans.actual_balance, vw_loans.committed_balance,
		entitys.entity_id, entitys.user_name, entitys.entity_name,vw_loans.letter_head,vw_loans.is_active
		
	FROM vw_loans INNER JOIN entitys ON vw_loans.member_id = entitys.member_id;
		
CREATE OR REPLACE VIEW vw_guarantees AS
	SELECT vw_loans.member_id, vw_loans.member_name, vw_loans.product_id, vw_loans.product_name, 
		vw_loans.loan_id, vw_loans.principal_amount, vw_loans.interest_rate, 
		vw_loans.activity_frequency_id, vw_loans.activity_frequency_name, vw_loans.loan_status,
		vw_loans.disbursed_date, vw_loans.expected_matured_date, vw_loans.matured_date, 
		members.member_id as guarantor_id, members.member_name as guarantor_name, 
		guarantees.org_id, guarantees.guarantee_id, guarantees.guarantee_amount, guarantees.guarantee_accepted,
		guarantees.accepted_date, guarantees.application_date, guarantees.is_active,
		guarantees.approve_status, guarantees.workflow_table_id, guarantees.action_date, guarantees.details,
		vw_loans.repayment_period,vw_loans.letter_head
	FROM guarantees INNER JOIN vw_loans ON guarantees.loan_id = vw_loans.loan_id
		INNER JOIN members ON guarantees.member_id = members.member_id;

CREATE OR REPLACE VIEW vw_guarantees_request AS
	SELECT vw_guarantees.member_id, vw_guarantees.member_name, vw_guarantees.product_id, 
		vw_guarantees.product_name, vw_guarantees.loan_id, vw_guarantees.principal_amount, 
		vw_guarantees.interest_rate, vw_guarantees.activity_frequency_id, 
		vw_guarantees.activity_frequency_name, vw_guarantees.disbursed_date, 
		vw_guarantees.expected_matured_date, vw_guarantees.matured_date, 
		vw_guarantees.loan_status, vw_guarantees.guarantor_id, vw_guarantees.repayment_period,
		vw_guarantees.guarantor_name, vw_guarantees.org_id, vw_guarantees.guarantee_id, 
		vw_guarantees.guarantee_amount, vw_guarantees.guarantee_accepted, 
		vw_guarantees.accepted_date, vw_guarantees.application_date, vw_guarantees.details, 
		entitys.entity_id, entitys.primary_email, entitys.primary_telephone, entitys.is_active, 
		(vw_guarantees.is_active) AS active_guarantee,vw_guarantees.letter_head
	FROM vw_guarantees 
		INNER JOIN entitys ON entitys.member_id = vw_guarantees.guarantor_id;

CREATE OR REPLACE VIEW vw_collaterals AS
	SELECT vw_loans.member_id, vw_loans.member_name, vw_loans.product_id, vw_loans.product_name, 
		vw_loans.loan_id, vw_loans.principal_amount, vw_loans.interest_rate, vw_loans.loan_status,
		vw_loans.activity_frequency_id, vw_loans.activity_frequency_name, 
		vw_loans.disbursed_date, vw_loans.expected_matured_date, vw_loans.matured_date, 
		collateral_types.collateral_type_id, collateral_types.collateral_type_name,
		collaterals.org_id, collaterals.collateral_id, collaterals.collateral_amount, collaterals.collateral_received, 
		collaterals.collateral_released, collaterals.application_date, collaterals.approve_status, 
		collaterals.workflow_table_id, collaterals.action_date, collaterals.details,vw_loans.letter_head
	FROM collaterals INNER JOIN vw_loans ON collaterals.loan_id = vw_loans.loan_id
		INNER JOIN collateral_types ON collaterals.collateral_type_id = collateral_types.collateral_type_id;
		
CREATE OR REPLACE VIEW vw_loan_notes AS
	SELECT vw_loans.member_id, vw_loans.member_name, vw_loans.product_id, vw_loans.product_name, 
		vw_loans.loan_id, vw_loans.principal_amount, vw_loans.interest_rate, vw_loans.loan_status,
		vw_loans.activity_frequency_id, vw_loans.activity_frequency_name, 
		vw_loans.disbursed_date, vw_loans.expected_matured_date, vw_loans.matured_date, 
		loan_notes.org_id, loan_notes.loan_note_id, loan_notes.comment_date, 
		loan_notes.narrative, loan_notes.note,vw_loans.letter_head
	FROM loan_notes INNER JOIN vw_loans ON loan_notes.loan_id = vw_loans.loan_id;
	
CREATE OR REPLACE VIEW vw_loan_activity AS
	SELECT vw_loans.member_id, vw_loans.member_name,  vw_loans.business_account,
		vw_loans.product_id, vw_loans.product_name, vw_loans.loan_status,
		vw_loans.loan_id, vw_loans.principal_amount, vw_loans.interest_rate, 
		vw_loans.disbursed_date, vw_loans.expected_matured_date, vw_loans.matured_date, 
		vw_loans.currency_id, vw_loans.currency_name, vw_loans.currency_symbol,
		
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
		account_activity.value_date, account_activity.transfer_account_no,
		account_activity.account_credit, account_activity.account_debit, account_activity.balance, 
		account_activity.exchange_rate, account_activity.application_date, account_activity.approve_status, 
		account_activity.workflow_table_id, account_activity.action_date, account_activity.details,
		
		(account_activity.account_credit * account_activity.exchange_rate) as base_credit,
		(account_activity.account_debit * account_activity.exchange_rate) as base_debit,
		vw_loans.letter_head
	FROM account_activity INNER JOIN vw_loans ON account_activity.loan_id = vw_loans.loan_id
		INNER JOIN vw_activity_types ON account_activity.activity_type_id = vw_activity_types.activity_type_id
		INNER JOIN activity_frequency ON account_activity.activity_frequency_id = activity_frequency.activity_frequency_id
		INNER JOIN activity_status ON account_activity.activity_status_id = activity_status.activity_status_id
		LEFT JOIN vw_periods ON account_activity.period_id = vw_periods.period_id
		LEFT JOIN vw_deposit_accounts trnf_accounts ON account_activity.transfer_account_id =  trnf_accounts.deposit_account_id;
    
------------Hooks to approval trigger
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON loans
	FOR EACH ROW EXECUTE PROCEDURE upd_action();
	
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON guarantees
	FOR EACH ROW EXECUTE PROCEDURE upd_action();
	
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON collaterals
	FOR EACH ROW EXECUTE PROCEDURE upd_action();


---AADDITIONAL FUNCTIONS FOR COUNT AND SUM

--==============COUNT=================

--- Function to count on total loans applied by the member
CREATE OR REPLACE FUNCTION get_applied_loans(integer) RETURNS integer AS $$
    SELECT COALESCE(count(loan_id), 0)::integer
	FROM loans
	WHERE (member_id = $1);
$$ LANGUAGE SQL;

---function to count active, approved and disbursed loans for the member
CREATE OR REPLACE FUNCTION get_active_loans(integer) RETURNS integer AS $$
    SELECT COALESCE(count(loan_id), 0)::integer
	FROM loans
	WHERE (approve_status = 'Approved') AND (member_id = $1);
$$ LANGUAGE SQL;

---function to count settled loans/fully paid by a member
CREATE OR REPLACE FUNCTION get_settled_loans(integer) RETURNS integer AS $$
    SELECT COALESCE(count(loan_id), 0)::integer
	FROM loans
	WHERE (is_active = false) AND (approve_status = 'Approved') AND (member_id = $1);
$$ LANGUAGE SQL;

--=============SUM=====================

---function to sum total loans amount applied by the member
CREATE OR REPLACE FUNCTION get_applied_loan_amount(integer) RETURNS integer AS $$
    SELECT COALESCE(sum(principal_amount), 0)::integer
	FROM loans
	WHERE (member_id = $1) AND loan_status != 'Draft';
$$ LANGUAGE SQL;

---function to sum active, approved and disbursed loans amount for the member
CREATE OR REPLACE FUNCTION get_active_loan_amount(integer) RETURNS integer AS $$
    SELECT COALESCE(sum(principal_amount), 0)::integer
	FROM loans
	WHERE (approve_status = 'Approved') AND (member_id = $1);
$$ LANGUAGE SQL;

---function to sum settled loans/fully paid by a member
CREATE OR REPLACE FUNCTION get_settled_loan_amount(integer) RETURNS integer AS $$
    SELECT COALESCE(sum(principal_amount), 0)::integer
	FROM loans
	WHERE (is_active = false) AND (approve_status = 'Approved') AND (member_id = $1);
$$ LANGUAGE SQL;


----VIEW to display members loan summary
CREATE OR REPLACE VIEW vw_member_loan_summary AS
	SELECT members.member_id, members.member_name, members.business_account,members.identification_number,
		members.identification_type,members.member_email,members.telephone_number,members.entry_date,
		get_applied_loans(loans.member_id) AS applied_loans,
		get_active_loans (loans.member_id) AS approved_loans,
		get_settled_loans (loans.member_id) AS fully_paid_loans,
		get_applied_loan_amount (loans.member_id) AS total_applied_loan_amount,
		get_active_loan_amount (loans.member_id) AS approved_amount,
		get_settled_loan_amount (loans.member_id) AS repaid_amount,
		(get_settled_loan_amount (loans.member_id) - get_active_loan_amount (loans.member_id)) AS balance_amount,
		members.org_id
	FROM members
		LEFT JOIN loans ON loans.member_id = members.member_id 
		WHERE members.business_account = 0
		GROUP BY members.member_id,loans.member_id
		ORDER BY members.member_id ASC;

---=================================================================
---Loan products settings
CREATE TABLE loan_configs (
	loan_config_id 			serial primary key,
	org_id 					integer references orgs,
	product_id 				integer references products, ---loan products

	is_guaranteed 			boolean default true not null,
	is_collateral 			boolean default false not null,
	membership_period 		integer default 6 not null, ----in months


	less_guaranteed			boolean default false not null,

	is_active 				boolean default true not null,
	narrative 				varchar(120),
	details 				text
);
CREATE INDEX loan_configs_org_id ON loan_configs (org_id);
CREATE INDEX loan_configs_product_id ON loan_configs (product_id);

---LOAN APPROVAL OFFICIALS
CREATE TABLE loan_approval (
	loan_approval_id 		serial primary key,
	sacco_official_id 		integer references sacco_officials,
	org_id 					integer references orgs,

	processing_approval 	boolean default true not null,
	final_approval 			boolean default false not null,
	is_active 				boolean default true not null,

	narrative 				varchar(120),
	details 				text
);
CREATE INDEX loan_approval_sacco_official_id ON loan_approval (sacco_official_id);
CREATE INDEX loan_approval_org_id ON loan_approval (org_id);

---LOAN APPROVAL PROCESS LEVELS
CREATE TABLE loan_approval_levels (
	loan_approval_level_id 	serial primary key,
	org_id 					integer references orgs,
	loan_approval_id 		integer references loan_approval,
	loan_id 				integer references loans,

	is_approved 			boolean default false not null,
	approved_time 			timestamp,
	status 					varchar(50) default 'Pending' not null,
	entity_id 				integer references entitys, ---approved by

	narrative 				varchar(120),
	details 				text
);
CREATE INDEX loan_approval_levels_org_id ON loan_approval_levels (org_id);
CREATE INDEX loan_approval_levels_loan_approval_id ON loan_approval_levels (loan_approval_id);
CREATE INDEX loan_approval_levels_loan_id ON loan_approval_levels (loan_id);
CREATE INDEX loan_approval_levels_entity_id ON loan_approval_levels (entity_id);


CREATE OR REPLACE VIEW vw_loan_configs AS
	SELECT loan_configs.loan_config_id, loan_configs.org_id, loan_configs.product_id, loan_configs.is_guaranteed, 
		loan_configs.is_collateral, loan_configs.membership_period, loan_configs.is_active, loan_configs.narrative, 
		loan_configs.details, vw_products.activity_frequency_id, vw_products.activity_frequency_name, 
		vw_products.currency_id, vw_products.currency_name, vw_products.currency_symbol, vw_products.interest_method_id,
		vw_products.interest_method_name, vw_products.reducing_balance, vw_products.interest_method_no, 
		vw_products.penalty_method_id, vw_products.penalty_method_name, vw_products.penalty_method_no, 
		vw_products.product_name, vw_products.description, (vw_products.maximum_repayments) AS maximum_repayments
	FROM loan_configs
		INNER JOIN vw_products ON vw_products.product_id = loan_configs.product_id;

CREATE OR REPLACE VIEW vw_loan_approval AS
	SELECT loan_approval.loan_approval_id, loan_approval.sacco_official_id, loan_approval.org_id, 
		loan_approval.processing_approval, loan_approval.final_approval, loan_approval.is_active, 
		loan_approval.narrative, loan_approval.details, vw_sacco_officials.position_level_name, 
		vw_sacco_officials.position_level_id, vw_sacco_officials.member_id, vw_sacco_officials.start_date, 
		vw_sacco_officials.end_date, vw_sacco_officials.term_limit, vw_sacco_officials.member_name, 
		vw_sacco_officials.identification_number, vw_sacco_officials.identification_type, 
		vw_sacco_officials.member_email, vw_sacco_officials.telephone_number, vw_sacco_officials.telephone_number2, 
		vw_sacco_officials.address, vw_sacco_officials.town, vw_sacco_officials.zip_code,vw_sacco_officials.entity_id
	FROM vw_sacco_officials
		INNER JOIN loan_approval ON loan_approval.sacco_official_id = vw_sacco_officials.sacco_official_id;

---LOAN APPROVALS VIEW
CREATE OR REPLACE VIEW vw_loan_approval_levels AS
	SELECT loan_approval.loan_approval_id,loan_approval.sacco_official_id,loan_approval.org_id,loan_approval.processing_approval,
	loan_approval.final_approval,loan_approval.is_active,loan_approval.narrative,loan_approval.details,

	vw_sacco_officials.position_level_name,vw_sacco_officials.position_level_id,vw_sacco_officials.member_id,
	vw_sacco_officials.start_date,vw_sacco_officials.end_date,vw_sacco_officials.term_limit,vw_sacco_officials.is_active AS active_official,
	vw_sacco_officials.member_name,vw_sacco_officials.identification_number,vw_sacco_officials.identification_type,
	vw_sacco_officials.member_email,vw_sacco_officials.telephone_number,vw_sacco_officials.telephone_number2,
	vw_sacco_officials.address,vw_sacco_officials.town,vw_sacco_officials.zip_code
		FROM loan_approval
			INNER JOIN vw_sacco_officials ON vw_sacco_officials.sacco_official_id = loan_approval.sacco_official_id;

---list the the approving members who are sacco officials
CREATE OR REPLACE VIEW vw_final_loan_approval AS
	SELECT loan_approval_levels.loan_approval_level_id, loan_approval_levels.org_id, loan_approval_levels.loan_approval_id, 
		loan_approval_levels.loan_id, loan_approval_levels.is_approved, loan_approval_levels.approved_time, 
		(loan_approval_levels.entity_id) AS approved_by, loan_approval_levels.narrative, loan_approval_levels.details, vw_loans.member_id, 
		vw_loans.member_name, vw_loans.business_account, vw_loans.product_id, vw_loans.product_name, vw_loans.currency_id, 
		vw_loans.currency_name, vw_loans.currency_symbol, vw_loans.account_number, vw_loans.principal_amount, vw_loans.interest_rate, 
		vw_loans.repayment_amount, vw_loans.disbursed_date, vw_loans.repayment_period, vw_loans.expected_repayment, 
		vw_loans.disburse_account, vw_loans.loan_status, vw_loan_approval.sacco_official_id, vw_loan_approval.processing_approval, 
		vw_loan_approval.final_approval, vw_loan_approval.is_active, vw_loan_approval.position_level_name, 
		(vw_loan_approval.member_name) AS official_name,vw_loan_approval.entity_id,loan_approval_levels.status
			FROM loan_approval_levels
				INNER JOIN vw_loan_approval ON vw_loan_approval.loan_approval_id = loan_approval_levels.loan_approval_id
				INNER JOIN vw_loans ON vw_loans.loan_id = loan_approval_levels.loan_id;


---=============FUNCTIONS ON LOAN PROCESSES======================
----  archiving function
CREATE OR REPLACE FUNCTION archiving_loan_setting(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg							varchar(120);
	
BEGIN
----DEACTIVATING
	---- deactivating loan configuration
	IF($3 = '1')THEN
		UPDATE loan_configs SET is_active = false, details = ('archived/deactivated on'|| ' :- ' ||current_date)
		WHERE (loan_config_id = $1::integer) AND (is_active = true);

		msg := 'Archived/deactivated Successfully...';
	
	END IF;

	--- deactivating loan approval
	IF($3 = '2')THEN
		UPDATE loan_approval SET is_active = false, details = ('archived/deactivated on'|| ' :- ' ||current_date)
		WHERE (loan_approval_id = $1::integer) AND (is_active = true);

		msg := 'Archived/deactivated Successfully...';
	
	END IF;

----ACTIVATING
	---- activating loan configuration
	IF($3 = '3')THEN
		UPDATE loan_configs SET is_active = true, details = ('activated on'|| ' :- ' ||current_date)
		WHERE (loan_config_id = $1::integer) AND (is_active = false);

		msg := 'Activated Successfully...';
	
	END IF;

	--- activating loan approval
	IF($3 = '4')THEN
		UPDATE loan_approval SET is_active = true, details = ('activated on'|| ' :- ' ||current_date)
		WHERE (loan_approval_id = $1::integer) AND (is_active = false);

		msg := 'Activated Successfully...';
	
	END IF;

------LOAN APPROVALS
	---processing approval
	IF($3 = '5')THEN
		UPDATE loan_approval SET processing_approval = true, details = ('Processing Approval Activated on'|| ' :- ' ||current_date)
		WHERE (loan_approval_id = $1::integer) AND (processing_approval = false);

		msg := 'Processing Approval Activated Successfully...';
	
	END IF;

	IF($3 = '6')THEN
		UPDATE loan_approval SET processing_approval = false, details = ('Processing Approval Deactivated on'|| ' :- ' ||current_date)
		WHERE (loan_approval_id = $1::integer) AND (processing_approval = true);

		msg := 'Processing Approval Deactivated Successfully...';
	
	END IF;
	-------------
	---final approval
	IF($3 = '7')THEN
		UPDATE loan_approval SET final_approval = true, details = ('Final Approval Activated on'|| ' :- ' ||current_date)
		WHERE (loan_approval_id = $1::integer) AND (final_approval = false);

		msg := 'Final Approval Activated Successfully...';
	
	END IF;

	IF($3 = '8')THEN
		UPDATE loan_approval SET final_approval = false, details = ('Final Approval Deactivated on'|| ' :- ' ||current_date)
		WHERE (loan_approval_id = $1::integer) AND (final_approval = true);

		msg := 'Final Approval Deactivated Successfully...';
	
	END IF;

	---------
	---activating and deactivating
	IF($3 = '9')THEN
		UPDATE loan_approval SET is_active = true, details = ('Activated on'|| ' :- ' ||current_date)
		WHERE (loan_approval_id = $1::integer) AND (is_active = false);

		msg := 'Activated Successfully...';
	
	END IF;

	IF($3 = '10')THEN
		UPDATE loan_approval SET is_active = false, details = ('Deactivated on'|| ' :- ' ||current_date)
		WHERE (loan_approval_id = $1::integer) AND (is_active = true);

		msg := 'Deactivated Successfully...';
	
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

