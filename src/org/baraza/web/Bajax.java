/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.web;

import java.text.SimpleDateFormat;
import java.text.DecimalFormat;
import java.text.ParseException;
import java.util.Enumeration;
import java.util.Calendar;
import java.util.Date;
import java.util.Map;
import java.util.HashMap;
import java.util.logging.Logger;
import java.io.StringReader;
import java.io.PrintWriter;
import java.io.OutputStream;
import java.io.InputStream;
import java.io.IOException;

import javax.json.Json;
import javax.json.JsonArray;
import javax.json.JsonObject;
import javax.json.JsonReader;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpSession;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BElement;

public class Bajax extends HttpServlet {
	Logger log = Logger.getLogger(Bajax.class.getName());

	BWeb web = null;
	BDB db = null;

	public void doPost(HttpServletRequest request, HttpServletResponse response)  {
		doGet(request, response);
	}

	public void doGet(HttpServletRequest request, HttpServletResponse response) { 
		ServletContext context = getServletContext();
		HttpSession session = request.getSession(true);
		String xmlcnf = (String)session.getAttribute("xmlcnf");
		String ps = System.getProperty("file.separator");
		String xmlfile = context.getRealPath("WEB-INF") + ps + "configs" + ps + xmlcnf;
		String projectDir = context.getInitParameter("projectDir");
		if(projectDir != null) xmlfile = projectDir + ps + "configs" + ps + xmlcnf;
		String dbconfig = "java:/comp/env/jdbc/database";
		
		Enumeration e = request.getParameterNames();
        while (e.hasMoreElements()) {
			String ce = (String)e.nextElement();
			System.out.println(ce + ":" + request.getParameter(ce));
		}

		response.setContentType("text/html");
		PrintWriter out = null;
		try { out = response.getWriter(); } catch(IOException ex) {}
		String resp = "";

		web = new BWeb(dbconfig, xmlfile);
		web.init(request);
		
		db = web.getDB();
		
		String sp = request.getServletPath();
		if(sp.equals("/ajaxupdate")) {
			if("edit".equals(request.getParameter("oper"))) {
				resp = updateGrid(request);
			}
		}
		System.out.println("AJAX Reached : " + request.getParameter("fnct"));		
		
		String function = request.getParameter("ajaxfunction");			// function to execute
		String params = request.getParameter("ajaxparams");				// function params
		String from = request.getParameter("from");						// from function
		if((function != null) && (params != null)) resp = executeSQLFxn(function, params, from);

		String fnct = request.getParameter("fnct");
		String id = request.getParameter("id");
		String ids = request.getParameter("ids");
		String startDate = request.getParameter("startdate");
		String startTime = request.getParameter("starttime");
		String endDate = request.getParameter("enddate");
		String endTime = request.getParameter("endtime");

		if("formupdate".equals(fnct)) {
			BWebForms webForm = new BWebForms(db);
			resp = webForm.updateForm(request.getParameter("entry_form_id"), request.getParameter("json"));
			response.setContentType("application/json;charset=\"utf-8\"");
		} else if("formsubmit".equals(fnct)) {
			BWebForms webForm = new BWebForms(db);
			resp = webForm.submitForm(request.getParameter("entry_form_id"), request.getParameter("json"));
			response.setContentType("application/json;charset=\"utf-8\"");
		} else if("calresize".equals(fnct)) {
			resp = calResize(id, endDate, endTime);
		} else if("calmove".equals(fnct)) {
			resp = calMove(id, startDate, startTime, endDate, endTime);
		} else if("filter".equals(fnct)) {
			resp = web.getFilterWhere(request);
		} else if("operation".equals(fnct)) {
			resp = calOperation(id, ids, request);
			response.setContentType("application/json;charset=\"utf-8\"");
		} else if("password".equals(fnct)) {
			resp = changePassword(request.getParameter("oldpass"), request.getParameter("newpass"));
			response.setContentType("application/json;charset=\"utf-8\"");
		} else if("importprocess".equals(fnct)) {
			resp = importProcess(web.getView().getAttribute("process"));
			response.setContentType("application/json;charset=\"utf-8\"");
		} else if("buy_product".equals(fnct)) {
			resp = buyProduct(id, request.getParameter("units"));
			response.setContentType("application/json;charset=\"utf-8\"");
		} else if("renew_product".equals(fnct)) {
			resp = renewProduct();
			response.setContentType("application/json;charset=\"utf-8\"");
		} else if("tableviewupdate".equals(fnct)) {
			resp = tableViewUpdate(request);
			response.setContentType("application/json;charset=\"utf-8\"");
		} else if("jsinsert".equals(fnct)) {
			resp = jsGrid(fnct, request);
			response.setContentType("application/json;charset=\"utf-8\"");
		} else if("jsupdate".equals(fnct)) {
			resp = jsGrid(fnct, request);
			response.setContentType("application/json;charset=\"utf-8\"");
		} else if("jsdelete".equals(fnct)) {
			resp = jsGrid(fnct, request);
			response.setContentType("application/json;charset=\"utf-8\"");
		} else if("attendance".equals(fnct)) {
			resp = attendance(request);
			response.setContentType("application/json;charset=\"utf-8\"");
		} else if("task".equals(fnct)) {
			resp = tasks(request);
			response.setContentType("application/json;charset=\"utf-8\"");
		}
		
		web.close();			// close DB commections
		out.println(resp);
	}
	
	public String updateGrid(HttpServletRequest request) {
		String resp = "";
		
		boolean hasEdit = false;
		BElement view = web.getView();
		String upSql = "UPDATE " + view.getAttribute("updatetable") + " SET ";
		for(BElement el : view.getElements()) {
			if(el.getName().equals("EDITFIELD")) {
				if(hasEdit) upSql += ", ";
				upSql += el.getValue() + " = '" + request.getParameter(el.getValue()) + "'";
				hasEdit = true;
			}
		}
		
		if(hasEdit) {
			String editKey = view.getAttribute("keyfield");
			String id = request.getParameter("KF");
			String autoKeyID = db.insAudit(view.getAttribute("updatetable"), id, "EDIT");
			
			if(view.getAttribute("auditid") != null) upSql += ", " + view.getAttribute("auditid") + " = " + autoKeyID;
			upSql += " WHERE " + editKey + " = '" + id + "'";
			
			resp = db.executeQuery(upSql);
			
			System.out.println("BASE GRID UPDATE : " + upSql);
		}
		
		if(resp == null) resp = "OK";
		
		return resp;
	}

	public String calResize(String id, String endDate, String endTime) {
		String resp = "";

		String sql = "UPDATE case_activity SET finish_time = '" + endTime + "' ";
		sql += "WHERE case_activity_id = " + id;
		System.out.println(sql);

		web.executeQuery(sql);

		return resp;
	}

	public String calMove(String id, String startDate, String startTime, String endDate, String endTime) {
		String resp = "";

		if("".equals(endDate)) {
			resp = calResize(id, endDate, endTime);
		} else {
			String sql = "UPDATE case_activity SET activity_date = '"  + endDate + "', activity_time = '" + startTime;
			sql += "', finish_time = '" + endTime + "' ";
			sql += "WHERE case_activity_id = " + id;
			System.out.println(sql);

			web.executeQuery(sql);
		}

		return resp;
	}

	public String executeSQLFxn(String fxn, String prms, String from) {
		String query = "";

		if(from == null) query = "SELECT " + fxn + "('" + prms + "')";
		else query = "SELECT " + fxn + "('" + prms + "') from " + from;
		System.out.println("SQL function = " + query);

		String str = "";
		if(!prms.trim().equals("")) str = web.executeFunction(query);

		return str;
	}

	public String escapeSQL(String str){				
		String escaped = str.replaceAll("'","\'");						
		return escaped;
	}
	
	public String calOperation(String id, String ids, HttpServletRequest request) {
		String resp = web.setOperations(id, ids, request);
		
		return resp;
	}

	public String changePassword(String oldPass, String newPass) {
		String resp = "";
				
		String fnct = web.getRoot().getAttribute("password");
		if(fnct == null) return "{\"success\": 0, \"message\": \"Cannot change Password\"}";
		
		oldPass = oldPass.replaceAll("'", "''");
		newPass = newPass.replaceAll("'", "''");
		
		String mySql = "SELECT " + fnct + "('" + web.getUserID() + "', '" + oldPass + "','" + newPass + "')";
		String myoutput = web.executeFunction(mySql);
		
		if(myoutput == null) resp = "{\"success\": 0, \"message\": \"Old Password Is incorrect\"}";
		else resp = "{\"success\": 1, \"message\": \"Password Changed Successfully\"}";
		
		return resp;
	}
	
	public String importProcess(String sqlProcess) {
		String resp = "";
		
		String myoutput = null;
		if(sqlProcess != null) {
			String mysql = "SELECT " + sqlProcess + "('0', '" + db.getUserID() + "', '')";
			myoutput = web.executeFunction(mysql);
		}
		
		if(myoutput == null) resp = "{\"success\": 0, \"message\": \"Processing has issues\"}";
		else resp = "{\"success\": 1, \"message\": \"Processing Successfull\"}";
		
		return resp;
	}
	
	public String renewProduct() {
		String resp = "";
		
		String mysql = "SELECT COALESCE(sum(a.cr - a.dr), 0) FROM "
		+ "((SELECT COALESCE(sum(receipt_amount), 0) as cr, 0::real as dr FROM product_receipts "
		+ "WHERE (is_paid = true) AND (org_id = " + db.getUserOrg() + ")) "
		+ "UNION "
		+ "(SELECT 0::real as cr, COALESCE(sum(quantity * price), 0) as dr FROM productions "
		+ "WHERE (org_id = " + db.getUserOrg() + "))) as a";
		String bals = db.executeFunction(mysql);
		Float bal = new Float(bals);
		
		String rSql = "SELECT a.product_id, a.product_name, a.details, a.annual_cost, a.expiry_date, a.sum_quantity "
		+ "FROM vws_productions a "
		+ "WHERE (a.is_renewed = false) AND (a.org_id = " + db.getUserOrg() + ")";
		BQuery rRs = new BQuery(web.getDB(), rSql);

		rRs.moveFirst();
		String productId = rRs.getString("product_id");
		Float annualCost = rRs.getFloat("annual_cost");
		Integer quantity = rRs.getInt("sum_quantity");
		rRs.close();
		
		Calendar cal = Calendar.getInstance();
		cal.add(Calendar.YEAR, 1);
		DecimalFormat df = new DecimalFormat("##########.#");
		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
		String calS = sdf.format(cal.getTime());
		
		if((annualCost * quantity) <= bal) {
			String updStr = "UPDATE productions SET is_renewed = true "
			+ "WHERE (is_renewed = false) AND (a.org_id = " + db.getUserOrg()
			+ ") AND (product_id = " + productId + ")";
			db.executeQuery(updStr);
			
			String insSql = "INSERT INTO productions(product_id, entity_id, org_id, quantity, price, expiry_date) VALUES ("
			+ productId + "," + db.getUserID() + "," + db.getUserOrg() + "," + quantity.toString() + "," 
			+ df.format(annualCost) + ", '" + calS + "')";
			db.executeQuery(insSql);
			
			resp = "{\"success\": 0, \"message\": \"Processing has issues\"}";
		} else {
			resp = "{\"success\": 1, \"message\": \"Your balance is " + bals + " which not sufficent for purchase\"}";
		}
		
		return resp;
	}
	
	public String buyProduct(String productId, String units) {
		String resp = "";
		
		String mysql = "SELECT COALESCE(sum(a.cr - a.dr), 0) FROM "
		+ "((SELECT COALESCE(sum(receipt_amount), 0) as cr, 0::real as dr FROM product_receipts "
		+ "WHERE (is_paid = true) AND (org_id = " + db.getUserOrg() + ")) "
		+ "UNION "
		+ "(SELECT 0::real as cr, COALESCE(sum(quantity * price), 0) as dr FROM productions "
		+ "WHERE (org_id = " + db.getUserOrg() + "))) as a";
		String bals = db.executeFunction(mysql);
System.out.println("BASE 2020 : " + bals);
		Float bal = new Float(bals);
		
		mysql = "SELECT product_id, product_name, is_singular, align_expiry, is_montly_bill, "
		+ "montly_cost, is_annual_bill, annual_cost, details "
		+ "FROM products "
		+ "WHERE product_id = " + productId;
		BQuery rs = new BQuery(db, mysql);
		rs.moveFirst();
		
		mysql = "SELECT production_id, product_id, product_name, is_renewed, quantity, price, amount, expiry_date "
		+ "FROM vw_productions "
		+ "WHERE (is_renewed = false) AND (org_id = " + web.getOrgID() 
		+ ") AND (product_id = " + rs.getString("product_id") + ") "
		+ "ORDER BY production_id desc";
		BQuery rsa = new BQuery(db, mysql);
		
		Float annualCost = rs.getFloat("annual_cost");
		Float buyUnits = new Float(units);
		Calendar cal = Calendar.getInstance();
		cal.add(Calendar.YEAR, 1);
		
		if(rs.getBoolean("align_expiry")) {
			if(rsa.moveFirst()) {
				Date expiryDate = rsa.getDate("expiry_date");
				long diff = cal.getTimeInMillis() - expiryDate.getTime();
				if(diff > 0) {
					diff = diff / (1000 * 60 * 60 * 24);
					annualCost = annualCost * (366 - diff) / 366;
					
					cal.setTime(expiryDate);
				}
				
				System.out.println("expiry date " + rsa.getDate("expiry_date"));
				System.out.println("expiry diff " + diff);
				System.out.println("expiry cost " + annualCost);
			}
		}
		DecimalFormat df = new DecimalFormat("##########.#");
		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
		String calS = sdf.format(cal.getTime());
		
		if((annualCost * buyUnits) <= bal) {
			String insSql = "INSERT INTO productions(product_id, entity_id, org_id, quantity, price, expiry_date) VALUES ("
			+ productId + "," + db.getUserID() + "," + db.getUserOrg() + "," + units + "," 
			+ df.format(annualCost) + ", '" + calS + "')";
			db.executeQuery(insSql);
			
			resp = "{\"success\": 0, \"message\": \"Processing has issues\"}";
		} else {
			resp = "{\"success\": 1, \"message\": \"Your balance is " + bals + " which not sufficent for purchase\"}";
		}

		rs.close();
		rsa.close();
		
		return resp;
	}
	
	public String tableViewUpdate(HttpServletRequest request) {
		String resp = "{\"error\": false, \"message\": \"Updated records\"}";
		
		BElement view = web.getView();
		String jsonField = request.getParameter("jsonfield");

		JsonReader jsonReader = Json.createReader(new StringReader(jsonField));
		JsonArray jFields = jsonReader.readArray();
		for (int i = 0; i < jFields.size(); i++) {
			JsonObject jField = jFields.getJsonObject(i);

			String upSql = "UPDATE " + view.getAttribute("updatetable") 
			+ " SET " + jField.getString("field_name") + " = '" + jField.getString("field_value") 
			+ "' WHERE " + view.getAttribute("keyfield") + " = '" + jField.getString("key_id") + "';";
System.out.println("BASE 1025 : " + upSql);
			web.executeQuery(upSql);
		}
		
		return resp;
	}
	
	public String jsGrid(String fnct, HttpServletRequest request) {
		String resp = "";
		
		BElement view = web.getView();
		if(request.getParameter("viewno") == null) return resp;
		Integer viewNo = new Integer(request.getParameter("viewno"));
		BElement SubView = view.getElement(viewNo);
		
		System.out.println("viewno = " + viewNo);
		System.out.println(SubView);
		
		Map<String, String[]> reqParams = new HashMap<String, String[]>();
		Enumeration e = request.getParameterNames();
		String keyField = null;
        while (e.hasMoreElements()) {
			String elName = (String)e.nextElement();
			reqParams.put(elName, request.getParameterValues(elName));
			if(elName.equals("keyfield")) keyField = request.getParameter(elName);
		}
		
		String linkData = null;
		int vds = web.getViewData().size();
		if(vds > 2) linkData = web.getViewData().get(vds - 1);
		
		if("jsinsert".equals(fnct)) {
			BQuery rs = new BQuery(db, SubView, null, null, false);
			rs.recAdd();
			if(linkData != null && SubView.getAttribute("linkfield") != null) rs.updateField(SubView.getAttribute("linkfield"), linkData); 
			rs.updateFields(reqParams, web.getViewData(), request.getRemoteAddr(), linkData);
			resp = rs.getRowJSON();
			rs.close();
		} else if("jsupdate".equals(fnct)) {
			String whereSql = SubView.getAttribute("keyfield") + " = '" + keyField + "'";
			BQuery rs = new BQuery(db, SubView, whereSql, null, false);
			rs.moveFirst();
			rs.recEdit();
			rs.updateFields(reqParams, web.getViewData(), request.getRemoteAddr(), "");
			rs.refresh();
			rs.moveFirst();
			resp = rs.getRowJSON();
			rs.close();
		} else if("jsdelete".equals(fnct)) {
			String whereSql = SubView.getAttribute("keyfield") + " = '" + keyField + "'";
			BQuery rs = new BQuery(db, SubView, whereSql, null, false);
			rs.moveFirst();
			rs.recDelete();
			rs.close();
			resp = "{}";
		}
		
		return resp;
	}
	
	public String attendance(HttpServletRequest request) {
		String resp = "";
		String myOutput = null;
System.out.println("BASE 2020 : ");

		String jsonField = request.getParameter("json");
		if(jsonField != null) {
			JsonReader jsonReader = Json.createReader(new StringReader(jsonField));
			JsonObject jObj = jsonReader.readObject();

			String mySql = "SELECT add_access_logs(" + db.getUserID() + "," + jObj.getString("log_type")
				+ ",'" + jObj.getString("log_in_out") + "', '" + request.getRemoteAddr() + "');";
System.out.println("BASE 2030 : " + mySql);
		
			myOutput = db.executeFunction(mySql);
		}
			
		if(myOutput == null) {
			resp = "{\"success\": 0, \"message\": \"Attendnace not added\"}";
		} else {
			String lWhere = "(log_time_out is null)";
			if(!myOutput.equals("0")) lWhere = "(access_log_id = " + myOutput + ")";
			
			BQuery alRs = new BQuery(db, web.getView().getElementByName("ATTENDANCE").getElementByName("ACCESSLOG"), lWhere, null);
			resp = alRs.getJSON();
			alRs.close();
		}
		
System.out.println("BASE 3120 : " + resp);
		
		return resp;
	}
	
	public String tasks(HttpServletRequest request) {
		String resp = "";
		String myOutput = null;

		String jsonField = request.getParameter("json");
System.out.println("BASE 2120 : " + jsonField);
		if(jsonField != null) {
			JsonReader jsonReader = Json.createReader(new StringReader(jsonField));
			JsonObject jObj = jsonReader.readObject();
			
			String mySql = null;
			if("start".equals(jObj.getString("task"))) {
				mySql = "SELECT add_timesheet(" + jObj.getString("task_name")
					+ ",true, '" + jObj.getString("task_narrative") + "');";
			} else {
				mySql = "SELECT add_timesheet(" + jObj.getString("timesheet_id") + ",false, '');";
			}
System.out.println("BASE 2130 : " + mySql);

			myOutput = db.executeFunction(mySql);
		}
		
		if(myOutput == null) {
			resp = "{\"success\": 0, \"message\": \"Task not added\"}";
		} else {
			BQuery alRs = new BQuery(db, web.getView().getElementByName("TASK").getElementByName("TIMESHEET"), null, null);
			resp = alRs.getJSON();
			alRs.close();
		}
		
System.out.println("BASE 2140 : " + resp);
		
		return resp;
	}
	
}
