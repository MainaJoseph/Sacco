/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.ide;

import java.awt.BorderLayout;
import java.awt.GridLayout;
import javax.swing.JLabel;
import javax.swing.JTextField;
import javax.swing.JButton;
import javax.swing.JPanel;
import javax.swing.JOptionPane;
import javax.swing.JFrame;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

import org.baraza.utils.Bio;
import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;

public class BSetup implements ActionListener {

	String ps;
	String path;
	JPanel panel;
	JTextField ftUserName, ftPassword;
	JLabel lbStatus;
	BXML xml;
	BElement root;
	
	public BSetup(String path) {
		ps = System.getProperty("file.separator");
		this.path = path;
		String setupXML = path + ps + "setup.xml";
		xml = new BXML(setupXML, false);
		root = xml.getRoot();
	}
	
	public void runSetup(String filename) {
		String dbUserName = root.getAttribute("dbusername");
		String dbPassword = root.getAttribute("dbpassword");
		
		String err = createDB(filename, dbUserName, dbPassword);
		if(err != null) System.out.println(err);
		else System.out.println("Database creation successfull.");
	}

	public void runUISetup() {
		String dbUserName = root.getAttribute("dbusername");
		String dbPassword = root.getAttribute("dbpassword");

		panel = new JPanel(new GridLayout(0, 2, 2, 2));

		lbStatus = new JLabel("Baraza Setup");
		JLabel lbUserName = new JLabel("User Name : ");
		ftUserName = new JTextField(dbUserName);

		JLabel lbPassword = new JLabel("Password : ");
		ftPassword = new JTextField(dbPassword);

		JButton btTest = new JButton("Test Connection");
		JButton btSave = new JButton("Save Configuration");
		JButton btDemo = new JButton("Create Demo");
		JButton btNew = new JButton("Create New");

		btTest.addActionListener(this);
		btSave.addActionListener(this);
		btDemo.addActionListener(this);
		btNew.addActionListener(this);

		panel.add(lbUserName);
		panel.add(ftUserName);
		panel.add(lbPassword);
		panel.add(ftPassword);

		panel.add(btTest);
		panel.add(btSave);
		panel.add(btDemo);
		panel.add(btNew);

		JFrame frame = new JFrame("Baraza Setup");
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		frame.getContentPane().add(panel, BorderLayout.CENTER);
		frame.getContentPane().add(lbStatus, BorderLayout.PAGE_END);
		frame.setLocation(200, 200);
		frame.setSize(400, 150);
		frame.setVisible(true);
	}

	public void saveConfigs(String dbUserName, String dbPassword) {
		root.setAttribute("dbusername", dbUserName);
		root.setAttribute("dbpassword", dbPassword);
		xml.saveFile();

		String configXML = path + ps + "config.xml";
		BXML cfgxml = new BXML(configXML, false);
		BElement cfg = cfgxml.getRoot();
		cfg.setAttribute("dbusername", dbUserName);
		cfg.setAttribute("dbpassword", dbPassword);
		for(BElement cel : cfg.getElements()) {
			cel.setAttribute("dbusername", dbUserName);
			cel.setAttribute("dbpassword", dbPassword);
		}
		cfgxml.saveFile();

		String webXML = "..";
		if(root.getAttribute("web") == null) webXML = "webapps" + ps +"baraza";
		webXML += ps + "META-INF" + ps + "context.xml";
		
		if(root.getAttribute("context") != null) {
			webXML = "projects" + ps + root.getAttribute("path") + ps;
			webXML += "configs" + ps + root.getAttribute("context");
		}
		
		BXML webxml = new BXML(webXML, false);
		BElement web = webxml.getRoot();
		for(BElement wel : web.getElements()) {
			if("org.apache.catalina.realm.JDBCRealm".equals(wel.getAttribute("className"))) {
				wel.setAttribute("connectionName", dbUserName);
				wel.setAttribute("connectionPassword", dbPassword);
			}
			if("jdbc/database".equals(wel.getAttribute("name"))) {
				wel.setAttribute("username", dbUserName);
				wel.setAttribute("password", dbPassword);
			}
		}
		webxml.saveFile();
	}

	public String createDB(String filename, String dbUserName, String dbPassword) {
		String err = null;

		BDB db = new BDB(root, dbUserName, dbPassword);
		if(db.getDB() != null) {
			err = db.executeFunction("SELECT rolname FROM pg_roles WHERE rolname = 'root';");
			if(err == null) db.executeQuery("CREATE ROLE root LOGIN;");
			
			db.executeQuery("DROP DATABASE " + root.getAttribute("dbname"));
			err = db.executeQuery("CREATE DATABASE " + root.getAttribute("dbname"));
		}
		db.close();

		BDB ndb = new BDB(root.getAttribute("dbclass"), root.getAttribute("newdbpath"), dbUserName, dbPassword);
		if((ndb.getDB() != null) && (err == null)) {
			String ps = System.getProperty("file.separator");
			String fpath = "projects" + ps + root.getAttribute("path") + ps + "database" + ps + "setup" + ps + filename;

			Bio io = new Bio();
			String mysql = io.loadFile(fpath);
			err = ndb.executeQuery(mysql);
		}
		ndb.close();
	
		return err;
	}

	public void actionPerformed(ActionEvent ev) {
		String aKey = ev.getActionCommand();

		if("Test Connection".equals(aKey)) {
			BDB db = new BDB(root, ftUserName.getText(), ftPassword.getText());
			if(db.getDB() == null) lbStatus.setText("Connection Error");
			else lbStatus.setText("Connection Successfull");
			db.close();
		} else if("Save Configuration".equals(aKey)) {
			saveConfigs(ftUserName.getText(), ftPassword.getText());
			lbStatus.setText("Configurations Saved");
		} else if("Create Demo".equals(aKey)) {
			lbStatus.setText("The process will take a while to complete.");
			int n = JOptionPane.showConfirmDialog(panel, "This will delete existing database, are you sure you want to proceed?", "Demo Database", JOptionPane.YES_NO_OPTION);
			if(n == 0) {
				String err = createDB("demo.sql", ftUserName.getText(), ftPassword.getText());
				
				if(err != null) {
					JOptionPane.showMessageDialog(panel, "Database creation error : " + err);
					lbStatus.setText(err);
					lbStatus.repaint();
				} else {
					JOptionPane.showMessageDialog(panel, "Database creation successfull.");
					lbStatus.setText("Database creation successfull.");
					lbStatus.repaint();
				}
			} else {
				lbStatus.setText("Baraza Setup");
			}
		} else if("Create New".equals(aKey)) {
			lbStatus.setText("The process will take a while to complete.");
			int n = JOptionPane.showConfirmDialog(panel, "This will delete existing database, are you sure you want to proceed?", "New Database", JOptionPane.YES_NO_OPTION);
			if(n == 0) {
				String err = createDB("setup.sql", ftUserName.getText(), ftPassword.getText());
				
				if(err != null) {
					JOptionPane.showMessageDialog(panel, "Database creation error : " + err);
					lbStatus.setText(err);
					lbStatus.repaint();
				} else {
					JOptionPane.showMessageDialog(panel, "Database creation successfull.");
					lbStatus.setText("Database creation successfull.");
					lbStatus.repaint();
				}
			} else {
				lbStatus.setText("Baraza Setup");
			}
		}
		
		lbStatus.repaint();
	}

	public static void main(String args[]) {
		String path = "projects";
		if (args.length == 1) {
			path = args[0].trim();
			BSetup st = new BSetup(path);
			st.runUISetup();
		} else if (args.length == 2) {
			path = args[0].trim();
			BSetup st = new BSetup(path);
			st.runSetup(args[1].trim());
		} else {
			BSetup st = new BSetup(path);
			st.runUISetup();
		}
	}
}

 
