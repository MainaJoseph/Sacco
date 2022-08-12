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

public class BDataServer extends HttpServlet {
	Logger log = Logger.getLogger(BDataServer.class.getName());

	BElement root = null;
	BDB db = null;
	BDataOps dataOps = null;
	
	public void init(ServletConfig config) throws ServletException {
		super.init(config);
		
		ServletContext context = config.getServletContext();
		String xmlfile = config.getInitParameter("xmlfile");
		String ps = System.getProperty("file.separator");
		xmlfile = context.getRealPath("WEB-INF") + ps + "configs" + ps + xmlfile;
		BXML xml = new BXML(xmlfile, false);
		
		if(xml.getDocument() != null) {
			root = xml.getRoot();
		
			String dbconfig = "java:/comp/env/jdbc/database";
			db = new BDB(dbconfig);
			db.setOrgID(root.getAttribute("org"));
			
			dataOps = new BDataOps(root, db);
		}
	}
	
	public void doPost(HttpServletRequest request, HttpServletResponse response)  {
		doGet(request, response);
	}

	public void doGet(HttpServletRequest request, HttpServletResponse response) {
		String resp = "";

		log.info("Start Data Server");
		
		BWebUtils.showHeaders(request);
		BWebUtils.showParameters(request);
		
		String action = request.getHeader("action");
		if(action == null) return;
System.out.println("BASE 2010 : " + action);
		
		JSONObject jResp = new JSONObject();
		if(action.equals("authorization")) {
			jResp = dataOps.authenticate(request);
		} else if(action.equals("udata")) {
			jResp = dataOps.unsecuredData(request);
		} else if(action.equals("uform")) {
			jResp = dataOps.getUForm(request);
		} else {
			jResp = dataOps.reAuthenticate(request.getHeader("authorization"));
			// Ensure the secure operations happen after re-authentication
			if(jResp.has("ResultCode") && (jResp.getInt("ResultCode") == 0)) {
				String userId = jResp.getString("userId");
				
System.out.println("BASE userId : " + userId);

				if(action.equals("form")) {
					jResp = dataOps.getForm(request, userId);
				} else if(action.equals("data")) {
					jResp = dataOps.securedData(request, userId);
				} else if(action.equals("read")) {
					jResp = dataOps.readData(request, userId);
				} else if(action.equals("operation")) {
					jResp = dataOps.operation(request, userId);
				}
			}
		}

		// Send feedback
		resp = jResp.toString();
System.out.println("BASE jRETURN : " + resp);

		response.setContentType("application/json;charset=\"utf-8\"");
		PrintWriter out = null;
		try { out = response.getWriter(); } catch(IOException ex) {}
		out.println(resp);

		log.info("End Data Server");
	}
	
	public void destroy() {
		db.close();
	}

}
