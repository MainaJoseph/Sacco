/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.DB;

import java.util.logging.Logger;
import java.util.List;
import java.util.ArrayList;
import java.util.Vector;
import java.text.DecimalFormat;

import java.io.FileReader;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.FileInputStream;
import java.io.IOException;

import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.openxml4j.exceptions.InvalidFormatException;

import org.baraza.xml.BElement;

public class BImportVector {
	Logger log = Logger.getLogger(BImportVector.class.getName());
	List<String> columnTitle;
	List<Integer> columnWidth;
	List<Integer> dataWidth;
	Vector<Vector<Object>> rows;

	String sql;
	String delimiter = null;

	String keyfield;
	List<String> keylist;

	public BImportVector(BElement view) {
		columnTitle = new ArrayList<String>();
		columnWidth = new ArrayList<Integer>();
		dataWidth = new ArrayList<Integer>();
		rows = new Vector<Vector<Object>>();
		
		delimiter = view.getAttribute("delimiter");

		for(BElement el : view.getElements()) {
			if(el.getAttribute("title") != null) {
				columnTitle.add(el.getAttribute("title"));
				columnWidth.add(Integer.valueOf(el.getAttribute("w")));
				dataWidth.add(Integer.valueOf(el.getAttribute("dw", "0")));
			}
       	}
	}

 	public String getColumnName(int col) {
		return columnTitle.get(col);
	}

	public int getRowCount() {
		return rows.size();
	}

	public int getColumnCount() {
		return columnTitle.size();
	}

    public Object getValueAt(int aRow, int aColumn) {
        Vector<Object> row = rows.elementAt(aRow);
        return row.elementAt(aColumn);
    }

	public boolean isCellEditable(int row, int col) {
		return false;
	}

	public void setValueAt(Object value, int row, int col) {
		Vector<Object> dataRow = rows.elementAt(row);
		dataRow.setElementAt(value.toString(), col);
	}

	public void getTextData(InputStream input) { // Get all rows.
		rows.removeAllElements();

		if(delimiter==null) delimiter = ",";

		try {
			BufferedReader reader = new BufferedReader(new InputStreamReader(input));

			String myline = "";
			do {
				myline = reader.readLine();
				if(myline != null) {
					int x = myline.indexOf("\"");
					while (x >= 0) {
						x = myline.indexOf("\"");
						int l = myline.length();
						int y = -1;
						if (x>=0) { 
							y = myline.indexOf("\"", x + 1);
							if(y>x) {
								String newline = myline.substring(0, x) + myline.substring(x+1, y).replace(",", "") + myline.substring(y+1, l);
								//System.out.println(newline);
								myline = newline;
							}
						}
					}
					
					String[] mytokens = myline.split(delimiter);
					
					if(mytokens.length>0) {
						Vector<Object> myvec = new Vector<Object>();
						for (int j=0;j<getColumnCount();j++) {
							if(j < mytokens.length) myvec.add(getstrvalue(mytokens[j]));
							else myvec.add("");
						}
						rows.add(myvec);
					}
				}
			} while (myline != null);

			if (input != null) input.close();
		} catch (IOException ex) {
			System.out.println("File error.");
		}
	}

	public void getRecordData(InputStream input) { // Get all rows.
		rows.removeAllElements();

		try {
			BufferedReader reader = new BufferedReader(new InputStreamReader(input));
			int mdw = 0;
			for(Integer dw : dataWidth) mdw += dw;

			String myline = "";
			do {
				myline = reader.readLine();
				if(myline != null) {
					if (myline.length()==mdw) {
						int sp = 0;
						Vector<Object> myvec = new Vector<Object>();
						for(Integer dw : dataWidth) {
							String mytoken = myline.substring(sp, sp+dw);
							sp += dw;
							myvec.add(mytoken.trim());
						}
						rows.add(myvec);
					}
				}
			} while (myline != null);

			if (input != null) input.close();
		} catch (IOException ex) {
			log.severe("File error : " + ex);
		}
	}

	public void getExcelData(InputStream input, String fileName, String worksheet, Integer firstRow) { // Get all rows.
		rows.removeAllElements();
		
		Workbook wb = null;
		try {
			if(fileName.indexOf(".xlsx")>1) wb = new XSSFWorkbook(input);
		    else if(fileName.indexOf(".xls")>1) wb = new HSSFWorkbook(input);
		} catch (IOException ex) {
			log.severe("an I/O error occurred, or the InputStream did not provide a compatible POIFS data structure : " + ex);
		}

		Sheet sheet = wb.getSheetAt(Integer.valueOf(worksheet));
		Row row = null;
		int i = 0;
		if(firstRow < sheet.getFirstRowNum()) firstRow = sheet.getFirstRowNum();
		String myline = "";
		for(i = firstRow; i <= sheet.getLastRowNum(); i++) {
			Vector<Object> myvec = new Vector<Object>();
			row = sheet.getRow(i);
			if(row != null)  {
				myline = getCellValue(row, 0);

				//System.out.println(myline);
				for (int j=0;j<getColumnCount();j++)
					myvec.add(getCellValue(row, j));
				if(!myline.equals(""))
					rows.add(myvec);
			} else myline = "";
		}
	}
	
	public String numberFormat(double cellVal) {
		DecimalFormat formatter = new DecimalFormat("############.###");
		return formatter.format(cellVal);
	}

	public void clearupload() {
		rows.removeAllElements();
	}

	public String getstrvalue(String mystr) {
		String newstr = mystr.replaceAll("\"", "").trim();

		return newstr;
	}

	public String getCellValue(Row row, int column) {
		String mystr = "";

		Cell cell = row.getCell(column);
		if (cell == null) cell = row.createCell(column);
		if (cell.getCellType() == cell.CELL_TYPE_STRING) {
			if(cell.getStringCellValue()!=null)
				mystr += cell.getStringCellValue().trim();
		} else if (cell.getCellType() == cell.CELL_TYPE_NUMERIC) {
			mystr += numberFormat(cell.getNumericCellValue());
		} else if (cell.getCellType() == cell.CELL_TYPE_FORMULA) {
			if(cell.getCachedFormulaResultType() == Cell.CELL_TYPE_NUMERIC) {
				mystr += numberFormat(cell.getNumericCellValue());
			} else if(cell.getCachedFormulaResultType() == Cell.CELL_TYPE_STRING) {
				mystr += cell.getRichStringCellValue();
			}
		}

		return mystr;
	}

	public Vector<Vector<Object>> getData() {
		return rows;
	}

	public void close() {}
}
