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
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;

import javax.json.Json;
import javax.json.JsonValue;
import javax.json.JsonArray;
import javax.json.JsonObject;
import javax.json.JsonObjectBuilder;
import javax.json.JsonArrayBuilder;
import javax.json.JsonReader;

import javax.servlet.http.HttpServletRequest;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.DB.BWebBody;
import org.baraza.xml.BElement;

public class BAccordion {
	BDB db;
	BElement view;
	String accordionJs = "";

	public BAccordion(BDB db, BElement view) {
		this.db = db;
		this.view = view;
	} 

	public String getAccordion(HttpServletRequest request, String linkData, String formLinkData, List<String> viewData) {
		String body = "\t<div class='panel-group accordion' id='accordion1'>\n";
		int vds = viewData.size();
		
		accordionJs = "";
		Integer ac = new Integer("0");
		for(BElement vw : view.getElements()) {
			body += "\t\t<div class='panel panel-default'>\n"
			+ "\t\t\t<div class='panel-heading'>\n"
			+ "\t\t\t\t<h4 class='panel-title'>\n"
			+ "\t\t\t\t\t<a class='accordion-toggle' data-toggle='collapse' data-parent='#accordion1' "
			+ "href='#collapse_" + ac.toString() + "'>" + vw.getAttribute("name") + "</a>\n"
			+ "\t\t\t\t</h4>\n"
			+ "\t\t\t</div>\n"
			+ "\t\t\t<div id='collapse_" + ac.toString() + "' class='panel-collapse " 
			+ vw.getAttribute("collapse", "collapse") + "'>\n"
			+ "\t\t\t\t<div class='panel-body'>\n";
			
			String whereSql = null;
			if(vw.getName().equals("FORM")) {
				if((linkData != null) && (vds > 2)) {
					if("[new]".equals(linkData)) whereSql = vw.getAttribute("keyfield") + " = null";
					else whereSql = vw.getAttribute("keyfield") + " = '" + linkData + "'";
				}
				
				BWebBody webbody = new BWebBody(db, vw, whereSql, null);
				body += webbody.getForm(false, formLinkData, request);
				webbody.close();
			} else if(vw.getName().equals("GRID") && !"[new]".equals(linkData)) {
				if(linkData != null && vw.getAttribute("linkfield") != null) 
					whereSql = vw.getAttribute("linkfield") + " = '" + linkData + "'";
				
				body += "<div class='row'>"
				+ "	<div class='col-md-12 column'>"
				+ "		<div id='sub_table" + ac.toString() + "'></div>"
				+ "	</div>"
				+ "</div>\n";
				
				accordionJs += getGrid(vw, whereSql, ac);
			}
			body += "\t\t\t\t</div>\n";
			body += "\t\t\t</div>\n";
			body += "\t\t</div>\n";
			ac++;
		}
		body += "\t</div>\n";
		
		return body;
	}
	
	public String getGrid(BElement vw, String whereSql, Integer ac) {
		StringBuilder myhtml = new StringBuilder();
		
		String fieldId = ac.toString();
		BQuery rs = new BQuery(db, vw, whereSql, null);
		
		// JSON data set
		myhtml.append("var db_" + fieldId + "_table = " + rs.getJSON() + ";\n\n");
		
		JsonObjectBuilder jshd = Json.createObjectBuilder();
		jshd.add("width", "100%");		// tableSize
		jshd.add("height", vw.getAttribute("th", "200") + "px");
		if(vw.getAttribute("new", "true").equals("true")) jshd.add("inserting", true);
		if(vw.getAttribute("edit", "true").equals("true")) jshd.add("editing", true);
		jshd.add("filtering", false);
		jshd.add("sorting", false);
		jshd.add("paging", false);
		
		jshd.add("data", "~~db_" + fieldId + "_table~~");
		
		JsonObjectBuilder jscnt = Json.createObjectBuilder();
		if(vw.getAttribute("new", "true").equals("true")) {
			jscnt.add("insertItem", "~~function(item) { return $.ajax({type:'GET', url:'ajax?fnct=jsinsert&viewno=" 
			+ fieldId + "', data: item}); }~~");
		}
		if(vw.getAttribute("edit", "true").equals("true")) {
			jscnt.add("updateItem", "~~function(item) { return $.ajax({type:'GET', url:'ajax?fnct=jsupdate&viewno=" 
			+ fieldId + "', data: item}); }~~");
		}
		if(vw.getAttribute("del", "true").equals("true")) {
			jscnt.add("deleteItem", "~~function(item) { return $.ajax({type:'GET', url:'ajax?fnct=jsdelete&viewno=" 
			+ fieldId + "', data: item}); }~~");
		}
		jshd.add("controller", jscnt);
		
		Map<String, String> jsTables = new HashMap<String, String>();
		JsonArrayBuilder jsColModel = Json.createArrayBuilder();
		for(BElement el : vw.getElements()) {
			JsonObjectBuilder jsColEl = Json.createObjectBuilder();
			String fld_name = el.getValue();
			String fld_title = el.getAttribute("title", "");
			String fld_size = el.getAttribute("w", "100");
			String fld_type = el.getName();
		
			jsColEl.add("title", fld_title);
			jsColEl.add("name", fld_name);
			jsColEl.add("width", Integer.valueOf(fld_size));
			if(el.getAttribute("required") != null) jsColEl.add("required", true);
			if(el.getAttribute("readonly") != null) jsColEl.add("editing", false);
			
			if(el.getAttribute("default") != null) {
				String defaultStr = "~~function() {var input = this.__proto__.insertTemplate.call(this); "
				+ "input.val('" + el.getAttribute("default") + "'); return input; }~~";
				jsColEl.add("insertTemplate", defaultStr);
			}
			
			if(fld_type.equals("TEXTFIELD")) {
				jsColEl.add("type", "text");
				jsColModel.add(jsColEl);
			} else if(fld_type.equals("TEXTNUMBER")) {
				jsColEl.add("type", "number");
				jsColModel.add(jsColEl);
			} else if(fld_type.equals("TEXTDECIMAL")) {
				jsColEl.add("type", "text");
				jsColModel.add(jsColEl);
			} else if(fld_type.equals("TEXTDATE")) {
				jsColEl.add("type", "date");
				jsColEl.add("myCustomProperty", "datecp");
				jsColModel.add(jsColEl);
			} else if(fld_type.equals("SPINTIME")) {
				jsColEl.add("type", "time");
				jsColEl.add("myCustomProperty", "timecp");
				jsColModel.add(jsColEl);
			} else if(fld_type.equals("TEXTAREA")) {
				jsColEl.add("type", "textarea");
				jsColModel.add(jsColEl);
			} else if(fld_type.equals("CHECKBOX")) {
				jsColEl.add("type", "checkbox");
				jsColModel.add(jsColEl);
			} else if(fld_type.equals("FUNCTION")) {
				jsColEl.add("type", "text");
				jsColEl.add("inserting", false);
				jsColEl.add("editing", false);
				jsColModel.add(jsColEl);
			} else if(fld_type.equals("COMBOBOX")) {
				jsColEl.add("type", "select");
				jsColEl.add("items", "~~db_" + el.getAttribute("lptable") + "_table~~");
				jsColEl.add("valueField", "id");
				jsColEl.add("textField", "name");
				jsColEl.add("align", "left");
				
				String whereCmbSql = el.getAttribute("where");
				String whereOrgSql = db.getSqlOrgWhere(el.getAttribute("noorg"));
				String whereUserSql = db.getSqlUserWhere(el.getAttribute("user"));
				if(whereCmbSql != null) whereCmbSql = " WHERE " + whereCmbSql;
				if(whereOrgSql != null && whereUserSql != null) whereOrgSql = whereOrgSql + " AND " + whereUserSql;
				if(whereOrgSql != null) {
					if(whereCmbSql == null) whereCmbSql = " WHERE " + whereOrgSql;
					else whereCmbSql = whereCmbSql + " AND " + whereOrgSql;
				}
				
				String sql = "SELECT " + el.getAttribute("lpkey", el.getValue()) + " as Id, ";
				if(el.getAttribute("cmb_fnct") == null) sql += el.getAttribute("lpfield") + " as Name ";
				else sql += el.getAttribute("cmb_fnct") + " as Name ";
				sql += "FROM " + el.getAttribute("lptable");
				if(whereCmbSql != null) sql += whereCmbSql;
				sql += " ORDER BY " + el.getAttribute("orderby", el.getAttribute("lpfield"));
				BQuery rsc = new BQuery(db, sql);
				myhtml.append("var db_" + el.getAttribute("lptable") + "_table = " + rsc.getJSON() + ";\n\n");
				rsc.close();
				
				jsColModel.add(jsColEl);
			}
		}
		
		JsonObjectBuilder jsColElKf = Json.createObjectBuilder();
		jsColElKf.add("name", "keyfield");
		jsColElKf.add("width", 0);
		jsColElKf.add("visible", false);
		jsColElKf.add("type", "text");
		jsColModel.add(jsColElKf);
		
		if(vw.getAttribute("edit", "true").equals("true")) {
			JsonObjectBuilder jsColEl = Json.createObjectBuilder();
			jsColEl.add("width", 50);
			jsColEl.add("type", "control");
			
			if(vw.getAttribute("del", "true").equals("false")) {
				jsColEl.add("deleteButton", false);
			}
			jsColModel.add(jsColEl);
		}
		
		// Add the the fields on the JSON structure
		jshd.add("fields", jsColModel);
		
		JsonObject jsObj = jshd.build();
		String tableDef = jsObj.toString().replaceAll("\"~~", "").replaceAll("~~\"", "");
		for(String jsTable : jsTables.keySet()) {
			tableDef = tableDef.replace("\"#" + jsTable + "#\"", jsTable);
			myhtml.append(jsTable + "=" + jsTables.get(jsTable) + ";\n");
		}
		myhtml.append("$('#sub_table" + fieldId + "').jsGrid(" + tableDef + "\n);\n"); 
		
		rs.close();
		
//System.out.println("BASE 2050 : " + myhtml.toString());

		return myhtml.toString();
	}

	public String getAccordionJs() { return accordionJs; }
}
