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
import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.io.File;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.IOException;
import  javax.xml.namespace.QName;

import com.github.sardine.Sardine;
import com.github.sardine.DavResource;
import com.github.sardine.SardineFactory;

public class BWebdav {
	Logger log = Logger.getLogger(Bio.class.getName());

	Sardine sardine = null;
	String basePath = null;

	public BWebdav(String path, String userName, String passWord) {
		if((path == null) || (userName == null)) return;
		basePath = path;
		try {
			sardine = SardineFactory.begin(userName, passWord);		
			List<DavResource> resources = sardine.list(basePath);
		} catch(IOException ex) {
			sardine = null;
			log.severe("File list error : " + ex);
		} catch(Exception ex) {
			sardine = null;
			log.severe("webdav error : " + ex);
		}
	}

	public void setPath(String path) {
		basePath = path;
	}

	public List<DavResource> listDir(String path) {
		List<DavResource> resources = new ArrayList<DavResource>();
		if(sardine == null) return resources;
		try {
			resources = sardine.list(basePath + path);
			for (DavResource res : resources)
				System.out.println(res); // calls the .toString() method.
		} catch(IOException ex) {
			log.severe("File list error : " + ex);
		}
		return resources;
	}

	public InputStream getFile(String fileName) {
		InputStream is = null;
		if(sardine == null) return is;
		try {
			is = sardine.get(basePath + fileName);
		} catch(IOException ex) {
			log.severe("File read error : " + ex);
		}
		return is;
	}

	public boolean saveFile(File file, String saveName) {
		if(sardine == null) return false;
		boolean isv = true;
		try {
			InputStream fis = new FileInputStream(file);
			sardine.put(basePath + saveName, fis);
		} catch(IOException ex) {
			isv = false;
			log.severe("File write error : " + ex);
		}
		return isv;
	}

	public boolean saveFile(InputStream fis, String saveName) {
		if(sardine == null) return false;
		boolean isv = true;
		try {
			sardine.put(basePath + saveName, fis);
		} catch(IOException ex) {
			isv = false;
			log.severe("File write error : " + ex);
		}
		return isv;
	}

	public boolean delFile(String fileName) {
		if(sardine == null) return false;
		boolean isv = true;
		try {
			sardine.delete(basePath + fileName);
		} catch(IOException ex) {
			isv = false;
			log.severe("File delete error : " + ex);
		}
		return isv;
	}

	public boolean createDir(String dirName) {
		if(sardine == null) return false;
		boolean isv = true;
		try {
			sardine.createDirectory(basePath + dirName);
		} catch(IOException ex) {
			isv = false;
			log.severe("Directory create error : " + ex);
		}
		return isv;
	}

	public boolean fileMove(String srcName, String dstName) {
		if(sardine == null) return false;
		boolean isv = true;
		try {
			sardine.move(basePath + srcName, basePath + dstName);
		} catch(IOException ex) {
			isv = false;
			log.severe("File move error : " + ex);
		}
		return isv;
	}

	public boolean fileCopy(String srcName, String dstName) {
		if(sardine == null) return false;
		boolean isv = true;
		try {
			sardine.copy(basePath + srcName, basePath + dstName);
		} catch(IOException ex) {
			isv = false;
			log.severe("File copy error : " + ex);
		}
		return isv;
	}

	public boolean fileExists(String fileName) {
		if(sardine == null) return false;
		boolean isv = true;
		try {
			isv = sardine.exists(basePath + fileName);
		} catch(IOException ex) {
			isv = false;
			log.severe("File Exists error : " + ex);
		}
		return isv;
	}

	public boolean setProperties(String fileName, Map<QName,String> addProps, List<QName> removeProps) {
		if(sardine == null) return false;
		boolean isv = true;
		try {
			sardine.patch(basePath + fileName, addProps, removeProps);
		} catch(IOException ex) {
			isv = false;
			log.severe("Set properties error : " + ex);
		}
		return isv;
	}
	
	public boolean isConnected() {
		if(sardine == null) return false;
		return true;
	}

	public Map<String,String> getProperties(DavResource resource) {
		Map<String,String> customProps = resource.getCustomProps();
		return customProps;
	}

}
