/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.utils;

public class BPropeties {

	public static String getParam(String paramName) {
		return System.getProperty(paramName);
	}

	public static String getParam(String paramName, String defaultValue) {
		return System.getProperty(paramName, defaultValue);
	}

}
