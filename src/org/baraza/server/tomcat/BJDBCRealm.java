/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2018.0329
 * @since       3.2
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.tomcat;

import java.util.logging.Logger;
import java.util.Map;
import java.util.HashMap;
import java.security.Principal;
import java.sql.Connection;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.SQLException;

import org.apache.catalina.realm.JDBCRealm;
import org.apache.catalina.connector.Request;
import org.apache.catalina.Context;
import org.apache.tomcat.util.descriptor.web.SecurityConstraint;

import org.baraza.utils.BLogHandle;

public class BJDBCRealm extends JDBCRealm {
	Logger log = Logger.getLogger(BJDBCRealm.class.getName());
	
	private Map<String, String> userList;
	private Map<String, String> IPList;
	
	public BJDBCRealm() {
		super();

		userList = new HashMap<String, String>();
		IPList = new HashMap<String, String>();
		log.info("Authenticating class starting");
	}
	
	public Principal authenticate(String username, String credentials) {
		Principal principal = super.authenticate(username, credentials);
		
		if(principal != null) {
			String loginId = logUser(principal.getName());
			userList.put(username, loginId);
			IPList.remove(username);
		}
		
		return principal;
	}
	
	public SecurityConstraint[] findSecurityConstraints(Request request, Context context) {
		SecurityConstraint[] sc = super.findSecurityConstraints(request, context);
		
		String userName = request.getRemoteUser();
		if((userName != null) && (IPList.get(userName) == null)) {
			String loginId = userList.get(userName);
			if(loginId != null) logUserIP(loginId, request.getRemoteAddr());
			IPList.put(userName, request.getRemoteAddr());
		}

		return sc;
	}
	
	public String logUser(String userName) {
		String loginId = null;
		try {
			String mysql = "SELECT add_sys_login('" + userName + "')";
			Connection db = open();
			Statement st = db.createStatement();
			ResultSet rs = st.executeQuery(mysql);
			db.commit();
			if(rs.next()) loginId = rs.getString(1);
			rs.close();
			st.close();
		} catch (SQLException ex) {
			log.severe("Database executeAutoKey error : " + ex);
		}
		return loginId;
	}
	
	public void logUserIP(String loginId, String userIP) {
		try {
			String mysql = "UPDATE sys_logins SET login_ip = '" + userIP
			+ "' WHERE sys_login_id = " + loginId;
			Connection db = open();
			Statement st = db.createStatement();
			st.execute(mysql);
			db.commit();
			st.close();
		} catch (SQLException ex) {
			log.severe("Database executeAutoKey error : " + ex);
		}
	}	
}

