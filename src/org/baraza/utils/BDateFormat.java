/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.utils;

import java.util.logging.Logger;
import java.util.Date;
import java.text.SimpleDateFormat;
import java.text.ParsePosition;
import java.text.ParseException;
import java.lang.Number;

public class BDateFormat {

	static Logger log = Logger.getLogger(BDateFormat.class.getName());
	
	public static String parseDate(String mydate, String dbFormat, int dbType) {
		String dbdate = null;

		try {
			Date psdate = new Date();
			SimpleDateFormat dateParse = new SimpleDateFormat();
			if((mydate.indexOf('-')>0) && (mydate.indexOf(':')>0)) dateParse.applyPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
			else if(mydate.indexOf('/')>0) dateParse.applyPattern("dd/MM/yyyy");
			else if(mydate.indexOf('-')>0) dateParse.applyPattern("dd-MM-yyyy");
			else if(mydate.indexOf('.')>0) dateParse.applyPattern("dd.MM.yyyy");
			else if(mydate.indexOf(' ')>0) dateParse.applyPattern("MMM dd, yyyy");

			psdate = dateParse.parse(mydate);
			if(dbFormat != null) {
				dateParse.applyPattern(dbFormat);
			} else {
				if(dbType == 1) dateParse.applyPattern("yyyy-MM-dd");
				else dateParse.applyPattern("yyyy-MM-dd HH:mm:ss");
			}

			dbdate = dateParse.format(psdate);
		} catch(ParseException ex) { 
			log.severe("Date format error : " + ex); 
		}

		return dbdate;
	}
	
	public static String parseTimeStamp(String mydate) {
		String dbdate = null;
		try {
			Date psdate = new Date();
			SimpleDateFormat dateParse = new SimpleDateFormat();
			if((mydate.indexOf('-')>0) && (mydate.indexOf(':')>0)) dateParse.applyPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
			else if(mydate.indexOf('/')>0) dateParse.applyPattern("dd/MM/yyyy hh:mm a");
			else if(mydate.indexOf('-')>0) dateParse.applyPattern("dd-MM-yyyy hh:mm a");
			else if(mydate.indexOf('.')>0) dateParse.applyPattern("dd.MM.yyyy hh:mm a");
			else if(mydate.indexOf(' ')>0) dateParse.applyPattern("MMM dd, yyyy hh:mm a");

			psdate = dateParse.parse(mydate);
			dateParse.applyPattern("yyyy-MM-dd HH:mm:ss");
			dbdate = dateParse.format(psdate);
		} catch(ParseException ex) {
			log.severe("Date format error : " + ex); 
		}
		return dbdate;
	}

	public static String parseTime(String myTime, String timeType) {
		String dbdate = null;
		try {
			Date psdate = new Date();
			SimpleDateFormat dateParse = new SimpleDateFormat();
			if(timeType == null) timeType = "1";
			if(timeType.equals("2")) dateParse.applyPattern("HH:mm");
			else if(myTime.indexOf(':')>0) dateParse.applyPattern("hh:mm a");

			psdate = dateParse.parse(myTime);
			dateParse.applyPattern("HH:mm:ss");
			dbdate = dateParse.format(psdate);
		} catch(ParseException ex) {
			log.severe("Date format error : " + ex); 
		}
		return dbdate;
	}

	
}
