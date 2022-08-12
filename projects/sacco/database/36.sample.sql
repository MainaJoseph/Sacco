
---- transaction cash deposits
INSERT INTO account_activity (activity_date, value_date, deposit_account_id, account_credit, activity_type_id, activity_frequency_id, activity_status_id, entity_id, org_id) VALUES
('2017-02-10', '2017-02-10', 101, 250000, 2, 1, 1, 0, 0),
('2017-03-10', '2017-03-10', 102, 140000, 2, 1, 1, 0, 0),
('2017-03-10', '2017-08-10', 103, 45000, 2, 1, 1, 0, 0),
('2017-04-10', '2017-04-10', 104, 74000, 2, 1, 1, 0, 0),
('2017-07-10', '2017-07-10', 105, 55000, 2, 1, 1, 0, 0),
('2017-08-10', '2017-08-10', 106, 45000, 2, 1, 1, 0, 0),
('2018-02-10', '2018-02-10', 107, 45000, 2, 1, 1, 0, 0),
('2018-02-10', '2018-02-10', 108, 45000, 2, 1, 1, 0, 0),
('2018-02-10', '2018-02-10', 109, 45000, 2, 1, 1, 0, 0),
('2018-02-10', '2018-02-10', 110, 45000, 2, 1, 1, 0, 0);

------ Cash withdraw
INSERT INTO account_activity (activity_date, value_date, deposit_account_id, account_debit, activity_type_id, activity_frequency_id, activity_status_id, entity_id, org_id) VALUES
('2017-04-10', '2017-04-14', 101, 95000, 5, 1, 1, 0, 0),
('2017-04-10', '2017-05-14', 106, 40000, 5, 1, 1, 0, 0);


------- Loan Payments
INSERT INTO account_activity (activity_date, value_date, deposit_account_id, account_credit, activity_type_id, activity_frequency_id, activity_status_id, entity_id, org_id)
SELECT start_date + 4, start_date + 4, 101, 15000, 2, 1, 1, 0, 0
FROM periods
WHERE (start_date > '2017-02-02') AND (start_date < current_date)
ORDER BY period_id;

---account activity
INSERT INTO account_activity (activity_date, value_date, deposit_account_id, account_credit, activity_type_id, activity_frequency_id, activity_status_id, entity_id, org_id)
SELECT start_date + 4, start_date + 4, 106, 5500, 2, 1, 1, 0, 0
FROM periods
WHERE (start_date > '2017-06-02') AND (start_date < current_date)
ORDER BY period_id;

---compute loans
SELECT compute_loans(period_id::text, '0', '1', '') 
FROM periods
WHERE (start_date < current_date - '1 month'::interval)
ORDER BY period_id;

---------- Re-compute the activity data

SELECT account_activity_id, deposit_account_id, transfer_account_id,
       activity_type_id, activity_frequency_id, activity_status_id,
       period_id, entity_id, org_id, link_activity_id,
       transfer_link_id, deposit_account_no, transfer_account_no, activity_date,
       value_date, account_credit, account_debit, balance, exchange_rate,
       application_date, approve_status, workflow_table_id, action_date,
       details, loan_id, transfer_loan_id INTO tmp1
FROM account_activity
ORDER BY account_activity_id;


CREATE OR REPLACE FUNCTION adj_account_activity() RETURNS trigger AS $$
DECLARE
    v_deposit_account_id        integer;
    v_period_id                    integer;
    v_loan_id                    integer;
    v_activity_type_id            integer;
    v_use_key_id                integer;
    v_minimum_balance            real;
    v_account_transfer            varchar(32);
BEGIN
   
    IF(TG_OP = 'INSERT')THEN
        IF(NEW.deposit_account_id is not null)THEN
            SELECT sum(account_credit - account_debit) INTO NEW.balance
            FROM account_activity
            WHERE (account_activity_id < NEW.account_activity_id)
                AND (deposit_account_id = NEW.deposit_account_id);
        END IF;
        IF(NEW.loan_id is not null)THEN
            SELECT sum(account_credit - account_debit) INTO NEW.balance
            FROM account_activity
            WHERE (account_activity_id < NEW.account_activity_id)
                AND (loan_id = NEW.loan_id);
        END IF;
        IF(NEW.balance is null)THEN
            NEW.balance := 0;
        END IF;
        NEW.balance := NEW.balance + (NEW.account_credit - NEW.account_debit);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER adj_account_activity BEFORE INSERT ON account_activity
  FOR EACH ROW EXECUTE PROCEDURE adj_account_activity();

ALTER TABLE account_activity DISABLE TRIGGER ins_account_activity;
ALTER TABLE account_activity DISABLE TRIGGER aft_account_activity;
ALTER TABLE account_activity DISABLE TRIGGER log_account_activity;

DELETE FROM logs.lg_account_activity;
DELETE FROM account_activity;

INSERT INTO account_activity (deposit_account_id, transfer_account_id,
       activity_type_id, activity_frequency_id, activity_status_id,
       period_id, entity_id, org_id, link_activity_id,
       transfer_link_id, deposit_account_no, transfer_account_no, activity_date,
       value_date, account_credit, account_debit, balance, exchange_rate,
       application_date, approve_status, workflow_table_id, action_date,
       details, loan_id, transfer_loan_id)
SELECT deposit_account_id, transfer_account_id,
       activity_type_id, activity_frequency_id, activity_status_id,
       period_id, entity_id, org_id, link_activity_id,
       transfer_link_id, deposit_account_no, transfer_account_no, activity_date,
       value_date, account_credit, account_debit, balance, exchange_rate,
       application_date, approve_status, workflow_table_id, action_date,
       details, loan_id, transfer_loan_id
FROM tmp1
ORDER BY activity_date, account_activity_id;

DROP TRIGGER adj_account_activity ON account_activity;
DROP FUNCTION adj_account_activity();

ALTER TABLE account_activity ENABLE TRIGGER ins_account_activity;
ALTER TABLE account_activity ENABLE TRIGGER aft_account_activity;
ALTER TABLE account_activity ENABLE TRIGGER log_account_activity;