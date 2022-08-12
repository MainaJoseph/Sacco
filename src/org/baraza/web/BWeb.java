/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.web;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.util.Iterator;
import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;

import java.util.logging.Logger;
import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Map;
import java.util.HashMap;
import java.util.Enumeration;
import java.util.Date;
import java.text.SimpleDateFormat;
import java.text.ParseException;
import java.sql.Connection;

import javax.json.Json;
import javax.json.JsonObject;
import javax.json.JsonObjectBuilder;
import javax.json.JsonArrayBuilder;

import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;

import org.baraza.utils.Bio;
import org.baraza.utils.BDateFormat;
import org.baraza.utils.BWebdav;
import org.baraza.utils.BWebUtils;
import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.DB.BWebBody;
import org.baraza.DB.BUser;
import org.baraza.DB.BCrossTab;
import org.baraza.reports.BWebReport;
import org.baraza.xml.BXML;
import org.baraza.xml.BElement;

public class BWeb {
	Logger log = Logger.getLogger(BWeb.class.getName());
	BDB db = null;
	BElement root = null;
	BElement view = null;
	HttpSession webSession = null;

	List<BElement> views;
	List<String> viewKeys;
	List<String> viewData;
	Map<String, String> params;
	Map<String, String> dashboardItems;

	boolean selectAll = false;
	boolean isLicense = true;
	boolean isExpired = false;
	String[] deskTypes = {"ACCORDION", "CROSSTAB", "DASHBOARD", "DIARY",  "FILES", "FILTER", "FORM", "FORMVIEW", "GRID", "JASPER", "TABLEVIEW"};	// The search data  has to be ordered alphabetically
	String viewKey = null;
	String dataItem = null;
	String userID = null;
	String wheresql = null;
	String sortby = null;
	String mainPage = "index.jsp";
	String comboField = null;
	String saveMsg = "";
	String accordionJs = "";
	String pictureURL = "";
	String pictureField = "";

	public BWeb(String dbconfig, String xmlfile) {
		if(xmlfile == null) return;				// File error check
		Bio io = new Bio();
		if(!io.FileExists(xmlfile)) return;	// File error check

		BXML xml = new BXML(xmlfile, false);

		if(xml.getDocument() == null) {
			log.severe("XML loading file error");
		} else {
			root = xml.getRoot();
			if(root.getAttribute("dbclass") != null) db = new BDB(root);
			else if(root.getAttribute("dbconfig") != null) db = new BDB(root.getAttribute("dbconfig"));
			else db = new BDB(dbconfig);
			
			if(root.getAttribute("readonly", "false").equals("true")) db.setReadOnly(true);
			
			BElement configs = root.getElementByName("CONFIGS");
			if(configs != null) {
				BElement audit = configs.getElementByName("AUDIT");
				if(audit != null) db.setFullAudit(audit);
			}
			
			db.setOrgID(root.getAttribute("org"));
		}

		if(db.getDB() == null) log.severe("Login error");
	}

	public void init(HttpServletRequest request) {
		if((root == null) || (db == null)) return;	// error check
		
		// login the user
		setUser(request.getRemoteAddr(), request.getRemoteUser());
		
		views = new ArrayList<BElement>();
		viewKeys = new ArrayList<String>();
		viewData = new ArrayList<String>();
		params = new HashMap<String, String>();
		dashboardItems = new HashMap<String, String>();

		webSession = request.getSession(true);
		viewKey = request.getParameter("view");

		if(webSession.getAttribute("loadviewkey") != null) {
			viewKey = (String)webSession.getAttribute("loadviewkey");
			webSession.removeAttribute("loadviewkey");
		}

		if((viewKey == null) && (webSession.getAttribute("viewkey") != null))
			viewKey = (String)webSession.getAttribute("viewkey");
		if(viewKey == null) viewKey = db.getStartView();
		if(viewKey == null) viewKey = "1:0";

		webSession.setAttribute("viewkey", viewKey);
		
		dataItem = request.getParameter("data");
		if(BWebUtils.checkInjection(dataItem)) dataItem = "";
		
		if(webSession.getAttribute("loaddata") != null) {
			dataItem = (String)webSession.getAttribute("loaddata");
			webSession.removeAttribute("loaddata");
		}
		if(dataItem != null) webSession.setAttribute("d" + viewKey, dataItem);
		else if(webSession.getAttribute("d" + viewKey) != null) 
			dataItem = (String)webSession.getAttribute("d" + viewKey);

		if(root.getElementByKey(viewKey.split(":")[0]) == null) viewKey = "1:0";			// Check for blank views
		String sv[] = viewKey.split(":");
		for(String svs : sv) viewKeys.add(svs);
		views.add(root.getElementByKey(sv[0]));
		viewData.add("");

		if(views.get(0).getAttribute("access", "role").equals("role")) {
			if(checkRole(sv[0]) == 2) {		// Check is you have assess to the node
				viewKey = db.getStartView();
				setView(request, viewKey);
				return;
			}
		}

		String dk = viewKeys.get(0) + ":";
		for(int i = 1; i < sv.length; i++) {
			dk += viewKeys.get(i);
			String sItems = (String)webSession.getAttribute("d" + dk);
			if(sItems == null) sItems = "";
			
			int subNo = Integer.valueOf(sv[i]);
			views.add(views.get(i-1).getSub(subNo));

			viewData.add(sItems);
			dk += ":";
		}
		view = views.get(views.size() - 1);
		
		// Setting the main page from session
		if(webSession.getAttribute("mainpage") != null) {
			mainPage = (String)webSession.getAttribute("mainpage");
		} else {
			webSession.setAttribute("mainpage", "index.jsp");
		}
		
		// Check if the version has expiery constraints
		if(root.getAttribute("billing", "false").equals("true")) {
			String expStr = "SELECT org_id FROM orgs WHERE ((expiry_date is null) or (expiry_date >= current_date)) AND (org_id = " + db.getUserID() + ")";
			if(db.executeFunction(expStr) == null) isExpired = true;
		}

		// Get the parameters used in Views
		getParams();
	}

	public void setView(HttpServletRequest request, String newview) {
		views = new ArrayList<BElement>();
		viewKeys = new ArrayList<String>();
		viewData = new ArrayList<String>();
		dashboardItems = new HashMap<String, String>();

		webSession = request.getSession(true);
		viewKey = newview;
		webSession.setAttribute("viewkey", viewKey);
		
		dataItem = request.getParameter("data");
		if(BWebUtils.checkInjection(dataItem)) dataItem = "";
		if(dataItem != null) webSession.setAttribute("d" + viewKey, dataItem);
		else if(webSession.getAttribute("d" + viewKey) != null) 
			dataItem = (String)webSession.getAttribute("d" + viewKey);

		String sv[] = viewKey.split(":");
		for(String svs : sv) viewKeys.add(svs);

		views.add(root.getElementByKey(viewKeys.get(0)));
		viewData.add("");

		String dk = viewKeys.get(0) + ":";
		for(int i = 1; i < sv.length; i++) {
			dk += viewKeys.get(i);
			String sItems = (String)webSession.getAttribute("d" + dk);
			if(sItems == null) sItems = "";
			
			int subNo = Integer.valueOf(sv[i]);
			views.add(views.get(i-1).getSub(subNo));

			viewData.add(sItems);
			dk += ":";
		}
		view = views.get(views.size() - 1);

		// Get the parameters used in Views
		getParams();
	}
	
	public int checkRole(String deskKey) {
		if((root == null) || (db == null)) return 0;	// error check
		if(db.getUser() == null) return 1;

		int toShow = 0;
		
		if(db.getUser().getSuperUser()) {
			toShow = 1;
		} else {
			BElement mel = root.getFirst();
			toShow = checkRole(mel, deskKey);
		}
	
		return toShow;
	}
	
	public int checkRole(BElement mel, String deskKey) {
		int toShow = 0;

		//System.out.println("BASE 2010 : " + mel.getAttribute("name"));

		for(BElement smel: mel.getElements()) {
						
			if(toShow == 0) {
				if(smel.isLeaf()) {
					if(deskKey.equals(smel.getValue())) {						
						boolean hasAccess  = checkAccess(smel.getAttribute("role"));
						if(hasAccess) return 1;
						else return 2;
					}
				} else {
					toShow = checkRole(smel, deskKey);
					if(toShow != 0) {
						boolean hasAccess  = checkAccess(smel.getAttribute("role"));
						if(hasAccess) return toShow;
						else return 2;
					}
				}
			}
		}
		
		return toShow;
	}

	public void setUser(String userIP, String userName) {
		if(db != null) {
			if(userName == null) userName = "root";
			db.setUser(userIP, userName);
			userID = db.getUserID();
			String authTable = root.getAttribute("auth.table");
			if(authTable != null) {
				String authId = root.getAttribute("auth.id");
				String authName = root.getAttribute("auth.name");
				db.setUser(authTable, authId, authName, userName);
				userID = db.getUserID();
			}
		}
	}
	
	public void newUser(String userIP, String userName) {
		if(db != null) {
			if(userName == null) userName = "root";
			db.newUser(userIP, userName);
			userID = db.getUserID();
		}
	}

	public void setMainPage(String mainPage) {
		this.mainPage = mainPage;
		webSession.setAttribute("mainpage", mainPage);
	}

	public String getMenu() {
		if((root == null) || (db == null)) return "";	// error check
		
		BElement mel = root.getFirst();

		String mymenu = "	<ul class='page-sidebar-menu ' data-keep-expanded='false' data-auto-scroll='true' data-slide-speed='200'>\n";
		
		if(root.getAttribute("dashboard", "true").equals("true")) {
			mymenu += "		<li class='start'>\n";
			mymenu += "			<a href='" + mainPage + "?view=1:0'>\n";
			mymenu += "			<i class='icon-home'></i>\n";
			mymenu += "			<span class='title'>Dashboard</span>\n";
			mymenu += "			</a>\n";
			mymenu += "		</li>\n";
		}
		
		mymenu += getSubMenu(mel, 0);
		mymenu += "	</ul>\n";

		return mymenu;
	}

	public String getSubMenu(BElement mel, int level) {
		String submenu = "";
		boolean toShow = true;
		
		for(BElement smel: mel.getElements()) {
			toShow = checkAccess(smel.getAttribute("role"));

			String bodypage = smel.getAttribute("page", mainPage);
			String blankpage = smel.getAttribute("blankpage", "");
			if(blankpage.equals("true")) blankpage = " target=\"_blank\" ";

			if(toShow) {
				if(smel.isLeaf()) {
                    String icon = smel.getAttribute("icon", "fa fa-arrow-right");
					String link = "";
					if(smel.getAttribute("xml") != null) {
						link = "<a href=\"" + bodypage + "?xml=" + smel.getAttribute("xml") + "&view=1:0\"" + blankpage + ">";
						link += " <i class='" + icon + "'></i> ";
					} else if(smel.getAttribute("url") != null) {
						link = "<a href=\"" + smel.getAttribute("url") + "\"" + blankpage + ">"; 
						link += " <i class='" + icon + "'></i> ";
					} else {
						link = "<a href=\"" + bodypage + "?view=" + smel.getValue() + ":0\"" + blankpage + ">"; 
						link += " <i class='" + icon + "'></i> ";
					}
					
					if(level == 0) link += "<span class='title'>" + smel.getAttribute("name") + "</span></a>";
					else link += "<span>" + smel.getAttribute("name") + "</span></a>";
					
					if(viewKeys.get(0).equals(smel.getValue())) submenu += "\t\t<li class='active'>\n";
					else submenu += "\t\t<li>\n";
					
					submenu += "\t\t\t" + link + "\n";
					submenu += "\t\t</li>\n";
				} else {
				
					if(locateMenu(smel, viewKeys.get(0))) submenu += "\t<li class='active open'>\n";
					else submenu += "\t<li>\n";
					
					submenu += "\t\t<a href='javascript:;'>";
					submenu += "<i class='" + smel.getAttribute("icon", "icon-list") + "'></i>";
					submenu += "<span class='title'>" + smel.getAttribute("name") + "</span>";
					submenu += "<span class='arrow'></span>";
					submenu += "</a>\n";
					submenu += "\t\t<ul class='sub-menu'>\n" + getSubMenu(smel, level+1) + "</ul>\n";
					submenu += "\t</li>\n";
				}
			}
		}

		return submenu;
	}

	public boolean locateMenu(BElement smel, String key) {
		boolean isMn = false;
		for(BElement mie : smel.getElements()) {
			if(mie.isLeaf()) {
				if(mie.getValue().equals(key)) return true;
			} else {
				isMn = locateMenu(mie, key);
			}
		}
		return isMn;
	}

	public void getParams() {
		if(views == null) return;
		
		for(int i = 0; i < views.size()-1; i++) {
			BElement desk = views.get(i);

			String keyV = "";
			for(int k=0; k <= i; k++) keyV += viewKeys.get(k) + ":";
			String keyD = viewData.get(i+1);

			getParams(desk, keyD);
		}

		//Debug for (String param : params.keySet()) System.out.println(param + " : " + params.get(param));
	}

	public void getParams(BElement elParam, String paramKey) {
		if(elParam == null) return;

		String paramStr = elParam.getAttribute("params");
		if((paramStr != null) && (!paramKey.equals("[new]"))) {
			String paramsql = "SELECT " + paramStr;
			paramsql += " FROM " + elParam.getAttribute("table");
			paramsql += " WHERE (" + elParam.getAttribute("keyfield") + " = '" + paramKey + "')";

			params.putAll(db.getFieldsData(paramStr.split(","), paramsql));
		}
	}

	public String getTabs() {
		if((root == null) || (db == null)) return "";	// error check
		
		String tabs = "";
		for(int i = 0; i < views.size()-1; i++) tabs += getTabs(i);

		return tabs;
	}

	public String getTabs(Integer i) {
		BElement desk = views.get(i);

		String keyV = "";
		for(int k=0; k <= i; k++) keyV += viewKeys.get(k) + ":";
		String keyD = viewData.get(i+1);

		String tabs = "\t\t<ul class='nav nav-tabs'>\n";
		Integer j = 0;
		for(BElement el : desk.getElements()) {
			String elName = el.getName();
			if(Arrays.binarySearch(deskTypes, elName)>=0) {
				// Show only a form for a new entry
				boolean show = true;
				if(keyD.equals("[new]") && (!elName.equals("FORM"))) show = false;
				if(keyD.equals("[new]") && (el.getAttribute("new", "true").equals("false"))) show = false;
				
				if(el.getAttribute("superuser", "false").equals("true")) {
					if(!db.getUser().getSuperUser()) show = false;
				} else {
					if(!checkAccess(el.getAttribute("role"))) show = false;
				}

				String viewFilter = el.getAttribute("viewfilter");
				if(viewFilter != null) {
					String viewFilters[] = viewFilter.split(",");
					for(String vfs : viewFilters) {
						String vf[] = vfs.split("=");
						if(!vf[1].equals(params.get(vf[0]))) show = false;
					}
				}

				if(show) {
					String tabName = el.getAttribute("name");
					if(el.getAttribute("tab.count") != null) {
						String tcSql = "SELECT " + el.getAttribute("tab.count") + " FROM " + el.getAttribute("table");
						String tcWhere = null;
						if(el.getAttribute("noorg") == null) tcWhere = db.getOrgWhere(null);
						if(el.getAttribute("user") != null) {
							if(tcWhere == null) tcWhere = " WHERE ";
							else tcWhere += " AND ";
							tcWhere += el.getAttribute("user") + " = " + db.getUserID();
						}
						if(el.getAttribute("linkfield") != null) {
							if(tcWhere == null) tcWhere = " WHERE ";
							else tcWhere += " AND ";
							tcWhere += el.getAttribute("linkfield") + " = " + keyD;
						}
                        if(el.getAttribute("where") != null) {
							if(tcWhere == null) tcWhere = " WHERE ";
							else tcWhere += " AND ";
							tcWhere += el.getAttribute("where");
						}
						if(tcWhere != null) tcSql += tcWhere;

						String tcVal = db.executeFunction(tcSql);
						if(tcVal != null) tabName += " <span class=\"badge badge-success\">" + tcVal + "</span>";
					}
					
					if(viewKeys.get(i+1).equals(j.toString()))
						tabs += "\t\t\t<li class='active'>";
					else
						tabs += "\t\t\t<li>";
					tabs += "<a href='?view=" + keyV +  j.toString();
					if(keyD.equals("[new]") && (elName.equals("FORM"))) {
						tabs += "&data=" + keyD + "'>New " + tabName + "</a></li>\n";
					} else if (elName.equals("FORM") && (!el.getAttribute("edit", "true").equals("false"))) {
						tabs += "&data=" + keyD + "'>Edit " + tabName + "</a></li>\n";
					} else {
						tabs += "&data=" + keyD + "'>" + tabName + "</a></li>\n";
					}
				}
				j++;
			}
		}
		tabs += "\t\t</ul>\n";

		return tabs;
	}

	public String getButtons() {
		if((root == null) || (db == null)) return "";	// error check
		
		String buttons = "<div class='actions'>\n";

		boolean showButtons = false;

		if(view.getName().equals("GRID")) {
			if(view.getAttribute("display", "grid").equals("grid")) showButtons = true;
			if(view.getAttribute("buttons", "noshow").equals("show")) showButtons = true;
		}

		if(showButtons) {
			int j = -1;
			int fv = -1;
			boolean hasForm = false;
			for(BElement el : view.getElements()) {
				String elName = el.getName();
				if(Arrays.binarySearch(deskTypes, elName) >= 0) j++;
				if(elName.equals("FORM") && el.getAttribute("new", "true").equals("true")) {
					if(!hasForm) fv = j;
					hasForm = true;
				}

				if(elName.equals("ACCORDION") && el.getAttribute("new", "true").equals("true")) {
					for(BElement ell : el.getElements()) {
						if(ell.getName().equals("FORM") && ell.getAttribute("new", "true").equals("true")) {
							if(!hasForm) fv = j;
							hasForm = true;
						}
					}
				}
			}

			String did = "";
			if(dataItem != null) did = "&data=" + dataItem;
			
			boolean newShow = true;
			if(view.getAttribute("new.show") != null) {
				String tcSql = "SELECT " + view.getAttribute("new.show") + " FROM " + view.getAttribute("table");
				String tcWhere = null;
				if(view.getAttribute("noorg") == null) tcWhere = db.getOrgWhere(null);
				if(view.getAttribute("user") != null) {
					if(tcWhere == null) tcWhere = " WHERE ";
					else tcWhere += " AND ";
					tcWhere += view.getAttribute("user") + " = " + db.getUserID();
				}
				if((view.getAttribute("linkfield") != null) && (dataItem != null)) {
					if(tcWhere == null) tcWhere = " WHERE ";
					else tcWhere += " AND ";
					tcWhere += view.getAttribute("linkfield") + " = " + dataItem;
				}
				if(view.getAttribute("where") != null) {
					if(tcWhere == null) tcWhere = " WHERE ";
					else tcWhere += " AND ";
					tcWhere += view.getAttribute("where");
				}
				if(tcWhere != null) tcSql += tcWhere;

				String tcVal = db.executeFunction(tcSql);
				if(tcVal == null) newShow = false;
				else if(tcVal.equals("false")) newShow = false;
			}
			
			if(hasForm && newShow) {
				String newBtn = view.getAttribute("new.button", "New");
				buttons += "<a class='btn blue btn-sm' title='Add New' href='?view=" + viewKey + ":" + String.valueOf(fv) + "&data=[new]'><i class='fa fa-plus'></i>   " + newBtn + "</a>\n";
			}
			buttons += "<a class='btn green btn-sm' href='?view=" + viewKey + did + "&refresh=true'><i class='fa fa-refresh'></i>   Refresh</a>\n";
			
			if(view.getAttribute("grid.export", "true").equals("true"))
				buttons += "<a class='btn green btn-sm' target='_blank' href='grid_export?view=" + viewKey + did + "&action=export'><i class='fa fa-file-excel-o'></i>   Export</a>\n";
			
			if(view.getAttribute("grid.print", "false").equals("true"))
				buttons += "<a class='btn green btn-sm' target='_blank' href='b_print.jsp?view=" + viewKey + did + "&action=print'><i class='fa fa-print'></i>   Print</a>\n";
			
            buttons += "<a class='btn btn-circle btn-icon-only btn-default btn-sm fullscreen' href='javascript:;' data-original-title='' title=''></a>";
		}
		
		if(view.getName().equals("CROSSTAB")) {
			String did = "";
			if(dataItem != null) did = "&data=" + dataItem;
			
			buttons += "<a class='btn green btn-sm' target='_blank' href='grid_export?view=" + viewKey + did + "&action=export'><i class='fa fa-file-excel-o'></i>   Export</a>\n";
		}
		
		if(view.getName().equals("ACCORDION")) {
			if(view.getAttribute("new", "true").equals("true") && ("[new]".equals(dataItem)))
				buttons += "<button class='btn btn-success i_tick icon small' name='process' value='Update'> <i class='fa  fa-save'></i> &nbsp; Save </button>\n";
			if(view.getAttribute("edit", "true").equals("true") && (!"[new]".equals(dataItem)))
				buttons += "<button class='btn btn-success i_tick icon small' name='process' value='Update'> <i class='fa  fa-save'></i> &nbsp; Save </button>\n";
			
			boolean canDel = true;
			if(view.getAttribute("delete", "true").equals("false")) canDel = false;
			if("[new]".equals(dataItem)) canDel = false;
			if(canDel && view.getAttribute("delete.role") != null) {
				if(!checkAccess(view.getAttribute("delete.role"))) canDel = false;
			}
			if(canDel) {
				buttons += "<button class='btn btn-danger i_cross icon small' name='process' value='Delete' "
				+ "onclick=\"return confirm('Are you sure you delete?')\""
				+ "> <i class='fa fa-trash-o'></i> &nbsp; Delete</button>\n";
			}
		}
		
		if(view.getName().equals("TABLEVIEW") && (view.getAttribute("updatetable") != null)) {
			buttons += "<button type='button' class='btn btn-success i_tick icon small' name='btProcess' id='btProcess' value='Submit'><i class='fa  fa-save'></i> &nbsp; Submit</button>\n";
		}
		
		if(isForm()) {
			buttons += getFormButtons();
			//buttons += getAudit();
		} 

		buttons += "</div>\n";

		return buttons;
	}

	public String getFormButtons() {
		if((root == null) || (db == null)) return "";	// error check
		
		String buttons = "";

		if(view.getName().equals("FORM")) {		
			String saveBtn = view.getAttribute("save.button", "Save");
			if(view.getAttribute("new", "true").equals("true") && ("[new]".equals(dataItem)))
				buttons += "<button class='btn btn-success i_tick icon small' name='process' value='Update'> <i class='fa  fa-save'></i> &nbsp; " + saveBtn + "</button>\n";
			if(view.getAttribute("fornew", "false").equals("true"))
				buttons += "<button class='btn btn-success i_tick icon small' name='process' value='Update'> <i class='fa  fa-save'></i> &nbsp; " + saveBtn + "</button>\n";
			if(view.getAttribute("edit", "true").equals("true") && (!"[new]".equals(dataItem)))
				buttons += "<button class='btn btn-success i_tick icon small' name='process' value='Update'> <i class='fa  fa-save'></i> &nbsp; " + saveBtn + "</button>\n";
			boolean canDel = true;
			if(view.getAttribute("delete", "true").equals("false")) canDel = false;
			if(canDel && view.getAttribute("delete.role") != null) {
				if(!checkAccess(view.getAttribute("delete.role"))) canDel = false;
			}
			if(canDel && (!"[new]".equals(dataItem)))
				buttons += "<button class='btn btn-danger i_cross icon small' name='process' value='Delete' "
				+ "onclick=\"return confirm('Are you sure you delete?')\""
				+ "> <i class='fa fa-trash-o'></i> &nbsp; Delete</button>\n";
			/*if(view.getAttribute("audit", "true").equals("true") && (!"[new]".equals(dataItem)))
				buttons += "<button class='btn blue i_key icon small' name='process' value='Audit'>Audit</button>\n";*/
            
            buttons += "<a class='btn btn-circle btn-icon-only btn-default btn-sm fullscreen' href='javascript:;' data-original-title='' title=''></a>";
		}

		return buttons;
	}

	public String getFileButtons(String callPage) {
		String buttons = "";
		if(view.getName().equals("FILES") && (view.getAttribute("new", "true").equals("true"))) {
			buttons = "<form id='form' action='" + callPage + "' method='POST'>\n";
			buttons += "<div class='configuration k-widget k-header' style='width: 500px'>\n";
			buttons += "<label for='files'>File Upload</label>\n";
			buttons += "<div>\n<input name=\"files\" id=\"files\" type=\"file\" />\n</div>\n";
			buttons += "<p><input type=\"submit\" value=\"Submit\" class=\"k-button\" /></p>\n";
			buttons += "</div>\n";
			buttons += "</form>\n";
		}

		return buttons;
	}

	public String getFileButtons() {
		String buttons = "";
		if(view.getName().equals("FILES") && (view.getAttribute("new", "true").equals("true"))) {
			buttons = "<form id='form' action='.' method='POST'>\n";
			buttons += "<div class='configuration k-widget k-header' style='width: 500px'>\n";
			buttons += "<label for='files'>File Upload</label>\n";
			buttons += "<div>\n<input name=\"files\" id=\"files\" type=\"file\" />\n</div>\n";
			buttons += "<p><input type=\"submit\" value=\"Submit\" class=\"k-button\" /></p>\n";
			buttons += "</div>\n";
			buttons += "</form>\n";
		}

		return buttons;
	}
	
	public String getDashboard() {
		if((root == null) || (db == null)) return "";	// error check
		
		String body = "";
		String taskList = "";
		
		BWebDashboard webDashboard = new BWebDashboard(db);
		
		body += "<div class='row margin-top-5'>\n";
		for(BElement el : view.getElements()) {
			boolean hasAccess  = checkAccess(el.getAttribute("role"));
			if(hasAccess && el.getName().equals("TILE")) body += webDashboard.getTile(el);
		}
		body += "</div>\n";
		
		body += "<div class='row'>\n";
		for(BElement el : view.getElements()) {
			boolean hasAccess  = checkAccess(el.getAttribute("role"));
			if(hasAccess && el.getName().equals("TILELIST")) body += webDashboard.getTileList(el);
		}
		body += "</div>\n";
		
		for(BElement el : view.getElements()) {
			boolean hasAccess  = checkAccess(el.getAttribute("role"));
			if(hasAccess) {
				if(el.getName().equals("ATTENDANCE")) {
					dashboardItems.put("ATTENDANCE", "true");
					
					String lWhere = "(log_time_out is null)";
					BQuery alRs = new BQuery(db, el.getElementByName("ACCESSLOG"), lWhere, null);
					dashboardItems.put("accessLog", alRs.getJSON());
					alRs.close();
				} else if(el.getName().equals("TASK")) {
					dashboardItems.put("TASK", "true");
					
					BQuery tlRs = new BQuery(db, el.getElementByName("TASKLIST"), null, null, false);
					while(tlRs.moveNext()) {
						taskList += "\n<option value='" + tlRs.getString("task_id") + "'>" + tlRs.getString("task_name") + "</option>";
					}
					dashboardItems.put("taskList", taskList);
					tlRs.close();
					
					BQuery tsRs = new BQuery(db, el.getElementByName("TIMESHEET"), null, null);
					dashboardItems.put("timeSheet", tsRs.getJSON());
					tsRs.close();
				}
			}
		}
		
		return body;
	}
	
	public boolean checkAccess(String role) {
		if(db.getUser() == null) return true;
		
		boolean hasAccess  = false;
		if(db.getUser().getSuperUser()) {
			hasAccess = true;
		} else if(role == null) {
			hasAccess = true;
		} else {
			String mRoles[] = role.split(",");
			for(String mRole : mRoles) {
				if(db.getUser().getUserRoles().contains(mRole)) hasAccess = true;
			}
		}
		
		return hasAccess;
	}
	
	public String getFilterWhere(HttpServletRequest request) {
		String filterName = request.getParameter("filtername");
		String filterType = request.getParameter("filtertype");
		String filterValue = request.getParameter("filtervalue");
		String filterAnd = request.getParameter("filterand");
		String filterOr = request.getParameter("filteror");
		
		if(filterName == null) return "";
		if(filterType == null) return "";
		if(filterValue == null) return "";
		if(BWebUtils.checkInjection(filterValue)) return "";
		if(filterAnd == null) filterAnd = "false";
		if(filterOr == null) filterOr = "false";
		
		boolean isField = false;
		for(BElement el : view.getElements()) {
			if(filterName.equals(el.getValue())) isField = true;
		}
		if(!isField) return "";
		
		if("ilikelike=><<=>=".indexOf(filterType) < 0) return "";
		
		String filterSN = "F" + getViewKey();
		
		// Only postgres supports ilike so for the others turn to like
		String filterSql = "";
		if((db.getDBType()!=1) && (filterType.startsWith("ilike"))) filterType = "like";

		if(filterType.startsWith("like")) {
			if(db.getDBType()==1) filterSql += "(cast(" + filterName + " as varchar) " + filterType + " '%" + filterValue + "%')";
			else filterSql += "(lower(" + filterName + ") " + filterType + " lower('%" + filterValue + "%'))";
		} else if(filterType.startsWith("ilike")) {
			filterSql += "(cast(" + filterName + " as varchar) " + filterType + " '%" + filterValue + "%')";
		} else {
			filterSql += "(" + filterName + " " + filterType + " '" + filterValue + "')";
		}
		
		if(webSession.getAttribute(filterSN) != null) {
			if(filterAnd.equals("true")) {
				filterSql = (String)webSession.getAttribute(filterSN) + " AND " + filterSql;
			} else if(filterOr.equals("true")) {
				filterSql = (String)webSession.getAttribute(filterSN) + " OR " + filterSql;
			}
		}
		
		webSession.setAttribute(filterSN, filterSql);
		if(dataItem != null) webSession.setAttribute("K" + filterSN, dataItem);
		else webSession.setAttribute("K" + filterSN, "");
		System.out.println(filterSql + " : " + filterAnd);
		
		return filterSql;
	}
	
	public Map<String, String> getWhere(HttpServletRequest request) {
		Map<String, String> whereParams = new HashMap<String, String>();

		String linkData = "";
		String linkParam = null;
		String formLinkData = "";
		wheresql = null;
		sortby = null;
		
		BElement sview = null;
		comboField = request.getParameter("field");
		if(comboField != null) sview = view.getElement(comboField).getElement(0);

		String filterSN = "F" + viewKey;
		if(webSession.getAttribute(filterSN) != null) {
			String filterKSN = "";
			if(webSession.getAttribute("K" + filterSN) != null) filterKSN = (String)webSession.getAttribute("K" + filterSN);
			String wDataItem = "";
			if(dataItem != null) wDataItem = dataItem;
			
			if(filterKSN.equals(wDataItem)) wheresql = (String)webSession.getAttribute(filterSN);
			else webSession.removeAttribute(filterSN);
			
			System.out.println("Filter Where :" + filterSN + ": " + wheresql);
		}

		int vds = viewKeys.size();
		if(vds > 2) {
			linkData = viewData.get(vds - 1);
			formLinkData = viewData.get(vds - 2);
			
			if((!linkData.equals("[new]")) && (comboField == null)) {
				if(view.getName().equals("FORM")) {
					if(wheresql != null) wheresql += " AND (";
					else wheresql = "(";
					wheresql += view.getAttribute("keyfield") + " = '" + linkData + "')";
				} else if(view.getAttribute("linkfield") != null) {
					if(wheresql != null) wheresql += " AND (";
					else wheresql = "(";
					wheresql += view.getAttribute("linkfield") + " = '" + linkData + "')";
				}
			}

			// Table linking on parameters
			String paramLinkData = linkData;
			String linkParams = view.getAttribute("linkparams");
			if(sview != null) { linkParams = sview.getAttribute("linkparams"); paramLinkData =  formLinkData; }
			if(linkParams != null) {
				BElement fView = views.get(vds - 2);
				if(sview != null) fView = views.get(vds - 3);
				String lp[] = linkParams.split("=");
				linkParam = params.get(lp[0].trim());

				if(wheresql != null) wheresql += " AND (";
				else wheresql = "(";
				if(linkParam == null) wheresql += lp[1] + " = null)";
				else wheresql += lp[1] + " = '" + linkParam + "')";
			}
		} else if(request.getParameter("filterid") != null) {
			linkData = request.getParameter("filterid");
		} else if(request.getParameter("formlinkdata") != null) {
			formLinkData = request.getParameter("formlinkdata");

			String linkField = view.getAttribute("linkfield");
			String linkFnct = view.getAttribute("linkfnct");
			String tableFilter = null;
			if((linkField != null) && (formLinkData != null) && (comboField == null)) {
				if(linkFnct == null) tableFilter = linkField + " = '" + formLinkData + "'";
				else tableFilter = linkField + " = " + linkFnct + "('" + formLinkData + "')";
			
				if(wheresql != null) wheresql += " AND (" + tableFilter + "')";
				else wheresql = "(" + tableFilter + "')";
			}
		}

		if(views.size() > 1) {
			BElement flt = views.get(views.size()-2);
			if(flt.getName().equals("FILTER")) {
				for(BElement sv : flt.getElements()) {
					if(sv.getName().equals("FILTERGRID")) {
						String myFilter = sv.getAttribute("filter", "filterid");
						String myFilterField = sv.getAttribute("filterfield", myFilter);
						getFilterParam(myFilter, myFilterField, " = ");
					} else if(sv.getName().equals("DRILLDOWN")) {
						String myFilter = sv.getAttribute("filter", "filterid");
						String myFilterField = sv.getAttribute("filterfield", myFilter);
						getFilterParam(myFilter, myFilterField, " = ");
					} else if(sv.getName().equals("FILTERFORM")) {
						for(BElement ffe : sv.getElements()) {
							String myFilter = ffe.getValue();
							String myFilterField = ffe.getAttribute("filterfield", myFilter);
							String myFilterType = ffe.getAttribute("filtertype", "=");
							getFilterParam(myFilter, myFilterField, myFilterType);
						}
					}
				}
			}
		}

		whereParams.put("linkData", linkData);
		whereParams.put("linkParam", linkParam);
		whereParams.put("formLinkData", formLinkData);
		whereParams.put("wheresql", wheresql);
		
//System.out.println("BASE 3030 WHERE : " + wheresql);
		
		return whereParams;
	}
	
	public String getBody(HttpServletRequest request, String reportPath) {
		if((root == null) || (db == null)) return "";	// error check
		
		String body = "";
		
		// Check for license
		//if(!hasLicense()) return "";
		
		// Save the parameters in filter is the session
		List<String> filterList = setFilterParams(request);
		
		// Call the where create function
		Map<String, String> whereParams = getWhere(request);
		String linkData = whereParams.get("linkData");
		String linkParam = whereParams.get("linkParam");
		String formLinkData = whereParams.get("formLinkData");
		
		int vds = viewKeys.size();
		BElement sview = null;
		comboField = request.getParameter("field");
		if(comboField != null) sview = view.getElement(comboField).getElement(0);
		
		if(view.getName().equals("GRID")) {
			if(request.getParameter("refresh") != null) webSession.removeAttribute("F" + viewKey);
		
			body += "\t<div class='table-scrollable'>\n";
			body += "\t\t<table id='jqlist' class='table table-striped table-bordered table-hover'></table>\n";
			body += "\t\t<div id='jqpager'></div>\n";
			body += "\t</div>\n";
		} else if(view.getName().equals("FILES")) {
			BWebBody webbody = new BWebBody(db, view, wheresql, sortby);
			if(selectAll) webbody.setSelectAll();
			body += webbody.getGrid(viewKeys, viewData, true, viewKey, false);
			webbody.close();
		} else if(view.getName().equals("FORMVIEW")) {
			BWebBody webbody = new BWebBody(db, view, wheresql, sortby);
			if(selectAll) webbody.setSelectAll();
			body += webbody.getGrid(viewKeys, viewData, true, viewKey, false);
			webbody.close();
		} else if(view.getName().equals("TABLEVIEW")) {
			BWebBody webbody = new BWebBody(db, view, wheresql, sortby);
			if(selectAll) webbody.setSelectAll();
			body += webbody.getGrid(viewKeys, viewData, true, viewKey, false);
			webbody.close();
		} else if(view.getName().equals("ACCORDION")) {
			BAccordion accordion = new BAccordion(db, view);
			body += accordion.getAccordion(request, linkData, formLinkData, viewData);
			accordionJs = accordion.getAccordionJs();
		} else if(view.getName().equals("CROSSTAB")) {
			BCrossTab crossTab = new BCrossTab(db, view, wheresql, sortby);
			body += crossTab.getGrid(viewKeys, viewData, true, viewKey, false);
			crossTab.close();
		} else if(view.getName().equals("FORM")) {
			if(comboField == null) {
				BWebBody webbody = new BWebBody(db, view, wheresql, sortby);
				if(vds > 2) {
					if(linkData.equals("[new]")) {
						if(view.getAttribute("new", "true").equals("true")) 
							body = webbody.getForm(true, formLinkData, request);
					} else if(view.getAttribute("edit", "true").equals("true")) {
						body += webbody.getForm(false, formLinkData, request);
					} else if(view.getAttribute("edit", "true").equals("false")) {
						body += webbody.getForm(false, formLinkData, request);
					}
				} else {
					if(view.getAttribute("foredit") != null) {
						body += webbody.getForm(false, formLinkData, request);
					} else {
						body += webbody.getForm(true, formLinkData, request);
					}
				}
				webbody.close();
			} else {
				BWebBody webbody = new BWebBody(db, sview, wheresql, sortby);
				body += webbody.getGrid(viewKeys, viewData, true, viewKey, true);
				webbody.close();
			}
		} else if(view.getName().equals("DIARY")) {
			body += "<div class='portlet-body'>\n";
			body += "	<div class='row'>\n";
			body += "		<div class='col-md-12 col-sm-12'>\n";
			body += "			<div id='calendar' class='as-toolbar'></div>\n";
			body += "		</div>\n";
			body += "	</div>\n";
			body += "</div>\n";
		} else if(view.getName().equals("JASPER")) {
			BWebReport report = new BWebReport(view, db.getUserID(), null, request);
			
			BElement flt = views.get(views.size() - 2);
			if(!flt.getName().equals("FILTER")) {
				String myFilter = view.getAttribute("linkfield", "filterid");
				if((linkParam != null) && (view.getAttribute("linkparams") != null)) linkData = linkParam;
				if(linkData != null) filterList.add(myFilter);
				webSession.setAttribute(myFilter, linkData);
			}
			// Table linking on parameters
			String linkParams = view.getAttribute("linkparams");
			if(linkParams != null) {
				String lp[] = linkParams.split("=");
				String lnParam = params.get(lp[0].trim());
				if(lnParam != null) {
					filterList.add(lp[1]);
					webSession.setAttribute(lp[1], lnParam);
				}
			}
			
			webSession.setAttribute("reportfilters", filterList);
			report.setParams(webSession);
			body += report.getReport(db, linkData, request, reportPath);
		} else if(view.getName().equals("FILTER")) {
			boolean isFirst = true;
			StringBuilder tabs = new StringBuilder();
			tabs.append("<div class='row'>\n");
			tabs.append("	<div class='col-md-12'>\n");
			tabs.append("		<div class='tabbable portlet-tabs'>\n");
			tabs.append("			<ul class='nav nav-tabs'>\n");
			for(BElement sv : view.getElements()) {
				if(sv.getName().equals("FILTERGRID") || sv.getName().equals("DRILLDOWN") || sv.getName().equals("FILTERFORM")) {
					if(isFirst) tabs.append("<li class='active'>\n");
					else tabs.append("<li>\n");
					isFirst = false;
					String tab = sv.getAttribute("name");
					tabs.append("<a href='#" + tab.replace(" ", "") + "' data-toggle='tab'>" + tab + " </a></li>\n");
				}
    		}
			tabs.append("			</ul>\n");
			tabs.append("		</div>\n");
			tabs.append("	</div>\n");
			tabs.append("</div>\n");
			tabs.append("<div class='tab-content'>\n");

			body += tabs.toString();

			boolean wgf = true;
			isFirst = true;
			for(BElement sv : view.getElements()) {
				String tab = sv.getAttribute("name", "").replace(" ", "");
				if(sv.getName().equals("FILTERGRID")) {
					if(isFirst) body += "<div class='tab-pane active' id='" + tab + "'>\n";
					else body += "<div class='tab-pane' id='" + tab + "'>\n";
					isFirst = false;
					BWebBody webbody = new BWebBody(db, sv, wheresql, sortby);
					body += webbody.getGrid(viewKeys, viewData, wgf, viewKey, false);
					body += "</div>";
					wgf = false;					
				} else if(sv.getName().equals("DRILLDOWN")) {
					if(isFirst) body += "<div class='tab-pane active' id='" + tab + "'>\n";
					else body += "<div class='tab-pane' id='" + tab + "'>\n";
					isFirst = false;
					BDrillWeb drillweb = new BDrillWeb();
					body += drillweb.getDrillDown(db, sv);
					body += "</div>";
				} else if(sv.getName().equals("FILTERFORM")) {
					if(isFirst) body += "<div class='tab-pane active' id='" + tab + "'>\n";
					else body += "<div class='tab-pane' id='" + tab + "'>\n";
					isFirst = false;
					BWebBody webbody = new BWebBody(db, sv, wheresql, sortby);
					body += webbody.getForm(true, formLinkData, request);
					body += "</div>";
				}
				
			}
			body += "</div>\n";
			body += "<input type='hidden' name='view' value='" + viewKey + ":0'/>\n";
			body += "<input type='hidden' name='data' value='0'/>\n";
			body += "<div><input type='submit' value='Report'/></div>\n";
		}

		return body;
	}

	public String palseValue(BElement el, String myvalue) {
		String dbvalue = null;
		if(myvalue == null) {
			dbvalue = null;
		} else if(el.getName().equals("COMBOBOX")) {
			dbvalue = myvalue;
		} else if(el.getName().equals("COMBOLIST")) {
			dbvalue = myvalue;
		} else if(el.getName().equals("TEXTDECIMAL")) {
			dbvalue = myvalue.replace(",", "");
		} else if(el.getName().equals("TEXTDATE")) {
			dbvalue = BDateFormat.parseDate(myvalue, el.getAttribute("dbformat"), db.getDBType());
		} else if(el.getName().equals("TEXTTIMESTAMP")) {
			dbvalue = BDateFormat.parseTimeStamp(myvalue);
		} else if(el.getName().equals("SPINTIME")) {
			dbvalue = BDateFormat.parseTime(myvalue, el.getAttribute("type", "1"));
		} else {
			dbvalue = myvalue;
		}
		return dbvalue;
	}
	
	/* Save the parameters in filter is the session */
	public List<String> setFilterParams(HttpServletRequest request) {
		List<String> filterList = new ArrayList<String>();
		if(views.size() > 1) {
			BElement flt = views.get(views.size()-2);
			if(flt.getName().equals("FILTER")) {
				for(BElement sv : flt.getElements()) {
					if(sv.getName().equals("FILTERGRID")) {
						String myFilter = sv.getAttribute("filter", "filterid");
						String myValue = request.getParameter(myFilter);
						filterList.add(myFilter);
						if(myValue != null) webSession.setAttribute(myFilter, myValue);
					} else if(sv.getName().equals("DRILLDOWN")) {
						String myFilter = sv.getAttribute("filter", "filterid");
						String myValue = request.getParameter(myFilter);
						filterList.add(myFilter);
						if(myValue != null) webSession.setAttribute(myFilter, myValue);
					} else if(sv.getName().equals("FILTERFORM")) {
						for(BElement ffe : sv.getElements()) {
							String myFilter = ffe.getValue();
							String myValue = request.getParameter(myFilter);
							filterList.add(myFilter);
							if(myValue != null) webSession.setAttribute(myFilter, palseValue(ffe, myValue));
					System.out.println("BASE 2005 : " + myFilter + " : " + myValue);
						}
					}
				}
			}
		}
		return filterList;
	}
	
	private void getFilterParam(String myFilter, String myFilterField, String myFilterType) {
		if(webSession.getAttribute(myFilter) != null) {
			String myValue = (String)webSession.getAttribute(myFilter);
			if(wheresql != null) wheresql += " AND (";
			else wheresql = "(";
			wheresql += myFilterField + " " + myFilterType + " '" + myValue + "')";
		}
	}

	public String getOperations() {
		String operations = null;
		if(view.getElementByName("ACTIONS") != null) {
			BElement opt = view.getElementByName("ACTIONS");
			operations = "";
			Integer i = 0;
			List<String> userRole = db.getUser().getUserRoles();
			
			for(BElement el : opt.getElements()) {
				boolean hasAccess = true;
				if(el.getAttribute("role") != null) {
					hasAccess = false;
					String mRoles[] = el.getAttribute("role").split(",");
					for(String mRole : mRoles) { if(userRole.contains(mRole.trim())) hasAccess = true; }
				}
				if(db.getUser().getSuperUser()) hasAccess = true;
				if(hasAccess) operations += "<option value='" + i.toString() + "'>" + el.getValue() + "</option>\n";
				i++;
			}
		}

		if(operations != null)
			operations = "<select class='fnctcombobox form-control ' id='operation' name='operation'>" + operations + "</select>";

		return operations;
	}

	public String setOperation(String actionKey, HttpServletRequest request) {
		String mystr = "";
		String mysql;

		BElement opt = view.getElementByName("ACTION");

		mysql = "SELECT " + opt.getAttribute("fnct") + "('" + actionKey + "', '" + db.getUserID();
		if(opt.getAttribute("phase") != null) mysql += "', '" + opt.getAttribute("phase") + "')";
		else mysql += "', '0')";

		if(opt.getAttribute("from") != null) mysql += " " + opt.getAttribute("from");
		log.info(mysql);

		String exans = db.executeFunction(mysql);
		if(exans == null) {
			mystr = "<div style='color:#FF0000' font-size:14px; font-weight:bold;>" + db.getLastErrorMsg() + "</div><br>\n";
		} else {
			String jumpView = opt.getAttribute("jumpview");
			if(jumpView != null) {
				viewKey = jumpView;
				webSession.setAttribute("viewkey", jumpView);
				webSession.setAttribute("loadviewkey", jumpView);
				init(request);
			}
			mystr = "<div style='color:#00FF00; font-size:14px;'>" + exans + "</div>";
		}

		return mystr;
	}

	public String setOperations(String operation, String ids, HttpServletRequest request) {
		JsonObjectBuilder jshd = Json.createObjectBuilder();
		
		String mystr = "";
		boolean fnctError = false;
		String mysql;

		String[] values = ids.split(",");
		BElement aView = view.getElementByName("ACTIONS");

		if((values != null) && (aView != null)) {
			int i = Integer.valueOf(operation);
			BElement el = aView.getElement(i);
			
			List<String> userRole = db.getUser().getUserRoles();
			boolean hasAccess = true;
			if(el.getAttribute("role") != null) {
				hasAccess = false;
				String mRoles[] = el.getAttribute("role").split(",");
				for(String mRole : mRoles) { if(userRole.contains(mRole.trim())) hasAccess = true; }
			}
			if(db.getUser().getSuperUser()) hasAccess = true;

			if(hasAccess) {
				for(String value : values) {
					boolean sqlOkay = true;
					if(el.getAttribute("sql_table") != null) {
						String sqlErr = checkSQL(el, value);
						if(sqlErr != null) {
							sqlOkay = false;
							fnctError = true;
							mystr += sqlErr + "; ";
						}
					}

					if(sqlOkay) {
						String autoKeyID = db.insAudit(el.getAttribute("fnct"), value, "FUNCTION");

						mysql = "SELECT " + el.getAttribute("fnct") + "('" + value + "', '" + db.getUserID();
						if(el.getAttribute("approval") != null) mysql += "', '" + el.getAttribute("approval");
						if(el.getAttribute("phase") != null) mysql += "', '" + el.getAttribute("phase");
						else mysql += "', '" + viewData.get(viewData.size() - 1);
						if(el.getAttribute("auditid") != null) mysql += "', '" + autoKeyID;
						mysql += "') ";

						if(el.getAttribute("from") != null) mysql += " " + el.getAttribute("from");
						log.info(mysql);

						String exans = db.executeFunction(mysql);
						if(exans == null) fnctError = true;
						if(exans == null) mystr = db.getLastErrorMsg() + "; ";
						else mystr += exans + "; ";
					}
				}
			
				if(fnctError) {
					jshd.add("msg", mystr);
					jshd.add("error", true);
				} else {
					jshd.add("error", false);
					String jumpView = aView.getAttribute("jumpview");
					if(jumpView != null) {
						viewKey = jumpView;
						webSession.setAttribute("viewkey", jumpView);
						webSession.setAttribute("loadviewkey", jumpView);
						init(request);
						jshd.add("jump", true);
					}
					jshd.add("msg", mystr);
				}
			} else {
				jshd.add("error", true);
				jshd.add("msg", "No access allowed for function");
			}
		}
		JsonObject jsObj = jshd.build();
		
		System.out.println("BASE 2030 : " + jsObj.toString());
		return jsObj.toString();
	}
	
	public String checkSQL(BElement el, String value) {
		String sqlErr = "";
		String appSql = "SELECT sql, message FROM " + el.getAttribute("sql_table")
		+ " WHERE (is_condition = true) AND " + el.getAttribute("sql_where") + " = '" + value + "'";
						
		BQuery aRs = new BQuery(db, appSql);
		while(aRs.moveNext()) {
			String ansSql = db.executeFunction(aRs.getString("sql") + value + "'");
			if(ansSql == null) sqlErr += aRs.getString("message") + ";";
			else if(ansSql.equals("f")) sqlErr += aRs.getString("message") + ";";
		}
		if(sqlErr.equals("")) sqlErr = null;
		
		return sqlErr;
	}
	
	public void updateMultiPart(HttpServletRequest request, ServletContext config, String tmpPath) {
		if(!ServletFileUpload.isMultipartContent(request)) {
			updateForm(request);
			return;
		}
		
		int yourMaxMemorySize = 262144;
		File yourTempDirectory = new File(tmpPath);
		DiskFileItemFactory factory = new DiskFileItemFactory(yourMaxMemorySize, yourTempDirectory);
		ServletFileUpload upload = new ServletFileUpload(factory);
		
		Map<String, String> reqParams = new HashMap<String, String>();
		try {
			List items = upload.parseRequest(request);
			Iterator itr = items.iterator();
			while(itr.hasNext()) {
				FileItem item = (FileItem) itr.next();
				if(item.isFormField()) {
					reqParams.put(item.getFieldName(), item.getString());
				} else if(item.getSize() > 0) {
					String pictureFile = savePicture(item, config);
					if(pictureFile != null) reqParams.put(item.getFieldName(), pictureFile);
				}
			}
			
			updateForm(request, reqParams);
		} catch (FileUploadException ex) {
			System.out.println("File upload exception " + ex);
		}
	}
	
	public String savePicture(FileItem item, ServletContext config) {
		String pictureFile = null;

		String repository = config.getInitParameter("repository_url");
		String username = config.getInitParameter("rep_username");
		String password = config.getInitParameter("rep_password");
System.out.println("repository : " + repository);
		BWebdav webdav = new BWebdav(repository, username, password);
		
		String contentType = item.getContentType();
		String fieldName = item.getFieldName();
		String fileName = item.getName();
		long fs = item.getSize();
		
		BElement el = view.getElement(fieldName);
		long maxfs = (Long.valueOf(el.getAttribute("maxfilesize", "4194304"))).longValue();

		String ext = null;
		int i = fileName.lastIndexOf('.');
		if(i>0 && i<fileName.length()-1) ext = fileName.substring(i+1).toLowerCase();
		if(ext == null) ext = "NAI";
		String pictureName = db.executeFunction("SELECT nextval('picture_id_seq')") + "pic." + ext;

		try {
			String[] imageTypes = {"BMP", "GIF", "JFIF", "JPEG", "JPG", "PNG", "TIF", "TIFF"};
			ext = ext.toUpperCase().trim();

			if(Arrays.binarySearch(imageTypes, ext) >= 0) {
				if(fs < maxfs) {
					webdav.saveFile(item.getInputStream(), pictureName);
					pictureFile = pictureName;
				}
			}
		}  catch(IOException ex) {
			log.severe("File saving failed Exception " + ex);
		}

		return pictureFile;
	}
	
	public void updateForm(HttpServletRequest request) {
		Map<String, String[]> reqParams = new HashMap<String, String[]>();
		Enumeration e = request.getParameterNames();
        while (e.hasMoreElements()) {
			String elName = (String)e.nextElement();
			reqParams.put(elName, request.getParameterValues(elName));
		}
		updateFormData(request, reqParams);
	}
	
	public void updateForm(HttpServletRequest request, Map<String, String> reqParams) {
		Map<String, String[]> newParams = new HashMap<String, String[]>();
		for(String paramName : reqParams.keySet()) {
			String[] pArray = new String[1];
			pArray[0] = reqParams.get(paramName);
			newParams.put(paramName, pArray);
		}
		updateFormData(request, newParams);
	}

	public void updateFormData(HttpServletRequest request, Map<String, String[]> reqParams) {
		String linkData = null;
		String formlink = null;
		int vds = viewKeys.size();
		saveMsg = "";

		if(vds > 2) {
			linkData = viewData.get(vds - 1);
			if(linkData.equals("[new]")) formlink = view.getAttribute("keyfield") + " = null";
			else formlink = view.getAttribute("keyfield") + " = '" + linkData + "'";
		}

		if(view.getName().equals("FORM")) {
			BQuery qForm = new BQuery(db, view, formlink, null);
			if(view.getAttribute("foredit") != null) {
				qForm.movePos(1);
				qForm.recEdit();
			} else if(vds < 3) {
				qForm.recAdd();
			} else if(linkData.equals("[new]")) {
				qForm.recAdd();
				if(view.getAttribute("linkfield") != null) 
					qForm.updateField(view.getAttribute("linkfield"), viewData.get(vds - 2));
			} else {
				qForm.movePos(1);
				qForm.recEdit();
			}

			Map<String, String> inputParams = new HashMap<String, String>();
			if(view.getAttribute("inputparams") != null) {
				String paramArr[] = view.getAttribute("inputparams").toLowerCase().split(",");
				for(String param : paramArr) {
					String pItems[] = param.split("=");
					if(pItems.length == 2) {
						qForm.updateField(pItems[0].trim(), params.get(pItems[1].trim()));
						//System.out.println("BASE 1010 " + pItems[0].trim() + " : " + params.get(pItems[1].trim()));
					}
				}
			}

			saveMsg = qForm.updateFields(reqParams, viewData, request.getRemoteAddr(), linkData);
			
			if("".equals(saveMsg)) {
				String jumpView = view.getAttribute("jumpview");
				BElement fView = view.getElementByName("FORMVIEW");
				dataItem = qForm.getKeyField();
				viewData.set(vds - 1, dataItem);

				// Create an allowance to excecute a function after new or updateCombo
				String postFnct = view.getAttribute("post_fnct");
				if(postFnct != null) {
					String upsql = "SELECT " + postFnct + "('" + dataItem + "') ";
					if(db.getDBType()==2) upsql += " FROM dual";
					db.executeQuery(upsql);
				}

				if(jumpView != null) {
					saveMsg = "<div class='Metronic-alerts alert alert-success fade in'>\n";
					saveMsg += "		<button aria-hidden='true' data-dismiss='alert' class='close' type='button'></button>\n";
					saveMsg += view.getAttribute("save.msg", "The record has been updated.") + "\n</div>\n";
					
					viewKey = jumpView;
					webSession.setAttribute("viewkey", jumpView);
					webSession.setAttribute("loadviewkey", jumpView);
					webSession.setAttribute("loaddata", dataItem);
					init(request);
				} else if(fView != null) {
					view = fView;
					views.add(fView);
					viewData.add(dataItem);
					viewKeys.add("0");
					viewKey += ":0";
				} else {
								
					saveMsg = "<div class='Metronic-alerts alert alert-success fade in'>\n";
					saveMsg += "		<button aria-hidden='true' data-dismiss='alert' class='close' type='button'></button>\n";
					saveMsg += view.getAttribute("save.msg", "The record has been updated.") + "\n</div>\n";
				
					if(vds > 2) {
						dataItem = viewData.get(vds - 2);
						view = views.get(vds - 2);

						views.remove(vds - 1);
						viewData.remove(vds - 1);
						viewKeys.remove(vds - 1);

						viewKey = viewKey.substring(0, viewKey.lastIndexOf(":"));
						webSession.setAttribute("viewkey", viewKey);
					}
				}
			} else {
				String tmsg = saveMsg;
				
				saveMsg = "<div class='Metronic-alerts alert alert-danger fade in'>\n";
				saveMsg += "		<button aria-hidden='true' data-dismiss='alert' class='close' type='button'></button>\n";
				saveMsg += tmsg + "\n</div>\n";
			}
			qForm.close();
		} else if(view.getName().equals("ACCORDION")) {
			BElement accdView = view.getElement(0);
System.out.println("Reached ACCORDION " + vds + " : " + formlink);

			BQuery qAccd = new BQuery(db, accdView, formlink, null);
			
			if(vds < 2) {
				qAccd.recAdd();
			} else if(linkData == null) {
				if(qAccd.moveFirst()) qAccd.recEdit();
			} else if(linkData.equals("[new]")) {
				qAccd.recAdd();
				if(accdView.getAttribute("linkfield") != null) 
					qAccd.updateField(accdView.getAttribute("linkfield"), viewData.get(vds - 2));
			} else {
				if(qAccd.moveFirst()) qAccd.recEdit();
			}
			
			saveMsg = qAccd.updateFields(reqParams, viewData, request.getRemoteAddr(), linkData);
			
			// Set the jump point
			dataItem = qAccd.getKeyField();
			viewData.set(vds - 1, dataItem);
			webSession.setAttribute("loaddata", dataItem);
			
			qAccd.close();
		}
	}

	public void deleteForm(HttpServletRequest request) {
		String linkData = null;
		String formlink = null;
		int vds = viewKeys.size();
		saveMsg = "";
		
		BElement fView = view;
		if(view.getName().equals("ACCORDION")) fView = view.getElementByName("FORM");
		if(fView == null) return;

		if(vds > 2) {
			linkData = viewData.get(vds - 1);
			if(!linkData.equals("[new]"))
				formlink = fView.getAttribute("keyfield") + " = '" + linkData + "'";
		}
		
		if(fView.getName().equals("FORM") && (!linkData.equals("[new]"))) {
			BQuery qForm = new BQuery(db, fView, formlink, null);
			qForm.movePos(1);
			qForm.recDelete();
			qForm.close();

			if(vds > 2) {
				dataItem = viewData.get(vds - 2);
				view = views.get(vds - 2);

				views.remove(vds - 1);
				viewData.remove(vds - 1);
				viewKeys.remove(vds - 1);

				viewKey = viewKey.substring(0, viewKey.lastIndexOf(":"));
				webSession.setAttribute("viewkey", viewKey);
			} else {
				dataItem = "[new]";
			}
			saveMsg = "<div style='color:#00FF00'>Record deleted.</div>";
		}
	}

	public String getFieldTitles() {
		String fieldTitles = null;

		if(view == null) return "";

		BElement sview = null;
		if(comboField != null) sview = view.getElement(comboField).getElement(0);

		if(view.getName().equals("GRID") && view.getAttribute("display", "grid").equals("grid")) {
			fieldTitles = "<select class='fnctcombobox form-control' name='filtername' id='filtername'>";
			for(BElement el : view.getElements()) {
				if(!el.getValue().equals(""))
					fieldTitles += "<option value='" +  el.getValue() + "'>" + el.getAttribute("title") + "</option>\n";
			}
			fieldTitles += "</select>";
		} else if (comboField != null) {
			fieldTitles = "<select class='fnctcombobox form-control' name='filtername' id='filtername'>";
			for(BElement el : sview.getElements()) {
				if(!el.getValue().equals(""))
					fieldTitles += "<option value='" +  el.getValue() + "'>" + el.getAttribute("title") + "</option>\n";
			}
			fieldTitles += "</select>";
		}

		return fieldTitles;
	}

	public String getFieldTitles(HttpServletRequest request) {
		String fieldTitles = null;
		String field = request.getParameter("field");

		if(view.getName().equals("GRID")) {
			fieldTitles = "<select class='fnctcombobox form-control' name='filtername' id='filtername'>";
			for(BElement el : view.getElements()) {
				if(!el.getValue().equals(""))
					fieldTitles += "<option value='" +  el.getValue() + "'>" + el.getAttribute("title") + "</option>\n";
			}
			fieldTitles += "</select>";
		} else if(view.getName().equals("FORM") && (field != null)) {
			BElement sview = view.getElement(field).getElement(0);
			fieldTitles = "<select class='fnctcombobox form-control' name='filtername' id='filtername'>";
			for(BElement el : sview.getElements()) {
				if(!el.getValue().equals(""))
					fieldTitles += "<option value='" +  el.getValue() + "'>" + el.getAttribute("title") + "</option>\n";
			}
			fieldTitles += "</select>";
		}

		return fieldTitles;
	}

	public String getEntityName() {
		BUser user = db.getUser();
		return user.getEntityName();
	}

	public String getOrgName() {
		BUser user = db.getUser();
		return user.getUserOrgName();
	}

	public String getOrgID() { return db.getOrgID(); }
	public String getUserOrg() { return db.getUserOrg(); }


	public String getHiddenValues() {
		String HiddenValues = "";
		if(view == null) return HiddenValues;
		if(!view.getName().equals("FILTER")) {
			HiddenValues = "<input type='hidden' name='view' value='" + viewKey + "'/>\n";
			HiddenValues += "<input type='hidden' name='data' value='" + dataItem + "'/>\n";
		}

		return HiddenValues;
	}

	public String getHiddenValues(HttpServletRequest request) {
		String HiddenValues = "";
		
		String field = request.getParameter("field");
		String formlinkdata = request.getParameter("formlinkdata");
		
		if(field != null) {
			HiddenValues = "<input type='hidden' name='field' value='" + field + "'/>\n";
			HiddenValues += "<input type='hidden' name='formlinkdata' value='" + formlinkdata + "'/>\n";
		}

		return HiddenValues;
	}

	public String submitGrid(HttpServletRequest request) {
		String responce = "";
		
		String tbName = view.getAttribute("updatetable");
		String editKey = view.getAttribute("keyfield");

		for(BElement el : view.getElements()) {
			if(el.getName().equals("EDITFIELD")) {
				String name = el.getValue();
				String prms = request.getParameter(name);

				if(prms != null) {
					String paps[] = prms.split(":");
					for(String pap : paps) {
						
						String mysql = "UPDATE " + tbName + " SET " + name + " = '" + pap + "'";
						if(view.getAttribute("auditid") != null) {
							String autoKeyID = db.insAudit(tbName, pap, "EDIT");
							mysql += ", " + view.getAttribute("auditid") + " = " + autoKeyID;
						}
						mysql += " WHERE " + editKey + " = '" + pap + "'";
				
log.severe("BASE : " + mysql);
						//responce = db.executeQuery(mysql);
					}
				}
			}
		}

		return responce;
	}

	public void getReport(HttpServletResponse response) {
		StringBuffer csvhtml = new StringBuffer();

		boolean fs = true;
		for(BElement el : view.getElements()) {
			if(!el.getValue().equals("")) {
				if(fs) fs = false;
				else csvhtml.append(",");
				csvhtml.append(csvFormat(el.getAttribute("title")));
			}
		}
		csvhtml.append("\n");

		BQuery rs = new BQuery(db, view, null, null);
		rs.reset();
		while(rs.moveNext()) {
			fs = true;
			for(BElement el : view.getElements()) {
				if(!el.getValue().equals("")) {
					if(fs) fs = false;
					else csvhtml.append(",");
					csvhtml.append(csvFormat(rs.getString(el.getValue())));
				}
			}
			csvhtml.append("\n");
		}

		response.setContentType("text/x-csv");
		response.setHeader("Content-Disposition", "attachment; filename=report.csv");

		try {
			PrintWriter hpw = response.getWriter();
			hpw.println(csvhtml.toString());
			hpw.close();
		} catch (IOException ex) {
			log.severe("IO Error : " + ex);
		}
	}
	
	public String getExport(HttpServletRequest request, HttpServletResponse response) {
		String body = "";
		if(view.getName().equals("GRID")) {
			if(view.getAttribute("export", "csv").equals("csv")) {
				body = getCsv(request, response);
			} else if(view.getAttribute("export", "csv").equals("xml")) {
				body = getXml(request, response);
			}
		} else if(view.getName().equals("CROSSTAB")) {
			body = getCsv(request, response);
		}
		return body;
	}

	public String getCsv(HttpServletRequest request, HttpServletResponse response) {
		HttpSession session = request.getSession(true);
		String body = "";
		wheresql = null;
		sortby = null;

		// Call the where create function
		Map<String, String> whereParams = getWhere(request);
		wheresql = whereParams.get("wheresql");
		
		BElement sview = null;
		comboField = request.getParameter("field");
		if(comboField != null) sview = view.getElement(comboField).getElement(0);
		
		response.setContentType("text/x-csv");
		response.setHeader("Content-Disposition", "attachment; filename=report.csv");

		if(view.getName().equals("GRID")) {
			BQuery csvData = new BQuery(db, view, wheresql, sortby);
			body = csvData.getCsv();
			csvData.close();
		} else if(view.getName().equals("CROSSTAB")) {
			BCrossTab ct = new BCrossTab(db, view, wheresql, sortby);
			body = ct.getCsv();
			ct.close();
		}

		return body;
	}
	
	public String getXml(HttpServletRequest request, HttpServletResponse response) {
		HttpSession session = request.getSession(true);
		String body = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
		wheresql = null;
		sortby = null;
		
		Map<String, String> whereParams = getWhere(request);
		wheresql = whereParams.get("wheresql");
		
		response.setContentType("text/xml");
		response.setHeader("Content-Disposition", "attachment; filename=report.xml");
		
		BElement tableXml = new BElement(view.getAttribute("name"));
		getXmlTable(tableXml, view, wheresql, sortby);
		if(tableXml.getNodeNumber() == 1) {
			tableXml = tableXml.getFirst();
			if(tableXml != null) body += tableXml.toString();
		} else {
			body += tableXml.toString();
		}
		
		return body;
	}
	
	public BElement getXmlTable(BElement tableXml, BElement tView, String tWhere, String tSortby) {
		BQuery xmlData = new BQuery(db, tView, tWhere, tSortby, false);
		String ifNull = view.getAttribute("ifnull", "");
		
		while(xmlData.moveNext()) {
			BElement rowXml = new BElement(tView.getAttribute("name"));
			for(BElement el : tView.getElements()) {
				if(el.getName().equals("GRID")) {
					String sWhere = el.getAttribute("linkfield") + " = '" + xmlData.getKeyField() + "'";
					getXmlTable(rowXml, el, sWhere, null);
				} else if(el.getAttribute("hide") == null) {
					String nodeName = el.getAttribute("title");
					if(el.getAttribute("xml.node") != null) nodeName = xmlData.getString(el.getAttribute("xml.node"));
					BElement xel = new BElement(nodeName);
					String elValue = xmlData.getString(el.getValue());
					if(elValue == null) elValue = ifNull;
					xel.setValue(elValue);
					
					if(tView.getAttribute("xml.intable") == null) rowXml.addNode(xel);
					else tableXml.addNode(xel);
				}
			}
			
			if(tView.getAttribute("xml.intable") == null) tableXml.addNode(rowXml);
		}
		xmlData.close();
		
		return tableXml;
	}
	
	public String csvFormat(String lans) {
		String ans = "";
		if(lans != null) {
			if(lans.indexOf(",")>=0) ans = "\"" + lans + "\"";
			else ans = lans;
		}
		return ans;
	}

	public String getSearchReturn() {
		String searchReturn = view.getAttribute("return");
		if(searchReturn == null) searchReturn = view.getAttribute("keyfield");
		return searchReturn;
	}

	public void setSelectAll() {
		selectAll = true;
	}

	public String getAudit() {
		int vds = viewKeys.size();
		String linkData = null;
		String myaudit = null;
		if(vds > 2) linkData = viewData.get(vds - 1);

		if(linkData != null) {
			String mysql = "SELECT entitys.entity_name, sys_audit_trail.user_id, sys_audit_trail.change_date, ";
			mysql += "sys_audit_trail.change_type, sys_audit_trail.user_ip ";
			if(db.getDBType() == 1) mysql += "FROM sys_audit_trail LEFT JOIN entitys ON sys_audit_trail.user_id  = CAST(entitys.entity_id as varchar) ";
			else mysql += "FROM sys_audit_trail LEFT JOIN entitys ON sys_audit_trail.user_id  = entitys.entity_id ";
			mysql += "WHERE (sys_audit_trail.table_name = '" + view.getAttribute("table") + "') ";
			mysql += "AND (sys_audit_trail.record_id = '" + linkData + "')";

			String mytitles[] = {"Done By", "ID", "Done On", "Change", "Source"};
			BQuery auditQuery = new BQuery(db, mysql, -1);
			auditQuery.setTitles(mytitles);
			auditQuery.readData(-1);
			myaudit = auditQuery.readDocument(true, false);
		}

		return myaudit;
	}

	public String showFooter() {
		String lblFt = "";
		
		int kl = views.size();
		if(kl > 2) {
			lblFt = "\n<ul class='breadcrumb' data-disabled='true'>";
			for(int j = 1; j < kl-1; j++) {
				String keyField = views.get(j).getAttribute("keyfield", "");
				String key = viewData.get(j+1);

				if(!"[new]".equals(key) && !views.get(j).getName().equals("FILTER")) {
					BQuery ft = new BQuery(db, views.get(j), keyField + " = '" + key + "'", null);
					lblFt += "\n<li><a href='#'><b>" + ft.getFooter() + "</b></a></li>";
					ft.close();
				}
			}
			lblFt += "\n</ul>";
		}

		return lblFt;
	}

	public String getCalendar() {

		String events = "";

		events += getEvents(view);
		for(BElement el : view.getElements()) {
			if(el.getName().equals("DIARY")) {
				String event = getEvents(el);
				if(!event.equals("")) {
					if(events.equals("")) events += getEvents(el);
					else events += ", " + getEvents(el);
				}
			}
		}

		events = " events: [" + events + "]\n";

		return events;
	}

	public String getEvents(BElement eventView) {
		String events = "";

		String wherefilter = null;
		if((eventView.getAttribute("linkfield") != null) && (dataItem != null)) 
			wherefilter = eventView.getAttribute("linkfield") + "='" + dataItem + "'";

		BQuery crs = new BQuery(db, eventView, wherefilter, null, false);
		boolean isFf = true;

		while(crs.moveNext()) {
			if(isFf) isFf = false;
			else events += ",\n";

			events += "{";
			events += "id: " + crs.readField(1);
			String calTitle = crs.readField(2);
			if(calTitle == null) calTitle = "";
			events += ", title: '" + calTitle.replace("'", "");
			events += "', start: '" + crs.readField(3) + " " + crs.readField(4);
			events += "', end: '" + crs.readField(5) + " " + crs.readField(6);
			events += "', allDay: " + crs.readField(7);
			
			if(eventView.getAttribute("color")==null) events += ", backgroundColor: Metronic.getBrandColor('silver') ";
			else  events += ", backgroundColor: Metronic.getBrandColor('" + eventView.getAttribute("color") + "') ";

			events += "}";
		}

		return events;
	}

	public String receivePhoto(HttpServletRequest request, String tmpPath) {
		String pictureFile = "";

		int yourMaxMemorySize = 262144;
		File yourTempDirectory = new File(tmpPath);
		DiskFileItemFactory factory = new DiskFileItemFactory(yourMaxMemorySize, yourTempDirectory);
		ServletFileUpload upload = new ServletFileUpload(factory);
		
		try {
			List items = upload.parseRequest(request);
			Iterator itr = items.iterator();
			while(itr.hasNext()) {
				FileItem item = (FileItem) itr.next();
				if (item.isFormField() && item.getFieldName().equals("field")) {
					pictureField = item.getString();
				}
			}

			BElement el = view.getElement(pictureField);
			long maxfs = (Long.valueOf(el.getAttribute("maxfilesize", "2097152"))).longValue(); 
			if(el.getAttribute("h") != null) pictureURL = "<img height='" + el.getAttribute("h") + "' width='auto' ";
			pictureURL += "src='" + el.getAttribute("pictures") + "?access=" + el.getAttribute("access");

			String repository = el.getAttribute("repository");
			String username = el.getAttribute("username");
			String password = el.getAttribute("password");
			BWebdav webdav = new BWebdav(repository, username, password);
			//webdav.listDir("");

			Iterator ftr = items.iterator();
			while(ftr.hasNext()) {
				FileItem item = (FileItem) ftr.next();
				if (!item.isFormField()) {
					String contentType = item.getContentType();
					String fieldName = item.getFieldName();
					String fileName = item.getName();
					long fs = item.getSize();

					String ext = null;
					int i = fileName.lastIndexOf('.');
					if(i>0 && i<fileName.length()-1) 
						ext = fileName.substring(i+1).toLowerCase();
					if(ext == null) ext = "NAI";
					pictureFile = db.executeFunction("SELECT nextval('picture_id_seq')");
					pictureFile += "pic." + ext;
					pictureURL += "&picture=" + pictureFile + "'>";

					String[] imageTypes = {"JPEG", "JPG", "JFIF", "TIFF", "TIF", "GIF", "BMP", "PNG"};
					ext = ext.toUpperCase().trim();
					if(Arrays.binarySearch(imageTypes, ext) >= 0) {
						if(fs < maxfs) webdav.saveFile(item.getInputStream(), pictureFile);
						else pictureFile = "";
					} else {
						pictureFile = "";
					}
				}
			}
		} catch (FileUploadException ex) {
			pictureFile = "";
			System.out.println("File upload exception " + ex);
		}  catch(IOException ex) {
			pictureFile = "";
			System.out.println("File saving failed Exception " + ex);
		}

		if(pictureFile == null) pictureURL = "";

		return pictureFile;
	}

	public String getSaveMsg() { 
		String sMsg = "";
		if(saveMsg != null) {
			if(!saveMsg.equals("")) sMsg = "<div style='color:#FF0000; font-size:14px; font-weight:bold;'>" + saveMsg + "</div>";
		}
		return sMsg; 
	}

	public String getMenuMsg(String xmlFile) { 
		String mySql = "SELECT msg FROM sys_menu_msg WHERE (menu_id = '" + viewKey + "') AND (xml_file = '" + xmlFile + "')";
		String sMsg = db.executeFunction(mySql);

		if(sMsg == null) sMsg = "";
		else sMsg = "<div style='color:#0000FF; font-size:12px; font-weight:bold;'>" + sMsg + "</div>";

		return sMsg; 
	}
	
	public String getJSONHeader() {
		JsonObjectBuilder jshd = Json.createObjectBuilder();
		JsonArrayBuilder jsColNames = Json.createArrayBuilder();
		JsonArrayBuilder jsColModel = Json.createArrayBuilder();
		
		if(view.getAttribute("superuser", "false").equals("true")) {
			if(!db.getUser().getSuperUser()) return "";
		}
		
		boolean hasAction = false;
		boolean hasSubs = false;
		boolean hasTitle = false;
		boolean hasFilter = false;
		int col = 0;
		for(BElement el : view.getElements()) {
			if(!el.getValue().equals("")) {
				JsonObjectBuilder jsColEl = Json.createObjectBuilder();
				String mydn = el.getValue();
				if(!el.getValue().equals("")) jsColNames.add(el.getAttribute("title", ""));
				jsColEl.add("name", mydn);
				jsColEl.add("width", Integer.valueOf(el.getAttribute("w", "50")));
				if(el.getName().equals("EDITFIELD")) {
					jsColEl.add("editable", true);
					
					if(el.getAttribute("edittype") != null) jsColEl.add("edittype", el.getAttribute("edittype"));
					if(el.getAttribute("editoptions") != null) {
						JsonObjectBuilder jsColElVal = Json.createObjectBuilder();
						jsColElVal.add("value", el.getAttribute("editoptions"));
						jsColEl.add("editoptions", jsColElVal);
					}
				}
				jsColModel.add(jsColEl);
			}
			
			if(el.getName().equals("ACTIONS")) hasAction = true;
			if(el.getName().equals("GRID") || el.getName().equals("FORM") || el.getName().equals("JASPER")) hasSubs = true;
			if(el.getName().equals("ACCORDION") || el.getName().equals("FILES") || el.getName().equals("DIARY")) hasSubs = true;
			if(el.getName().equals("COLFIELD") || el.getName().equals("TITLEFIELD")) hasTitle = true;
			if(el.getName().equals("FILTERGRID")) hasFilter = true;
		}
		
		JsonObjectBuilder jsColEl = Json.createObjectBuilder();
		jsColNames.add("CL");
		jsColEl.add("name", "CL");
		jsColEl.add("width", 5);
		jsColEl.add("hidden", true);
		jsColModel.add(jsColEl);
		
		JsonObjectBuilder jsColKF = Json.createObjectBuilder();
		jsColNames.add("KF");
		jsColKF.add("name", "KF");
		jsColKF.add("width", 5);
		jsColKF.add("hidden", true);
		jsColModel.add(jsColKF);
		
		String jUrl = view.getAttribute("url", "jsondata");
		
		jshd.add("url", jUrl);
		jshd.add("datatype", "json");
		jshd.add("mtype", "GET");
		jshd.add("colNames", jsColNames);
		jshd.add("colModel", jsColModel);
		jshd.add("pager", "#jqpager");
		jshd.add("viewrecords", true);
		jshd.add("gridview", true);
		jshd.add("autoencode", true);
		jshd.add("autowidth", true);
		jshd.add("sortable", true);
		if(view.getAttribute("ssort") == null) jshd.add("loadonce", true);
		else jshd.add("loadonce", false);
		JsonObject jsObj = jshd.build();
		
		//System.out.println("BASE 2030 : " + jsObj.toString());

		return jsObj.toString();
	}

	public String getViewName() {
		if(view == null) return "";
		return view.getAttribute("name", ""); 
	}
	
	public String getViewType() {
		if(view == null) return "";
		return view.getName(); 
	}
	
	public String getViewColour() {
		String viewColor = "purple";
		if(root == null) return viewColor;
		viewColor = root.getAttribute("color", "purple");
		if(view == null) return viewColor;
		return view.getAttribute("color", viewColor); 
	}
    
    public String getViewIcon() {
		String viewIcon = "icon-list";
		if(root == null) return viewIcon;
		if(view == null) return viewIcon;
        if(view.getName().equals("GRID")) viewIcon = "icon-list";
        if(view.getName().equals("FORM")) viewIcon = "icon-note";
        if(view.getName().equals("JASPER")) viewIcon = "icon-doc";
		return view.getAttribute("icon", viewIcon); 
	}
	

	public String getButtonNav() {
		if(root == null) return null;
		if(view == null) return null;
		return view.getAttribute("button.nav");
	}
	
	public boolean hasPasswordChange() {
		if(root == null) return false;
		if(root.getAttribute("password") == null) return false;
        return true;
	}
	
	public String getEncType() {
		if(view == null) return "";
		if(!view.getName().equals("FORM")) return "";
		if(view.getElementByName("PICTURE") == null) return ""; 
		return " enctype=\"multipart/form-data\" ";
	}

	public boolean hasChildren() {
		boolean hasSubs = false;
		for(BElement el : view.getElements()) {
			if(el.getName().equals("GRID") || el.getName().equals("FORM") || el.getName().equals("JASPER")) hasSubs = true;
			if(el.getName().equals("FILES") || el.getName().equals("DIARY") || el.getName().equals("FORMVIEW")) hasSubs = true;
			if(el.getName().equals("ACCORDION") || el.getName().equals("CROSSTAB")) hasSubs = true;
		}

		return hasSubs;
	}
	
	public String getFilterStatus() {
		String filterStatus = "";
		
		String filterSN = "F" + viewKey;
		if(webSession.getAttribute(filterSN) != null) {
			String filterKSN = "";
			if(webSession.getAttribute("K" + filterSN) != null) filterKSN = (String)webSession.getAttribute("K" + filterSN);
			String wDataItem = "";
			if(dataItem != null) wDataItem = dataItem;
			
			if(filterKSN.equals(wDataItem)) filterStatus = "Filtered";
			else webSession.removeAttribute(filterSN);
		}
		
		return filterStatus;
	}
	
	public boolean isDiary() {
		boolean elDiary = false;
		if(view.getName().equals("DIARY")) elDiary = true;
		return elDiary;
	}

	public boolean isForm() {
		boolean elForm = false;
		if(view.getName().equals("FORM")) elForm = true;
		return elForm;
	}

	public boolean isEditField() {
		boolean editField = false;
		if(view.getElementByName("EDITFIELD") != null) editField = true;
		return editField;
	}
	
    public boolean isFileImport() {
		boolean fileImport = false;
		if(root == null) return fileImport;
		if(view == null) return fileImport;
		if(view.getAttribute("new", "true").equals("false")) return fileImport;
		if(view.getName().equals("FILES")) {
			fileImport = true;
        } else if(view.getName().equals("GRID")) {
			if(view.getAttribute("import") != null) fileImport = true;
        }
		return fileImport; 
	}
    
	public boolean isMaterial() {
		if(root == null) return false;
		if(root.getAttribute("material", "false").equals("true")) return true;
        return false;
	}
	
	public boolean hasExpired() {
		return isExpired;
	}
	
	public boolean getLicense() {
		return isLicense;
	}
	
	public boolean hasLicense() {
		isLicense = true;		
		return isLicense;
	}
	
	public String getAccordionJs() { return accordionJs; }
	public boolean isGrid() { if(view.getName().equals("GRID")) return true; return false; }
	public String getPictureField() { return pictureField; }
	public String getPictureURL() { return pictureURL; }
	public BDB getDB() { return db; }
	public String executeFunction(String mysql) { return db.executeFunction(mysql); }
	public String getUserID() { return db.getUserID(); }
	public BUser getUser() { return db.getUser(); }
	public void setReadOnly(boolean readOnly) { db.setReadOnly(readOnly); }
	public String executeQuery(String mysql) { return db.executeQuery(mysql); }
	
	public BQuery getQuery(String mysql) { return new BQuery(db, mysql); }
	
	public boolean hasDashboardItem(String dashboardItem) {return dashboardItems.containsKey(dashboardItem); }
	public String getDashboardItem(String dashboardItem) {
		if(!dashboardItems.containsKey(dashboardItem)) return "{}";
		return dashboardItems.get(dashboardItem); 
	}

	public BElement getRoot() { return root; }
	public BElement getView() { return view; }
	public String getViewKey() { return viewKey; }
	public List<String> getViewData() { return viewData; }
	public String getDataItem() { return dataItem; }

	public void close() {
		db.close();
	}

}
