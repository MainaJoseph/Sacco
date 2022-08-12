/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.web;

import java.util.Iterator;
import java.util.List;
import java.util.ArrayList;
import java.io.File;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.FileOutputStream;
import java.io.IOException;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import javax.json.Json;
import javax.json.JsonObject;
import javax.json.JsonObjectBuilder;
import javax.json.JsonArrayBuilder;

import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.DB.BImportVector;
import org.baraza.utils.BWebdav;
import org.baraza.xml.BElement;

public class BWebFiles extends HttpServlet {
	BWeb web = null;
	BWebdav webdav = null;
	BElement view = null;
	BDB db = null;
	BQuery query = null;
	String fileTable = null;
	String linkField = null;
	String linkValue = null;
	String userField = null;
	String folder = null;
	long maxfs = 0;

	public void doPost(HttpServletRequest request, HttpServletResponse response)  {
		doGet(request, response);
	}

	public void doGet(HttpServletRequest request, HttpServletResponse response) {
		String sp = request.getServletPath();
		configure(request);
		
		String resp = null;
		if(view.getName().equals("GRID")) {
			resp = importFile(request);
		} if(view.getName().equals("FILES")) {
			if(sp.equals("/barazafiles")) getFile(request, response);
			if(sp.equals("/webdavfiles")) getWebDavFile(request, response);
			if(sp.equals("/putbarazafiles")) resp = receiveFile(request);
			if(sp.equals("/delbarazafiles")) delFile(request, response);
		}
		
		if(resp != null) {
			response.setContentType("application/json;charset=\"utf-8\"");
			try { 
				PrintWriter out = response.getWriter();
				out.println(resp);
			} catch(IOException ex) {}
		}
			
		// Close initialisations
		query.close();
		web.close();
	}

	public void configure(HttpServletRequest request) {
		ServletContext context = this.getServletContext();
		HttpSession session = request.getSession(true);
		String dbconfig = "java:/comp/env/jdbc/database";
		String xmlcnf = xmlcnf = (String)session.getAttribute("xmlcnf");
		String ps = System.getProperty("file.separator");
		String xmlfile = context.getRealPath("WEB-INF") + ps + "configs" + ps + xmlcnf;
		String projectDir = context.getInitParameter("projectDir");
		if(projectDir != null) xmlfile = projectDir + ps + "configs" + ps + xmlcnf;
		
		String webPath = "http://" + request.getLocalAddr() + ":" + request.getLocalPort();

		web = new BWeb(dbconfig, xmlfile);
		web.init(request);

		view = web.getView();

		maxfs = (Long.valueOf(view.getAttribute("maxfilesize", "16777216"))).longValue(); 
		fileTable = view.getAttribute("filetable");
		linkField = view.getAttribute("linkfield");
		userField = view.getAttribute("user");
		linkValue = web.getDataItem();

		if(view.getName().equals("FILES")) {
			String repository = webPath + view.getAttribute("repository");
			String username = view.getAttribute("username");
			String password = view.getAttribute("password");
			folder = view.getAttribute("folder");
			if(repository != null) webdav = new BWebdav(repository, username, password);

System.out.println("BASE 1020 : " + repository);
		}

		db = web.getDB();
		query = new BQuery(db, view, null, null, false);

		System.out.println(linkValue);
	}
	
	
	public String importFile(HttpServletRequest request) {
		String resp = "{\"success\": 0, \"message\": \"Upload Failed\"}";
		JsonObjectBuilder jshd = Json.createObjectBuilder();
		
		int yourMaxMemorySize = 262144;
		
		ServletContext sc = getServletContext();
		String tmpPath = sc.getRealPath("/WEB-INF/tmp");
		File yourTempDirectory = new File(tmpPath);
		String fileName = null;
		
		// Create a factory for disk-based file items
		DiskFileItemFactory factory = new DiskFileItemFactory(yourMaxMemorySize, yourTempDirectory);

		// Create a new file upload handler
		ServletFileUpload upload = new ServletFileUpload(factory);

		try {
			String orgID = db.getOrgID();
			String userOrg = db.getUserOrg();
			
			List items = upload.parseRequest(request);
			Iterator itr = items.iterator();
			while(itr.hasNext()) {
				FileItem item = (FileItem) itr.next();

				if (item.isFormField()) {
					String name = item.getFieldName();
					String value = item.getString();
					System.out.println(name + " = " + value);
				} else {
					String contentType = item.getContentType();
					String fieldName = item.getFieldName();
					fileName = item.getName();
					long fs = item.getSize();
					
					if(fs < maxfs) {
System.out.println("BASE IMPORT 1410 : " + fileName);
						String importType = view.getAttribute("import");
						BImportVector iv = new BImportVector(view);
						
						if(importType.equals("excel")) {
							String worksheet = view.getAttribute("worksheet", "0");
							Integer firstRow = new Integer(view.getAttribute("firstrow", "0"));
							iv.getExcelData(item.getInputStream(), fileName, worksheet, firstRow);
						} else if(importType.equals("text")) {
							iv.getTextData(item.getInputStream());
						} else if(importType.equals("record")) {
							iv.getRecordData(item.getInputStream());
						}
						query.importData(iv.getData());
						iv.close();
						
						jshd.add("success", 1);
						jshd.add("name", item.getName());
						jshd.add("size", item.getSize());
						jshd.add("message", "Process File");
						JsonObject jsObj = jshd.build();
						resp = jsObj.toString();
					}
				}
			}
		} catch (FileUploadException ex) {
			System.out.println("File upload exception " + ex);
		} catch(IOException ex) {
			System.out.println("File saving failed IO Exception " + ex);
		}  catch(Exception ex) {
			System.out.println("File saving failed Exception " + ex);
		}
		
System.out.println("BASE IMPORT 1420 : " + resp);

		return resp;
	}

	public String receiveFile(HttpServletRequest request) {
		String resp = "{\"success\": 0, \"message\": \"Upload Failed\"}";

		int yourMaxMemorySize = 262144;
		
		ServletContext sc = getServletContext();
		String tmpPath = sc.getRealPath("/WEB-INF/tmp");
		File yourTempDirectory = new File(tmpPath);
		
		// Create a factory for disk-based file items
		DiskFileItemFactory factory = new DiskFileItemFactory(yourMaxMemorySize, yourTempDirectory);

		// Create a new file upload handler
		ServletFileUpload upload = new ServletFileUpload(factory);

		try {
			List items = upload.parseRequest(request);
			Iterator itr = items.iterator();
			while(itr.hasNext()) {
				FileItem item = (FileItem) itr.next();

				if (item.isFormField()) {
					String name = item.getFieldName();
					String value = item.getString();
					System.out.println(name + " = " + value);
				} else {
					String contentType = item.getContentType();
					String fieldName = item.getFieldName();
					String fileName = item.getName();
					long fs = item.getSize();

					if(fs < maxfs) {
System.out.println("BASE 1410 : " + fileName);
						String orgID = db.getOrgID();
						String userOrg = db.getUserOrg();
						String userID = db.getUserID();
System.out.println("BASE 1420 : " + orgID + " : " + userOrg + " : " + userID);
						query.recAdd();
						query.updateField("file_name", fileName);
						if(linkField != null) query.updateField(linkField, linkValue);
						if(userField != null) query.updateField(userField, userID);
						if(fileTable != null) query.updateField("table_name", fileTable);
						if(contentType != null) query.updateField("file_type", contentType);
						if(orgID != null) query.updateField(orgID, userOrg);
						query.updateField("file_size", String.valueOf(fs));

						String ext = ".dat";
						if(fileName.lastIndexOf(".")>0) ext = fileName.substring(fileName.lastIndexOf("."));
						if(ext == null) ext = ".dat";
						
						query.recSave();
						String folder_name = "";
						if(folder != null) {
							folder_name = query.getString(folder) + "/";
System.out.println("BASE 1420 : " + folder_name);
							if(!webdav.fileExists(folder_name)) webdav.createDir(folder_name);
							webdav.listDir(folder_name);
						}
						String wdfn = folder_name + query.getKeyField() + "ob" + ext;

System.out.println("BASE 1440 : " + wdfn);

						webdav.saveFile(item.getInputStream(), wdfn);
					}
				}
			}
			resp = "{\"success\": 1, \"message\": \"Upload Sucessful\"}";
		} catch (FileUploadException ex) {
			System.out.println("File upload exception " + ex);
		} catch(IOException ex) {
			System.out.println("File saving failed IO Exception " + ex);
		}  catch(Exception ex) {
			System.out.println("File saving failed Exception " + ex);
		}

		return resp;
	}

	public void getFile(HttpServletRequest request, HttpServletResponse response) {
		String wdfn = request.getParameter("fileid");

		if(wdfn != null) {
			query.filter(query.getKeyFieldName() + " = '" + wdfn + "'", null);
			query.moveFirst();
			String folder_name = "";
			if(folder != null) 	folder_name = query.getString(folder) + "/";
			String fileName = query.readField("file_name");
			String ext = ".dat";
			if(fileName.lastIndexOf(".")>0) ext = fileName.substring(fileName.lastIndexOf("."));
			if(ext == null) ext = ".dat";
			wdfn = folder_name + wdfn + "ob" + ext;
System.out.println("BASE 1520 : " + wdfn);

			response.setHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
			try {
				InputStream in = webdav.getFile(wdfn);
				OutputStream out = response.getOutputStream();

				int size = in.available();
				byte[] content = new byte[1024];
				int c;
				while ((c = in.read(content)) != -1) out.write(content, 0, c);

				out.close();
				in.close();
			} catch (IOException ex) {
				System.out.println("IO Error : " + ex);
			}
		}
	}

	public void getWebDavFile(HttpServletRequest request, HttpServletResponse response) {
		String wdfn = request.getParameter("filename");

		if(wdfn != null) {
			System.out.println("BASE 1010 : " + wdfn);

			int lifn = wdfn.lastIndexOf("/");
			String repository = wdfn.substring(0, lifn - 1);
			String fileName = wdfn.substring(lifn, wdfn.length());
System.out.println("Repository : "  + repository);
System.out.println("File : "  + fileName);
			String username = view.getAttribute("username");
			String password = view.getAttribute("password");
			webdav = new BWebdav(repository, username, password);

			response.setHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
			try {
				InputStream in = webdav.getFile(wdfn);
				OutputStream out = response.getOutputStream();

				int size = in.available();
				byte[] content = new byte[size];
				int c;
				while ((c = in.read(content)) != -1) out.write(content);

				out.close();
				in.close();
			} catch (IOException ex) {
				System.out.println("IO Error : " + ex);
			}
		}
	}

	public String delFile(HttpServletRequest request, HttpServletResponse response) {
		String resp = "{\"success\": 0, \"message\": \"Delete Failed\"}";
		
		String wdfn = request.getParameter("fileid");
		System.out.println("BASE 1010 : " + wdfn);

		if(wdfn != null) {
			query.filter(query.getKeyFieldName() + " = '" + wdfn + "'", null);
			query.moveFirst();
			String folder_name = "";
			if(folder != null) 	folder_name = query.getString(folder) + "/";
			String fileName = query.readField("file_name");
			String ext = ".dat";
			if(fileName.lastIndexOf(".")>0) ext = fileName.substring(fileName.lastIndexOf("."));
			if(ext == null) ext = ".dat";
			wdfn = folder_name + wdfn + "ob" + ext;

			query.recDelete();
			webdav.delFile(wdfn);
			
			resp = "{\"success\": 1, \"message\": \"Delete Sucessful\"}";
		}
		
		try {
			String referer = request.getHeader("Referer");
System.out.println("Referer : "  + referer);
			response.sendRedirect(referer);
		} catch(IOException ex) {
			System.out.println("IO Error : " + ex);
		}
		
		return resp;
	}

}

