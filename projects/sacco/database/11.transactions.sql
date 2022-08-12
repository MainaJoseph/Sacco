CREATE TABLE stores (
	store_id				serial primary key,
	org_id					integer references orgs,
	store_name				varchar(120),
	details					text,
	UNIQUE(org_id, store_name)
);
CREATE INDEX stores_org_id ON stores (org_id);

CREATE TABLE bank_accounts (
	bank_account_id			serial primary key,
	org_id					integer references orgs,
	bank_branch_id			integer references bank_branch,
	account_id				integer references accounts,
	currency_id				integer references currency,
	bank_account_name		varchar(120),
	bank_account_number		varchar(50),
    narrative				varchar(240),
	is_default				boolean default false not null,
	is_active				boolean default true not null,
    details					text
);
CREATE INDEX bank_accounts_org_id ON bank_accounts (org_id);
CREATE INDEX bank_accounts_bank_branch_id ON bank_accounts (bank_branch_id);
CREATE INDEX bank_accounts_account_id ON bank_accounts (account_id);
CREATE INDEX bank_accounts_currency_id ON bank_accounts (currency_id);

CREATE TABLE item_category (
	item_category_id		serial primary key,
	org_id					integer references orgs,
	item_category_name		varchar(120) not null,
	details					text,
	UNIQUE(org_id, item_category_name)
);
CREATE INDEX item_category_org_id ON item_category (org_id);

CREATE TABLE item_units (
	item_unit_id			serial primary key,
	org_id					integer references orgs,
	item_unit_name			varchar(50) not null,
	details					text,
	UNIQUE(org_id, item_unit_name)
);
CREATE INDEX item_units_org_id ON item_units (org_id);

CREATE TABLE items (
	item_id					serial primary key,
	org_id					integer references orgs,
	item_category_id		integer references item_category,
	tax_type_id				integer references tax_types,
	item_unit_id			integer references item_units,
	sales_account_id		integer references accounts,
	purchase_account_id		integer references accounts,
	item_name				varchar(120) not null,
	bar_code				varchar(32),
	inventory				boolean default false not null,
	for_sale				boolean default true not null,
	for_purchase			boolean default true not null,
	for_stock				boolean default true not null,
	sales_price				real,
	purchase_price			real,
	reorder_level			integer,
	lead_time				integer,
	is_active				boolean default true not null,
	details					text,
	UNIQUE(org_id, item_name)
);
CREATE INDEX items_org_id ON items (org_id);
CREATE INDEX items_item_category_id ON items (item_category_id);
CREATE INDEX items_tax_type_id ON items (tax_type_id);
CREATE INDEX items_item_unit_id ON items (item_unit_id);
CREATE INDEX items_sales_account_id ON items (sales_account_id);
CREATE INDEX items_purchase_account_id ON items (purchase_account_id);

CREATE TABLE quotations (
	quotation_id 			serial primary key,
	org_id					integer references orgs,
	item_id					integer references items,
	entity_id				integer references entitys,
	active					boolean default false not null,
	amount 					real,
	valid_from				date,
	valid_to				date,
	lead_time				integer,
	details					text
);
CREATE INDEX quotations_org_id ON quotations (org_id);
CREATE INDEX quotations_item_id ON quotations (item_id);
CREATE INDEX quotations_entity_id ON quotations (entity_id);

CREATE TABLE stocks (
	stock_id				serial primary key,
	org_id					integer references orgs,
	store_id				integer references stores,
	stock_name				varchar(50),
	stock_take_date			date,
	details					text
);
CREATE INDEX stocks_store_id ON stocks (store_id);
CREATE INDEX stocks_org_id ON stocks (org_id);

CREATE TABLE stock_lines (
	stock_line_id			serial primary key,
	org_id					integer references orgs,
	stock_id				integer references stocks,
	item_id					integer references items,
	quantity				integer,
	narrative				varchar(240)
);
CREATE INDEX stock_lines_stock_id ON stock_lines (stock_id);
CREATE INDEX stock_lines_item_id ON stock_lines (item_id);
CREATE INDEX stock_lines_org_id ON stock_lines (org_id);

CREATE TABLE store_movement (
	store_movement_id		serial primary key,
	store_id				integer references stores,
	store_to_id				integer references stores,
	item_id					integer references items,
	org_id					integer references orgs,
	movement_date			date not null,
	quantity				integer not null,
	narrative				varchar(240)
);
CREATE INDEX store_movement_store_id ON store_movement (store_id);
CREATE INDEX store_movement_store_to_id ON store_movement (store_to_id);
CREATE INDEX store_movement_item_id ON store_movement (item_id);
CREATE INDEX store_movement_org_id ON store_movement (org_id);

CREATE TABLE transaction_types (
	transaction_type_id		integer primary key,
	transaction_type_name	varchar(50) not null,
	document_prefix			varchar(16) default 'D' not null,
	for_sales				boolean default true not null,
	for_posting				boolean default true not null
);

CREATE TABLE transaction_counters (
	transaction_counter_id	serial primary key,
	transaction_type_id		integer references transaction_types,
	org_id					integer references orgs,
	document_number			integer default 1 not null
);
CREATE INDEX transaction_counters_transaction_type_id ON transaction_counters (transaction_type_id);
CREATE INDEX transaction_counters_org_id ON transaction_counters (org_id);

CREATE TABLE transaction_status (
	transaction_status_id	integer primary key,
	transaction_status_name	varchar(50) not null
);

CREATE TABLE ledger_types (
	ledger_type_id			serial primary key,
	account_id				integer references accounts,
	tax_account_id			integer references accounts,
	org_id					integer references orgs,
	ledger_type_name		varchar(120) not null,
	ledger_posting			boolean default true not null,
	income_ledger			boolean default true not null,
	expense_ledger			boolean default true not null,
	details					text,
	UNIQUE(org_id, ledger_type_name)
);
CREATE INDEX ledger_types_account_id ON ledger_types (account_id);
CREATE INDEX ledger_types_tax_account_id ON ledger_types (tax_account_id);
CREATE INDEX ledger_types_org_id ON ledger_types (org_id);

CREATE TABLE ledger_links (
	ledger_link_id			serial primary key,
	ledger_type_id			integer references ledger_types,
	org_id					integer references orgs,
	link_type				integer,
	link_id					integer
);
CREATE INDEX ledger_links_ledger_type_id ON ledger_links (ledger_type_id);
CREATE INDEX ledger_links_org_id ON ledger_links (org_id);

CREATE TABLE transactions (
	transaction_id 			serial primary key,
	entity_id 				integer references entitys,
	transaction_type_id		integer references transaction_types,
	ledger_type_id			integer references ledger_types,
	transaction_status_id	integer references transaction_status default 1,
	bank_account_id			integer references bank_accounts,
	journal_id				integer references journals,
	currency_id				integer references currency,
	department_id			integer references departments,
	entered_by				integer references entitys,
	org_id					integer references orgs,
	
	exchange_rate			real default 1 not null,
	transaction_date		date not null,
	payment_date			date not null,
	transaction_amount		real default 0 not null,
	transaction_tax_amount	real default 0 not null,
	document_number			integer default 1 not null,
	
	tx_type					integer,
	
	for_processing			boolean default false not null,
	is_cleared				boolean default false not null,
	completed				boolean default false not null,

	reference_number		varchar(50),
	payment_number			varchar(50),
	order_number			varchar(50),
	payment_terms			varchar(50),
	
	job						varchar(240),
	point_of_use			varchar(240),
	
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	
    narrative				varchar(120),
	notes					text,
    details					text
);
CREATE INDEX transactions_entity_id ON transactions (entity_id);
CREATE INDEX transactions_transaction_type_id ON transactions (transaction_type_id);
CREATE INDEX transactions_bank_account_id ON transactions (bank_account_id);
CREATE INDEX transactions_journal_id ON transactions (journal_id);
CREATE INDEX transactions_transaction_status_id ON transactions (transaction_status_id);
CREATE INDEX transactions_currency_id ON transactions (currency_id);
CREATE INDEX transactions_department_id ON transactions (department_id);
CREATE INDEX transactions_workflow_table_id ON transactions (workflow_table_id);
CREATE INDEX transactions_entered_by ON transactions (entered_by);
CREATE INDEX transactions_org_id ON transactions (org_id);

CREATE TABLE transaction_details (
	transaction_detail_id 	serial primary key,
	transaction_id 			integer references transactions,
	account_id				integer references accounts,
	item_id					integer references items,
	store_id				integer references stores,
	org_id					integer references orgs,
	quantity				integer not null,
    amount 					real default 0 not null,
	tax_amount				real default 0 not null,
	discount				real default 0 not null CHECK (discount BETWEEN 0 AND 100),
	narrative				varchar(240),
	purpose					varchar(320),
	details					text
);
CREATE INDEX transaction_details_transaction_id ON transaction_details (transaction_id);
CREATE INDEX transaction_details_account_id ON transaction_details (account_id);
CREATE INDEX transaction_details_item_id ON transaction_details (item_id);
CREATE INDEX transaction_details_org_id ON transaction_details (org_id);

CREATE TABLE transaction_links (
	transaction_link_id		serial primary key,
	org_id					integer references orgs,
	transaction_id			integer references transactions,
	transaction_to			integer references transactions,
	transaction_detail_id	integer references transaction_details,
	transaction_detail_to	integer references transaction_details,
	amount					real default 0 not null,
	quantity				integer default 0  not null,
	narrative				varchar(240)
);
CREATE INDEX transaction_links_org_id ON transaction_links (org_id);
CREATE INDEX transaction_links_transaction_id ON transaction_links (transaction_id);
CREATE INDEX transaction_links_transaction_to ON transaction_links (transaction_to);
CREATE INDEX transaction_links_transaction_detail_id ON transaction_links (transaction_detail_id);
CREATE INDEX transaction_links_transaction_detail_to ON transaction_links (transaction_detail_to);

CREATE TABLE ss_types (
	ss_type_id				serial primary key,
	org_id					integer references orgs,
	ss_type_name			varchar(120),
	details					text
);
CREATE INDEX ss_types_org_id ON ss_types (org_id);

CREATE TABLE ss_items (
	ss_item_id				serial primary key,
	ss_type_id				integer references ss_types,
	org_id					integer references orgs,
	ss_item_name			varchar(120),
	picture					varchar(120),
	description				text,

	purchase_date			date not null,
	purchase_price			real default 0 not null,
	sale_date				date,
	sale_price				real default 0 not null,
	sold					boolean default false not null,
	
	details					text
);
CREATE INDEX ss_items_ss_type_id ON ss_items (ss_type_id);
CREATE INDEX ss_items_org_id ON ss_items (org_id);


CREATE VIEW vw_bank_accounts AS
	SELECT vw_bank_branch.bank_id, vw_bank_branch.bank_name, vw_bank_branch.bank_branch_id, vw_bank_branch.bank_branch_name, 
		vw_accounts.account_type_id, vw_accounts.account_type_name, vw_accounts.account_id, vw_accounts.account_name,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		bank_accounts.bank_account_id, bank_accounts.org_id, bank_accounts.bank_account_name, bank_accounts.bank_account_number, 
		bank_accounts.narrative, bank_accounts.is_active, bank_accounts.details
	FROM bank_accounts INNER JOIN vw_bank_branch ON bank_accounts.bank_branch_id = vw_bank_branch.bank_branch_id
		INNER JOIN vw_accounts ON bank_accounts.account_id = vw_accounts.account_id
		INNER JOIN currency ON bank_accounts.currency_id = currency.currency_id;

CREATE VIEW vw_items AS
	SELECT sales_account.account_id as sales_account_id, sales_account.account_name as sales_account_name, 
		purchase_account.account_id as purchase_account_id, purchase_account.account_name as purchase_account_name, 
		item_category.item_category_id, item_category.item_category_name, item_units.item_unit_id, item_units.item_unit_name, 
		tax_types.tax_type_id, tax_types.tax_type_name,
		tax_types.account_id as tax_account_id, tax_types.tax_rate, tax_types.tax_inclusive,
		items.item_id, items.org_id, items.item_name, items.bar_code,
		items.for_sale, items.for_purchase, items.for_stock, items.inventory,
		items.sales_price, items.purchase_price, items.reorder_level, items.lead_time, 
		items.is_active, items.details
	FROM items INNER JOIN accounts as sales_account ON items.sales_account_id = sales_account.account_id
		INNER JOIN accounts as purchase_account ON items.purchase_account_id = purchase_account.account_id
		INNER JOIN item_category ON items.item_category_id = item_category.item_category_id
		INNER JOIN item_units ON items.item_unit_id = item_units.item_unit_id
		INNER JOIN tax_types ON items.tax_type_id = tax_types.tax_type_id;

CREATE VIEW vw_quotations AS
	SELECT entitys.entity_id, entitys.entity_name, items.item_id, items.item_name, 
		quotations.quotation_id, quotations.org_id, quotations.active, quotations.amount, quotations.valid_from, 
		quotations.valid_to, quotations.lead_time, quotations.details
	FROM quotations	INNER JOIN entitys ON quotations.entity_id = entitys.entity_id
		INNER JOIN items ON quotations.item_id = items.item_id;
		
CREATE VIEW vw_stocks AS
	SELECT stores.store_id, stores.store_name,
		stocks.stock_id, stocks.org_id, stocks.stock_name, stocks.stock_take_date, stocks.details
	FROM stocks INNER JOIN stores ON stocks.store_id = stores.store_id;

CREATE VIEW vw_stock_lines AS
	SELECT vw_stocks.stock_id, vw_stocks.stock_name, vw_stocks.stock_take_date, 
		vw_stocks.store_id, vw_stocks.store_name, items.item_id, items.item_name, 
		stock_lines.stock_line_id, stock_lines.org_id, stock_lines.quantity, stock_lines.narrative
	FROM stock_lines INNER JOIN vw_stocks ON stock_lines.stock_id = vw_stocks.stock_id
		INNER JOIN items ON stock_lines.item_id = items.item_id;
		
CREATE VIEW vw_store_movement AS
	SELECT items.item_id, items.item_name, stores.store_id, stores.store_name, 
		store_to.store_id as store_to_id, stores.store_name as store_to_name, 
		store_movement.org_id, store_movement.store_movement_id, 
		store_movement.movement_date, store_movement.quantity, store_movement.narrative
	FROM store_movement INNER JOIN items ON store_movement.item_id = items.item_id
		INNER JOIN stores ON store_movement.store_id = stores.store_id
		INNER JOIN stores store_to ON store_movement.store_to_id = store_to.store_id;
	
CREATE VIEW vw_ledger_types AS
	SELECT vw_accounts.account_class_id, vw_accounts.chat_type_id, vw_accounts.chat_type_name, 
		vw_accounts.account_class_name, vw_accounts.account_type_id, vw_accounts.account_type_name,
		vw_accounts.account_id, vw_accounts.account_no, vw_accounts.account_name, 
		vw_accounts.is_header, vw_accounts.is_active,
		
		ta.account_class_id as t_account_class_id, ta.chat_type_id as t_chat_type_id, 
		ta.chat_type_name as t_chat_type_name, ta.account_class_name as t_account_class_name, 
		ta.account_type_id as t_account_type_id, ta.account_type_name as t_account_type_name,
		ta.account_id as t_account_id, ta.account_no as t_account_no, ta.account_name as t_account_name, 
		
		ledger_types.org_id, ledger_types.ledger_type_id, ledger_types.ledger_type_name, 
		ledger_types.ledger_posting, ledger_types.income_ledger, ledger_types.expense_ledger, ledger_types.details
	FROM ledger_types INNER JOIN vw_accounts ON ledger_types.account_id = vw_accounts.account_id
		INNER JOIN vw_accounts ta ON ledger_types.tax_account_id = ta.account_id;

CREATE VIEW vw_transaction_counters AS
	SELECT transaction_types.transaction_type_id, transaction_types.transaction_type_name, 
		transaction_types.document_prefix, transaction_types.for_posting, transaction_types.for_sales, 
		transaction_counters.org_id, transaction_counters.transaction_counter_id, transaction_counters.document_number
	FROM transaction_counters INNER JOIN transaction_types ON transaction_counters.transaction_type_id = transaction_types.transaction_type_id;
	
CREATE VIEW vw_transactions AS
	SELECT transaction_types.transaction_type_id, transaction_types.transaction_type_name, 
		transaction_types.document_prefix, transaction_types.for_posting, transaction_types.for_sales, 
		entitys.entity_id, entitys.entity_name, entitys.account_id as entity_account_id, 
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		vw_bank_accounts.bank_id, vw_bank_accounts.bank_name, vw_bank_accounts.bank_branch_name, vw_bank_accounts.account_id as gl_bank_account_id, 
		vw_bank_accounts.bank_account_id, vw_bank_accounts.bank_account_name, vw_bank_accounts.bank_account_number, 
		departments.department_id, departments.department_name,
		ledger_types.ledger_type_id, ledger_types.ledger_type_name, ledger_types.account_id as ledger_account_id, 
		ledger_types.tax_account_id, ledger_types.ledger_posting,
		transaction_status.transaction_status_id, transaction_status.transaction_status_name, transactions.journal_id, 
		transactions.transaction_id, transactions.org_id, transactions.transaction_date, transactions.transaction_amount,
		transactions.transaction_tax_amount,
		transactions.application_date, transactions.approve_status, transactions.workflow_table_id, transactions.action_date, 
		transactions.narrative, transactions.document_number, transactions.payment_number, transactions.order_number,
		transactions.exchange_rate, transactions.payment_terms, transactions.job, transactions.details, transactions.notes,
		(transactions.transaction_amount - transactions.transaction_tax_amount) as transaction_net_amount,
		(CASE WHEN transactions.journal_id is null THEN 'Not Posted' ELSE 'Posted' END) as posted,
		(CASE WHEN (transactions.transaction_type_id = 2) or (transactions.transaction_type_id = 8) or (transactions.transaction_type_id = 10) or (transactions.transaction_type_id = 21)  
			THEN transactions.transaction_amount ELSE 0 END) as debit_amount,
		(CASE WHEN (transactions.transaction_type_id = 5) or (transactions.transaction_type_id = 7) or (transactions.transaction_type_id = 9) or (transactions.transaction_type_id = 22) 
			THEN transactions.transaction_amount ELSE 0 END) as credit_amount
	FROM transactions INNER JOIN transaction_types ON transactions.transaction_type_id = transaction_types.transaction_type_id
		INNER JOIN transaction_status ON transactions.transaction_status_id = transaction_status.transaction_status_id
		INNER JOIN currency ON transactions.currency_id = currency.currency_id
		LEFT JOIN entitys ON transactions.entity_id = entitys.entity_id
		LEFT JOIN vw_bank_accounts ON vw_bank_accounts.bank_account_id = transactions.bank_account_id
		LEFT JOIN departments ON transactions.department_id = departments.department_id
		LEFT JOIN ledger_types ON transactions.ledger_type_id = ledger_types.ledger_type_id;

CREATE VIEW vw_trx AS
	SELECT vw_orgs.org_id, vw_orgs.org_name, vw_orgs.is_default as org_is_default, vw_orgs.is_active as org_is_active, 
		vw_orgs.logo as org_logo, vw_orgs.cert_number as org_cert_number, vw_orgs.pin as org_pin, 
		vw_orgs.vat_number as org_vat_number, vw_orgs.invoice_footer as org_invoice_footer,
		vw_orgs.org_sys_country_id, vw_orgs.org_sys_country_name, 
		vw_orgs.org_address_id, vw_orgs.org_table_name,
		vw_orgs.org_post_office_box, vw_orgs.org_postal_code, 
		vw_orgs.org_premises, vw_orgs.org_street, vw_orgs.org_town, 
		vw_orgs.org_phone_number, vw_orgs.org_extension, 
		vw_orgs.org_mobile, vw_orgs.org_fax, vw_orgs.org_email, vw_orgs.org_website,
		
		vw_entitys.address_id, vw_entitys.address_name,
		vw_entitys.sys_country_id, vw_entitys.sys_country_name, vw_entitys.table_name, vw_entitys.is_default,
		vw_entitys.post_office_box, vw_entitys.postal_code, vw_entitys.premises, vw_entitys.street, vw_entitys.town, 
		vw_entitys.phone_number, vw_entitys.extension, vw_entitys.mobile, vw_entitys.fax, vw_entitys.email, vw_entitys.website,
		vw_entitys.entity_id, vw_entitys.entity_name, vw_entitys.User_name, vw_entitys.Super_User, vw_entitys.attention, 
		vw_entitys.Date_Enroled, vw_entitys.is_Active, vw_entitys.entity_type_id, vw_entitys.entity_type_name,
		vw_entitys.entity_role, vw_entitys.use_key_id,
		transaction_types.transaction_type_id, transaction_types.transaction_type_name, 
		transaction_types.document_prefix, transaction_types.for_sales, transaction_types.for_posting,
		transaction_status.transaction_status_id, transaction_status.transaction_status_name, 
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		departments.department_id, departments.department_name,
		transactions.journal_id, transactions.bank_account_id, transactions.ledger_type_id,
		transactions.transaction_id, transactions.transaction_date, transactions.transaction_amount, transactions.transaction_tax_amount,
		transactions.application_date, transactions.approve_status, transactions.workflow_table_id, transactions.action_date, 
		transactions.narrative, transactions.document_number, transactions.payment_number, transactions.order_number,
		transactions.exchange_rate, transactions.payment_terms, transactions.job, transactions.details, transactions.notes,
		(transactions.transaction_amount - transactions.transaction_tax_amount) as transaction_net_amount,
		(CASE WHEN transactions.journal_id is null THEN 'Not Posted' ELSE 'Posted' END) as posted,
		(CASE WHEN (transactions.transaction_type_id = 2) or (transactions.transaction_type_id = 8) or (transactions.transaction_type_id = 10)
			THEN transactions.transaction_amount ELSE 0 END) as debit_amount,
		(CASE WHEN (transactions.transaction_type_id = 5) or (transactions.transaction_type_id = 7) or (transactions.transaction_type_id = 9)
			THEN transactions.transaction_amount ELSE 0 END) as credit_amount
	FROM transactions INNER JOIN transaction_types ON transactions.transaction_type_id = transaction_types.transaction_type_id
		INNER JOIN vw_orgs ON transactions.org_id = vw_orgs.org_id
		INNER JOIN transaction_status ON transactions.transaction_status_id = transaction_status.transaction_status_id
		INNER JOIN currency ON transactions.currency_id = currency.currency_id
		LEFT JOIN vw_entitys ON transactions.entity_id = vw_entitys.entity_id
		LEFT JOIN departments ON transactions.department_id = departments.department_id;

CREATE VIEW vw_trx_sum AS
	SELECT transaction_details.transaction_id, 
		SUM(transaction_details.quantity * transaction_details.amount * (100 - transaction_details.discount) / 100) as total_amount,
		SUM(transaction_details.quantity * transaction_details.tax_amount * (100 - transaction_details.discount) / 100) as total_tax_amount,
		SUM(transaction_details.quantity * ((100 - transaction_details.discount) / 100) * 
			(transaction_details.amount + transaction_details.tax_amount)) as total_sale_amount
	FROM transaction_details
	GROUP BY transaction_details.transaction_id;

CREATE VIEW vw_transaction_details AS
	SELECT vw_transactions.department_id, vw_transactions.department_name, vw_transactions.transaction_type_id, 
		vw_transactions.transaction_type_name, vw_transactions.document_prefix, vw_transactions.transaction_id, 
		vw_transactions.transaction_date, vw_transactions.entity_id, vw_transactions.entity_name,
		vw_transactions.document_number, vw_transactions.approve_status, vw_transactions.workflow_table_id,
		vw_transactions.currency_name, vw_transactions.exchange_rate,
		accounts.account_id, accounts.account_name, stores.store_id, stores.store_name, 
		
		vw_items.item_id, vw_items.item_name,
		vw_items.tax_type_id, vw_items.tax_account_id, vw_items.tax_type_name, vw_items.tax_rate, vw_items.tax_inclusive,
		vw_items.sales_account_id, vw_items.purchase_account_id,
		vw_items.for_sale, vw_items.for_purchase, vw_items.for_stock, vw_items.inventory,
		
		transaction_details.transaction_detail_id, transaction_details.org_id, transaction_details.quantity, 
		transaction_details.amount, transaction_details.tax_amount, transaction_details.discount,
		transaction_details.narrative, transaction_details.details,
		COALESCE(transaction_details.narrative, vw_items.item_name) as item_description,
		(transaction_details.quantity * ((100 - transaction_details.discount) / 100) * transaction_details.amount) as full_amount,
		(transaction_details.quantity * ((100 - transaction_details.discount) / 100) * transaction_details.tax_amount) as full_tax_amount,
		(transaction_details.quantity * ((100 - transaction_details.discount) / 100) * 
			(transaction_details.amount + transaction_details.tax_amount)) as full_total_amount,
		(CASE WHEN (vw_transactions.transaction_type_id = 5) or (vw_transactions.transaction_type_id = 9) 
			THEN (transaction_details.quantity * ((100 - transaction_details.discount) / 100) * transaction_details.tax_amount) ELSE 0 END) as tax_debit_amount,
		(CASE WHEN (vw_transactions.transaction_type_id = 2) or (vw_transactions.transaction_type_id = 10) 
			THEN (transaction_details.quantity * ((100 - transaction_details.discount) / 100) * transaction_details.tax_amount) ELSE 0 END) as tax_credit_amount,
		(CASE WHEN (vw_transactions.transaction_type_id = 5) or (vw_transactions.transaction_type_id = 9) 
			THEN (transaction_details.quantity * ((100 - transaction_details.discount) / 100) * transaction_details.amount) ELSE 0 END) as full_debit_amount,
		(CASE WHEN (vw_transactions.transaction_type_id = 2) or (vw_transactions.transaction_type_id = 10) 
			THEN (transaction_details.quantity * ((100 - transaction_details.discount) / 100) * transaction_details.amount)  ELSE 0 END) as full_credit_amount,
		(CASE WHEN (vw_transactions.transaction_type_id = 2) or (vw_transactions.transaction_type_id = 9) 
			THEN vw_items.sales_account_id ELSE vw_items.purchase_account_id END) as trans_account_id
	FROM transaction_details INNER JOIN vw_transactions ON transaction_details.transaction_id = vw_transactions.transaction_id
		LEFT JOIN vw_items ON transaction_details.item_id = vw_items.item_id
		LEFT JOIN accounts ON transaction_details.account_id = accounts.account_id
		LEFT JOIN stores ON transaction_details.store_id = stores.store_id;
		
CREATE VIEW vw_tx_ledger AS
	SELECT ledger_types.ledger_type_id, ledger_types.ledger_type_name, ledger_types.account_id, ledger_types.ledger_posting,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		entitys.entity_id, entitys.entity_name, 
		bank_accounts.bank_account_id, bank_accounts.bank_account_name,
		
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
	WHERE transactions.tx_type is not null;
	
CREATE OR REPLACE FUNCTION prev_balance(date) RETURNS real AS $$
    SELECT COALESCE(sum(transactions.exchange_rate * transactions.tx_type * transactions.transaction_amount), 0)::real
	FROM transactions
	WHERE (transactions.payment_date < $1) 
		AND (transactions.tx_type is not null);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION prev_clear_balance(date) RETURNS real AS $$
    SELECT COALESCE(sum(transactions.exchange_rate * transactions.tx_type * transactions.transaction_amount), 0)::real
	FROM transactions
	WHERE (transactions.payment_date < $1) AND (transactions.completed = true) 
		AND (transactions.is_cleared = true) AND (transactions.tx_type is not null);
$$ LANGUAGE SQL;
	
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

CREATE VIEW vw_stock_movement AS
	SELECT org_id, department_id, department_name, transaction_type_id, transaction_type_name, 
		document_prefix, document_number, transaction_id, transaction_date, 
		entity_id, entity_name, approve_status,  store_id, store_name, 
		item_id, item_name, 
		(CASE WHEN transaction_type_id = 11 THEN quantity ELSE 0 END) as q_sold,
		(CASE WHEN transaction_type_id = 12 THEN quantity ELSE 0 END) as q_purchased,
		(CASE WHEN transaction_type_id = 17 THEN quantity ELSE 0 END) as q_used

	FROM vw_transaction_details

	WHERE (transaction_type_id IN (11, 17, 12)) AND (for_stock = true) AND (approve_status <> 'Draft');

CREATE VIEW vw_ss_items AS
	SELECT orgs.org_id, orgs.org_name, 
		ss_types.ss_type_id, ss_types.ss_type_name, 
		ss_items.ss_item_id, ss_items.ss_item_name, ss_items.picture, 
		ss_items.description, ss_items.purchase_date, ss_items.purchase_price, 
		ss_items.sale_date, ss_items.sale_price, ss_items.sold, ss_items.details,

		(ss_items.sale_price - ss_items.purchase_price) as gross_margin
	FROM ss_items INNER JOIN ss_types ON ss_items.ss_type_id = ss_types.ss_type_id
		INNER JOIN orgs ON ss_items.org_id = orgs.org_id;
	

CREATE OR REPLACE FUNCTION get_opening_stock(integer, date) RETURNS integer AS $$
	SELECT COALESCE(sum(q_purchased - q_sold - q_used)::integer, 0)
	FROM vw_stock_movement
	WHERE (item_id = $1) AND (transaction_date < $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION upd_trx_ledger(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg							varchar(120);
BEGIN
	
	IF ($3 = '1') THEN
		UPDATE transactions SET for_processing = true WHERE transaction_id = $1::integer;
		msg := 'Opened for processing';
	ELSIF ($3 = '2') THEN
		UPDATE transactions SET for_processing = false WHERE transaction_id = $1::integer;
		msg := 'Closed for processing';
	ELSIF ($3 = '3') THEN
		UPDATE transactions  SET payment_date = current_date, completed = true
		WHERE transaction_id = $1::integer AND completed = false;
		msg := 'Completed';
	ELSIF ($3 = '4') THEN
		UPDATE transactions  SET is_cleared = true WHERE transaction_id = $1::integer;
		msg := 'Cleared for posting ';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cpy_trx_ledger(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_ledger_date				timestamp;
	last_date					timestamp;
	v_start						integer;
	v_end						integer;
	v_inteval					interval;
	msg							varchar(120);
BEGIN

	SELECT max(payment_date)::timestamp INTO last_date
	FROM transactions
	WHERE (to_char(payment_date, 'YYYY.MM') = $1);
	v_start := EXTRACT(YEAR FROM last_date) * 12 + EXTRACT(MONTH FROM last_date);
	
	SELECT max(payment_date)::timestamp INTO v_ledger_date
	FROM transactions;
	v_end := EXTRACT(YEAR FROM v_ledger_date) * 12 + EXTRACT(MONTH FROM v_ledger_date) + 1;
	v_inteval :=  ((v_end - v_start) || ' months')::interval;

	IF ($3 = '1') THEN
		INSERT INTO transactions(ledger_type_id, entity_id, bank_account_id, 
				currency_id, journal_id, org_id, exchange_rate, tx_type, payment_date, 
				transaction_amount, transaction_tax_amount, reference_number, 
				narrative, transaction_type_id, transaction_date)
		SELECT ledger_type_id, entity_id, bank_account_id, 
			currency_id, journal_id, org_id, exchange_rate, tx_type, (payment_date + v_inteval), 
			transaction_amount, transaction_tax_amount, reference_number,
			narrative, transaction_type_id, (transaction_date  + v_inteval)
		FROM transactions
		WHERE (tx_type is not null) AND (to_char(payment_date, 'YYYY.MM') = $1);

		msg := 'Appended a new month';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cpy_trx_transaction(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_inteval					interval;
	msg							varchar(120);
BEGIN
	
	IF ($3 = '1') THEN
		v_inteval :=  '1 month'::interval;
		
		INSERT INTO transactions(ledger_type_id, entity_id, bank_account_id, 
				currency_id, journal_id, org_id, exchange_rate, tx_type, payment_date, 
				transaction_amount, transaction_tax_amount, reference_number, 
				narrative, transaction_type_id, transaction_date)
		SELECT ledger_type_id, entity_id, bank_account_id, 
			currency_id, journal_id, org_id, exchange_rate, tx_type, (payment_date + v_inteval), 
			transaction_amount, transaction_tax_amount, reference_number,
			narrative, transaction_type_id, (transaction_date  + v_inteval)
		FROM transactions
		WHERE (transaction_id = $1::int);

		msg := 'Appended a new month';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upd_transaction_details() RETURNS trigger AS $$
DECLARE
	statusID 	INTEGER;
	journalID 	INTEGER;
	v_for_sale	BOOLEAN;
	accountid 	INTEGER;
	taxrate 	REAL;
BEGIN
	SELECT transactions.transaction_status_id, transactions.journal_id, transaction_types.for_sales
		INTO statusID, journalID, v_for_sale
	FROM transaction_types INNER JOIN transactions ON transaction_types.transaction_type_id = transactions.transaction_type_id
	WHERE (transaction_id = NEW.transaction_id);

	IF ((statusID > 1) OR (journalID is not null)) THEN
		RAISE EXCEPTION 'Transaction is already posted no changes are allowed.';
	END IF;

	IF(v_for_sale = true)THEN
		SELECT items.sales_account_id, tax_types.tax_rate INTO accountid, taxrate
		FROM tax_types INNER JOIN items ON tax_types.tax_type_id = items.tax_type_id
		WHERE (items.item_id = NEW.item_id);
	ELSE
		SELECT items.purchase_account_id, tax_types.tax_rate INTO accountid, taxrate
		FROM tax_types INNER JOIN items ON tax_types.tax_type_id = items.tax_type_id
		WHERE (items.item_id = NEW.item_id);
	END IF;

	NEW.tax_amount := NEW.amount * taxrate / 100;
	IF(accountid is not null)THEN
		NEW.account_id := accountid;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_transaction_details BEFORE INSERT OR UPDATE ON transaction_details
    FOR EACH ROW EXECUTE PROCEDURE upd_transaction_details();

CREATE OR REPLACE FUNCTION af_upd_transaction_details() RETURNS trigger AS $$
DECLARE
	v_amount					real;
	v_tax_amount				real;
BEGIN

	IF(TG_OP = 'DELETE')THEN
		SELECT SUM(quantity * (amount + tax_amount) * ((100 - discount) / 100)), 
			SUM(quantity *  tax_amount * ((100 - discount) / 100)) 
			INTO v_amount, v_tax_amount
		FROM transaction_details WHERE (transaction_id = OLD.transaction_id);
		IF(v_amount is null)THEN v_amount := 0; END IF;
		IF(v_tax_amount is null)THEN v_tax_amount := 0; END IF;
		
		UPDATE transactions SET transaction_amount = v_amount, transaction_tax_amount = v_tax_amount
		WHERE (transaction_id = OLD.transaction_id);	
	ELSE
		SELECT SUM(quantity * (amount + tax_amount) * ((100 - discount) / 100)), 
			SUM(quantity *  tax_amount * ((100 - discount) / 100)) 
			INTO v_amount, v_tax_amount
		FROM transaction_details WHERE (transaction_id = NEW.transaction_id);
		
		UPDATE transactions SET transaction_amount = v_amount, transaction_tax_amount = v_tax_amount
		WHERE (transaction_id = NEW.transaction_id);	
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER af_upd_transaction_details AFTER INSERT OR UPDATE OR DELETE ON transaction_details
    FOR EACH ROW EXECUTE PROCEDURE af_upd_transaction_details();

CREATE OR REPLACE FUNCTION ins_transactions() RETURNS trigger AS $$
DECLARE
	v_counter_id	integer;
	transid 		integer;
	currid			integer;
BEGIN

	IF(TG_OP = 'INSERT') THEN
		SELECT transaction_counter_id, document_number INTO v_counter_id, transid
		FROM transaction_counters 
		WHERE (transaction_type_id = NEW.transaction_type_id) AND (org_id = NEW.org_id);
		UPDATE transaction_counters SET document_number = transid + 1 
		WHERE (transaction_counter_id = v_counter_id);

		NEW.document_number := transid;
		IF(NEW.currency_id is null)THEN
			SELECT currency_id INTO NEW.currency_id
			FROM orgs
			WHERE (org_id = NEW.org_id);
		END IF;
				
		IF(NEW.payment_date is null) AND (NEW.transaction_date is not null)THEN
			NEW.payment_date := NEW.transaction_date;
		END IF;
	ELSE
	
		--- Ensure the direct expediture items are not added
		IF (OLD.ledger_type_id is null) AND (NEW.ledger_type_id is not null) THEN
			NEW.ledger_type_id := null;
		END IF;
			
		IF (OLD.journal_id is null) AND (NEW.journal_id is not null) THEN
		ELSIF ((OLD.approve_status != 'Completed') AND (NEW.approve_status = 'Completed')) THEN
			NEW.completed = true;
		ELSIF ((OLD.approve_status = 'Completed') AND (NEW.approve_status != 'Completed')) THEN
		ELSIF ((OLD.is_cleared = false) AND (NEW.is_cleared = true)) THEN
		ELSIF ((OLD.journal_id is not null) AND (OLD.transaction_status_id = NEW.transaction_status_id)) THEN
			RAISE EXCEPTION 'Transaction % is already posted no changes are allowed.', NEW.transaction_id;
		ELSIF ((OLD.transaction_status_id > 1) AND (OLD.transaction_status_id = NEW.transaction_status_id)) THEN
			RAISE EXCEPTION 'Transaction % is already completed no changes are allowed.', NEW.transaction_id;
		END IF;
	END IF;
	
	IF ((NEW.approve_status = 'Draft') AND (NEW.completed = true)) THEN
		NEW.approve_status := 'Completed';
		NEW.transaction_status_id := 2;
	END IF;
	
	IF(NEW.transaction_type_id = 7)THEN
		NEW.tx_type := 1;
	END IF;
	IF(NEW.transaction_type_id = 8)THEN
		NEW.tx_type := -1;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_transactions BEFORE INSERT OR UPDATE ON transactions
    FOR EACH ROW EXECUTE PROCEDURE ins_transactions();

CREATE OR REPLACE FUNCTION get_period(date) RETURNS INTEGER AS $$
	SELECT period_id FROM periods WHERE (start_date <= $1) AND (end_date >= $1); 
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_open_period(date) RETURNS INTEGER AS $$
	SELECT period_id FROM periods WHERE (start_date <= $1) AND (end_date >= $1)
		AND (opened = true) AND (closed = false); 
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION complete_transaction(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec RECORD;
	bankacc INTEGER;
	msg varchar(120);
BEGIN
	SELECT transaction_id, transaction_type_id, transaction_status_id, bank_account_id INTO rec
	FROM transactions
	WHERE (transaction_id = CAST($1 as integer));

	IF($3 = '2') THEN
		UPDATE transactions SET transaction_status_id = 4 
		WHERE transaction_id = rec.transaction_id;
		msg := 'Transaction Archived';
	ELSIF($3 = '1') AND (rec.transaction_status_id = 1)THEN
		IF((rec.transaction_type_id = 7) or (rec.transaction_type_id = 8)) THEN
			IF(rec.bank_account_id is null)THEN
				msg := 'Transaction completed.';
				RAISE EXCEPTION 'You need to add the bank account to receive the funds';
			ELSE
				UPDATE transactions SET transaction_status_id = 2, approve_status = 'Completed'
				WHERE transaction_id = rec.transaction_id;
				msg := 'Transaction completed.';
			END IF;
		ELSE
			UPDATE transactions SET transaction_status_id = 2, approve_status = 'Completed'
			WHERE transaction_id = rec.transaction_id;
			msg := 'Transaction completed.';
		END IF;
	ELSE
		msg := 'Transaction alerady completed.';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION copy_transaction(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg varchar(120);
BEGIN

	INSERT INTO transactions (org_id, department_id, entity_id, currency_id, transaction_type_id, transaction_date, order_number, payment_terms, job, narrative, details, notes)
	SELECT org_id, department_id, entity_id, currency_id, transaction_type_id, CURRENT_DATE, order_number, payment_terms, job, narrative, details, notes
	FROM transactions
	WHERE (transaction_id = CAST($1 as integer));

	INSERT INTO transaction_details (org_id, transaction_id, account_id, item_id, quantity, amount, tax_amount, narrative, details, discount)
	SELECT org_id, currval('transactions_transaction_id_seq'), account_id, item_id, quantity, amount, tax_amount, narrative, details, discount
	FROM transaction_details
	WHERE (transaction_id = CAST($1 as integer));

	msg := 'Transaction Copied';

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION process_transaction(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec RECORD;
	bankacc INTEGER;
	msg varchar(120);
BEGIN
	SELECT org_id, transaction_id, transaction_type_id, transaction_status_id, transaction_amount INTO rec
	FROM transactions
	WHERE (transaction_id = CAST($1 as integer));

	IF(rec.transaction_status_id = 1) THEN
		msg := 'Transaction needs to be completed first.';
	ELSIF(rec.transaction_status_id = 2) THEN
		IF (($3 = '7') AND ($3 = '8')) THEN
			SELECT max(bank_account_id) INTO bankacc
			FROM bank_accounts WHERE (is_default = true);

			INSERT INTO transactions (org_id, department_id, entity_id, currency_id, transaction_type_id, transaction_date, bank_account_id, transaction_amount)
			SELECT transactions.org_id, transactions.department_id, transactions.entity_id, transactions.currency_id, 1, CURRENT_DATE, bankacc, 
				SUM(transaction_details.quantity * (transaction_details.amount + transaction_details.tax_amount))
			FROM transactions INNER JOIN transaction_details ON transactions.transaction_id = transaction_details.transaction_id
			WHERE (transactions.transaction_id = rec.transaction_id)
			GROUP BY transactions.transaction_id, transactions.entity_id;

			INSERT INTO transaction_links (org_id, transaction_id, transaction_to, amount)
			VALUES (rec.org_id, currval('transactions_transaction_id_seq'), rec.transaction_id, rec.transaction_amount);
		
			UPDATE transactions SET transaction_status_id = 3 WHERE transaction_id = rec.transaction_id;
		ELSE
			INSERT INTO transactions (org_id, department_id, entity_id, currency_id, transaction_type_id, transaction_date, order_number, payment_terms, job, narrative, details)
			SELECT org_id, department_id, entity_id, currency_id, CAST($3 as integer), CURRENT_DATE, order_number, payment_terms, job, narrative, details
			FROM transactions
			WHERE (transaction_id = rec.transaction_id);

			INSERT INTO transaction_details (org_id, transaction_id, account_id, item_id, quantity, amount, tax_amount, narrative, details)
			SELECT org_id, currval('transactions_transaction_id_seq'), account_id, item_id, quantity, amount, tax_amount, narrative, details
			FROM transaction_details
			WHERE (transaction_id = rec.transaction_id);

			INSERT INTO transaction_links (org_id, transaction_id, transaction_to, amount)
			VALUES (REC.org_id, currval('transactions_transaction_id_seq'), rec.transaction_id, rec.transaction_amount);

			UPDATE transactions SET transaction_status_id = 3 WHERE transaction_id = rec.transaction_id;
		END IF;
		msg := 'Transaction proccesed';
	ELSE
		msg := 'Transaction previously Processed.';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION post_transaction(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec					RECORD;
	v_period_id			int;
	v_journal_id		int;
	msg					varchar(120);
BEGIN
	SELECT org_id, department_id, transaction_id, transaction_type_id, transaction_type_name as tx_name, 
		transaction_status_id, journal_id, gl_bank_account_id, currency_id, exchange_rate,
		transaction_date, transaction_amount, transaction_tax_amount, document_number, 
		credit_amount, debit_amount, entity_account_id, entity_name, approve_status, 
		ledger_account_id, tax_account_id, ledger_posting INTO rec
	FROM vw_transactions
	WHERE (transaction_id = CAST($1 as integer));

	v_period_id := get_open_period(rec.transaction_date);
	IF(v_period_id is null) THEN
		msg := 'No active period to post.';
		RAISE EXCEPTION 'No active period to post.';
	ELSIF(rec.journal_id is not null) THEN
		msg := 'Transaction previously Posted.';
		RAISE EXCEPTION 'Transaction previously Posted.';
	ELSIF(rec.transaction_status_id = 1) THEN
		msg := 'Transaction needs to be completed first.';
		RAISE EXCEPTION 'Transaction needs to be completed first.';
	ELSIF(rec.approve_status != 'Approved') THEN
		msg := 'Transaction is not yet approved.';
		RAISE EXCEPTION 'Transaction is not yet approved.';
	ELSIF((rec.ledger_account_id is not null) AND (rec.ledger_posting = false)) THEN
		msg := 'Transaction not for posting.';
		RAISE EXCEPTION 'Transaction not for posting.';
	ELSE
		v_journal_id := nextval('journals_journal_id_seq');
		INSERT INTO journals (journal_id, org_id, department_id, currency_id, period_id, exchange_rate, journal_date, narrative)
		VALUES (v_journal_id, rec.org_id, rec.department_id, rec.currency_id, v_period_id, rec.exchange_rate, rec.transaction_date, rec.tx_name || ' - posting for ' || rec.document_number);
		
		IF((rec.transaction_type_id = 7) or (rec.transaction_type_id = 8)) THEN
			INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
			VALUES (rec.org_id, v_journal_id, rec.entity_account_id, rec.debit_amount, rec.credit_amount, rec.tx_name || ' - ' || rec.entity_name);

			INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
			VALUES (rec.org_id, v_journal_id, rec.gl_bank_account_id, rec.credit_amount, rec.debit_amount, rec.tx_name || ' - ' || rec.entity_name);
		ELSIF((rec.transaction_type_id = 21) or (rec.transaction_type_id = 22)) THEN		
			INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
			VALUES (rec.org_id, v_journal_id, rec.gl_bank_account_id, rec.credit_amount, rec.debit_amount, rec.tx_name || ' - ' || rec.entity_name);
			
			IF(rec.transaction_tax_amount = 0)THEN
				INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
				VALUES (rec.org_id, v_journal_id, rec.ledger_account_id, rec.debit_amount, rec.credit_amount, rec.tx_name || ' - ' || rec.entity_name);
			ELSIF(rec.transaction_type_id = 21)THEN
				INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
				VALUES (rec.org_id, v_journal_id, rec.ledger_account_id, rec.debit_amount - rec.transaction_tax_amount, rec.credit_amount, rec.tx_name || ' - ' || rec.entity_name);
				
				INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
				VALUES (rec.org_id, v_journal_id, rec.tax_account_id, rec.transaction_tax_amount, 0, rec.tx_name || ' - ' || rec.entity_name);
			ELSE
				INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
				VALUES (rec.org_id, v_journal_id, rec.ledger_account_id, rec.debit_amount, rec.credit_amount - rec.transaction_tax_amount, rec.tx_name || ' - ' || rec.entity_name);
				
				INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
				VALUES (rec.org_id, v_journal_id, rec.tax_account_id, 0, rec.transaction_tax_amount, rec.tx_name || ' - ' || rec.entity_name);			
			END IF;
		ELSE
			INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
			VALUES (rec.org_id, v_journal_id, rec.entity_account_id, rec.debit_amount, rec.credit_amount, rec.tx_name || ' - ' || rec.entity_name);

			INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
			SELECT org_id, v_journal_id, trans_account_id, full_debit_amount, full_credit_amount, rec.tx_name || ' - ' || item_name
			FROM vw_transaction_details
			WHERE (transaction_id = rec.transaction_id) AND (full_amount > 0);

			INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
			SELECT org_id, v_journal_id, tax_account_id, tax_debit_amount, tax_credit_amount, rec.tx_name || ' - ' || item_name
			FROM vw_transaction_details
			WHERE (transaction_id = rec.transaction_id) AND (full_tax_amount > 0);
		END IF;

		UPDATE transactions SET journal_id = v_journal_id WHERE (transaction_id = rec.transaction_id);
		msg := process_journal(CAST(v_journal_id as varchar),'0','0');
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_tx_link(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
BEGIN
	
	INSERT INTO transaction_details (transaction_id, org_id, item_id, quantity, amount, tax_amount, narrative, details)
	SELECT CAST($3 as integer), org_id, item_id, quantity, amount, tax_amount, narrative, details
	FROM transaction_details
	WHERE (transaction_detail_id = CAST($1 as integer));

	INSERT INTO transaction_links (org_id, transaction_detail_id, transaction_detail_to, quantity, amount)
	SELECT org_id, transaction_detail_id, currval('transaction_details_transaction_detail_id_seq'), quantity, amount
	FROM transaction_details
	WHERE (transaction_detail_id = CAST($1 as integer));

	return 'DONE';
END;
$$ LANGUAGE plpgsql;


------------Hooks to approval trigger
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON transactions
    FOR EACH ROW EXECUTE PROCEDURE upd_action();


CREATE OR REPLACE FUNCTION get_budgeted(integer, date, integer) RETURNS real AS $$
DECLARE
	reca		RECORD;
	app_id		Integer;
	v_bill		real;
	v_variance	real;
BEGIN

	FOR reca IN SELECT transaction_detail_id, account_id, amount 
		FROM transaction_details WHERE (transaction_id = $1) LOOP

		SELECT sum(amount) INTO v_bill
		FROM transactions INNER JOIN transaction_details ON transactions.transaction_id = transaction_details.transaction_id
		WHERE (transactions.department_id = $3) AND (transaction_details.account_id = reca.account_id)
			AND (transactions.journal_id is null) AND (transaction_details.transaction_detail_id <> reca.transaction_detail_id);
		IF(v_bill is null)THEN
			v_bill := 0;
		END IF;

		SELECT sum(budget_lines.amount) INTO v_variance
		FROM fiscal_years INNER JOIN budgets ON fiscal_years.fiscal_year_id = budgets.fiscal_year_id
			INNER JOIN budget_lines ON budgets.budget_id = budget_lines.budget_id
		WHERE (budgets.department_id = $3) AND (budget_lines.account_id = reca.account_id)
			AND (budgets.approve_status = 'Approved')
			AND (fiscal_years.fiscal_year_start <= $2) AND (fiscal_years.fiscal_year_end >= $2);
		IF(v_variance is null)THEN
			v_variance := 0;
		END IF;

		v_variance := v_variance - (reca.amount + v_bill);

		IF(v_variance < 0)THEN
			RETURN v_variance;
		END IF;
	END LOOP;

	RETURN v_variance;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upd_approvals(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	app_id		Integer;
	reca 		RECORD;
	recb		RECORD;
	recc		RECORD;
	recd		RECORD;

	min_level	Integer;
	mysql		varchar(240);
	msg 		varchar(120);
BEGIN
	app_id := CAST($1 as int);
	SELECT approvals.approval_id, approvals.org_id, approvals.table_name, approvals.table_id, 
		approvals.approval_level, approvals.review_advice, approvals.org_entity_id,
		workflow_phases.workflow_phase_id, workflow_phases.workflow_id, workflow_phases.return_level 
	INTO reca
	FROM approvals INNER JOIN workflow_phases ON approvals.workflow_phase_id = workflow_phases.workflow_phase_id
	WHERE (approvals.approval_id = app_id);

	SELECT count(approval_checklist_id) as cl_count INTO recc
	FROM approval_checklists
	WHERE (approval_id = app_id) AND (manditory = true) AND (done = false);

	SELECT orgs.org_id, transactions.transaction_type_id, orgs.enforce_budget,
		get_budgeted(transactions.transaction_id, transactions.transaction_date, transactions.department_id) as budget_var 
		INTO recd
	FROM orgs INNER JOIN transactions ON orgs.org_id = transactions.org_id
	WHERE (transactions.workflow_table_id = reca.table_id);

	IF ($3 = '1') THEN
		UPDATE approvals SET approve_status = 'Completed', completion_date = now()
		WHERE approval_id = app_id;
		msg := 'Completed';
	ELSIF ($3 = '2') AND (recc.cl_count <> 0) THEN
		msg := 'There are manditory checklist that must be checked first.';
	ELSIF (recd.transaction_type_id = 5) AND (recd.enforce_budget = true) AND (recd.budget_var < 0) THEN
		msg := 'You need a budget to approve the expenditure.';
	ELSIF ($3 = '2') AND (recc.cl_count = 0) THEN
		UPDATE approvals SET approve_status = 'Approved', action_date = now(), app_entity_id = CAST($2 as int)
		WHERE approval_id = app_id;

		SELECT min(approvals.approval_level) INTO min_level
		FROM approvals INNER JOIN workflow_phases ON approvals.workflow_phase_id = workflow_phases.workflow_phase_id
		WHERE (approvals.table_id = reca.table_id) AND (approvals.approve_status = 'Draft')
			AND (workflow_phases.advice = false);
		
		IF(min_level is null)THEN
			mysql := 'UPDATE ' || reca.table_name || ' SET approve_status = ' || quote_literal('Approved') 
			|| ', action_date = now()'
			|| ' WHERE workflow_table_id = ' || reca.table_id;
			EXECUTE mysql;

			INSERT INTO sys_emailed (table_id, table_name, email_type)
			VALUES (reca.table_id, 'vw_workflow_approvals', 1);
			
			FOR recb IN SELECT workflow_phase_id, advice, notice
			FROM workflow_phases
			WHERE (workflow_id = reca.workflow_id) AND (approval_level >= reca.approval_level) LOOP
				IF (recb.advice = true) THEN
					UPDATE approvals SET approve_status = 'Approved', action_date = now(), completion_date = now()
					WHERE (workflow_phase_id = recb.workflow_phase_id) AND (table_id = reca.table_id);
				END IF;
			END LOOP;
		ELSE
			FOR recb IN SELECT workflow_phase_id, advice, notice
			FROM workflow_phases
			WHERE (workflow_id = reca.workflow_id) AND (approval_level <= min_level) LOOP
				IF (recb.advice = true) THEN
					UPDATE approvals SET approve_status = 'Approved', action_date = now(), completion_date = now()
					WHERE (workflow_phase_id = recb.workflow_phase_id) 
						AND (approve_status = 'Draft') AND (table_id = reca.table_id);
				ELSE
					UPDATE approvals SET approve_status = 'Completed', completion_date = now()
					WHERE (workflow_phase_id = recb.workflow_phase_id) 
						AND (approve_status = 'Draft') AND (table_id = reca.table_id);
				END IF;
			END LOOP;
		END IF;
		msg := 'Approved';
	ELSIF ($3 = '3') THEN
		UPDATE approvals SET approve_status = 'Rejected',  action_date = now(), app_entity_id = CAST($2 as int)
		WHERE approval_id = app_id;

		mysql := 'UPDATE ' || reca.table_name || ' SET approve_status = ' || quote_literal('Rejected') 
		|| ', action_date = now()'
		|| ' WHERE workflow_table_id = ' || reca.table_id;
		EXECUTE mysql;

		INSERT INTO sys_emailed (table_id, table_name, email_type, org_id)
		VALUES (reca.table_id, 'vw_workflow_approvals', 2, reca.org_id);
		msg := 'Rejected';
	ELSIF ($3 = '4') AND (reca.return_level = 0) THEN
		UPDATE approvals SET approve_status = 'Review',  action_date = now(), app_entity_id = CAST($2 as int)
		WHERE approval_id = app_id;

		mysql := 'UPDATE ' || reca.table_name || ' SET approve_status = ' || quote_literal('Draft')
		|| ', action_date = now()'
		|| ' WHERE workflow_table_id = ' || reca.table_id;
		EXECUTE mysql;

		msg := 'Forwarded for review';
	ELSIF ($3 = '4') AND (reca.return_level <> 0) THEN
		UPDATE approvals SET approve_status = 'Review',  action_date = now(), app_entity_id = CAST($2 as int)
		WHERE approval_id = app_id;

		INSERT INTO approvals (org_id, workflow_phase_id, table_name, table_id, org_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done, approve_status)
		SELECT org_id, workflow_phase_id, reca.table_name, reca.table_id, CAST($2 as int), escalation_days, escalation_hours, approval_level, phase_narrative, reca.review_advice, 'Completed'
		FROM vw_workflow_entitys
		WHERE (workflow_id = reca.workflow_id) AND (approval_level = reca.return_level)
			AND (entity_id = reca.org_entity_id)
		ORDER BY workflow_phase_id;

		UPDATE approvals SET approve_status = 'Draft' WHERE approval_id = app_id;

		msg := 'Forwarded to owner for review';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_balance(integer, varchar(12)) RETURNS real AS $$
	SELECT COALESCE(sum(exchange_rate * (debit_amount - credit_amount)), 0)
	FROM vw_trx
	WHERE (vw_trx.approve_status = 'Approved')
		AND (vw_trx.for_posting = true)
		AND (vw_trx.entity_id = $1)
		AND (vw_trx.transaction_date < $2::date);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_balance(integer, integer, varchar(12)) RETURNS real AS $$
	SELECT COALESCE(sum(debit_amount - credit_amount), 0)
	FROM vw_trx
	WHERE (vw_trx.approve_status = 'Approved')
		AND (vw_trx.for_posting = true)
		AND (vw_trx.entity_id = $1)
		AND (vw_trx.currency_id = $2)
		AND (vw_trx.transaction_date < $3::date);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION payroll_payable(integer, integer) RETURNS varchar(120) AS $$
DECLARE
	v_org_id				integer;
	v_org_name				varchar(50);
	v_org_client_id			integer;
	v_account_id			integer;
	v_entity_type_id		integer;
	v_bank_account_id		integer;
	reca					RECORD;
	msg						varchar(120);
BEGIN

	SELECT orgs.org_id, orgs.org_client_id, orgs.org_name INTO v_org_id, v_org_client_id, v_org_name
	FROM orgs INNER JOIN periods ON orgs.org_id = periods.org_id
	WHERE (periods.period_id = $1);
	
	IF(v_org_client_id is null)THEN
		SELECT account_id INTO v_account_id
		FROM default_accounts 
		WHERE (org_id = v_org_id) AND (use_key_id = 52);
		
		SELECT max(entity_type_id) INTO v_entity_type_id
		FROM entity_types
		WHERE (org_id = v_org_id) AND (use_key_id = 3);
		
		IF((v_account_id is not null) AND (v_entity_type_id is not null))THEN
			v_org_client_id := nextval('entitys_entity_id_seq');
			
			INSERT INTO entitys (entity_id, org_id, entity_type_id, account_id, entity_name, user_name, function_role, use_key_id)
			VALUES (v_org_client_id, v_org_id, v_entity_type_id, v_account_id, v_org_name, lower(trim(v_org_name)), 'supplier', 3);
		END IF;
	END IF;
	
	SELECT bank_account_id INTO v_bank_account_id
	FROM bank_accounts
	WHERE (org_id = v_org_id) AND (is_default = true);
	
	IF((v_org_client_id is not null) AND (v_bank_account_id is not null))THEN
		--- add transactions for banking payments	
		INSERT INTO transactions (transaction_type_id, transaction_status_id, entered_by, tx_type, 
			entity_id, bank_account_id, currency_id, org_id, ledger_type_id,
			exchange_rate, transaction_date, payment_date, transaction_amount, narrative)
		SELECT 21, 1, $2, -1, 
			v_org_client_id, v_bank_account_id, a.currency_id, a.org_id, 
			get_ledger_link(a.org_id, 1, a.pay_group_id, a.gl_payment_account, 'PAYROLL Payments ' || a.pay_group_name),
			a.exchange_rate, a.end_date, a.end_date, sum(a.b_banked),
			'PAYROLL Payments ' || a.pay_group_name
		FROM vw_ems a
		WHERE (a.period_id = $1)
		GROUP BY a.org_id, a.period_id, a.end_date, a.gl_payment_account, a.pay_group_id, a.currency_id, 
			a.exchange_rate, a.pay_group_name;

		--- add transactions for deduction remitance
		INSERT INTO transactions (transaction_type_id, transaction_status_id, entered_by, tx_type, 
			entity_id, bank_account_id, currency_id, org_id, ledger_type_id,
			exchange_rate, transaction_date, payment_date, transaction_amount, narrative)
		SELECT 21, 1, $2, -1, 
			v_org_client_id, v_bank_account_id, a.currency_id, a.org_id, 
			get_ledger_link(a.org_id, 2, a.adjustment_id, a.account_number, 'PAYROLL Deduction ' || a.adjustment_name),
			a.exchange_rate, a.end_date, a.end_date, sum(a.amount),
			'PAYROLL Deduction ' || a.adjustment_name
		FROM vw_employee_adjustments a
		WHERE (a.period_id = $1)
		GROUP BY a.currency_id, a.org_id, a.adjustment_id, a.account_number, a.adjustment_name, 
			a.exchange_rate, a.end_date;
			
		--- add transactions for tax remitance
		INSERT INTO transactions (transaction_type_id, transaction_status_id, entered_by, tx_type, 
			entity_id, bank_account_id, currency_id, org_id, ledger_type_id,
			exchange_rate, transaction_date, payment_date, transaction_amount, narrative)
		SELECT 21, 1, $2, -1, 
			v_org_client_id, v_bank_account_id, a.currency_id, a.org_id, 
			get_ledger_link(a.org_id, 3, a.tax_type_id, a.account_number, 'PAYROLL Tax ' || a.tax_type_name),
			a.exchange_rate, a.end_date, a.end_date, sum(a.amount + a.employer),
			'PAYROLL Tax ' || a.tax_type_name
		FROM vw_employee_tax_types a
		WHERE (a.period_id = $1)
		GROUP BY a.currency_id, a.org_id, a.tax_type_id, a.account_number, a.tax_type_name, 
			a.exchange_rate, a.end_date;
	END IF;
		
	RETURN msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_ledger_link(integer, integer, integer, varchar(32), varchar(100)) RETURNS integer AS $$
DECLARE
	v_ledger_type_id		integer;
	v_account_no			integer;
	v_account_id			integer;
BEGIN

	SELECT ledger_types.ledger_type_id, accounts.account_no INTO v_ledger_type_id, v_account_no
	FROM ledger_types INNER JOIN ledger_links ON ledger_types.ledger_type_id = ledger_links.ledger_type_id
		INNER JOIN accounts ON ledger_types.account_id = accounts.account_id
	WHERE (ledger_links.org_id = $1) AND (ledger_links.link_type = $2) AND (ledger_links.link_id = $3);
	
	IF(v_ledger_type_id is null)THEN
		v_ledger_type_id := nextval('ledger_types_ledger_type_id_seq');
		SELECT accounts.account_id INTO v_account_id
		FROM accounts
		WHERE (accounts.org_id = $1) AND (accounts.account_no::text = $4);
		
		INSERT INTO ledger_types (ledger_type_id, account_id, tax_account_id, org_id,
			ledger_type_name, ledger_posting, expense_ledger, income_ledger)
		VALUES (v_ledger_type_id, v_account_id, v_account_id, $1,
			$5, true, true, false);

		INSERT INTO ledger_links (ledger_type_id, org_id, link_type, link_id)
		VALUES (v_ledger_type_id, $1, $2, $3);
	END IF;
	
	RETURN v_ledger_type_id;
END;
$$ LANGUAGE plpgsql;



