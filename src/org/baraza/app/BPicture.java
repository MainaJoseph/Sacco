/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.app;

import java.util.logging.Logger;
import java.io.File;

import javax.swing.Icon;
import javax.swing.ImageIcon;
import javax.swing.JLabel;
import javax.swing.JFileChooser;
import javax.swing.JOptionPane;
import java.net.URL;

import java.awt.event.MouseListener;
import java.awt.event.MouseEvent;

import org.baraza.xml.BElement;
import org.baraza.swing.BFileDialogueFilter;
import org.baraza.utils.BWebdav;
import org.baraza.DB.BDB;

public class BPicture extends JLabel implements MouseListener {
	Logger log = Logger.getLogger(BPicture.class.getName());
	
	String pictureFile = null;
	String pictureURL, pictureAccess;
	BDB db = null;	
	BWebdav webdav = null;

	public BPicture(BDB db, BElement el) {
		super();
		this.db = db;
		this.addMouseListener(this);
	
		pictureURL = org.baraza.utils.BPropeties.getParam("pictures_url", "http://localhost:9090/repository/barazapictures");
		pictureAccess = org.baraza.utils.BPropeties.getParam("photo_access", "ob");
		String repository = org.baraza.utils.BPropeties.getParam("repository_url", "http://localhost:9090/repository/webdav/pictures/");
		String username = org.baraza.utils.BPropeties.getParam("rep_username", "repository");
		String password = org.baraza.utils.BPropeties.getParam("rep_password", "baraza");

		webdav = new BWebdav(repository, username, password);
	}

	public void setPicture(String value) {
		if(value == null) {
			this.setText("Double click to add image");
			return;
		}
		pictureFile = value;
		String mypic = pictureURL + "?access=" + pictureAccess + "&picture=" + pictureFile;
		String html = "<html>\n<body>\n<div style=\"text-align: center;\">\n";
        html += "<img src='" + mypic + "'>\n";
        html += "</div>\n</body>\n</html>";

		try {
			this.setText(html);
		} catch(Exception ex) {
			log.severe("html pucture diplay error " + ex);
		}
	}
	
	public String getPicture() {
		return pictureFile;
	}

	public void readimage() {
		if((webdav == null) || (!webdav.isConnected())) {
			JOptionPane.showMessageDialog(this, "The file repository is not connected");
			return;
		}
		
		JFileChooser fc = new JFileChooser();
		String[] ffa = {"jpg", "jpeg", "gif"};
		BFileDialogueFilter ff = new BFileDialogueFilter(ffa, "Picure Images");
		fc.setFileFilter(ff);
		fc.setAcceptAllFileFilterUsed(false);
		int returnVal = fc.showOpenDialog(this);

        if (returnVal == JFileChooser.APPROVE_OPTION) {
			File file = fc.getSelectedFile();

			pictureFile = db.executeFunction("SELECT nextval('picture_id_seq')");
			pictureFile += "pic." + ff.getExtension(file);
			if(webdav.isConnected()) webdav.saveFile(file, pictureFile);

 			Icon icon = new ImageIcon(file.getPath());
			this.setIcon(icon);
		}
	}

    protected ImageIcon createImageIcon(String path, String description) {
        URL imgURL = getClass().getResource(path);
        if (imgURL != null) {
            return new ImageIcon(imgURL, description);
        } else {
            System.err.println("Couldn't find file: " + path);
            return null;
        }
    }

	public void mousePressed(MouseEvent ev) {}
	public void mouseReleased(MouseEvent ev) {}
	public void mouseEntered(MouseEvent ev) {}
	public void mouseExited(MouseEvent ev) {}
	public void mouseClicked(MouseEvent ev) {
		if (ev.getClickCount() == 2) {
			readimage();
		}
	}

}
