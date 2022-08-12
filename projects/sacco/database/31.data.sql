------ emails
---applications
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
	VALUES (1, 0, 'Application', 'Thank you for your Application', 'Thank you {{name}} for your application.<br><br>
		Your user name is {{username}}<br> 
		Your password is {{password}}<br><br>
	Regards<br>
	OpenBaraza<br>');

--- New member Login credentials
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
	VALUES (2, 0, 'New member', 'Your credentials ', 'Hello {{name}},<br><br>
		Your credentials to the Sacco system have been created.<br>
		Your user name is: {{username}}<br>
		Your password is: {{password}}<br><br>
	Regards<br>
	OpenBaraza<br>');

--- Password Reset
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
	VALUES (3, 0, 'Password reset', 'Password reset', 'Hello {{name}},<br><br>
		Your password has been reset to:<br><br>
		Your user name is: {{username}}<br> 
		Your password is: {{password}}<br><br>
	Regards<br>
	OpenBaraza<br>');

-- ====================== for default org/sacco ======================

---subscription Notifications
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
	VALUES (4, 0, 'Subscription', 'Subscription', 'Hello {{name}},<br><br>
		Welcome to OpenBaraza Sacco Platform<br><br>
		Your password is:<br><br>
			Your user name is {{username}}<br> 
			Your password is {{password}}<br><br>
	Regards,<br>
	OpenBaraza<br>');

---subscription approval notificatiion
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
	VALUES (5, 0, 'Subscription', 'Subscription', 'Hello {{name}},<br><br>
		Your OpenBaraza Sacco Platform application has been approved<br><br>
		Welcome to OpenBaraza Sacco Platform<br><br>
	Regards,<br>
	OpenBaraza<br>');

-- ============================================================================

---loan approval notification 
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
	VALUES (6, 0, 'loan approval', 'loan approval', 'Hello {{name}},<br><br>
		Your loan has been approved<br><br>
	Regards,<br>
	OpenBaraza<br>');

---guarantees request notification
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
	VALUES (7, 0, 'guarantees', 'guarantees', 'Hello {{name}},<br><br>
		Your Request has been approved<br><br>
	Regards,<br>
	OpenBaraza<br>');

--- member termination notification
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
	VALUES (8, 0, 'member termination', 'member termination', 'Hello {{name}},<br><br>
		Your have been fully terminated from the sacco and all accounts eactivated/closed<br><br>
	Regards,<br>
	OpenBaraza<br>');

---account activity notification
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
	VALUES (9, 0, 'Account Activity', 'Account Activity', 'Hello {{name}},<br><br>
		New transaction has been recorded from your accounts<br><br>
	Regards,<br>
	OpenBaraza<br>');

---
SELECT pg_catalog.setval('sys_emails_sys_email_id_seq', 9, true);

UPDATE sys_emails SET use_type = sys_email_id;


