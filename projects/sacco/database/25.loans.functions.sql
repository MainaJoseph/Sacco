----==LOANS APPROVAL PROCESS=============
---===============================LOANS FUNCTIONS MODULE ============================================================
--loan statuses
	-- 1. Draft => means the loan has been applied but not approved
	-- 2. Active => means the loan has being approved and disbursed_date
	-- 3. Settled => means the loan has being fully paid.
	-- 4. Defaulted => means the loan has been defaulted or repayment has stopped

----Loan Approval Application
CREATE OR REPLACE FUNCTION loan_approval_final(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg							varchar(120);
	reca 						RECORD;
	v_deposit_account_id		integer;
	v_product_id				integer;
	v_principal_amount			real;
	v_repayment_amount			real;
	v_maximum_repayments		integer;
	v_repayment_period			integer;
	v_contribution_amount		real;
	v_guaranteed_amount		    real;
	v_total_amount			    real;
	v_collateral_amount 		real;
	v_is_guaranteed 			boolean;
	v_is_collateral 			boolean;
	recb 						RECORD;
	v_entry_date 				date;
	v_membership_period			integer;
	v_config_period				integer;
	v_approval_count 			integer;
BEGIN
	---SUBMISSION FOR LOAN APPROVAL
	IF($3 = '1')THEN
		SELECT COALESCE(COUNT(loan_id)) AS loan_approval_count INTO v_approval_count 
		FROM loan_approval_levels
		WHERE (loan_id = $1::integer) AND (is_approved = false);
		
		IF(v_approval_count = 0) THEN
			UPDATE loans SET loan_status = 'Completed', approve_status = 'Completed'
			WHERE (loan_id = $1::integer) AND (approve_status = 'Draft') AND (loan_status = 'Processing');
				
			msg := 'Applied for loan Approval';
		ELSE
			RAISE EXCEPTION 'Pending Processing Approval Detected...!';
		END IF;
	END IF;

	---LOAN APPLICATION PROCESSING 
	----(member loan application process check for securities)
	IF($3 = '2')THEN
		---get application details for loan product and deposit account
		SELECT deposit_accounts.deposit_account_id, loans.principal_amount, loans.repayment_amount,
				loans.repayment_period, products.maximum_repayments,products.product_id
			INTO v_deposit_account_id, v_principal_amount, v_repayment_amount, v_repayment_period, v_maximum_repayments,
			v_product_id
		FROM deposit_accounts INNER JOIN loans ON (deposit_accounts.account_number = loans.disburse_account)
			INNER JOIN products ON loans.product_id = products.product_id
			AND (deposit_accounts.member_id = loans.member_id) AND (loans.loan_id = $1::integer)
			AND (deposit_accounts.approve_status = 'Approved');

		---get contribution available balance
		SELECT COALESCE((available_balance),0)  INTO v_contribution_amount
		FROM vw_deposit_accounts INNER JOIN loans ON loans.member_id = vw_deposit_accounts.member_id
		WHERE (loans.loan_id = $1::integer)
		AND (product_no = 2);

		---get total guarantees for the loan
		v_guaranteed_amount := 0;
		SELECT COALESCE(sum(guarantee_amount),0) AS total_guarentee INTO v_guaranteed_amount
		FROM guarantees
		WHERE guarantee_accepted = true AND (approve_status = 'Approved') 
		AND (is_active = true) AND (loan_id = $1::integer);

		---get total collateral value
		v_collateral_amount := 0;
		SELECT COALESCE(sum(collateral_amount),0) AS total_collateral INTO v_collateral_amount
		FROM collaterals
		WHERE collateral_received = true AND (approve_status = 'Approved') 
		AND (collateral_released = false) AND (loan_id = $1::integer);	

		---get member entry date to the sacco
		SELECT entry_date into v_entry_date FROM members
		INNER JOIN loans ON loans.member_id = members.member_id
		WHERE (loan_id = $1::integer);

		---get member's membership duration in months
		SELECT EXTRACT(YEAR FROM AGE(current_date, entry_date)) * 12 +
		EXTRACT(MONTH FROM AGE(current_date ,entry_date))AS membership_period INTO v_membership_period
		FROM members
		INNER JOIN loans ON loans.member_id = members.member_id
		WHERE (loan_id = $1::integer);

		---=====CHECKS FOR THE LOAN REQUIREMENTS======

		---check the disbursment account
		IF(v_deposit_account_id is null)THEN
			msg := 'The disburse account needs to be active and owned by the member';
			RAISE EXCEPTION '%', msg;

		---check repaymemnt period
		ELSIF(v_repayment_period > v_maximum_repayments)THEN
			msg := 'The repayment periods are more than what is prescribed by the product';
			RAISE EXCEPTION '%', msg;
		END IF;

		---CHECK LOAN SECURITIES CONFIGURATION
		SELECT loan_config_id,org_id,product_id,is_guaranteed,is_collateral,membership_period,less_guaranteed,
		is_active INTO recb
		FROM loan_configs
		WHERE product_id = v_product_id;

		IF(recb.loan_config_id is null) THEN
			msg:= 'The Sacco loan product has not being configured.....';
			RAISE EXCEPTION '%', msg;
		END IF;

		---check membership period requirement
		IF(recb.membership_period > v_membership_period::int) THEN
			msg:= 'You do not meet the membership period to qualify for this loan...';
			RAISE EXCEPTION ' %',msg;
		END IF;

		----loans with guarantee requirement
		IF (recb.is_guaranteed = true) THEN
			---getting the total
			v_total_amount = v_contribution_amount + v_guaranteed_amount;

			IF(v_principal_amount > v_total_amount)THEN
				msg := 'The Guaranteed amount Value is less than Total Amount of Loan Requested...';
				RAISE EXCEPTION '%',msg;
			ELSE
				UPDATE loans SET loan_status = 'Processing'
				WHERE (loan_id = $1::integer) AND (approve_status = 'Draft');
				
				msg := 'Applied for loan approval';
				END IF;
		END IF;

		----loan collateral requirement
		IF (recb.is_collateral = true) THEN
			---getting the total
			v_total_amount = v_contribution_amount + v_collateral_amount;

			IF(v_principal_amount > v_total_amount)THEN
				msg := 'The Collateral amount Value is less than Total Amount of Loan Requested...';
				RAISE EXCEPTION '%',msg;
			ELSE
				UPDATE loans SET loan_status = 'Processing'
				WHERE (loan_id = $1::integer) AND (approve_status = 'Draft');
				
				msg := 'Applied for loan approval';
			END IF;
		END IF;

		----loan guarantee and collateral requirement
		IF ((recb.is_guaranteed = true) AND (recb.is_collateral = true)) THEN
			---getting the total
			v_total_amount = v_contribution_amount + v_collateral_amount + v_guaranteed_amount;
			
			IF(v_principal_amount > v_total_amount)THEN
				msg := 'The total guaranteed and Collateral amount is less than Total Amount of Loan Requested...';
				RAISE EXCEPTION '%', msg;
			ELSE
				UPDATE loans SET loan_status = 'Processing'
				WHERE (loan_id = $1::integer) AND (approve_status = 'Draft');
				
				msg := 'Applied for loan approval';
			END IF;
		END IF;

		----loan no collateral/guarantee requirement
		IF ((recb.is_guaranteed = false) and (recb.is_collateral = false)) THEN
			
			UPDATE loans SET loan_status = 'Processing'
			WHERE (loan_id = $1::integer) AND (approve_status = 'Draft');
			
			msg := 'Loan Approval Application Successful..';
		END IF;
	END IF;

	-- FULLY SETTLED LOANS UPDATE AND RELEASE OF GUARANTORS AND COLLATERALS
	IF($3 = '3')THEN
		--- get loan balances
		SELECT vw_loan_balance.loan_balance INTO reca FROM vw_loan_balance
		WHERE vw_loan_balance.loan_id = $1::integer;

		IF (reca.loan_balance = 0::real) THEN
			---update loans table
			UPDATE loans SET loan_status = 'Settled', is_active = false
			WHERE (loan_id = $1::integer) AND (approve_status = 'Approved') AND (is_active = true);

			--update guarantees table			
			UPDATE guarantees SET is_active = false, details = 'Loan Fully Paid back'
			WHERE (loan_id = $1::integer) AND (is_active = true);
			
			msg := 'Loan Fully Paid back.. updated successfully';
		ELSE
			--msg := 'Loan NOT Fully Paid back..';
			RAISE EXCEPTION 'Loan NOT Fully Paid back.. Loan Balance:- % ',reca.loan_balance;
		END IF;	
	END IF;	

	---SET LOAN AS DEFAULTED AND NOTIFY THE GUARANTORS
	IF($3 = '4')THEN
		UPDATE loans SET loan_status = 'Defaulted', is_active = false
		WHERE (loan_id = $1::integer) AND (approve_status = 'Approved') AND (is_active = true);
		
		msg := 'Loan Defaulted. updated';
	
	END IF;

	---LOAN FINAL APPROVAL FOR DISBURSEMENT
	IF($3 = '5')THEN

		UPDATE loans SET approve_status = 'Approved', action_date = current_date 
		WHERE (loan_id = $1::integer) AND (approve_status = 'Draft');
		
		msg := 'Loan Approved and Disbursed to member transaction account';
	
	END IF;

	-----final approval and disbursment
	IF($3 = '9')THEN
		
			UPDATE loans SET loan_status = 'Approved', approve_status = 'Approved', action_date = now()
			WHERE (loan_id = $1::integer) AND (approve_status = 'Completed');
				
			msg := 'Loan approved successfully... Amount disbursed to members transaction account..';
		
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

 
----LOANS TRIGGER TO CHECK LOANS WHOSE STATUS IS UNDER PROCESSING
CREATE OR REPLACE FUNCTION aft_loans_processing() RETURNS trigger AS $$
DECLARE
	reca 					RECORD;
	msg						varchar(120);
BEGIN
	
	SELECT loan_id, loan_status INTO reca FROM loans WHERE loan_status = 'Processing';
	IF((reca.loan_status = 'Processing'))THEN
		INSERT INTO loan_approval_levels ( org_id,loan_approval_id,loan_id,narrative)
		SELECT org_id,loan_approval_id,NEW.loan_id,'For your Approval'
		FROM loan_approval
		WHERE org_id = NEW.org_id AND is_active = true;
	END IF;
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER aft_loans_processing AFTER INSERT OR UPDATE ON loans
	FOR EACH ROW EXECUTE PROCEDURE aft_loans_processing();


--------====================> upwards not updated to impress sacco

---insert loan configs trigger
CREATE OR REPLACE FUNCTION ins_loan_configs() RETURNS trigger AS $$
DECLARE
	myrec				RECORD;
BEGIN

	IF(TG_OP = 'INSERT')THEN
		SELECT loan_config_id,org_id,product_id,is_guaranteed,is_collateral,membership_period,less_guaranteed,
		is_active INTO myrec
		FROM loan_configs WHERE product_id = NEW.product_id;

		IF(NEW.product_id = myrec.product_id) THEN
		RAISE EXCEPTION 'Loan product configuration already exists...OR is archived...';
		END IF;			
	END IF;	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_loan_configs BEFORE INSERT OR UPDATE ON loan_configs
	FOR EACH ROW EXECUTE PROCEDURE ins_loan_configs();

---insert loan approval staff trigger
CREATE OR REPLACE FUNCTION ins_loan_approval() RETURNS trigger AS $$
DECLARE
	myrec				RECORD;	
	msg					varchar(120);
BEGIN

	IF(TG_OP = 'INSERT')THEN
		SELECT loan_approval_id,sacco_official_id,org_id,processing_approval,final_approval,
		is_active INTO myrec
		FROM loan_approval WHERE sacco_official_id = NEW.sacco_official_id;

		IF(NEW.sacco_official_id = myrec.sacco_official_id) THEN
			RAISE EXCEPTION 'Sacco Official for loan approval already exists....';
		END IF;	

		IF((NEW.processing_approval = true) and (NEW.final_approval = true))THEN
			msg := 'One cannot do two levels of loan approval.. Choose either processing approval OR final approval..';
			RAISE EXCEPTION '%',msg;
		END IF;

	END IF;	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_loan_approval BEFORE INSERT OR UPDATE ON loan_approval
	FOR EACH ROW EXECUTE PROCEDURE ins_loan_approval();

----loan processing approval.
CREATE OR REPLACE FUNCTION loan_workflow_approval(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg							varchar(120);
	reca 						RECORD;	
BEGIN
	---- loan processing approval
	IF($3 = '1')THEN

		UPDATE loan_approval_levels SET is_approved = true,approved_time = now(), entity_id = $2::integer, 
		status = 'Approval_Accepted', details = ('approved on'|| ' :- ' ||current_date)
		WHERE (loan_approval_level_id = $1::integer);

		msg := 'Loan Approved Successfully...';
	
	END IF;
	-----reject approval
	IF($3 = '2')THEN
		SELECT details INTO reca FROM loan_approval_levels WHERE (loan_approval_level_id = $1::integer);
		--- details = ('Approval Rejected on'|| ' :- ' ||current_date)
		IF(reca.details is null) THEN
			RAISE EXCEPTION 'Give details for Rejecting the loan Approval....';
		ELSE
			UPDATE loan_approval_levels SET is_approved = false ,approved_time = now(), entity_id = $2::integer, 
			status='Approval_Rejected'
			WHERE (loan_approval_level_id = $1::integer);

			msg := 'Loan Approval Rejected...';
		END IF;
	
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

