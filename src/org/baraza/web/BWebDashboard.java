/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.web;

import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.naming.Context;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BElement;

public class BWebDashboard {
	BDB db;
	
	public BWebDashboard(BDB db) {
		this.db = db;
	}

	public String getTile(BElement el) {
		StringBuffer body = new StringBuffer();
		
		BQuery rs = new BQuery(db, el, null, null, false);
		boolean neof = rs.moveFirst();
				
		body.append("<div class='col-lg-3 col-md-3 col-sm-6 col-xs-12'>\n");
		body.append("	<div class='dashboard-stat2'>\n");
		for(BElement ell : el.getElements()) {
			String val = null;
			if(neof) val = rs.readField(ell.getValue());
			if(val == null) {
				if(ell.getAttribute("default") == null) val = "";
				else val = ell.getAttribute("default");
			}
			if(ell.getAttribute("type", "display").equals("display")) {
				String tileName = ell.getAttribute("title", "Name");
				if(el.getAttribute("jumpview") != null) {
					tileName = "<a href='?view=" + el.getAttribute("jumpview") + "'>";
					tileName += ell.getAttribute("title", "Name") + "</a>";
				} else if(el.getAttribute("url") != null) {
					tileName = "<a href='" + el.getAttribute("url") + "'>";
					tileName += ell.getAttribute("title", "Name") + "</a>";
				}
				
				body.append("		<div class='display'>\n");
				body.append("			<div class='number'>\n");
				body.append("				<h4 class='" + ell.getAttribute("color", "font-green-sharp") + "'>" + val + "</h4>\n");
				body.append("				<small>" + tileName + "</small>\n");
				body.append("			</div>\n");
				body.append("			<div class='icon'>\n");
				body.append("				<i class='" + ell.getAttribute("icon", "icon-pie-chart") + "'></i>\n");
				body.append("			</div>\n");
				body.append("		</div>\n");
			} else if(ell.getAttribute("type", "display").equals("progress")) {
				body.append("		<div class='progress-info'>\n");
				body.append("			<div class='progress'>\n");
				body.append("				<span style='width: " + val + "%;' class='progress-bar progress-bar-success green-sharp'>\n");
				body.append("				<span class='sr-only'>" + val + "% progress</span>\n");
				body.append("				</span>\n");
				body.append("			</div>\n");
				body.append("			<div class='status'>\n");
				body.append("				<div class='status-title'>progress</div>\n");
				body.append("				<div class='status-number'>" + val + "%</div>\n");
				body.append("			</div>\n");
				body.append("		</div>\n");
			}
		}
		body.append("	</div>\n");
		body.append("</div>\n");
		
		return body.toString();
	}
	
	public String getTileList(BElement el) {
		StringBuffer body = new StringBuffer();
		
		body.append("<div class='col-md-6 col-sm-12'>\n");
		body.append("	<!-- BEGIN PORTLET-->\n");
		body.append("	<div class='portlet light tasks-widget'>\n");
		
		if(el.getAttribute("title") != null) {
			body.append("		<div class='portlet-title'>\n");
			body.append("			<div class='caption caption-md'>\n");
			body.append("				<i class='icon-bar-chart theme-font-color hide'></i>\n");
			body.append("				<span class='caption-subject theme-font-color bold uppercase'>" + el.getAttribute("title") + "</span>\n");
			body.append("			</div>\n");
			body.append("		</div>\n");
		}
		
		body.append("		<div class='portlet-body'>\n");
		body.append("			<div class='table-scrollable'>\n");
		BQuery rs = new BQuery(db, el, null, null, false);
		body.append(rs.readDocument(true, false));
		body.append("			</div>\n");
		body.append("		</div>\n");

		body.append("	</div>\n");
		body.append("</div>\n");
		
		return body.toString();
	}
}