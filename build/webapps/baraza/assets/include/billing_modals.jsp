<%@ page import="org.baraza.DB.BDB" %>
<%@ page import="org.baraza.DB.BQuery" %>

<% 

	String productId = request.getParameter("product_id");

	BDB db = new BDB("java:/comp/env/jdbc/database");

	String mysql = "SELECT product_id, product_name, is_singular, align_expiry, is_montly_bill, "
		+ "montly_cost, is_annual_bill, annual_cost, details "
		+ "FROM products "
		+ "WHERE product_id = " + request.getParameter("product_id");
	BQuery rs = new BQuery(db, mysql);
	rs.moveFirst();

%>

<div class="modal-header">
	<button type="button" class="close" data-dismiss="modal" aria-hidden="true"></button>
	<h4 class="modal-title">Item Detail</h4>
</div>
<div class="modal-body">
	<div class="row">
		<label class="col-md-3 control-label">Product ID</label>
		<label class="col-md-6 control-label"><%= rs.getString("product_id") %></label>
	</div>
	<div class="row">
		<label class="col-md-3 control-label">Product Name</label>
		<label class="col-md-6 control-label"><%= rs.getString("product_name") %></label>
	</div>
	<div class="row">
		<label class="col-md-3 control-label">Single Product</label>
		<label class="col-md-6 control-label"><%= rs.getBoolean("is_singular", 1) %></label>
	</div>
	<div class="row">
		<label class="col-md-3 control-label">Expiry Aligned</label>
		<label class="col-md-6 control-label"><%= rs.getBoolean("align_expiry", 1) %></label>
	</div>
	<div class="row">
		<label class="col-md-3 control-label">Price per unit year</label>
		<label class="col-md-6 control-label"><%= rs.getString("annual_cost") %></label>
	</div>
	<div class="row">
		<label class="col-md-3 control-label">Details</label>
		<label class="col-md-6 control-label"><%= rs.getString("details") %></label>
	</div>
	<div class="row">
		<label class="col-md-3 control-label">Units to purchase</label>
		<div class="col-md-6"><input type="text" id="units" class="col-md-6 form-control" value="5"/></div>
	</div>
</div>
<div class="modal-footer">
	<button type="button" id="makePurchase" class="btn blue">Make Purchase</button>
	<button type="button" class="btn default" data-dismiss="modal">Cancel</button>
</div>


<script type="text/javascript">
	$('#makePurchase').click(function() {
		var units = $("#units").val();

		$.post("ajax?fnct=buy_product&id=" + <%= productId %> + "&units=" + units, function(data) {

			if(data.success == 0) {
				$('#ajax').modal('hide');
			} else if(data.success == 1){
				alert(data.message);
			}

		}, "JSON");
	});
</script>

<%
	rs.close();
	db.close();

%>

