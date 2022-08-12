/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2017.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.ide;

import java.util.Vector;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;

import org.baraza.xml.BXML;
import org.baraza.xml.BElement;


public class BVersions {

	public static void main(String args[]) {
		if(args.length == 1) {
			BVersions migration = new BVersions(args[0]);
		} else {
			System.out.println("java -cp ./baraza.jar org.baraza.ide.BVersions <xmlFile>");
		}
	}

	public BVersions(String xmlFile) {
		System.out.println("Baraza Versions - Processing : " + xmlFile);
		
		BXML xml = new BXML(xmlFile, false);
		BElement root = xml.getRoot();
		makeVersion(root);
	}
	
	public void makeVersion(BElement root) {
		for(BElement el : root.getElements()) {
			System.out.println("Processing : " + el.getAttribute("name"));
			BXML source = new BXML(el.getAttribute("source"), false);
			
			for(BElement action : el.getElements()) {
				System.out.println(action.getName());
				
				if(action.getName().equals("REMOVE")) {
					for(BElement node : action.getElements()) {
						System.out.println("\t" + node.getName() + " : " + node.getAttribute("name"));
						removeNode(source.getRoot().getElementByName("MENU"), node);
					}
				} else if(action.getName().equals("REPLACE")) {
					for(BElement node : action.getElements()) {
						System.out.println("\t" + node.getName() + " : " + node.getAttribute("name"));
						replaceNode(source.getRoot(), node);
					}
				}
			}
			
			source.saveFile(el.getAttribute("destination"));
		}
	}
	
	public void removeNode(BElement nodes, BElement dNodes) {
		for(BElement node : nodes.getElements()) {
			if(dNodes.getValue().trim().equals("")) {
				if(dNodes.getAttribute("name").equals(node.getAttribute("name"))) {
					nodes.delNode(node);
					return;
				} else if(!node.isLeaf()) {
					removeNode(node, dNodes);
				}
			} else {
				if(dNodes.getValue().equals(node.getValue())) {
					nodes.delNode(node);
					return;
				} else if(!node.isLeaf()) {
					removeNode(node, dNodes);
				}
			}
		}
	}
	
	public void replaceNode(BElement nodes, BElement newNode) {
		String key = newNode.getAttribute("key", "x");
		int pos = 0;
		for(BElement node : nodes.getElements()) {
			if(node.getAttribute("key", "y").equals(key)) {
				nodes.delNode(pos);
				nodes.addNode(newNode, pos);
				break;
			}
			pos++;
		}
	}

}

