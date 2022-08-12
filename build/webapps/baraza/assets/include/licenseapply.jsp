

<div class='form-body'>
	<div>Your need to register the system</div>
	<div class='col-md-9'>
		<div class='form-group'>
			<label class='control-label col-md-3'>Organisation Name</label>
			<div class='col-md-9'>
				<input name='org_name' id='org_name' class='form-control' value='<%= web.getOrgName() %>'/>
			</div>
		</div>			
	</div>
	<div class='col-md-9'>
		<div class='form-group'>
			<label class='control-label col-md-3'>System Key</label>
			<div class='col-md-9'>
				<input name='sys_key' id='sys_key' class='form-control' value=''/>
			</div>
		</div>			
	</div>
	<div class='col-md-3'>
		<button class='btn btn-success i_tick icon small' id="licenseApply" name='licenseApply' type='button' value='Apply'><i class='fa  fa-save'></i> &nbsp; Apply</button>
	</div>
</div>
