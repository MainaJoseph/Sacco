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

public class BCrossSet {

	Map<String, Integer> columns;
	Map<String, Integer> rows;
	Map<Integer, Object> setTable;
	
	public BCrossSet(Vector<Vector<Object>> dataTable) {
		columns = new HashMap<String, Integer>();
		rows = new HashMap<String, Integer>();
		setTable = new HashMap<Integer, Object>();
		
		int j = 0;
		for(Vector<Object> data : dataTable) {
			String col0 = ""; if(data.get(0) != null) col0 = data.get(0).toString();
			String col1 = ""; if(data.get(1) != null) col1 = data.get(1).toString();
			String col2 = ""; if(data.get(2) != null) col2 = data.get(2).toString();
			j++;
			
			Integer column = columns.size();
			if(!columns.containsKey(col0)) columns.put(col0, column);
			column = columns.get(col0);
			
			Integer row = rows.size();
			if(!rows.containsKey(col1)) rows.put(col1, row);
			row = rows.get(col1);
			
			setTable.put((row * 64) + column, col2);
		}
	}
	
	public Vector<Object> getRowData(String key) {
		Vector<Object> data = new Vector<Object>();
		Integer row = rows.get(key);
		if(row == null) {
			for(String colKey : columns.keySet()) 
				data.add(null);
		} else {
			for(String colKey : columns.keySet()) {
				Integer column = columns.get(colKey);
				Object cellData = setTable.get((row * 64) + column);
				data.add(cellData);
			}
		}
		return data;
	}
	
	public String getColTitles() {
		StringBuffer myhtml = new StringBuffer();
		for(String colKey : columns.keySet()) 
			myhtml.append("<th>" + colKey + "</th>");
		return myhtml.toString();
	}
	
	public String getRowHtml(Object key) {
		StringBuffer myhtml = new StringBuffer();
		String sKey = "";
		if(key != null) sKey = key.toString();
		Integer row = rows.get(key);
		
		if(row == null) {
			for(String colKey : columns.keySet()) 
				myhtml.append("<td></td>");
		} else {
			for(String colKey : columns.keySet()) { 
				Integer column = columns.get(colKey);
				Object cellData = setTable.get((row * 64) + column);
				
				if(cellData == null) myhtml.append("<td></td>");
				else myhtml.append("<td>" + cellData.toString() + "</td>");
			}
		}
		
		return myhtml.toString();
	}
	
	public String getCsvTitles() {
		StringBuffer myCsv = new StringBuffer();
		for(String colKey : columns.keySet()) 
			myCsv.append("," + getCsvValue(colKey));
		return myCsv.toString();
	}
	
	public String getRowCsv(Object key) {
		StringBuffer myCsv = new StringBuffer();
		String sKey = "";
		if(key != null) sKey = key.toString();
		Integer row = rows.get(key);
		
		if(row == null) {
			for(String colKey : columns.keySet()) 
				myCsv.append(",");
		} else {
			for(String colKey : columns.keySet()) { 
				Integer column = columns.get(colKey);
				myCsv.append("," + getCsvValue(setTable.get((row * 64) + column)));
			}
		}
		
		return myCsv.toString();
	}
	
	public Map<String, Integer> getColumns() {
		return columns;
	}
	
	public Map<String, Integer> getRows() {
		return rows;
	}

	public String getCsvValue(Object cellVal) {
		String mystr = "";
		if(cellVal!=null) {
			if(cellVal.toString().startsWith("0")) mystr = "\"'" + cellVal.toString() + "\"";
			else mystr = "\"" + cellVal.toString() + "\"";
		}

		return mystr;
    }
}
