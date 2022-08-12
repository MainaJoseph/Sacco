CREATE TABLE investment_types (
	investment_type_id		serial primary key,
	org_id				integer references orgs,
	investment_type_name	varchar (120),
	interest_amount 		real,
	details				text
);
CREATE INDEX investment_types_org_id ON investment_types (org_id);

CREATE TABLE investment_status (
	investment_status_id	serial primary key,
	org_id				integer references orgs,
	investment_status_name	varchar (120),
	details				text
);
CREATE INDEX investment_status_org_id ON investment_status (org_id);

CREATE TABLE investments (
	investment_id			serial primary key,
	investment_type_id		integer references investment_types,
	investment_status_id	integer references investment_status,
	currency_id			integer references currency,
	entity_id 			integer references entitys,
	org_id				integer references orgs,

	investment_name 		varchar(120),
	started_date			date,
	expected_maturity		date,
	
	exchange_rate			real default 1 not null,
	proposed_capital		real default 0 not null,
	expected_profit			real default 0 not null,
	
	initial_payment			real default 0 not null,
	monthly_payments		real default 0 not null,
	monthly_returns			real default 0 not null,
	
	is_active				boolean default true not null,
	is_completed			boolean default true not null,

	application_date		timestamp,
	approve_status			varchar(16),
	workflow_table_id		integer,
	action_date				timestamp,

	details					text
);
CREATE INDEX investments_investment_type_id ON investments (investment_type_id);
CREATE INDEX investments_investment_status_id ON investments (investment_status_id);
CREATE INDEX investments_currency_id ON investments (currency_id);
CREATE INDEX investments_entity_id ON investments (entity_id);
CREATE INDEX investments_org_id ON investments (org_id);


ALTER TABLE transactions ADD investment_id integer references investments;
CREATE INDEX transactions_investment_id ON transactions (investment_id);

CREATE TABLE phases (
	phase_id				serial primary key,
	investment_id			integer references investments,
	org_id					integer references orgs,
	phase_name				varchar(240) not null,
	start_date				date not null,
	end_date				date,
	completed				boolean not null default false,
	phase_cost				real default 0 not null,
	details					text
);
CREATE INDEX phases_investment_id ON phases (investment_id);
CREATE INDEX phases_org_id ON phases(org_id);

CREATE TABLE tasks (
	task_id				serial primary key,
	phase_id				integer references phases,
	member_id				integer references members,
	org_id					integer references orgs,
	task_name				varchar(320) not null,
	task_start				date not null,
	task_deadline				date,
	task_end				date,
	task_cost				real default 0 not null,
	task_completed			boolean not null default false,
	details					text
);
CREATE INDEX tasks_phase_id ON tasks (phase_id);
CREATE INDEX tasks_member_id ON tasks (member_id);
CREATE INDEX tasks_org_id ON tasks (org_id);

CREATE VIEW vw_investments AS
	SELECT investment_types.investment_type_id, investment_types.investment_type_name,
		investment_status.investment_status_id, investment_status.investment_status_name, 
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		entitys.entity_id, entitys.entity_name, 
		investments.org_id, investments.investment_id, investments.investment_name, investments.started_date, 
		investments.expected_maturity, investments.exchange_rate, investments.proposed_capital, 
		investments.expected_profit, investments.initial_payment, investments.monthly_payments, 
		investments.monthly_returns, investments.is_active, investments.is_completed, 
		investments.application_date, investments.approve_status, investments.workflow_table_id, investments.action_date, 
		investments.details
	FROM investments INNER JOIN investment_types ON investments.investment_type_id = investment_types.investment_type_id
		INNER JOIN investment_status ON investments.investment_status_id = investment_status.investment_status_id
		INNER JOIN currency ON investments.currency_id = currency.currency_id
		INNER JOIN entitys ON investments.entity_id = entitys.entity_id;
		
CREATE VIEW vw_phases AS
	SELECT vw_investments.investment_type_id, vw_investments.investment_type_name,
		vw_investments.investment_status_id, vw_investments.investment_status_name, 
		vw_investments.investment_id, vw_investments.investment_name, vw_investments.started_date,
		phases.org_id, phases.phase_id, phases.phase_name, phases.start_date, phases.end_date, 
		phases.completed, phases.phase_cost, phases.details
	FROM phases INNER JOIN vw_investments ON phases.investment_id = vw_investments.investment_id;
	
CREATE VIEW vw_tasks AS
	SELECT vw_phases.investment_type_id, vw_phases.investment_type_name,
		vw_phases.investment_status_id, vw_phases.investment_status_name, 
		vw_phases.investment_id, vw_phases.investment_name, vw_phases.started_date,
		vw_phases.phase_id, vw_phases.phase_name, vw_phases.start_date, vw_phases.end_date, vw_phases.completed,
		members.entity_id, members.member_name, 
		tasks.org_id, tasks.task_id, tasks.task_name, tasks.task_start, tasks.task_deadline, tasks.task_end,
		tasks.task_cost, tasks.task_completed, tasks.details
	FROM tasks INNER JOIN vw_phases ON tasks.phase_id = vw_phases.phase_id
		INNER JOIN members ON tasks.member_id = members.member_id;

------------ Update Transactions view
DROP VIEW vws_tx_ledger;
DROP VIEW vw_tx_ledger;

CREATE VIEW vw_tx_ledger AS
	SELECT ledger_types.ledger_type_id, ledger_types.ledger_type_name, ledger_types.account_id, ledger_types.ledger_posting,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		entitys.entity_id, entitys.entity_name, 
		bank_accounts.bank_account_id, bank_accounts.bank_account_name,
		
		vw_investments.investment_type_id, vw_investments.investment_type_name,
		vw_investments.investment_status_id, vw_investments.investment_status_name, 
		vw_investments.investment_id, vw_investments.investment_name,
		
		transactions.org_id, transactions.transaction_id, transactions.journal_id, 
		transactions.exchange_rate, transactions.tx_type, transactions.transaction_date, transactions.payment_date,
		transactions.transaction_amount, transactions.transaction_tax_amount, transactions.reference_number, 
		transactions.payment_number, transactions.for_processing, transactions.completed, transactions.is_cleared,
		transactions.application_date, transactions.approve_status, transactions.workflow_table_id, transactions.action_date, 
		transactions.narrative, transactions.details,
		
		(CASE WHEN transactions.journal_id is null THEN 'Not Posted' ELSE 'Posted' END) as posted,
		to_char(transactions.payment_date, 'YYYY.MM') as ledger_period,
		to_char(transactions.payment_date, 'YYYY') as ledger_year,
		to_char(transactions.payment_date, 'Month') as ledger_month,
		
		(transactions.exchange_rate * transactions.tx_type * transactions.transaction_amount) as base_amount,
		(transactions.exchange_rate * transactions.tx_type * transactions.transaction_tax_amount) as base_tax_amount,
		
		(CASE WHEN transactions.completed = true THEN 
			(transactions.exchange_rate * transactions.tx_type * transactions.transaction_amount)
		ELSE 0::real END) as base_balance,
		
		(CASE WHEN transactions.is_cleared = true THEN 
			(transactions.exchange_rate * transactions.tx_type * transactions.transaction_amount)
		ELSE 0::real END) as cleared_balance,
		
		(CASE WHEN transactions.tx_type = 1 THEN 
			(transactions.exchange_rate * transactions.transaction_amount)
		ELSE 0::real END) as dr_amount,
		
		(CASE WHEN transactions.tx_type = -1 THEN 
			(transactions.exchange_rate * transactions.transaction_amount) 
		ELSE 0::real END) as cr_amount
		
	FROM transactions
		INNER JOIN currency ON transactions.currency_id = currency.currency_id
		INNER JOIN entitys ON transactions.entity_id = entitys.entity_id
		LEFT JOIN bank_accounts ON transactions.bank_account_id = bank_accounts.bank_account_id
		LEFT JOIN ledger_types ON transactions.ledger_type_id = ledger_types.ledger_type_id
		LEFT JOIN vw_investments ON transactions.investment_id = vw_investments.investment_id
	WHERE transactions.tx_type is not null;
	
CREATE VIEW vws_tx_ledger AS
	SELECT org_id, ledger_period, ledger_year, ledger_month, 
		sum(base_amount) as sum_base_amount, sum(base_tax_amount) as sum_base_tax_amount,
		sum(base_balance) as sum_base_balance, sum(cleared_balance) as sum_cleared_balance,
		sum(dr_amount) as sum_dr_amount, sum(cr_amount) as sum_cr_amount,
		
		to_date(ledger_period || '.01', 'YYYY.MM.DD') as start_date,
		sum(base_amount) + prev_balance(to_date(ledger_period || '.01', 'YYYY.MM.DD')) as prev_balance_amount,
		sum(cleared_balance) + prev_clear_balance(to_date(ledger_period || '.01', 'YYYY.MM.DD')) as prev_clear_balance_amount
			
	FROM vw_tx_ledger
	GROUP BY org_id, ledger_period, ledger_year, ledger_month;
