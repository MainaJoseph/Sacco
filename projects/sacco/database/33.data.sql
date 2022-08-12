
--- Create use key types
INSERT INTO use_keys (use_key_id, use_key_name, use_function) VALUES 
(100, 'members', 0),
(101, 'Receipts', 4),
(102, 'Payments', 4),
(103, 'Opening Account', 4),
(104, 'Transfer', 4),
(105, 'Loan Intrests', 4),
(106, 'Loan Penalty', 4),
(107, 'Loan Payment', 4),
(108, 'Loan Disbursement', 4),
(109, 'Account Intrests', 4),
(110, 'Account Penalty', 4),
(111, 'Contributions', 4),
(201, 'Initial Charges', 4),
(202, 'Transaction Charges', 4),
(203, 'Termination Charges', 4),
(204, 'Loan Processing Fee', 4),
(210, 'Commodity Purchase', 5),
(220, 'Commodity Sale', 5),
(230, 'Commodity Trade', 5),
(250, 'Forex', 5),
---ACCESS LEVELS USE KEYS
(70, 'Operations', 0),
(71, 'configurations', 0),
(72, 'Loans', 0),
(73, 'Service Desk', 0),
(74, 'Sacco Reports', 0),
(75, 'Investments', 0),
(76, 'SMS', 0),
(77, 'Processing', 0),
(78, 'Transaction', 0),
(79, 'Master Configs', 0),
(80, 'Sacco Business', 0),
(81, 'Financial Reports', 0),
(82, 'Loan Processing Approval', 0),
----SYSTEM SMS 
(300, 'Login Credentials', 0),
(301, 'Account Deposits', 0),
(302, 'Account Transfers', 0),
(303, 'Account Withdrawals', 0),
(304, 'Loan Approval', 0),
(305, 'Loan Rejection', 0),
(306, 'Loan Repayment Fully', 0),
(307, 'Loan Defaulted', 0),
(308, 'Guarantee Request', 0),
(309, 'Guarantee Acceptance', 0),
(310, 'Guarantee Rejection', 0);

---- Access levels
INSERT INTO sys_access_levels (use_key_id, org_id, sys_access_level_name, access_tag) VALUES
(0, 0, 'Subscription', 'subscription'),
(0, 0, 'admin', 'admin'),
(1, 0, 'Staff', 'staff'),
(2, 0, 'Client', 'client'),
(4, 0, 'Applicants', 'applicant'),
(100, 0, 'Members', 'members'),
(100, 0, 'Service Desk Module', 'service_desk'),

(0, 0, 'Operations Module', 'operations'),
(0, 0, 'configurations Module', 'configurations'),
(0, 0, 'Loans Module', 'loans'),
(0, 0, 'Processing Module', 'processing'),
(0, 0, 'Transaction Module', 'transactions'),
(0, 0, 'Sacco Report Module', 'sacco_reports'),
(0, 0, 'Loan Approval Module', 'loan_approval'),
(0, 0, 'Members Module', 'members_module'),

(75, 0, 'Investments Module', 'investments'),
(76, 0, 'SMS Module', 'sms'),
(79, 0, 'Master Configs', 'master_config'),
(80, 0, 'Sacco Business', 'sacco_business'),
(81, 0, 'Financial Reports', 'financial_reports'),
(82, 0, 'Loan Processing Approval', 'loan_processing_approval');

-----SMS CONFIGURATIONS
INSERT INTO sms_configs(org_id,use_key_id,sms_config_name,is_active,sms_template) VALUES
(0,300, 'Login Credentials sms',false, 'Dear  {{member_name}}  your username is:  {{user_name}}  and password :-  {{first_password}}  . from {{sacco_name}}'),
(0,301, 'Account Deposits sms',false, 'sms template to make the message body'),
(0,302, 'Account Transfers sms',false, 'sms template to make the message body'),
(0,303, 'Account Withdrawals sms',false, 'sms template to make the message body'),
(0,304, 'Loan Approval sms',false, 'sms template to make the message body'),
(0,305, 'Loan Rejection sms',false, 'sms template to make the message body'),
(0,306, 'Loan Repayment Fully sms',false, 'sms template to make the message body'),
(0,307, 'Loan Defaulted sms',false, 'sms template to make the message body'),
(0,308, 'Guarantee Request sms',false, 'sms template to make the message body'),
(0,309, 'Guarantee Acceptance sms',false, 'sms template to make the message body'),
(0,310, 'Guarantee Rejection sms',false, 'sms template to make the message body');

---ACTIVITY FREQUNCY
INSERT INTO activity_frequency (activity_frequency_id, activity_frequency_name) 
VALUES (1, 'Once'), (4, 'Monthly');
--- (1, 'Once'), (2, 'Daily'), (3, 'Weekly'), (4, 'Monthly'), (5, 'Quartely'), (6, 'Half Yearly'), (7, 'Yearly');

---kin types
INSERT INTO kin_types (org_id, kin_type_name) VALUES 
(0, 'Wife'),(0, 'Husband'),(0, 'Daughter'),(0, 'Son'),(0, 'Mother'),(0, 'Father'),(0, 'Brother'),(0, 'Sister'),
(0, 'Uncle'),(0, 'Aunt'),(0, 'Niece'),(0, 'Nephew'),(0, 'Others');

---sacco official positions
INSERT INTO position_levels (position_level_id, org_id,position_level_name,narrative) VALUES
(1,0,'Chairperson', 'Sacco Chairperson Position'),
(2,0,'Vice Chairperson', 'Sacco Vice Chairperson Position'),
(3,0,'Treasurer', 'Sacco Treasurer Position'),
(4,0,'Secretary', 'Sacco Secretary Position');
SELECT pg_catalog.setval('position_levels_position_level_id_seq', 5, true);

INSERT INTO activity_status (activity_status_id, activity_status_name) VALUES 
(1, 'Completed'),
(2, 'UnCleared'),
(3, 'Processing'),
(4, 'Commited');

INSERT INTO entity_types (org_id, use_key_id, entity_type_name, entity_role) VALUES (0, 100, 'Sacco Members', 'member');
INSERT INTO locations (org_id, location_name) VALUES (0, 'Head Office');
INSERT INTO departments (org_id, department_name) VALUES (0, 'Board of Directors');

---collateral types
INSERT INTO collateral_types (org_id, collateral_type_name) VALUES 
(0, 'Land Title'),
(0, 'Car Log book');

---issue levels
INSERT INTO issue_levels(issue_level_id,org_id, issue_level_name) VALUES 
(1,0, 'Critical'), 
(2,0, 'High'), 
(3,0, 'Medium'), 
(4,0, 'Low');
SELECT pg_catalog.setval('issue_levels_issue_level_id_seq', 5, true);

---issue types
INSERT INTO issue_types (issue_type_id,org_id, issue_type_name) VALUES
(1,0, 'Transactions'), 
(2,0, 'Contributions'), 
(3,0, 'Loans'), 
(4,0, 'Statements'), 
(5,0, 'Shares'), 
(6,0, 'Others');
SELECT pg_catalog.setval('issue_types_issue_type_id_seq', 7, true);

---issue definations
INSERT INTO issue_definitions (issue_definition_id,issue_type_id,org_id,issue_definition_name) VALUES
(1,1,0,'Accounts Balance Querry'),
(2,1,0, 'Contributions Balance'),
(3,6,0, 'Others');
SELECT pg_catalog.setval('issue_definitions_issue_definition_id_seq', 4, true);

INSERT INTO activity_types (activity_type_id, cr_account_id, dr_account_id, use_key_id, org_id, activity_type_name, is_active) VALUES 
(1, 34005, 34005, 202, 0, 'No Charges', true),
(2, 34005, 34005, 101, 0, 'Cash Deposits', true),
(3, 34005, 34005, 101, 0, 'Cheque Deposits', true),
(4, 34005, 34005, 101, 0, 'MPESA Deposits', true),
(5, 34005, 34005, 102, 0, 'Cash Withdrawal', true),
(6, 34005, 34005, 102, 0, 'Cheque Withdrawal', true),
(7, 34005, 34005, 102, 0, 'MPESA Withdrawal', true),
(8, 70015, 34005, 105, 0, 'Loan Intrests', true),
(9, 70025, 34005, 106, 0, 'Loan Penalty', true),
(10, 34005, 34005, 107, 0, 'Loan Payment', true),
(11, 34005, 34005, 108, 0, 'Loan Disbursement', true),
(12, 34005, 34005, 104, 0, 'Account Transfer', true),
(14, 70015, 34005, 109, 0, 'Account Intrests', true),
(15, 70025, 34005, 110, 0, 'Account Penalty', true),
(21, 70020, 34005, 201, 0, 'Account opening charges', true),
(22, 70020, 34005, 202, 0, 'Transfer fees', true),
(23, 70020, 34005, 210, 0, 'Commodity Purchase', true),
(24, 70020, 34005, 220, 0, 'Commodity Sale', true),
(25, 70020, 34005, 230, 0, 'Commodity Trade', true),
(26, 70020, 34005, 250, 0, 'Forex', true),
(27, 70020, 34005, 203, 0, 'Member Termination Charges', true),
(28, 34005, 34005, 111, 0, 'Contributions', true),
(29, 70020, 34005, 201, 0, 'Loan Processing fees', true),
(30, 34005, 34005, 101, 0, 'Payroll Deduction Deposits', true);
SELECT pg_catalog.setval('activity_types_activity_type_id_seq', 30, true);
UPDATE activity_types SET activity_type_no = activity_type_id;

INSERT INTO interest_methods (interest_method_id, activity_type_id, org_id, interest_method_name, formural, account_number, reducing_balance, reducing_payments) VALUES 
(0, 8, 0, 'No Intrest', null, '400000003', false, false),
(1, 8, 0, 'Loan reducing balance', 'get_intrest(1, loan_id, period_id)', '400000003', true, false),
(2, 8, 0, 'Loan Fixed Intrest', 'get_intrest(2, loan_id, period_id)', '400000003', false, false),
(3, 14, 0, 'Savings intrest', 'get_intrest(3, deposit_account_id, period_id)', '400000003', false, false),
(4, 8, 0, 'Loan reducing balance and payments', 'get_intrest(1, loan_id, period_id)', '400000003', true, true);
SELECT pg_catalog.setval('interest_methods_interest_method_id_seq', 4, true);
UPDATE interest_methods SET interest_method_no = interest_method_id;

INSERT INTO penalty_methods (penalty_method_id, activity_type_id, org_id, penalty_method_name, formural, account_number) VALUES 
(0, 9, 0, 'No penalty', null, '400000004'),
(1, 9, 0, 'Loan Penalty 15', 'get_penalty(1, loan_id, period_id, 15)', '400000004'),
(2, 15, 0, 'Account Penalty 15', 'get_penalty(1, deposit_account_id, period_id, 15)', '400000004');
SELECT pg_catalog.setval('penalty_methods_penalty_method_id_seq', 2, true);
UPDATE penalty_methods SET penalty_method_no = penalty_method_id;

INSERT INTO products (product_id, activity_frequency_id, interest_method_id, penalty_method_id, currency_id, org_id, product_name, description, loan_account, is_active, interest_rate, min_opening_balance, lockin_period_frequency, minimum_balance, maximum_balance, minimum_day, maximum_day, minimum_trx, maximum_trx, less_initial_fee, approve_status) VALUES
(0, 4, 0, 0, 1, 0, 'Sacco', 'sacco', false, false, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, 'Approved'),
(1, 4, 0, 0, 1, 0, 'Transaction account', 'Account to handle transactions', false, true, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, 'Approved'),
(2, 4, 0, 0, 1, 0, 'Contribution account', 'Account to handle Contribution', false, true, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, 'Approved'),
(3, 4, 3, 0, 1, 0, 'Savings account', 'Account to handle savings', false, true, 3, 0, 0, 0, 0, 0, 0, 0, 0, false, 'Approved'),
(4, 4, 1, 1, 1, 0, 'Basic loans', 'Basic loans', true, true, 12, 0, 0, 0, 0, 0, 0, 0, 0, false, 'Approved'),
(5, 4, 2, 1, 1, 0, 'Compound loans', 'Compound loans', true, true, 12, 0, 0, 0, 0, 0, 0, 0, 0, true, 'Approved'),
(6, 4, 4, 1, 1, 0, 'Reducing balance loans', 'Reducing balance loans', true, true, 12, 0, 0, 0, 0, 0, 0, 0, 0, true, 'Approved'),
(7, 4, 0, 0, 2, 0, 'Forex Account', 'Forex transaction accounts', false, true, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, 'Approved');

SELECT pg_catalog.setval('products_product_id_seq', 7, true);
UPDATE products SET product_no = product_id;

---sacco account definations
INSERT INTO account_definations (activity_type_id, charge_activity_id, activity_frequency_id, product_id, org_id, account_defination_name, start_date, end_date, account_number, is_active) VALUES 
(2, 1, 1, 0, 0, 'Cash Deposit', '2017-01-01', NULL, '400000001', true),
(3, 1, 1, 0, 0, 'Cheque Deposit', '2017-01-01', NULL, '400000001', true),
(4, 1, 1, 0, 0, 'MPESA Deposit', '2017-01-01', NULL, '400000001', true),
(5, 1, 1, 0, 0, 'Cash Withdraw', '2017-01-01', NULL, '400000001', true),
(6, 1, 1, 0, 0, 'Cheque Withdraw', '2017-01-01', NULL, '400000001', true),
(7, 1, 1, 0, 0, 'MPESA Withdraw', '2017-01-01', NULL, '400000001', true);

---transaction account definations
INSERT INTO account_definations (activity_type_id, charge_activity_id, activity_frequency_id, product_id, org_id, account_defination_name, start_date, end_date, account_number, is_active) VALUES 
(2, 1, 1, 1, 0, 'Cash Deposit', '2017-01-01', NULL, '400000001', true),
(3, 1, 1, 1, 0, 'Cheque Deposit', '2017-01-01', NULL, '400000001', true),
(4, 1, 1, 1, 0, 'MPESA Deposit', '2017-01-01', NULL, '400000001', true),
(5, 1, 1, 1, 0, 'Cash Withdraw', '2017-01-01', NULL, '400000001', true),
(6, 1, 1, 1, 0, 'Cheque Withdraw', '2017-01-01', NULL, '400000001', true),
(7, 1, 1, 1, 0, 'MPESA Withdraw', '2017-01-01', NULL, '400000001', true);

--- account opening and transfers on transaction accounts
INSERT INTO account_definations (activity_type_id, charge_activity_id, activity_frequency_id, product_id, org_id, account_defination_name, start_date, end_date, fee_ps, account_number, is_active, has_charge) 
VALUES (12, 22, 1, 1, 0, 'Transfer', '2017-01-01', NULL, 1, '400000002', true, true);
INSERT INTO account_definations (activity_type_id, charge_activity_id, activity_frequency_id, product_id, org_id, account_defination_name, start_date, end_date, fee_amount, account_number, is_active, has_charge) 
VALUES (21, 1, 1, 1, 0, 'Opening account', '2017-01-01', NULL, 1000, '400000002', true, true);

---Basic loans product account defination
INSERT INTO account_definations (activity_type_id, charge_activity_id, activity_frequency_id, product_id, org_id, account_defination_name, start_date, end_date, account_number, is_active, has_charge, fee_amount) VALUES
(29, 1, 1, 4, 0, 'Loan Processing fees', '2017-01-01', NULL, '400000002', true, true, 2000),
(11, 1, 1, 4, 0, 'Loan Disbursement', '2017-01-01', NULL, '400000001', true, false, 0),
(10, 1, 1, 4, 0, 'Loan Payment', '2017-01-01', NULL, '400000001', true, false, 0);

---saving account product account definations
INSERT INTO account_definations (activity_type_id, charge_activity_id, activity_frequency_id, product_id, org_id, account_defination_name, start_date, end_date, account_number, is_active, has_charge, fee_ps) VALUES 
(2, 1, 1, 3, 0, 'Cash Deposit', '2017-01-01', NULL, '400000001', true, false, 0),
(3, 1, 1, 3, 0, 'Cheque Deposit', '2017-01-01', NULL, '400000001', true, false, 0),
(4, 1, 1, 3, 0, 'MPESA Deposit', '2017-01-01', NULL, '400000001', true, false, 0),
(5, 1, 1, 3, 0, 'Cash Withdraw', '2017-01-01', NULL, '400000001', true, false, 0),
(6, 1, 1, 3, 0, 'Cheque Withdraw', '2017-01-01', NULL, '400000001', true, false, 0),
(7, 1, 1, 3, 0, 'MPESA Withdraw', '2017-01-01', NULL, '400000001', true, false, 0),
(12, 22, 1, 3, 0, 'Transfer', '2017-01-01', NULL, '400000002', true, true, 1);

---compound loans product account defination
INSERT INTO account_definations (activity_type_id, charge_activity_id, activity_frequency_id, product_id, org_id, account_defination_name, start_date, end_date, account_number, is_active, has_charge, fee_amount) VALUES 
(29, 1, 1, 5, 0, 'Loan Processing fees', '2017-01-01', NULL, '400000002', true, true, 0),
(11, 1, 1, 5, 0, 'Loan Disbursement', '2017-01-01', NULL, '400000001', true, false, 0),
(10, 1, 1, 5, 0, 'Loan Payment', '2017-01-01', NULL, '400000001', true, false, 0);

---reducing balance loans product account defination
INSERT INTO account_definations (activity_type_id, charge_activity_id, activity_frequency_id, product_id, org_id, account_defination_name, start_date, end_date, account_number, is_active, has_charge, fee_amount) VALUES 
(29, 1, 1, 6, 0, 'Loan Processing fees', '2017-01-01', NULL, '400000002', true, true, 0),
(11, 1, 1, 6, 0, 'Loan Disbursement', '2017-01-01', NULL, '400000001', true, false, 0),
(10, 1, 1, 6, 0, 'Loan Payment', '2017-01-01', NULL, '400000001', true, false, 0);

---USD forex account product account defination
INSERT INTO account_definations (activity_type_id, charge_activity_id, activity_frequency_id, product_id, org_id, account_defination_name, start_date, end_date, account_number, is_active) VALUES 
(2, 1, 1, 7, 0, 'Cash Deposit', '2017-01-01', NULL, '400000005', true),
(3, 1, 1, 7, 0, 'Cheque Deposit', '2017-01-01', NULL, '400000005', true),
(4, 1, 1, 7, 0, 'MPESA Deposit', '2017-01-01', NULL, '400000005', true),
(5, 1, 1, 7, 0, 'Cash Withdraw', '2017-01-01', NULL, '400000005', true),
(6, 1, 1, 7, 0, 'Cheque Withdraw', '2017-01-01', NULL, '400000005', true),
(7, 1, 1, 7, 0, 'MPESA Withdraw', '2017-01-01', NULL, '400000005', true);

--- Create Initial member and member account
INSERT INTO members (member_id, org_id, business_account, member_name, identification_number, identification_type, member_email, telephone_number, date_of_birth, nationality, approve_status)
VALUES (0, 0, 2, 'OpenBaraza Sacco', '0', 'Org', 'info@openbaraza.org', '+254', current_date, 'KE', 'Approved');

INSERT INTO deposit_accounts (member_id, product_id, org_id, is_active, approve_status, narrative, minimum_balance) VALUES 
(0, 0, 0, true, 'Approved', 'Deposits', -100000000000),
(0, 0, 0, true, 'Approved', 'Charges', -100000000000),
(0, 0, 0, true, 'Approved', 'Interest', -100000000000),
(0, 0, 0, true, 'Approved', 'Penalty', -100000000000),
(0, 0, 0, true, 'Approved', 'Shares', -100000000000),
(0, 7, 0, true, 'Approved', 'USD Deposit', -100000000000);
SELECT pg_catalog.setval('deposit_accounts_deposit_account_id_seq', 100, true);

---- Workflow setup
INSERT INTO workflows (workflow_id, org_id, source_entity_id, workflow_name, table_name, table_link_field, table_link_id, approve_email, reject_email, approve_file, reject_file, details) VALUES
(20, 0, 0, 'member Application', 'members', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL),
(21, 0, 0, 'Account opening', 'deposit_accounts', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL),
(22, 0, 0, 'Loan Application', 'loans', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL),
(23, 0, 0, 'Guarantees Application', 'guarantees', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL),
(24, 0, 0, 'Collaterals Application', 'collaterals', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL),
(25, 0, 0, 'member Application', 'applicants', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL),
(26, 0, 6, 'Account opening - member', 'deposit_accounts', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL),
(27, 0, 6, 'Loan Application - member', 'loans', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL),
(28, 0, 0, 'Commodity trade', 'commodity_trades', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL),
(29, 0, 6, 'Commodity trade - member', 'commodity_trades', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL);
SELECT pg_catalog.setval('workflows_workflow_id_seq', 30, true);

INSERT INTO workflow_phases (workflow_phase_id, org_id, workflow_id, approval_entity_id, approval_level, return_level, escalation_days, escalation_hours, required_approvals, advice, notice, phase_narrative, advice_email, notice_email, advice_file, notice_file, details) VALUES
(20, 0, 20, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(21, 0, 21, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(22, 0, 22, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(23, 0, 23, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(24, 0, 24, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(25, 0, 25, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(26, 0, 26, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(27, 0, 27, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(28, 0, 28, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL),
(29, 0, 29, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL);
SELECT pg_catalog.setval('workflow_phases_workflow_phase_id_seq', 30, true);
