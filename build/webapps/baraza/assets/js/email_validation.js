/**
 * Email Regex Function
 */
function validateEmail(email) {
	var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
	return re.test(email);
}

/**
 *  @param id, passes email id
 *  @param divMsgId, Displays the status Message
 *  @param email, email values
 *  Validates the email
 */
function validate(id, divMsgId, email) {
	var checkEmailStatusOk = "<div style='color:green'><i class='glyphicon glyphicon-ok'></i> Supplied Email is valid</div>";
	var checkEmailStatusNotOk = "<div style='color:red'><i class='glyphicon glyphicon-remove'></i> Supplied Email is not valid</div>";
	if (validateEmail(email)) {
		divMsgId.html(checkEmailStatusOk);
		//Adds success green color on label and input
		id.parent('div').parent('div').removeClass('has-error').addClass('has-success');

		return true;
	} else {
		divMsgId.html(checkEmailStatusNotOk);
		//Adds failure red color on label and input
		id.parent('div').parent('div').removeClass('has-success').addClass('has-error');

		return false;
	}
}

/**
 *
 * @param emailOneVal
 * @param emailTwoVal
 * @param divMessage , Div tag that displays the Status Message
 * @param emailId, The Id of the input
 */
function emailMatch(emailOneVal, emailTwoVal, divMessage, emailId){

	var checkEmailMatch = "<div style='color:green'><i class='glyphicon glyphicon-ok'></i> Emails Match</div>";
	var checkEmailNotMatch = "<div style='color:red'><i class='glyphicon glyphicon-remove'></i> Emails Don't Match</div>";

	if (emailOneVal != emailTwoVal) {
		divMessage.html(checkEmailNotMatch);
		//Adds failure red color on label and input
		emailId.parent('div').parent('div').removeClass('has-success').addClass('has-error').hasClass('form-group');

		return false;
	} else {
		divMessage.html(checkEmailMatch);

		//Adds success green color on label and input
		emailId.parent('div').parent('div').removeClass('has-error').addClass('has-success').hasClass('form-group');

		return true;
	}
}



