/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.web;

import java.util.logging.Logger;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.Enumeration;
import java.util.Base64;
import java.io.OutputStream;
import java.io.InputStream;
import java.io.PrintWriter;
import java.io.IOException;

import org.json.JSONObject;
import org.json.JSONArray;

import javax.servlet.ServletContext;
import javax.servlet.ServletConfig;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.ServletException;

import org.baraza.utils.BWebUtils;
import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.DB.BUser;
import org.baraza.xml.BXML;
import org.baraza.xml.BElement;

public class BDataOps {
	Logger log = Logger.getLogger(BDataOps.class.getName());

	BElement root = null;
	BDB db = null;
	Map<String, BUser> users;
	
	public BDataOps(BElement root, BDB db) {
		users = new HashMap<String, BUser>();
		this.db = db;
		this.root = root;
	}
	
	public JSONObject authenticate(HttpServletRequest request)  {
		JSONObject jResp = new JSONObject();

		String authUser = request.getHeader("authuser");
		String authPass = request.getHeader("authpass");
		if(authUser == null || authPass == null) {
			jResp.put("ResultCode", 1);
			jResp.put("ResultDesc", "Wrong username or password");
			return jResp;
		}

		authUser = new String(Base64.getDecoder().decode(authUser));
		authPass = new String(Base64.getDecoder().decode(authPass));
		
		String authFunction = root.getAttribute("authentication", "password_validate");
		
		String userId = db.executeFunction("SELECT " + authFunction + "('" + authUser + "', '" + authPass + "')");
		if(userId == null) userId = "-1";
System.out.println("BASE 2010 : " + authUser + " : " + authPass + " : " + userId);

		if(userId.equals("-1")) {
			jResp.put("ResultCode", 1);
			jResp.put("ResultDesc", "Wrong username or password");
		} else {
			String token = BWebUtils.createToken(userId);
System.out.println("BASE 3010 : " + token);

			users.put(userId, new BUser(db, request.getRemoteAddr(), authUser, userId));
			
			jResp.put("ResultCode", 0);
			jResp.put("access_token", token);
			jResp.put("expires_in", "15");
		}
		
		return jResp;
	}
	
	public JSONObject reAuthenticate(String token) {
		JSONObject jResp = new JSONObject();
		String userId = BWebUtils.decodeToken(token);
System.out.println("BASE 3030 : " + userId);
			
		if(userId == null) {
			jResp.put("ResultCode", 1);
			jResp.put("access_error", "Wrong token");
		} else {
			jResp.put("ResultCode", 0);
			jResp.put("userId", userId);
		}
		
		return jResp;
	}
	
	public JSONObject unsecuredData(HttpServletRequest request) {
		JSONObject jResp = new JSONObject();
		String body = BWebUtils.requestBody(request);
		JSONObject jParams = new JSONObject(body);
		String viewKey = request.getParameter("view");
		BElement view = getView(viewKey);
		
		if(!view.getName().equals("FORM")) {
			jResp.put("ResultCode", 2);
			jResp.put("ResultDesc", "Wrong object");
			return jResp;
		}
		
		if(view.getAttribute("secured", "true").equals("false")) {
			String saveMsg = postData(view, request.getRemoteAddr(), jParams, null);
			if(saveMsg.equals("")) {
				jResp.put("ResultCode", 0);
				jResp.put("ResultDesc", "Okay");
			} else {
				jResp.put("ResultCode", 2);
				jResp.put("ResultDesc", saveMsg);
			}
		} else {
			jResp.put("ResultCode", 1);
			jResp.put("ResultDesc", "Security issue");
		}
			
		return jResp;
	}
	
	public JSONObject getUForm(HttpServletRequest request) {
		System.out.println("BASE 5010 : " + "Start form");
		JSONObject jResp = new JSONObject();
		String viewKey = request.getParameter("view");
		BElement view = getView(viewKey);
		
		if(!view.getName().equals("FORM")) {
			jResp.put("ResultCode", 2);
			jResp.put("ResultDesc", "Wrong object");
			return jResp;
		}
		
		if(view.getAttribute("secured", "true").equals("false")) {
			jResp = getForm(request, null);
		} else {
			jResp.put("ResultCode", 1);
			jResp.put("ResultDesc", "Security issue");
		}
			
		return jResp;
	}

	public JSONObject getForm(HttpServletRequest request, String userId) {
		JSONObject jResp = new JSONObject();
		JSONArray jTable = new JSONArray();
		
		String linkData = request.getParameter("linkdata");
		String viewKey = request.getParameter("view");
		BElement view = getView(viewKey);
		BUser user = null;
		if(userId != null) user = users.get(userId);
		
		if(!view.getName().equals("FORM")) return jResp;
				
		for(BElement el : view.getElements()) {
			int fieldType = BWebUtils.getFieldType(el.getName());
			JSONObject jField = new JSONObject();
			jField.put("type", fieldType);
			jField.put("name", el.getValue());
			jField.put("title", el.getAttribute("title"));
			
			if(el.getName().equals("COMBOBOX")) {
				String comboboxSQL = BWebUtils.comboboxSQL(el, user, db.getOrgID(), linkData);
System.out.println("BASE 3070 : " + comboboxSQL);

				BQuery cmbrs = new BQuery(db, comboboxSQL);
				jField.put("list", cmbrs.getJSON());
System.out.println("BASE 3080 : " + cmbrs.getJSON());
				
				cmbrs.close();
			} else if(el.getName().equals("COMBOLIST")) {
				JSONArray jComboList = new JSONArray();
				for(BElement ell : el.getElements()) {
					String mykey = ell.getAttribute("key", ell.getValue());
					
					JSONObject jItem = new JSONObject();
					jItem.put("id", mykey);
					jItem.put("value", ell.getValue());
					jComboList.put(jItem);
				}
				jField.put("list", jComboList);
			}
			
			jTable.put(jField);
		}
		
		jResp.put("form", jTable);
		
		return jResp;
	}

	public JSONObject securedData(HttpServletRequest request, String userId) {
		JSONObject jResp = new JSONObject();
		String body = BWebUtils.requestBody(request);
		if(body == null) body = "{}";
		
		String viewKey = request.getParameter("view");
		BElement view = getView(viewKey);
		BUser user = users.get(userId);

		if(!view.getName().equals("FORM")) return jResp;
		
		JSONObject jParams = new JSONObject(body);
		String saveMsg = postData(view, request.getRemoteAddr(), jParams, user);
		if(saveMsg.equals("")) {
			jResp.put("ResultCode", 0);
			jResp.put("ResultDesc", "Okay");
		} else {
			jResp.put("ResultCode", 2);
			jResp.put("ResultDesc", saveMsg);
		}
			
		return jResp;
	}

	public JSONObject readData(HttpServletRequest request, String userId) {
		JSONObject jResp = new JSONObject();

		String viewKey = request.getParameter("view");
		BElement view = getView(viewKey);
		BUser user = users.get(userId);
		
		if(view.getName().equals("FORM")) return jResp;
		
		String whereSql = request.getParameter("where");
		if(BWebUtils.checkInjection(whereSql)) whereSql = null;
System.out.println("BASE 3020 WHERE : " + whereSql);
		
		BQuery rs = new BQuery(db, view, whereSql, null, user, false);
		if(rs.moveNext()) {
			JSONArray jTable = new JSONArray(rs.getJSON());
			jResp.put("data", jTable);
		}
		rs.close();
		
		return jResp;
	}

	public JSONObject operation(HttpServletRequest request, String userId) {
		JSONObject jResp = new JSONObject();
		String body = BWebUtils.requestBody(request);
		if(body == null) body = "{}";
		
		String viewKey = request.getParameter("view");
		String operation = request.getParameter("operation");
System.out.println("BASE 3350 : " + operation);

		BElement view = getView(viewKey);
		BUser user = users.get(userId);
		
		if(!view.getName().equals("GRID")) return jResp;

		JSONArray jIds = new JSONArray(body);
		String saveMsg = setOperations(view, operation, request.getRemoteAddr(), jIds, user);
		
		jResp.put("ResultCode", 0);
		jResp.put("ResultMsg", saveMsg);
		
		return jResp;
	}
	
	public BElement getView(String viewKey) {
System.out.println("BASE 4040 : " + viewKey);
		
		List<BElement> views = new ArrayList<BElement>();
		List<String> viewKeys = new ArrayList<String>();
		String sv[] = viewKey.split(":");
		for(String svs : sv) viewKeys.add(svs);
		views.add(root.getElementByKey(sv[0]));
		
		for(int i = 1; i < sv.length; i++) {
			int subNo = Integer.valueOf(sv[i]);
			views.add(views.get(i-1).getSub(subNo));
		}
		BElement view = views.get(views.size() - 1);
		
System.out.println("BASE 4070 : " + view.toString());
		
		return view;
	}
	
	public String postData(BElement view, String remoteAddr, JSONObject jParams, BUser user) {
		String fWhere = view.getAttribute("keyfield") + " = null";
		BQuery rs = new BQuery(db, view, fWhere, null, user, true);
		
		List<String> viewData = new ArrayList<String>();
		Map<String, String[]> newParams = new HashMap<String, String[]>();
		for(String paramName : jParams.keySet()) {
			String[] pArray = new String[1];
			pArray[0] = jParams.getString(paramName);
			newParams.put(paramName, pArray);
		}

		rs.recAdd();
		String saveMsg = rs.updateFields(newParams, viewData, remoteAddr, null);
		rs.close();
		
		return saveMsg;
	}
	
	public String setOperations(BElement view, String operation, String remoteAddr, JSONArray jIds, BUser user) {
		Integer aPos = new Integer(operation);
		BElement el = view.getElementByName("ACTIONS").getElement(aPos);
		String saveMsg = null;
		
		if(el != null) {

			for(int i=0; i<jIds.length(); i++) {
				JSONObject jId = jIds.getJSONObject(i);
				String value = jId.getString("id");

				String auditSql = user.insAudit(el.getAttribute("fnct"), value, "FUNCTION");
				String autoKeyID = db.executeAutoKey(auditSql);

				String mySql = "SELECT " + el.getAttribute("fnct") + "('" + value + "', '" + user.getUserID();
				if(el.getAttribute("approval") != null) mySql += "', '" + el.getAttribute("approval");
				if(el.getAttribute("phase") != null) mySql += "', '" + el.getAttribute("phase");
				if(el.getAttribute("auditid") != null) mySql += "', '" + autoKeyID;
				mySql += "') ";

				if(el.getAttribute("from") != null) mySql += " " + el.getAttribute("from");
				log.info(mySql);
System.out.println("BASE 5050 : " + mySql);

				String exans = db.executeFunction(mySql);
				if(exans == null) saveMsg = db.getLastErrorMsg() + "; ";
				else saveMsg += exans + "; ";
			}
		}
		
		return saveMsg;
	}
	
}
