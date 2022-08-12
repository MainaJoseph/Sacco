
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES
(16, 'Requisitions', false, false),
(14, 'Sales Quotation', true, false),
(15, 'Purchase Quotation', false, false),
(1, 'Sales Order', true, false),
(2, 'Sales Invoice', true, true),
(3, 'Sales Template', true, false),
(4, 'Purchase Order', false, false),
(5, 'Purchase Invoice', false, true),
(6, 'Purchase Template', false, false),
(7, 'Receipts', true, true),
(8, 'Payments', false, true),
(9, 'Credit Note', true, true),
(10, 'Debit Note', false, true),
(11, 'Delivery Note', true, false),
(12, 'Receipt Note', false, false),
(17, 'Work Use', true, false),
(21, 'Direct Expenditure', true, true),
(22, 'Direct Income', false, true);

INSERT INTO transaction_counters(transaction_type_id, org_id, document_number)
SELECT transaction_type_id, 0, 1
FROM transaction_types;

INSERT INTO transaction_status (transaction_status_id, transaction_status_name) VALUES
(1, 'Draft'),
(2, 'Completed'),
(3, 'Processed'),
(4, 'Archive');

INSERT INTO account_class (account_class_no, chat_type_id, chat_type_name, account_class_name) VALUES 
(10, 1, 'ASSETS', 'FIXED ASSETS'),
(20, 1, 'ASSETS', 'INTANGIBLE ASSETS'),
(30, 1, 'ASSETS', 'CURRENT ASSETS'),
(40, 2, 'LIABILITIES', 'CURRENT LIABILITIES'),
(50, 2, 'LIABILITIES', 'LONG TERM LIABILITIES'),
(60, 3, 'EQUITY', 'EQUITY AND RESERVES'),
(70, 4, 'REVENUE', 'REVENUE AND OTHER INCOME'),
(80, 5, 'COST OF REVENUE', 'COST OF REVENUE'),
(90, 6, 'EXPENSES', 'EXPENSES');
UPDATE account_class SET org_id = 0, account_class_id = account_class_no;
SELECT pg_catalog.setval('account_class_account_class_id_seq', 99, true);

INSERT INTO account_types (account_type_no, account_class_id, account_type_name) VALUES 
('100', '10', 'COST'),
('110', '10', 'ACCUMULATED DEPRECIATION'),
('200', '20', 'COST'),
('210', '20', 'ACCUMULATED AMORTISATION'),
('300', '30', 'DEBTORS'),
('310', '30', 'INVESTMENTS'),
('320', '30', 'CURRENT BANK ACCOUNTS'),
('330', '30', 'CASH ON HAND'),
('340', '30', 'PRE-PAYMMENTS'),
('400', '40', 'CREDITORS'),
('410', '40', 'ADVANCED BILLING'),
('420', '40', 'TAX'),
('430', '40', 'WITHHOLDING TAX'),
('500', '50', 'LOANS'),
('600', '60', 'CAPITAL GRANTS'),
('610', '60', 'ACCUMULATED SURPLUS'),
('700', '70', 'SALES REVENUE'),
('710', '70', 'OTHER INCOME'),
('800', '80', 'COST OF REVENUE'),
('900', '90', 'STAFF COSTS'),
('905', '90', 'COMMUNICATIONS'),
('910', '90', 'DIRECTORS ALLOWANCES'),
('915', '90', 'TRANSPORT'),
('920', '90', 'TRAVEL'),
('925', '90', 'POSTAL and COURIER'),
('930', '90', 'ICT PROJECT'),
('935', '90', 'STATIONERY'),
('940', '90', 'SUBSCRIPTION FEES'),
('945', '90', 'REPAIRS'),
('950', '90', 'PROFESSIONAL FEES'),
('955', '90', 'OFFICE EXPENSES'),
('960', '90', 'MARKETING EXPENSES'),
('965', '90', 'STRATEGIC PLANNING'),
('970', '90', 'DEPRECIATION'),
('975', '90', 'CORPORATE SOCIAL INVESTMENT'),
('980', '90', 'FINANCE COSTS'),
('985', '90', 'TAXES'),
('990', '90', 'INSURANCE'),
('995', '90', 'OTHER EXPENSES');
UPDATE account_types SET org_id = 0, account_type_id = account_type_no;
SELECT pg_catalog.setval('account_types_account_type_id_seq', 999, true);

INSERT INTO accounts (account_no, account_type_id, account_name) VALUES 
('10000',100,'COMPUTERS and EQUIPMENT'),
('10005',100,'FURNITURE'),
('11000',110,'COMPUTERS and EQUIPMENT'),
('11005',110,'FURNITURE'),
('20000',200,'INTANGIBLE ASSETS'),
('20005',200,'NON CURRENT ASSETS: DEFFERED TAX'),
('20010',200,'INTANGIBLE ASSETS: ACCOUNTING PACKAGE'),
('21000',210,'ACCUMULATED AMORTISATION'),
('30000',300,'TRADE DEBTORS'),
('30005',300,'STAFF DEBTORS'),
('30010',300,'OTHER DEBTORS'),
('30015',300,'DEBTORS PROMPT PAYMENT DISCOUNT'),
('30020',300,'INVENTORY'),
('30025',300,'INVENTORY WORK IN PROGRESS'),
('30030',300,'GOODS RECEIVED CLEARING ACCOUNT'),
('31005',310,'UNIT TRUST INVESTMENTS'),
('32000',320,'COMMERCIAL BANK'),
('32005',320,'MPESA'),
('33000',330,'CASH ACCOUNT'),
('33005',330,'PETTY CASH'),
('34000',340,'PREPAYMENTS'),
('34005',340,'DEPOSITS'),
('34010',340,'TAX RECOVERABLE'),
('34015',340,'TOTAL REGISTRAR DEPOSITS'),
('40000',400,'TRADE CREDITORS'),
('40005',400,'ADVANCE BILLING'),
('40010',400,'LEAVE - ACCRUALS'),
('40015',400,'ACCRUED LIABILITIES: CORPORATE TAX'),
('40020',400,'OTHER ACCRUALS'),
('40025',400,'PROVISION FOR CREDIT NOTES'),
('40030',400,'NSSF'),
('40035',400,'NHIF'),
('40040',400,'HELB'),
('40045',400,'PAYE'),
('40050',400,'PENSION'),
('40055',400,'PAYROLL LIABILITIES'),
('41000',410,'ADVANCED BILLING'),
('42000',420,'Value Added Tax (VAT)'),
('42010',420,'REMITTANCE'),
('43000',430,'WITHHOLDING TAX'),
('50000',500,'BANK LOANS'),
('60000',600,'CAPITAL GRANTS'),
('60005',600,'ACCUMULATED AMORTISATION OF CAPITAL GRANTS'),
('60010',600,'DIVIDEND'),
('61000',610,'RETAINED EARNINGS'),
('61005',610,'ACCUMULATED SURPLUS'),
('61010',610,'ASSET REVALUATION GAIN / LOSS'),
('70005',700,'GOODS SALES'),
('70010',700,'SERVICE SALES'),
('70015',700,'INTEREST INCOME'),
('70020',700,'CHARGES INCOME'),
('70025',700,'PENALTY INCOME'),
('71000',710,'FAIR VALUE GAIN/LOSS IN INVESTMENTS'),
('71005',710,'DONATION'),
('71010',710,'EXCHANGE GAIN(LOSS)'),
('71015',710,'REGISTRAR TRAINING FEES'),
('71020',710,'DISPOSAL OF ASSETS'),
('71025',710,'DIVIDEND INCOME'),
('71030',710,'INTEREST INCOME'),
('71035',710,'TRAINING, FORUM, MEETINGS and WORKSHOPS'),
('80000',800,'COST OF GOODS'),
('90000',900,'BASIC SALARY'),
('90005',900,'STAFF ALLOWANCES'),
('90010',900,'AIRTIME'),
('90012',900,'TRANSPORT ALLOWANCE'),
('90015',900,'REMOTE ACCESS'),
('90020',900,'EMPLOYER PENSION CONTRIBUTION'),
('90025',900,'NSSF EMPLOYER CONTRIBUTION'),
('90035',900,'CAPACITY BUILDING - TRAINING'),
('90040',900,'INTERNSHIP ALLOWANCES'),
('90045',900,'BONUSES'),
('90050',900,'LEAVE ACCRUAL'),
('90055',900,'WELFARE'),
('90056',900,'STAFF WELLFARE: CONSUMABLES'),
('90060',900,'MEDICAL INSURANCE'),
('90065',900,'GROUP PERSONAL ACCIDENT AND WIBA'),
('90070',900,'STAFF EXPENDITURE'),
('90075',900,'GROUP LIFE INSURANCE'),
('90500',905,'FIXED LINES'),
('90505',905,'CALLING CARDS'),
('90510',905,'LEASE LINES'),
('90515',905,'REMOTE ACCESS'),
('90520',905,'LEASE LINE'),
('91000',910,'SITTING ALLOWANCES'),
('91005',910,'HONORARIUM'),
('91010',910,'WORKSHOPS and SEMINARS'),
('91500',915,'CAB FARE'),
('91505',915,'FUEL'),
('91510',915,'BUS FARE'),
('91515',915,'POSTAGE and BOX RENTAL'),
('92000',920,'TRAINING'),
('92005',920,'BUSINESS PROSPECTING'),
('92505',925,'DIRECTORY LISTING'),
('92510',925,'COURIER'),
('93000',930,'IP TRAINING'),
('93010',930,'COMPUTER SUPPORT'),
('93500',935,'PRINTED MATTER'),
('93505',935,'PAPER'),
('93510',935,'OTHER CONSUMABLES'),
('93515',935,'TONER and CATRIDGE'),
('93520',935,'COMPUTER ACCESSORIES'),
('94010',940,'LICENSE FEE'),
('94015',940,'SYSTEM SUPPORT FEES'),
('94500',945,'FURNITURE'),
('94505',945,'COMPUTERS and EQUIPMENT'),
('94510',945,'JANITORIAL'),
('95000',950,'AUDIT'),
('95005',950,'MARKETING AGENCY'),
('95010',950,'ADVERTISING'),
('95015',950,'CONSULTANCY'),
('95020',950,'TAX CONSULTANCY'),
('95025',950,'MARKETING CAMPAIGN'),
('95030',950,'PROMOTIONAL MATERIALS'),
('95035',950,'RECRUITMENT'),
('95040',950,'ANNUAL GENERAL MEETING'),
('95045',950,'SEMINARS, WORKSHOPS and MEETINGS'),
('95500',955,'OFFICE RENT'),
('95502',955,'OFFICE COSTS'),
('95505',955,'CLEANING'),
('95510',955,'NEWSPAPERS'),
('95515',955,'OTHER CONSUMABLES'),
('95520',955,'ADMINISTRATIVE EXPENSES'),
('96005',960,'WEBSITE REVAMPING COSTS'),
('96505',965,'STRATEGIC PLANNING'),
('96510',965,'MONITORING and EVALUATION'),
('97000',970,'COMPUTERS and EQUIPMENT'),
('97005',970,'FURNITURE'),
('97010',970,'AMMORTISATION OF INTANGIBLE ASSETS'),
('97500',975,'CORPORATE SOCIAL INVESTMENT'),
('97505',975,'DONATION'),
('98000',980,'LEDGER FEES'),
('98005',980,'BOUNCED CHEQUE CHARGES'),
('98010',980,'OTHER FEES'),
('98015',980,'SALARY TRANSFERS'),
('98020',980,'UPCOUNTRY CHEQUES'),
('98025',980,'SAFETY DEPOSIT BOX'),
('98030',980,'MPESA TRANSFERS'),
('98035',980,'CUSTODY FEES'),
('98040',980,'PROFESSIONAL FEES: MANAGEMENT FEES'),
('98500',985,'EXCISE DUTY'),
('98505',985,'FINES and PENALTIES'),
('98510',985,'CORPORATE TAX'),
('98515',985,'FRINGE BENEFIT TAX'),
('99000',990,'ALL RISKS'),
('99005',990,'FIRE and PERILS'),
('99010',990,'BURGLARY'),
('99015',990,'COMPUTER POLICY'),
('99500',995,'BAD DEBTS WRITTEN OFF'),
('99505',995,'PURCHASE DISCOUNT'),
('99510',995,'COST OF GOODS SOLD (COGS)'),
('99515',995,'PURCHASE PRICE VARIANCE'),
('99999',995,'SURPLUS/DEFICIT');
UPDATE accounts set org_id = 0, account_id = account_no;
SELECT pg_catalog.setval('accounts_account_id_seq', 99999, true);

INSERT INTO use_keys (use_key_id, use_key_name, use_function) VALUES 
(15, 'Transaction Tax', 2);

INSERT INTO tax_types (org_id, use_key_id, tax_type_name, tax_rate, account_id) VALUES 
(0, 15, 'Exempt', 0, '42000'),
(0, 15, 'VAT', 16, '42000');
UPDATE tax_types SET currency_id = 1;

---- Default account for payroll
INSERT INTO use_keys (use_key_id, use_key_name, use_function) VALUES 
(23, 'Travel Cost', 3),
(24, 'Travel Payment', 3),
(25, 'Travel Tax', 3),
(26, 'Salary Payment', 3),
(27, 'Basic Salary', 3),
(28, 'Payroll Advance', 3),
(29, 'Staff Allowance', 3),
(30, 'Staff Remitance', 3),
(31, 'Staff Expenditure', 3);

INSERT INTO default_accounts (org_id, use_key_id, account_id) VALUES 
(0, 23, 90012),
(0, 24, 30005),
(0, 25, 40045),
(0, 26, 40055),
(0, 27, 90000),
(0, 28, 40055),
(0, 29, 90005),
(0, 30, 40055),
(0, 31, 90070);


---- Default account for 
INSERT INTO use_keys (use_key_id, use_key_name, use_function) VALUES 
(51, 'Client Account', 3),
(52, 'Supplier Account', 3),
(53, 'Sales Account', 3),
(54, 'Purchase Account', 3),
(55, 'VAT Account', 3),
(56, 'Suplus/Deficit', 3),
(57, 'Retained Earnings', 3);

INSERT INTO default_accounts (org_id, use_key_id, account_id) VALUES 
(0, 51, 30000),
(0, 52, 40000),
(0, 53, 70005),
(0, 54, 80000),
(0, 55, 42000),
(0, 56, 99999),
(0, 57, 61000);

INSERT INTO item_category (org_id, item_category_name) VALUES 
(0, 'Services'),
(0, 'Goods'),
(0, 'Utilities');

INSERT INTO item_units (org_id, item_unit_name) VALUES 
(0, 'Each'),
(0, 'Man Hours'),
(0, '100KG');

INSERT INTO stores (org_id, store_name) VALUES 
(0, 'Main Store');


INSERT INTO bank_accounts (bank_account_id, org_id, currency_id, bank_branch_id, account_id, bank_account_name, is_default) VALUES 
(0, 0, 1, 0, '33000', 'Cash Account', true);

INSERT INTO lead_categorys (org_id, lead_category_name) VALUES
(0, 'General');

INSERT INTO workflows (workflow_id, org_id, source_entity_id, workflow_name, table_name, table_link_field, table_link_id, approve_email, reject_email, approve_file, reject_file, details) VALUES 
(1, 0, 0, 'Budget', 'budgets', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL),
(2, 0, 0, 'Requisition', 'transactions', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL),
(3, 0, 3, 'Purchase Transactions', 'transactions', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL),
(4, 0, 2, 'Sales Transactions', 'transactions', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL),
(5, 0, 1, 'Leave', 'employee_leave', NULL, NULL, 'Leave approved', 'Leave rejected', NULL, NULL, NULL),
(6, 0, 5, 'subscriptions', 'subscriptions', NULL, NULL, 'subscription approved', 'subscription rejected', NULL, NULL, NULL),
(7, 0, 1, 'Claims', 'claims', NULL, NULL, 'Claims approved', 'Claims rejected', NULL, NULL, NULL),
(8, 0, 1, 'Loan', 'loans', NULL, NULL, 'Loan approved', 'Loan rejected', NULL, NULL, NULL),
(9, 0, 1, 'Advances', 'employee_advances', NULL, NULL, 'Advance approved', 'Advance rejected', NULL, NULL, NULL),
(10, 0, 4, 'Hire', 'applications', NULL, NULL, 'Hire approved', 'Hire rejected', NULL, NULL, NULL),
(11, 0, 1, 'Contract', 'applications', NULL, NULL, 'Contract approved', 'Contract rejected', NULL, NULL, NULL),
(12, 0, 1, 'Employee Objectives', 'employee_objectives', NULL, NULL, 'Objectives approved', 'Objectives rejected', NULL, NULL, NULL),
(13, 0, 1, 'Review Objectives', 'job_reviews', NULL, NULL, 'Review approved', 'Review rejected', NULL, NULL, NULL),
(14, 0, 1, 'Employee Travels', 'employee_travels', NULL, NULL, 'Review approved', 'Review rejected', NULL, NULL, NULL),
(15, 0, 1, 'Petty Cash', 'pc_expenditure', NULL, NULL, 'Review approved', 'Review rejected', NULL, NULL, NULL);
SELECT pg_catalog.setval('workflows_workflow_id_seq', 15, true);


INSERT INTO workflow_phases (workflow_phase_id, org_id, workflow_id, approval_entity_id, approval_level, return_level, escalation_days, escalation_hours, required_approvals, advice, notice, phase_narrative, advice_email, notice_email, advice_file, notice_file, details) VALUES 
(1, 0, 1, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(2, 0, 2, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(3, 0, 3, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(4, 0, 4, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(5, 0, 5, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(6, 0, 6, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(7, 0, 7, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(8, 0, 8, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(9, 0, 9, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(10, 0, 10, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(11, 0, 11, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(12, 0, 12, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(13, 0, 13, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(14, 0, 14, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(15, 0, 15, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL);
SELECT pg_catalog.setval('workflow_phases_workflow_phase_id_seq', 15, true);







