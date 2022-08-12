/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.web;

import org.apache.poi.poifs.filesystem.*;
import org.apache.poi.hssf.usermodel.*;

import java.util.logging.Logger;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.text.SimpleDateFormat;
import java.text.ParseException;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.File;
import java.io.InputStream;
import java.io.IOException;
import java.io.StringReader;
import java.io.PrintWriter;

import javax.json.Json;
import javax.json.JsonValue;
import javax.json.JsonArray;
import javax.json.JsonObject;
import javax.json.JsonObjectBuilder;
import javax.json.JsonArrayBuilder;
import javax.json.JsonReader;

import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.utils.BNumberFormat;
import org.baraza.utils.BCipher;

public class BWebForms {
	Logger log = Logger.getLogger(BWebForms.class.getName());
	Map<String, String[]> params;
	JsonObject answers;
	String entryFormId = null;
	String formid = "0";
	String fhead, ffoot, ftitle;
	boolean saveStatus = false;

	BDB db = null;
	String access_text = null;

	public BWebForms(String dbconfig) {
		db = new BDB(dbconfig);
		
		answers = Json.createObjectBuilder().build();
		params = new HashMap<String, String[]>();
	}

	public BWebForms(String dbconfig, String at) {
	    db = new BDB(dbconfig);
	    access_text = at;
	    
	    answers = Json.createObjectBuilder().build();
		params = new HashMap<String, String[]>();
	}
	
	public BWebForms(BDB db) {
		this.db = db;
		
		answers = Json.createObjectBuilder().build();
		params = new HashMap<String, String[]>();
	}

	public String getWebForm(Map<String, String[]> sParams) {
		String mystr = "";

		answers = Json.createObjectBuilder().build();
		params = new HashMap<String, String[]>(sParams);
		
		String entityId = null;
		String approveStatus = null;
		
		String action = getParameter("action");
		if((action == null) || (action.trim().equals("FORM"))) {
			formid = getParameter("actionvalue");
		} else {
			entryFormId = getParameter("actionvalue");
			Map<String, String> formRS = db.readFields("form_id, entity_id, approve_status, answer", "entry_forms WHERE entry_form_id = " + entryFormId);
			processAnswers(formRS.get("answer"));
			formid = formRS.get("form_id");
			entityId = formRS.get("entity_id");
			approveStatus = formRS.get("approve_status");
			
			if((entryFormId != null) && "Draft".equals(approveStatus)) saveStatus = true;
		}
		
		getFormType();

		mystr += fhead;
		mystr += printForm(null, "false");
		mystr += ffoot;

		return mystr;
	}
	
	public void getFormType() {
		fhead = "";
		ffoot = "";
		ftitle = "";

		String mysql = "SELECT form_header, form_footer, form_name, form_number ";
		mysql += "FROM forms WHERE form_id = " + formid;
		BQuery rs = new BQuery(db, mysql);
		if(rs.moveNext()) {
			fhead = rs.getString("form_header");
			ffoot = rs.getString("form_footer");
			ftitle = rs.getString("form_number") + " : " + rs.getString("form_name");
		}
		rs.close();

		if(fhead == null) fhead = "";
		else fhead = "<section>" + fhead + "</section>\n";

		if(ffoot == null) ffoot = "";
		else ffoot = "<section>" + ffoot + "</section>\n";
	}
	
	public String getFormTabs() {
		StringBuilder myhtml = new StringBuilder();
		
		String mysql = "SELECT * FROM fields WHERE (form_id = " + formid + ")";
		mysql += " AND (field_type = 'TAB') ";
		mysql += " ORDER BY field_order, field_id;";
		BQuery rs = new BQuery(db, mysql);
		
		int tabCount = 0;
		String tabs = "";
		while(rs.moveNext()) {
			String question = rs.getString("question");
			if(rs.getString("question") == null) question = "";

			if(tabCount == 0) tabs = "<li class='active'>";
			else tabs += "\n<li>";
			tabs += "<a href='#tab" + rs.getString("field_id") + "' data-toggle='tab'>" + question + " </a></li>\n";
			
			tabCount++;
		}
			
		if(tabCount > 0) {
			myhtml.append("<div class='row'>\n"
			+ "	<div class='col-md-12'>\n"
			+ "		<div class='tabbable portlet-tabs'>\n"
			+ "			<ul class='nav nav-tabs'>\n"
			+ tabs
			+ "			</ul>\n"
			+ "		</div>\n"
			+ "	</div>\n"
			+ "</div>\n"
			+ "<div class='tab-content'>\n");
		}
		
		
		return myhtml.toString();
	}
		
	//new printForm() method based on tables
	public String printForm(String disabled, String process) {
		StringBuilder myhtml = new StringBuilder();

		int fieldOrder = 0;
		int shareLine = 0;
		int sl = -1;
		int cnt_title = 0;
		int size = 0;
		int table_count = 0;

		String label = "";
		String input = "";
		String fieldType = "TEXTFIELD";
		String fieldclass = "";
		String question = "";
		String details = "";
		String label_position = "";

		if(disabled == null) disabled = "";
		else disabled = " disabled=\"true\" ";

		boolean isTabs = false;
		String tab = "";
		String tab_head = "";
		String tab_body = "";

		String mysql = "SELECT * FROM fields WHERE form_id = " + formid;
		mysql += " ORDER BY field_order, field_id;";
		BQuery rs = new BQuery(db, mysql);
		
		int elCount = 0;
		int fieldRows = 2;
		int fieldCount = 0;
		int tabCount = 0;
		String fieldId = "";
		while(rs.moveNext()) {
			fieldOrder = rs.getInt("field_order");
			fieldId = rs.getString("field_id");
			shareLine = rs.getInt("share_line");

			fieldType = "TEXTFIELD";
			if(rs.getString("field_type") != null) fieldType = rs.getString("field_type").trim().toUpperCase();
			
			question = rs.getString("question");
			if(rs.getString("question") == null) question = "";

			details = rs.getString("details");
			if(rs.getString("details") == null) details = "";

			fieldclass = "";
			if(rs.getString("field_class") != null) fieldclass = " class='" + rs.getString("field_class") + "' ";
			
			size = 10;
			if(rs.getString("field_size") != null) size = rs.getInt("field_size");

			if(rs.getBoolean("field_bold")) question = "<b>" + question + "</b>";
			if(rs.getBoolean("field_italics")) question = "<i>" + question + "</i>";

			label = "<label for='F" + rs.getString("field_id") +  "'> " + question + "</label>";
			
			// Start a new row
			if(fieldType.equals("TITLE") || fieldType.equals("TEXT") || fieldType.equals("SUBGRID") || fieldType.equals("TABLE")) {
				if((elCount == 0) && (tabCount == 0)) myhtml.append("<table class='table' width='95%' >\n");
				
				if((fieldCount != 0) && (fieldCount < fieldRows)) 
					myhtml.append("<td colspan='" + String.valueOf(fieldRows * 2 - fieldCount) + "'></td></tr>\n");
				myhtml.append("<tr>");
				fieldCount = 0;
			} else if(fieldType.equals("TAB")) {
				if(tabCount == 0) {
					myhtml.append("<div class='tab-pane active' id='tab" + fieldId + "'>\n");
				} else {
					myhtml.append("</table></div>");
					myhtml.append("<div class='tab-pane' id='tab" + fieldId + "'>\n");
				}
				myhtml.append("<table class='table' width='95%' >\n");
				tabCount++;
			} else {
				if((elCount == 0) && (tabCount == 0)) myhtml.append("<table class='table' width='95%' >\n");
				
				if((fieldCount % fieldRows) == 0) {
					myhtml.append("<tr>");
					fieldCount = 0;
				}
				if(!question.equals("")) myhtml.append("<td style='width:200px'>" + label + "</td>");
			}
			
			if(fieldType.equals("TEXTFIELD")) {
				input = "<td><input " + disabled + " type='text' "
				+ " style='width:" + size + "0px' "
				+ " name='F" + fieldId +  "'"
				+ " id ='F" + fieldId +  "'"
				+ getAnswer(fieldId)
				+ " placeholder='" + details +"'"
				+ " class='form-control' /></td>\n";
				fieldCount++;
			} else if(fieldType.equals("TEXTAREA")) {
				input = "<td><textarea " + disabled + " type='text' "
				+ " style='width:" + size + "0px' "
				+ " name='F" + fieldId +  "'"
				+ " id ='F" + fieldId +  "'"
				+ " placeholder='" + details +"'"
				+ " class='form-control' />" + getAnswer(fieldId, false) + "</textarea></td>\n";
				fieldCount++;
			} else if(fieldType.equals("DATE")) {
				input = "<td><div class='input-group input-medium date date-picker' data-date-format='dd-mm-yyyy' data-date-viewmode='years'>";
				input += "<input " + disabled + " type='text' "
				+ " style='width:" + size + "0px' "
				+ " name='F" + fieldId +  "'"
				+ " id ='F" + fieldId +  "'"
				+ getAnswer(fieldId)
				+ " class='form-control'/>";
				input += "<span class='input-group-btn'>"
				+ "<button class='btn default' type='button'><i class='fa fa-calendar'></i></button>"
				+ "</span>";
				input += "</div></td>\n";
				fieldCount++;
			} else if(fieldType.equals("TIME")) {
				input = "<td><div class='input-group input-medium'>\n";
				input += "<input " + disabled + " type='text' "
				+ " style='width:" + size + "0px' "
				+ " name='F" + fieldId +  "'"
				+ " id ='F" + fieldId +  "'"
				+ getAnswer(fieldId)
				+ " class='form-control'/>";
				input += "<span class='input-group-btn'>"
				+ "	<button class='btn default clockface-toggle' data-target='F" + fieldId + "' type='button'><i class='fa fa-clock-o'></i></button>"
				+ "</span>";
				input += "</div></td>\n";
				fieldCount++;
			} else if(fieldType.equals("LIST")) {
				input = "<td><select class='form-control' ";
				input += " style='width:" + size + "0px' ";
				input += " name='F" + fieldId +  "'";
				input += " id='F" + fieldId +  "'";
				input += ">\n";

				String lookups = rs.getString("field_lookup");
				String listVal = getAnswer(fieldId, false);
				if(listVal == null) listVal = "";
				else listVal = listVal.replace("\"", "").trim();

				if(lookups != null) {
					String[] lookup = lookups.split("#");
					for(String lps : lookup) {
						if(lps.compareToIgnoreCase(listVal)==0)
							input += "<option selected='selected'>" + lps + "</option>\n";
						else
							input += "<option>" + lps + "</option>\n";
					}
				}

				input += "</select></td>\n";
				fieldCount++;
			} else if(fieldType.equals("SELECT")) {
				input = "<td><select class='form-control' ";
				input += " name='F" + fieldId + "'";
				input += " id='F" + fieldId + "'";
				input += " style='width:" + size + "0px' ";
				input += ">\n";

				String lookups = rs.getString("field_lookup");
				String selectVal = getAnswer(fieldId, false);
				if(selectVal == null) selectVal = "";
				else selectVal = selectVal.replace("\"","").trim();
				String spanVal = "";

				if(lookups != null) {
					BQuery lprs = new BQuery(db, lookups);
					int cols = lprs.getColnum();

					while(lprs.moveNext()) {
						if(cols == 1){
							if(lprs.readField(1).trim().compareToIgnoreCase(selectVal)==0) {
								spanVal = lprs.readField(1);
								input += "<option value='" + lprs.readField(1) + "' selected='selected'>" + lprs.readField(1) + "</option>\n";
							} else {
								input += "<option value='" + lprs.readField(1) + "'>" + lprs.readField(1) + "</option>\n";
							}
						} else {
							if(lprs.readField(1).trim().compareToIgnoreCase(selectVal)==0) {
								spanVal = lprs.readField(2);
								input += "<option value='" + lprs.readField(1) + "' selected='selected'>" + lprs.readField(2) + "</option>\n";
							} else {
								input += "<option value='" + lprs.readField(1) + "'>" + lprs.readField(2) + "</option>\n";
							}
						}
					}
					lprs.close();
				}
				input += "</select></td>\n";
				fieldCount++;
			} else if(fieldType.equals("TITLE")) {
				cnt_title ++;
				input = "<td colspan='" + String.valueOf(fieldRows * 2) + "'>";
				input += "<div class='form_title'><b><strong>" + question + "</strong></b></div>";
				input += "</td>\n";
				fieldCount = 0;
			} else if(fieldType.equals("TEXT")) {
				cnt_title ++;
				input = "<td colspan='" + String.valueOf(fieldRows * 2) + "'>";
				input += "<div class='form_text'>" + question + "</div>";
				input += "</td>\n";
				fieldCount = 0;
			} else if(fieldType.equals("SUBGRID") || fieldType.equals("TABLE")) {
				input = "";
				myhtml.append("<td colspan='" + String.valueOf(fieldRows * 2) + "'>"
				+ "<div class='container'>"
				+ "	<div class='col-md-12 column'>"
				+ "		<div id='sub_table" + fieldId + "'></div>"
				+ "	</div>"
				//+ "	<a id='add_row" + fieldId + "' class='btn btn-default pull-left'>Add Row</a>"
				+"</div>"
				+ "</td>");
				
				table_count++;
				fieldCount = 0;
			} else if(fieldType.equals("TAB")) {
				input = "";
				fieldCount = 0;
			} else {
				System.out.println("TYPE NOT DEFINED : " + fieldType);
			}
			
			myhtml.append(input);
			
			// create a new line if the is no line sharing
			if(!fieldType.equals("TAB")) {
				if(shareLine == -1) {
					if((fieldCount != 0) && (fieldCount < fieldRows)) 
						myhtml.append("<td colspan='" + String.valueOf(fieldRows * 2 - fieldCount) + "'></td></tr>\n");
					fieldCount = 0;
				} else if((fieldCount % fieldRows) == 0) {
					myhtml.append("</tr>\n");
				}
			}
			
			elCount++;
		}
		
		if((fieldCount % fieldRows) != 0) myhtml.append("</tr>\n");
		
		if(tabCount == 0) {
			myhtml.append("</table>");
		} else {
			myhtml.append("</table>\n</div>\n</div>");
		}
				
		rs.close();

		return myhtml.toString();
	}
	
	public String printSubForm() {
		String myhtml = "";
		String tableList = null;
		
		String mysql = "SELECT * FROM fields WHERE (form_id = " + formid + ")";
		mysql += " AND ((field_type = 'SUBGRID') OR (field_type = 'TABLE')) ";
		mysql += " ORDER BY field_order, field_id;";
		BQuery rs = new BQuery(db, mysql);
		
		while(rs.moveNext()) {
			myhtml += "\n\n" + printSubTable(rs.getString("field_id"), rs.getString("field_size"));
			
			if(tableList == null) tableList = "var db_list = ['db" + rs.getString("field_id") + ".table'";
			else tableList += ", 'db" + rs.getString("field_id") + ".table'";
		}
		if(tableList == null) tableList = "var db_list = [";
		tableList += "];";
		
		myhtml += "\n\n" + tableList;
		rs.close();
		
		return myhtml;
	}
	
	public String printSubTable(String fieldId, String tableSize) {
		StringBuilder myhtml = new StringBuilder();
		
		String mysql = "SELECT sub_field_id, sub_field_type, sub_field_size, sub_field_lookup, question ";
		mysql += " FROM vw_sub_fields WHERE field_id = " + fieldId;
		mysql += " ORDER BY sub_field_order";
		BQuery rs = new BQuery(db, mysql);
		
		myhtml.append("var db" + fieldId + " = {\n"
		+ "loadData: function(filter) { return this.table;  },\n"
		+ "insertItem: function(insertingClient) { this.table.push(insertingClient); },\n"
		+ "updateItem: function(updatingClient) { },\n"
		+ "deleteItem: function(deletingClient) {\n"
		+ "var clientIndex = $.inArray(deletingClient, this.table);\n"
		+ "this.table.splice(clientIndex, 1);\n"
		+ "}\n};\n"
		+ "window.db" + fieldId + " = db" + fieldId + ";\n"
		+ "db" + fieldId + ".table = " + getSubAnswer(fieldId) + ";\n\n");
		
		JsonObjectBuilder jshd = Json.createObjectBuilder();
		jshd.add("width", tableSize + "%");
		jshd.add("height", "200px");
		jshd.add("inserting", true);
		jshd.add("editing", true);
		jshd.add("filtering", false);
		jshd.add("sorting", false);
		jshd.add("paging", false);
		
		jshd.add("data", "#db_table#");
		
		Map<String, String> jsTables = new HashMap<String, String>();
		JsonArrayBuilder jsColModel = Json.createArrayBuilder();
		while(rs.moveNext()) {
			JsonObjectBuilder jsColEl = Json.createObjectBuilder();
			String fld_name = "SF" + rs.getString("sub_field_id");
			String fld_title = rs.getString("question");
			String fld_size = rs.getString("sub_field_size");
			String fld_type = rs.getString("sub_field_type");
			if(fld_title == null) fld_title = "";
			if(fld_size == null) fld_size = "100";
			else fld_size = fld_size + "0";
		
			jsColEl.add("title", fld_title);
			jsColEl.add("name", fld_name);
			jsColEl.add("width", Integer.valueOf(fld_size));
			if(fld_type.equals("TEXTFIELD")) {
				jsColEl.add("type", "text");
			} else if(fld_type.equals("TEXTAREA")) {
				jsColEl.add("type", "textarea");
			} else if(fld_type.equals("DATEFIELD")) {
				jsColEl.add("type", "myDateField");
			} else if(fld_type.equals("LIST")) {
				String lookups = rs.getString("sub_field_lookup");
				if(lookups != null) {
					jsColEl.add("type", "select");
					jsColEl.add("items", "#db" + fieldId + ".sel_" + fld_name + "#");
					jsColEl.add("valueField", "Name");
					jsColEl.add("textField", "Name");
					jsColEl.add("align", "left");

					JsonObjectBuilder jsSelObj = Json.createObjectBuilder();
					JsonArrayBuilder jsSelModel = Json.createArrayBuilder();
					String[] lookup = lookups.split("#");
					for(String lps : lookup) {
						jsSelObj.add("Name", lps);
						jsSelModel.add(jsSelObj);
					}
					jsTables.put("db" + fieldId + ".sel_" + fld_name, jsSelModel.build().toString());
				}
			} else if(fld_type.equals("SELECT")) {
				String lookups = rs.getString("sub_field_lookup");
				if(lookups != null) {
					jsColEl.add("type", "select");
					jsColEl.add("items", "#db" + fieldId + ".sel_" + fld_name + "#");
					jsColEl.add("valueField", "Id");
					jsColEl.add("textField", "Name");
					jsColEl.add("align", "left");

					JsonObjectBuilder jsSelObj = Json.createObjectBuilder();
					JsonArrayBuilder jsSelModel = Json.createArrayBuilder();
					BQuery lprs = new BQuery(db, lookups);
					int cols = lprs.getColnum();
					while(lprs.moveNext()) {
						if(cols == 1){
							jsSelObj.add("Id", lprs.readField(1));
							jsSelObj.add("Name", lprs.readField(1));
							jsSelModel.add(jsSelObj);
						} else {
							jsSelObj.add("Id", lprs.readField(1));
							jsSelObj.add("Name", lprs.readField(2));
							jsSelModel.add(jsSelObj);
						}
					}
					lprs.close();
					
					jsTables.put("db" + fieldId + ".sel_" + fld_name, jsSelModel.build().toString());
				}
			}
			
			jsColModel.add(jsColEl);
		}
		JsonObjectBuilder jsColEl = Json.createObjectBuilder();
		jsColEl.add("width", 75);
		jsColEl.add("type", "control");
		jsColModel.add(jsColEl);
		jshd.add("fields", jsColModel);
		
		JsonObject jsObj = jshd.build();
		String tableDef = jsObj.toString().replaceAll("\"#db_table#\"", "db" + fieldId + ".table");	
		for(String jsTable : jsTables.keySet()) {
			tableDef = tableDef.replace("\"#" + jsTable + "#\"", jsTable);
			myhtml.append(jsTable + "=" + jsTables.get(jsTable) + ";\n");
		}
		myhtml.append("$('#sub_table" + fieldId + "').jsGrid(" + tableDef + "\n);\n"); 
		
		rs.close();
		return myhtml.toString();
	}
		
	public String updateForm(String entryFormId, String jsonData) {
		this.entryFormId = entryFormId;
		String resp = "";
System.out.println("Start saving the form " + jsonData);

		String updSql = "SELECT entry_form_id, form_id, answer FROM entry_forms WHERE entry_form_id = " + entryFormId;
		BQuery rs = new BQuery(db, updSql);
		
		if(rs.moveNext()) {
			rs.recEdit();
			rs.updateRecField("answer", jsonData);
			rs.recSave();
			resp = "{\"success\": 1, \"message\": \"Form data updated\"}";
		} else {
			resp = "{\"success\": 0, \"message\": \"Unable to update form data\"}";
		}
		
		rs.close();
		
		return resp;
	}

	public String submitForm(String entryFormId, String jsonData) {
		this.entryFormId = entryFormId;
		String resp = "";
System.out.println("Start saving the form " + entryFormId);

		String updSql = "SELECT entry_form_id, form_id, answer, approve_status "
		+ "FROM entry_forms "
		+ "WHERE entry_form_id = " + entryFormId;
		BQuery rs = new BQuery(db, updSql);
		
		if(rs.moveNext()) {
			rs.recEdit();
			rs.updateRecField("answer", jsonData);
			rs.recSave();
			
			resp = submitValidate(rs.getString("form_id"), entryFormId, jsonData);
			
			resp = "{\"success\": 1, \"message\": \"" + resp + "\"}";
		} else {
			resp = "{\"success\": 0, \"message\": \"" + resp + "\"}";
		}
		
		rs.close();
		
		return resp;
	}

	public String submitValidate(String formId, String entryFormId, String jsonData) {
		String resp = "";
		String mysql = "SELECT * FROM fields "
		+ " WHERE (form_id = " + formId + ") AND (manditory = '1') ";
		mysql += "ORDER BY field_order, field_id;";
		BQuery rs = new BQuery(db, mysql);
		
		// Process the answers
		processAnswers(jsonData);

		String ans = "";
		boolean verified = true;
		while(rs.moveNext()) {
			String fieldType = "TEXTFIELD";
			if(rs.getString("field_type") != null) fieldType = rs.getString("field_type");

			String question = rs.getString("question");
			if(rs.getString("question") == null) question = "";

			if(fieldType.equals("TEXTFIELD") || fieldType.equals("DATE") || fieldType.equals("TIME") || fieldType.equals("TEXTAREA") || fieldType.equals("LIST") || fieldType.equals("SELECT")) {
				ans = getAnswer(rs.getString("field_id"));
				if(ans.trim().equals("")) {
					verified = false;
					resp += "<div style='color:#FF0000; font-weight:bold;'>* You need to answer : " + question + "</div><br/>";
				}
			}
		}
		rs.close();
		
		if(verified) {
			if(saveTable(formId, entryFormId) != null) verified = false;
		}
		
		if(verified) {
			mysql = "UPDATE entry_forms SET approve_status = 'Completed', completion_date = now() "
			+ "WHERE (entry_form_id = " + entryFormId + ")";
			db.executeQuery(mysql);
			resp += "<b>The form has been submitted successfully</b><br/>";	
		} else {
			resp += "<b>You need to ensure you have made the selection properly</b><br/>";
		}

		return resp;
	}
	
	public String saveTable(String formid, String entryformid) {
		String dbErr = null;
		String mysql = "SELECT table_name FROM forms WHERE form_id = " + formid;
		String tableName = db.executeFunction(mysql);

		if(tableName != null) {
			mysql = "SELECT field_name, field_id, field_fnct FROM fields WHERE form_id = " + formid;
			mysql += " ORDER BY field_order, field_id;";
			BQuery rs = new BQuery(db, mysql);

			mysql = "INSERT INTO " + tableName + " (entry_form_id";
			String values = ") VALUES (" + entryformid;
			while(rs.moveNext()) {
				String fieldName = rs.getString("field_name");
				if(fieldName != null) {
					String fieldFnct = rs.getString("field_fnct");
					String ans = getAnswer(rs.getString("field_id"), false);
					String ansa = "'" + ans + "'";
					if(ans == null) { ansa = "null"; ans = ""; }

					if((fieldFnct != null) && (ans != null))
						ansa = fieldFnct.replace("#", ans);

					if(!ans.equals("")) {
						mysql += ", " + fieldName;
						values += ", " + ansa;
					}
					
					System.out.println("BASE 1010 : " + fieldName + " : " + ansa);
				}
			}
			mysql +=   values + ")";
			dbErr = db.executeQuery(mysql);
			
			rs.close();

			System.out.println("\n\nBASE 1020 : " + mysql);
		}

		return dbErr;
	}


	public String getParameter(String paramName) {
		String paramValue = null;
		if(params.get(paramName) != null) paramValue = params.get(paramName)[0];
		return paramValue;
	}
	
	public void processAnswers(String answer) {
		if(answer == null) return;
		
		JsonReader jr = Json.createReader(new StringReader(answer));
		answers = jr.readObject();
		jr.close();
	}
	
	public String getAnswer(String fieldid) {
		return getAnswer(fieldid, true);
	}

	public String getAnswer(String fieldid, boolean addValue) {
		String aId = "F" + fieldid;
		if(!answers.containsKey(aId)) return "";
		if(answers.get(aId) instanceof JsonObject || answers.get(aId) instanceof JsonArray) return "";
		
		String answer = answers.getString(aId);
		if(answer == null) {
			answer = "";
		} else if(answer.trim().equals("")) {
			answer = "";
		} else if(addValue) {
			answer = answer.replaceAll("&", "&amp;").replaceAll("\"", "&quot;");
			answer = " value=\"" + answer + "\"";
		}

		return answer;
	}
	
	public String getSubAnswer(String fieldid) {
		String aId = "db" + fieldid + ".table";
		if(!answers.containsKey(aId)) return "[ ]";
		if(!(answers.get(aId) instanceof JsonArray)) return "[ ]";
		
		String answer = answers.getJsonArray(aId).toString();

		return answer;
	}
	
	public String getTitle() { return ftitle; }
	public String getEntryFormId() { return entryFormId; }
	public boolean canSave() { return saveStatus; }
	
	public void close() {
		if(db != null) db.close();
	}

}
