---issue level table
CREATE TABLE issue_levels (
	issue_level_id			serial primary key,
	org_id					integer references orgs,
	issue_level_name		varchar(50) not null,
	details					text
);
CREATE INDEX issue_levels_org_id ON issue_levels(org_id);

---issue types table
CREATE TABLE issue_types (
	issue_type_id			serial primary key,
	org_id					integer references orgs,
	issue_type_name			varchar(50) not null,
	details					text
);
CREATE INDEX issue_types_org_id ON issue_types(org_id);

---issue definations
CREATE TABLE issue_definitions (
	issue_definition_id		serial primary key,
	issue_type_id			integer references issue_types,
	org_id					integer references orgs,
	issue_definition_name	varchar(50)  not null,
	description				text,
	solution				text
);
CREATE INDEX issue_definitions_issue_type_id ON issue_definitions(issue_type_id);
CREATE INDEX issue_definitions_org_id ON issue_definitions(org_id);

---helpdesk table
CREATE TABLE helpdesk (
	helpdesk_id				serial primary key,
	org_id					integer references orgs,
	issue_definition_id		integer references issue_definitions,
	issue_level_id			integer references issue_levels,

	member_id				integer references members,
	description				text,

	recorded_by				integer references entitys,
	recoded_time			timestamp not null default now(),

	-----after adding
	solved_time				timestamp,
	is_solved				boolean not null default false,
	closed_by				integer references entitys,

	---if its escalated/assigned to a individual
	is_escalated 			boolean not null default false,
	escalated_to 			integer references entitys,
	escalated_by 			integer references entitys,
	escalated_time 			timestamp,

	curr_action				varchar(50), --In Progres, escalated, Blocked, Done
	curr_status				varchar(50), --, Open, Closed

	problem					text,
	solution				text
);
CREATE INDEX helpdesk_issue_definition_id ON helpdesk(issue_definition_id);
CREATE INDEX helpdesk_issue_level_id ON helpdesk(issue_level_id);
CREATE INDEX helpdesk_member_id ON helpdesk(member_id);
CREATE INDEX helpdesk_recorded_by ON helpdesk(recorded_by);
CREATE INDEX helpdesk_closed_by ON helpdesk(closed_by);
CREATE INDEX helpdesk_escalated_to ON helpdesk(escalated_to);
CREATE INDEX helpdesk_escalated_by ON helpdesk(escalated_by);
CREATE INDEX helpdesk_org_id ON helpdesk(org_id);


CREATE OR REPLACE VIEW vw_issue_definitions AS
	SELECT issue_types.issue_type_id, issue_types.issue_type_name, 
		issue_definitions.org_id, issue_definitions.issue_definition_id, issue_definitions.issue_definition_name, 
		issue_definitions.description, issue_definitions.solution,
		(issue_types.issue_type_name || ' - ' || issue_definitions.issue_definition_name) as issue_definition_disp
	FROM issue_definitions INNER JOIN issue_types ON issue_definitions.issue_type_id = issue_types.issue_type_id;
	
-- CREATE VIEW vw_helpdesk AS
-- 	SELECT vw_issue_definitions.issue_type_id, vw_issue_definitions.issue_type_name, 
-- 		vw_issue_definitions.issue_definition_id, vw_issue_definitions.issue_definition_name, 

-- 		issue_levels.issue_level_id, issue_levels.issue_level_name,

-- 		helpdesk.recorded_by, recorder.entity_name as recorder_name, 
-- 		helpdesk.closed_by, closer.entity_name as closer_name, helpdesk.org_id, helpdesk.helpdesk_id, helpdesk.description,
-- 		helpdesk.recoded_time, helpdesk.solved_time, helpdesk.is_solved, helpdesk.curr_action, 
-- 		helpdesk.curr_status, helpdesk.problem, helpdesk.solution
-- 	FROM helpdesk INNER JOIN vw_issue_definitions ON helpdesk.issue_definition_id = vw_issue_definitions.issue_definition_id
-- 		INNER JOIN issue_levels ON helpdesk.issue_level_id = issue_levels.issue_level_id
-- 		INNER JOIN entitys as recorder ON helpdesk.recorded_by = recorder.entity_id
-- 		LEFT JOIN entitys as closer ON helpdesk.closed_by = closer.entity_id;

----new helpdesk view
CREATE OR REPLACE VIEW vw_helpdesk_issues AS
	SELECT vw_issue_definitions.issue_type_id, vw_issue_definitions.issue_type_name, 
			vw_issue_definitions.issue_definition_id, vw_issue_definitions.issue_definition_name,
			issue_levels.issue_level_id, issue_levels.issue_level_name,

			helpdesk.recorded_by, recorder.entity_name as recorder_name, 
			helpdesk.org_id, helpdesk.helpdesk_id, helpdesk.description,
			helpdesk.recoded_time, helpdesk.solved_time, helpdesk.is_solved, helpdesk.curr_action, 
			helpdesk.curr_status, helpdesk.problem, helpdesk.solution,
			helpdesk.closed_by, closer.entity_name as closer_name,

			helpdesk.escalated_to, escalated_to.entity_name as escalated_to_name,helpdesk.is_escalated,
			helpdesk.escalated_by, escalated_by.entity_name as escalated_by_name,helpdesk.escalated_time,

			members.member_id, members.member_name, members.telephone_number, members.member_email
		FROM helpdesk 
		INNER JOIN vw_issue_definitions ON helpdesk.issue_definition_id = vw_issue_definitions.issue_definition_id
			INNER JOIN issue_levels ON helpdesk.issue_level_id = issue_levels.issue_level_id
			INNER JOIN entitys as recorder ON helpdesk.recorded_by = recorder.entity_id
			INNER JOIN members ON helpdesk.member_id = members.member_id
			LEFT JOIN entitys as closer ON helpdesk.closed_by = closer.entity_id
			LEFT JOIN entitys as escalated_to ON helpdesk.escalated_to = escalated_to.entity_id
			LEFT JOIN entitys as escalated_by ON helpdesk.escalated_by = escalated_by.entity_id;

---VIEW MEMBERS ISSUES TRACKING
CREATE OR REPLACE VIEW vw_member_issues AS
	SELECT vw_helpdesk_issues.issue_type_id, vw_helpdesk_issues.issue_type_name, vw_helpdesk_issues.issue_definition_id, 
		vw_helpdesk_issues.issue_definition_name, vw_helpdesk_issues.issue_level_id, vw_helpdesk_issues.issue_level_name, 
		vw_helpdesk_issues.recorded_by, vw_helpdesk_issues.recorder_name, vw_helpdesk_issues.org_id, 
		vw_helpdesk_issues.helpdesk_id, vw_helpdesk_issues.description, vw_helpdesk_issues.recoded_time, 
		vw_helpdesk_issues.is_solved, vw_helpdesk_issues.solved_time, vw_helpdesk_issues.curr_action, 
		vw_helpdesk_issues.curr_status, vw_helpdesk_issues.problem, vw_helpdesk_issues.solution, vw_helpdesk_issues.closed_by, 
		vw_helpdesk_issues.closer_name, vw_helpdesk_issues.member_id, vw_helpdesk_issues.member_name , vw_helpdesk_issues.is_escalated, 
		vw_helpdesk_issues.telephone_number, vw_helpdesk_issues.member_email,entitys.entity_id
	FROM vw_helpdesk_issues
		INNER JOIN entitys ON entitys.member_id = vw_helpdesk_issues.member_id;

------view for escalations
CREATE OR REPLACE VIEW vw_escalated_issues AS
	SELECT vw_helpdesk_issues.issue_type_id, vw_helpdesk_issues.issue_type_name, vw_helpdesk_issues.issue_definition_id, 
		vw_helpdesk_issues.issue_definition_name, vw_helpdesk_issues.issue_level_id, vw_helpdesk_issues.issue_level_name, 
		vw_helpdesk_issues.recorded_by, vw_helpdesk_issues.recorder_name, vw_helpdesk_issues.org_id, vw_helpdesk_issues.helpdesk_id, 
		vw_helpdesk_issues.description, vw_helpdesk_issues.recoded_time, vw_helpdesk_issues.is_solved,vw_helpdesk_issues.escalated_time,
		vw_helpdesk_issues.curr_action, vw_helpdesk_issues.curr_status, vw_helpdesk_issues.problem, vw_helpdesk_issues.solution,
		vw_helpdesk_issues.escalated_to, vw_helpdesk_issues.escalated_to_name, vw_helpdesk_issues.is_escalated, 
		vw_helpdesk_issues.escalated_by, vw_helpdesk_issues.escalated_by_name, vw_helpdesk_issues.member_name, 
		vw_helpdesk_issues.telephone_number, vw_helpdesk_issues.member_email, entitys.entity_id
	FROM vw_helpdesk_issues
		INNER JOIN entitys ON vw_helpdesk_issues.escalated_to = entitys.entity_id;

---====================================Functions for helpdesk ===========================

---closing the issue
CREATE OR REPLACE FUNCTION issue_tracking(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 					varchar(120);
	reca 					RECORD;
	v_entity_id 			integer;
BEGIN

	msg := null;
	---clossing the issue
	IF($3 = '1')THEN
		SELECT problem, solution INTO reca FROM helpdesk WHERE helpdesk_id = $1::integer;

		IF ((reca.problem is null) AND (reca.solution is null)) THEN
			RAISE EXCEPTION 'You must provide the solution to the issue before closing the issue...!';
		ELSE
			UPDATE helpdesk SET closed_by = $2::integer, solved_time = current_timestamp, is_solved = true,
			curr_action = 'Done', curr_status = 'Closed'
			WHERE helpdesk_id = $1::integer;
		END IF;
		msg := 'Closed the call';
	END IF;

	---escalating the issue
	IF($3 = '3')THEN
		SELECT entity_id INTO v_entity_id FROM entitys WHERE entity_id = $1::integer;

		UPDATE helpdesk SET escalated_to = v_entity_id, is_escalated = true, curr_action = 'Escalated/Fowarded',escalated_by = $2::integer
		WHERE helpdesk_id = cast($4 as int);			
		msg := 'Issue Escalated/Assigned Successfully...';
			
	END IF;
	
	return msg;
END;
$$ LANGUAGE plpgsql;



