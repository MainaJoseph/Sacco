/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.DB;

import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.Vector;

import org.baraza.xml.BElement;

public class BCrossTab {

	List<String> titles;
	List<String> fieldNames;
	List<String> keyFieldData;
	Vector<Vector<Object>> dataTable;
	
	BQuery baseRs;
	Map<String, BCrossSet> crosstabRs;
	BElement view;
	
	public BCrossTab(BDB db, BElement view, String wheresql, String sortby) {
		this.view = view;

		System.out.println("BASE : " + wheresql);
		System.out.println("BASE : " + view.toString());
	
		baseRs = new BQuery(db, view, wheresql, null);
		
		dataTable = new Vector<Vector<Object>>(); 
		titles = new ArrayList<String>();
		fieldNames = new ArrayList<String>();
		crosstabRs = new HashMap<String, BCrossSet>();
		for(BElement el : view.getElements()) {
			if(el.getName().equals("CROSSTAB")) {
				BQuery ctq = new BQuery(db, el, wheresql, null);
				BCrossSet cs = new BCrossSet(ctq.getData());
				crosstabRs.put(el.getAttribute("name"), cs);
				ctq.close();
				
				for(String csc : cs.getColumns().keySet()) titles.add(csc);
			} else {
				titles.add(el.getAttribute("title", ""));
				fieldNames.add(el.getValue());
			}
		}
	}
	
	public String getGrid(List<String> viewKeys, List<String> viewData, boolean addJSc, String viewKey, boolean sfield) {
		StringBuffer myhtml = new StringBuffer();
		
		int btSize = baseRs.getData().size();
		Vector<String> keyData = baseRs.getKeyFieldData();
System.out.println("BASE : size " + btSize);

		myhtml.append("<div class='table-scrollable'>\n");
		myhtml.append("<table id='crosstab' class='table table-striped table-bordered table-hover'>\n");

		myhtml.append("<thead><tr>");
		for(BElement el : view.getElements()) {
			if(el.getName().equals("CROSSTAB")) {
				BCrossSet cs = crosstabRs.get(el.getAttribute("name"));
				myhtml.append(cs.getColTitles());
			} else {
				myhtml.append("<th>" + el.getAttribute("title") + "</th>");
			}
		}
		myhtml.append("</tr></thead>\n");
		
		int j = 0;

		for(Vector<Object> data : baseRs.getData()) {
			Vector<Object> dataRow = new Vector<Object>();
			int i = 0;
			myhtml.append("<tr>");
			for(BElement el : view.getElements()) {
				if(el.getName().equals("CROSSTAB")) {
					BCrossSet cs = crosstabRs.get(el.getAttribute("name"));
					myhtml.append(cs.getRowHtml(keyData.get(j)));
				} else {
					if(data.get(i) == null) {
						myhtml.append("<td></td>");
					} else {
						String dv = data.get(i).toString();
						myhtml.append("<td>" + dv + "</td>");
					}
					i++;
				}
			}
			j++;
			myhtml.append("</tr>\n");
			dataTable.add(data);//dataRow);
		}
		myhtml.append("</table>\n");
		myhtml.append("</div>\n");
	
		return myhtml.toString();
	}
	
	public String getCsv() {
		StringBuffer myCsv = new StringBuffer();
		
		int btSize = baseRs.getData().size();
		Vector<String> keyData = baseRs.getKeyFieldData();
System.out.println("BASE : size " + btSize);

		int i = 0;
		for(BElement el : view.getElements()) {
			if(el.getName().equals("CROSSTAB")) {
				BCrossSet cs = crosstabRs.get(el.getAttribute("name"));
				myCsv.append(cs.getCsvTitles());
			} else {
				if(i!=0) myCsv.append(","); 
				myCsv.append(getCsvValue(el.getAttribute("title")));
			}
			i++;
		}
		myCsv.append("\n");
		
		int j = 0;
		for(Vector<Object> data : baseRs.getData()) {
			Vector<Object> dataRow = new Vector<Object>();
			i = 0;
			for(BElement el : view.getElements()) {
				if(el.getName().equals("CROSSTAB")) {
					BCrossSet cs = crosstabRs.get(el.getAttribute("name"));
					myCsv.append(cs.getRowCsv(keyData.get(j)));
				} else {
					if(i!=0) myCsv.append(","); 
					myCsv.append(getCsvValue(data.get(i)));
					i++;
				}
			}
			j++;
			myCsv.append("\n");
			dataTable.add(data);//dataRow);
		}
	
		return myCsv.toString();
	}

	public String getCsvValue(Object cellVal) {
		String mystr = "";
		if(cellVal!=null) {
			if(cellVal.toString().startsWith("0")) mystr = "\"'" + cellVal.toString() + "\"";
			else mystr = "\"" + cellVal.toString() + "\"";
		}

		return mystr;
    }
	
	// Close record sets
	public void close() {
		baseRs.close();
	}
}
