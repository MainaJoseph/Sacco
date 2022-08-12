UPDATE orgs SET org_name = 'OpenBaraza', cert_number = 'C.102554', pin = 'P051165288J', vat_number = '0142653A', 
default_country_id = 'KE', currency_id = 1,
org_full_name = 'OpenBaraza',
invoice_footer = 'Make all payments to : OpenBaraza
Thank you for your Business
We Turn your information into profitability'
WHERE org_id = 0;

UPDATE transaction_counters SET document_number = '10001';

INSERT INTO address (org_id, sys_country_id, table_name, table_id, post_office_box, postal_code, premises, street, town, phone_number, extension, mobile, fax, email, website, is_default, first_password, details) 
VALUES (0, 'KE', 'orgs', 0, '45689', '00100', '12th Floor, Barclays Plaza', 'Loita Street', 'Nairobi', '+254 (20) 2227100/2243097', NULL, '+254 725 819505 or +254 738 819505', NULL, 'accounts@dewcis.com', 'www.dewcis.com', true, NULL, NULL);

DELETE FROM currency WHERE currency_id IN (3, 4);
INSERT INTO currency_rates (org_id, currency_id, exchange_rate)
VALUES (0, 2, 100);

INSERT INTO fiscal_years (fiscal_year, org_id, fiscal_year_start, fiscal_year_end) VALUES
('2017', 0, '2017-01-01', '2017-12-31'),
('2018', 0, '2018-01-01', '2018-12-31'),
('2019', 0, '2019-01-01', '2019-12-31');

SELECT add_periods(fiscal_year_id::text, null, null)
FROM fiscal_years
ORDER BY fiscal_year_id;

UPDATE periods SET opened = true WHERE start_date <= current_date;
UPDATE periods SET activated = true WHERE start_date <= current_date;

---- default sacco members
INSERT INTO members (member_id, entity_id, org_id, business_account, person_title, member_name, identification_number, identification_type, member_email, telephone_number, telephone_number2, address, town, zip_code, date_of_birth, gender, nationality, marital_status, picture_file, employed, self_employed, employer_name, monthly_salary, monthly_net_income, annual_turnover, annual_net_income, employer_address, introduced_by, application_date, approve_status, workflow_table_id, action_date, details) VALUES 
(1, 0, 0, 0, 'Mr', 'Peter Mwangi', '30043751', 'ID', 'peter@peter.me.ke', '0797897897', NULL, '0725741369', 'Nairobi', NULL, '2010-06-08', 'M', 'KE', 'S', NULL, true, false, 'Dew CIS Solutions Ltd', NULL, NULL, NULL, NULL, NULL, NULL, '2017-06-07 14:14:49.971406', 'Completed', 2, '2017-06-07 15:09:33.906413', NULL),
(2, 0, 0, 0, 'Miss', 'Dorcas Mwigereri', '258741369', 'ID', 'dmwigereri@gmail.com', '0708066768', NULL, '3698547', 'Nairobi', '00200', '1993-06-09', 'F', 'KE', 'S', NULL, true, false, 'Dew CIS', NULL, NULL, NULL, NULL, NULL, NULL, '2017-06-07 15:06:57.308398', 'Completed', 3, '2017-06-07 15:09:33.922914', NULL),
(3, 0, 0, 0, 'Mr', 'Haron Korir', '22165656295', 'ID', 'hkorir@gmail.com', '0723456987', NULL, '22564', 'Nairobi', '00200', '1990-08-09', 'M', 'KE', 'M', NULL, true, false, 'Dew CIS', NULL, NULL, NULL, NULL, NULL, NULL, '2017-06-07 15:06:57.308398', 'Completed', 3, '2017-06-07 15:09:33.922914', NULL),
(4, 0, 0, 0, 'Miss', 'Faith Mandela', '300741369', 'ID', 'fmandela@gmail.com', '0782456852', NULL, '35874', 'Nairobi', '00200', '1993-09-12', 'F', 'KE', 'S', NULL, true, false, 'Dew CIS', NULL, NULL, NULL, NULL, NULL, NULL, '2017-06-07 15:06:57.308398', 'Completed', 3, '2017-06-07 15:09:33.922914', NULL),
(5, 0, 0, 0, 'Mr', 'Kamau M. Yoz', '272645978655', 'ID', 'mkamau@gmail.com', '0729357951', NULL, '20058', 'Nairobi', '00200', '1989-02-09', 'M', 'KE', 'S', NULL, true, false, 'Dew CIS', NULL, NULL, NULL, NULL, NULL, NULL, '2017-06-07 15:06:57.308398', 'Completed', 3, '2017-06-07 15:09:33.922914', NULL),
(6, 0, 0, 0, 'Miss', 'Florence Ngugi', '24798523625', 'ID', 'fngugi@gmail.com', '0715258963', NULL, '32547', 'Nairobi', '00200', '1987-07-09', 'F', 'KE', 'S', NULL, true, false, 'Dew CIS', NULL, NULL, NULL, NULL, NULL, NULL, '2017-06-07 15:06:57.308398', 'Completed', 3, '2017-06-07 15:09:33.922914', NULL),
(7, 0, 0, 0, 'Mr', 'Dennis Gichangi', '2015648970', 'ID', 'dennis@dennis.me.ke', '0725564978', NULL, '99987', 'Nairobi', '00200', '1983-06-09', 'M', 'KE', 'M', NULL, true, false, 'Dew CIS', NULL, NULL, NULL, NULL, NULL, NULL, '2017-06-07 15:06:57.308398', 'Completed', 3, '2017-06-07 15:09:33.922914', NULL),
(8, 0, 0, 0, 'Mr', 'Francis Chege', '2956481440', 'ID', 'fchege@gmail.com', '0788268751', NULL, '20202', 'Nairobi', '00200', '1991-06-09', 'M', 'KE', 'S', NULL, true, false, 'Dew CIS', NULL, NULL, NULL, NULL, NULL, NULL, '2017-06-07 15:06:57.308398', 'Completed', 3, '2017-06-07 15:09:33.922914', NULL),
(9, 0, 0, 0, 'Mr', 'Evin Mwailongo', '3005987432', 'ID', 'evin@gmail.com', '0755468913', NULL, '30025', 'Nairobi', '00200', '1992-06-09', 'M', 'KE', 'S', NULL, true, false, 'Dew CIS', NULL, NULL, NULL, NULL, NULL, NULL, '2017-06-07 15:06:57.308398', 'Completed', 13, '2017-06-07 15:09:33.922914', NULL),
(10, 0, 0, 0, 'Mrs', 'Rachel Mogire', '2897564130', 'ID', 'rmogire@gmail.com', '0709456258', NULL, '580698', 'Nairobi', '00200', '1991-06-09', 'F', 'KE', 'M', NULL, true, false, 'Dew CIS', NULL, NULL, NULL, NULL, NULL, NULL, '2017-06-07 15:06:57.308398', 'Completed', 13, '2017-06-07 15:09:33.922914', NULL);
SELECT pg_catalog.setval('members_member_id_seq', 10, true);

INSERT INTO sacco_officials (sacco_official_id, position_level_id, org_id,member_id,start_date,end_date,term_limit,is_active,narrative,details) VALUES
(1,1,0,7,'2017-01-01','2020-01-01',2,true,NULL,NULL),
(2,2,0,1,'2017-01-01','2020-01-01',2,true,NULL,NULL),
(3,3,0,6,'2017-01-01','2020-01-01',2,true,NULL,NULL),
(4,4,0,2,'2017-01-01','2020-01-01',2,true,NULL,NULL);
SELECT pg_catalog.setval('sacco_officials_sacco_official_id_seq', 5, true);


UPDATE entitys SET member_id = 1 WHERE entity_id = 0;

---member accounts
INSERT INTO deposit_accounts (member_id, product_id, entity_id, org_id, opening_date, is_active) VALUES
----member transaction accounts
(1, 1, 0, 0, '2017-02-02', true),
(2, 1, 0, 0, '2017-03-02', true),
(3, 1, 0, 0, '2017-04-02', true),
(4, 1, 0, 0, '2017-05-02', true),
(5, 1, 0, 0, '2017-06-02', true),
(6, 1, 0, 0, '2017-07-02', true),
(7, 1, 0, 0, '2017-08-02', true),
(8, 1, 0, 0, '2017-08-02', true),
(9, 1, 0, 0, '2017-08-02', true),
(10, 1, 0, 0, '2017-08-02', true),

----members contribution accounts
(1, 2, 0, 0, '2017-02-02', true),
(2, 2, 0, 0, '2017-03-02', true),
(3, 2, 0, 0, '2017-04-02', true),
(4, 2, 0, 0, '2017-05-02', true),
(5, 2, 0, 0, '2017-06-02', true),
(6, 2, 0, 0, '2017-07-02', true),
(7, 2, 0, 0, '2017-08-02', true),
(8, 2, 0, 0, '2017-08-02', true),
(9, 2, 0, 0, '2017-08-02', true),
(10, 2, 0, 0, '2017-08-02', true);

UPDATE deposit_accounts SET approve_status = 'Completed' WHERE member_id > 0;

---sacco commoditys
INSERT INTO commodity_types (commodity_type_id, org_id, commodity_type_name)
VALUES (1, 0, 'Sacco Shares');
SELECT pg_catalog.setval('commodity_types_commodity_type_id_seq', 1, true);

INSERT INTO commoditys (commodity_type_id, org_id, commodity_name, commodity_account, current_price)
VALUES (1, 0, 'Shares', '400000006', 10);


---loans
INSERT INTO loans (member_id, product_id, entity_id, org_id, disburse_account, principal_amount, repayment_period, disbursed_date) VALUES
(1, 4, 0, 0, '400000101', 100000, 10, '2017-04-12'),
(4, 4, 0, 0, '400000401', 50000, 10, '2017-05-12');

UPDATE loans SET approve_status = 'Completed' WHERE member_id > 0;
 
---- Make approvals 2
SELECT upd_approvals(approval_id::text, '0', '2', '')
FROM approvals;


--------- Reset users
UPDATE entitys SET first_password = 'baraza';
UPDATE entitys SET entity_password = md5('baraza');

--------add user admin
INSERT INTO entitys (org_id,use_key_id,entity_type_id,entity_name,user_name,function_role,is_active,first_password) VALUES
(0,0,0, 'Administrator', 'admin', 'admin,manager,operations', true, 'baraza')