
<% 

	String rSql = "SELECT a.product_id, a.product_name, a.details, a.annual_cost, a.expiry_date, a.sum_quantity, "
		+ "(a.sum_quantity * a.annual_cost) as renewal_fee "
		+ "FROM vws_productions a "
		+ "WHERE (a.is_renewed = false) AND (a.org_id = " + web.getUserOrg() + ")";

	BQuery rRs = new BQuery(web.getDB(), rSql);
	rRs.moveFirst();

%>

<div class='form-body'>
	<div class="row">
		<label class="col-md-9 control-label"><b>Your need to renew the billing</b></label>
	</div>
	<div class="row">
		<label class="col-md-3 control-label">Product ID</label>
		<label class="col-md-6 control-label"><%= rRs.getString("product_id") %></label>
	</div>
	<div class="row">
		<label class="col-md-3 control-label">Product Name</label>
		<label class="col-md-6 control-label"><%= rRs.getString("product_name") %></label>
	</div>
	<div class="row">
		<label class="col-md-3 control-label">Annual unit cost</label>
		<label class="col-md-6 control-label"><%= rRs.getString("annual_cost") %></label>
	</div>
	<div class="row">
		<label class="col-md-3 control-label">Expiry Date</label>
		<label class="col-md-6 control-label"><%= rRs.getString("expiry_date") %></label>
	</div>
	<div class="row">
		<label class="col-md-3 control-label">Quantity</label>
		<label class="col-md-6 control-label"><%= rRs.getString("sum_quantity") %></label>
	</div>
	<div class="row">
		<label class="col-md-3 control-label">Expiry Date</label>
		<label class="col-md-6 control-label"><%= rRs.getString("renewal_fee") %></label>
	</div>
	<div class="row">
		<label class="col-md-3 control-label">Details</label>
		<label class="col-md-6 control-label"><%= rRs.getString("details") %></label>
	</div>
	<div class="row">
		<div class='col-md-3'>
			<button class='btn btn-success i_tick icon small' id="renewalApply" name='renewalApply' type='button' value='Apply'><i class='fa  fa-save'></i> &nbsp; Apply</button>
		</div>
	</div>
</div>


<% rRs.close(); %>
