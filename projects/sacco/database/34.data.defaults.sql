--======DEFAULT DATA=========
--- Data
INSERT INTO currency (currency_id, currency_name, currency_symbol) VALUES (5, 'Kenya Shillings', 'KES');
INSERT INTO orgs (org_id, org_name, org_sufix, currency_id, default_country_id, logo) VALUES (1, 'Open Baraza', 'ob', 5, 'KE', 'logo.png');
UPDATE currency SET org_id = 1 WHERE currency_id = 5;
SELECT pg_catalog.setval('orgs_org_id_seq', 1, true);
SELECT pg_catalog.setval('currency_currency_id_seq', 5, true);

INSERT INTO currency_rates (org_id, currency_id, exchange_rate) VALUES (1, 5, 1);

INSERT INTO entity_types (org_id, entity_type_name, entity_role, use_key_id) VALUES (1, 'Users', 'user', 0);
INSERT INTO entity_types (org_id, entity_type_name, entity_role, use_key_id) VALUES (1, 'Staff', 'staff', 1);
INSERT INTO entity_types (org_id, entity_type_name, entity_role, use_key_id) VALUES (1, 'Client', 'client', 2);
INSERT INTO entity_types (org_id, entity_type_name, entity_role, use_key_id) VALUES (1, 'Supplier', 'supplier', 3);
INSERT INTO entity_types (org_id, entity_type_name, entity_role, use_key_id) VALUES (1, 'Applicant', 'applicant', 4);
INSERT INTO entity_types (org_id, entity_type_name, entity_role, use_key_id) VALUES (1, 'Sacco Members', 'member', 100);


INSERT INTO locations (org_id, location_name) VALUES (1, 'Head Office');
INSERT INTO departments (org_id, department_name) VALUES (1, 'Board of Directors');

---NEXT OF KIN TYPES
INSERT INTO kin_types (org_id, kin_type_name)
SELECT 1, kin_type_name
FROM kin_types
WHERE org_id = 0;

---sacco positions
INSERT INTO position_levels (org_id,position_level_name,narrative)
SELECT 1,position_level_name,narrative
FROM position_levels
WHERE org_id = 0;

---USER LEVELS FOR SACCO
INSERT INTO sys_access_levels (org_id, use_key_id,sys_access_level_name, access_tag)
SELECT 1,use_key_id,sys_access_level_name, access_tag
FROM sys_access_levels
WHERE org_id = 0;


---SYS SMS CONFIGURATIONS
INSERT INTO sms_configs(org_id,use_key_id,sms_config_name,is_active,sms_template)
SELECT 1,use_key_id,sms_config_name,is_active,sms_template
FROM sms_configs
WHERE org_id = 0;

---COLLATERAL TYPES
INSERT INTO collateral_types (org_id, collateral_type_name)
SELECT 1,collateral_type_name
FROM collateral_types
WHERE org_id = 0;

---ISSUES LEVEL
INSERT INTO issue_levels(org_id, issue_level_name)
SELECT 1, issue_level_name
FROM issue_levels
WHERE org_id = 0;

---ISSUE TYPES
INSERT INTO issue_types (org_id, issue_type_name)
SELECT 1, issue_type_name
FROM issue_types
WHERE org_id = 0;


INSERT INTO tax_types (org_id, tax_type_id, use_key_id, tax_type_name, tax_rate, account_id) VALUES (1, 11, 15, 'Exempt', 0, '42000');
INSERT INTO tax_types (org_id, tax_type_id, use_key_id, tax_type_name, tax_rate, account_id) VALUES (1, 12, 15, 'VAT', 16, '42000');
SELECT pg_catalog.setval('tax_types_tax_type_id_seq', 12, true);

INSERT INTO account_class (org_id, account_class_no, chat_type_id, chat_type_name, account_class_name)
SELECT 1, account_class_no, chat_type_id, chat_type_name, account_class_name
FROM account_class
WHERE org_id = 0;

INSERT INTO account_types (org_id, account_class_id, account_type_no, account_type_name)
SELECT a.org_id, a.account_class_id, b.account_type_no, b.account_type_name
FROM account_class a INNER JOIN account_types b ON a.account_class_no = b.account_class_id
WHERE (a.org_id = 1) AND (b.org_id = 0);

INSERT INTO accounts (org_id, account_type_id, account_no, account_name)
SELECT a.org_id, a.account_type_id, b.account_no, b.account_name
FROM account_types a INNER JOIN accounts b ON a.account_type_no = b.account_type_id
WHERE (a.org_id = 1) AND (b.org_id = 0);

INSERT INTO default_accounts (org_id, use_key_id, account_id)
SELECT b.org_id, a.use_key_id, b.account_id
FROM default_accounts a INNER JOIN accounts b ON a.account_id = b.account_no
WHERE (a.org_id = 0) AND (b.org_id = 1);

INSERT INTO collateral_types (org_id, collateral_type_name) VALUES (1, 'Property Title Deed');

INSERT INTO activity_types (cr_account_id, dr_account_id, use_key_id, org_id, activity_type_name, is_active, activity_type_no)
SELECT dra.account_id, cra.account_id, activity_types.use_key_id, 1, activity_types.activity_type_name, activity_types.is_active, 
	activity_types.activity_type_no
FROM activity_types
	INNER JOIN accounts dra ON activity_types.dr_account_id = dra.account_no
	INNER JOIN accounts cra ON activity_types.cr_account_id = cra.account_no
WHERE (dra.org_id = 1) AND (cra.org_id = 1) AND (activity_types.org_id = 0)
ORDER BY activity_types.activity_type_id;

INSERT INTO interest_methods (activity_type_id, org_id, interest_method_name, reducing_balance, reducing_payments, formural, account_number, interest_method_no)
SELECT oa.activity_type_id, oa.org_id, interest_methods.interest_method_name, 
       interest_methods.reducing_balance, interest_methods.reducing_payments, 
       interest_methods.formural, interest_methods.account_number,
       interest_methods.interest_method_no
FROM interest_methods INNER JOIN activity_types ON interest_methods.activity_type_id = activity_types.activity_type_id
INNER JOIN activity_types oa ON activity_types.activity_type_no = oa.activity_type_no
WHERE (activity_types.org_id = 0) AND (oa.org_id = 1)
ORDER BY interest_methods.interest_method_id;

INSERT INTO penalty_methods(activity_type_id, org_id, penalty_method_name, formural, account_number, penalty_method_no)
SELECT oa.activity_type_id, oa.org_id, penalty_methods.penalty_method_name, penalty_methods.formural, penalty_methods.account_number,
	penalty_methods.penalty_method_no
FROM penalty_methods INNER JOIN activity_types ON penalty_methods.activity_type_id = activity_types.activity_type_id
INNER JOIN activity_types oa ON activity_types.activity_type_no = oa.activity_type_no
WHERE (activity_types.org_id = 0) AND (oa.org_id = 1)
ORDER BY penalty_methods.penalty_method_id;

INSERT INTO products(interest_method_id, penalty_method_id, activity_frequency_id, 
	currency_id, org_id, product_name, description, loan_account, 
	is_active, interest_rate, min_opening_balance, lockin_period_frequency, 
	minimum_balance, maximum_balance, minimum_day, maximum_day, minimum_trx, 
	maximum_trx, maximum_repayments, product_no,  approve_status)
SELECT interest_methods.interest_method_id, penalty_methods.penalty_method_id, vw_products.activity_frequency_id, 
	5, 1, vw_products.product_name, vw_products.description, vw_products.loan_account, 
	vw_products.is_active, vw_products.interest_rate, vw_products.min_opening_balance, vw_products.lockin_period_frequency, 
	vw_products.minimum_balance, vw_products.maximum_balance, vw_products.minimum_day, vw_products.maximum_day, vw_products.minimum_trx, 
	vw_products.maximum_trx, vw_products.maximum_repayments, vw_products.product_no, vw_products.approve_status
FROM vw_products INNER JOIN interest_methods ON vw_products.interest_method_no = interest_methods.interest_method_no
	INNER JOIN penalty_methods ON vw_products.penalty_method_no = penalty_methods.penalty_method_no
WHERE (vw_products.org_id = 0) AND (interest_methods.org_id = 1)
AND (penalty_methods.org_id = 1)
ORDER BY vw_products.product_id;

INSERT INTO account_definations(product_id, activity_type_id, charge_activity_id, 
	activity_frequency_id, org_id, account_defination_name, start_date, 
	end_date, fee_amount, fee_ps, has_charge, is_active, account_number)
SELECT products.product_id, activity_types.activity_type_id, charge_activity.activity_type_id, 
	ad.activity_frequency_id, 1, ad.account_defination_name, 
	ad.start_date, ad.end_date, ad.fee_amount, 
	ad.fee_ps, ad.has_charge, ad.is_active, 
	(ad.account_number::integer - 400000000)::varchar(32)
FROM vw_account_definations as ad INNER JOIN products ON ad.product_no = products.product_no
	INNER JOIN activity_types ON ad.activity_type_no = activity_types.activity_type_no
	INNER JOIN activity_types as charge_activity ON ad.charge_activity_no = charge_activity.activity_type_no
WHERE (ad.org_id = 0) AND (products.org_id = 1)
	AND (activity_types.org_id = 1) AND (charge_activity.org_id = 1);
	

INSERT INTO workflows (link_copy, org_id, source_entity_id, workflow_name, table_name, approve_email, reject_email) 
SELECT aa.workflow_id, cc.org_id, cc.entity_type_id, aa.workflow_name, aa.table_name, aa.approve_email, aa.reject_email
FROM workflows aa INNER JOIN entity_types bb ON aa.source_entity_id = bb.entity_type_id
	INNER JOIN entity_types cc ON bb.use_key_id = cc.use_key_id
WHERE aa.org_id = 0 AND cc.org_id = 1
ORDER BY aa.workflow_id;

INSERT INTO workflow_phases (org_id, workflow_id, approval_entity_id, approval_level, return_level, 
	escalation_days, escalation_hours, required_approvals, advice, notice, 
	phase_narrative, advice_email, notice_email) 
SELECT bb.org_id, bb.workflow_id, cc.entity_type_id, aa.approval_level, aa.return_level, 
	aa.escalation_days, aa.escalation_hours, aa.required_approvals, aa.advice, aa.notice, 
	aa.phase_narrative, aa.advice_email, aa.notice_email
FROM workflow_phases aa INNER JOIN workflows bb ON aa.workflow_id = bb.link_copy
	INNER JOIN entity_types cc ON aa.approval_entity_id = cc.use_key_id
WHERE aa.org_id = 0 AND bb.org_id = 1 AND cc.org_id = 1;

INSERT INTO sys_emails (org_id, use_type, sys_email_name, title, details)
SELECT 1, use_type, sys_email_name, title, details
FROM sys_emails
WHERE org_id = 0 AND sys_email_id IN (1,2,3,6,7,8,9) ;

UPDATE transaction_counters SET document_number = '10001';