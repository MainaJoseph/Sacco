/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2018.0329
 * @since       3.2
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.blockchain;

import java.util.Date;
import org.baraza.utils.BCipher;

public class BBlock {

	public String hash;
	public String previousHash; 
	private String data; 				//our data will be a simple message.
	private long timeStamp; 			//as number of milliseconds since 1/1/1970.
	private int nonce;

	//Block Constructor.
	public BBlock(String data,String previousHash ) {
		this.data = data;
		this.previousHash = previousHash;
		this.timeStamp = new Date().getTime();
		this.hash = calculateHash(); 				//Making sure we do this after we set the other values.
	}
	
	public String calculateHash() {
		String calculatedhash = BCipher.applySha256(previousHash + Long.toString(timeStamp) + data);
		return calculatedhash;
	}
	
	public void mineBlock(int difficulty) {
		String target = new String(new char[difficulty]).replace('\0', '0');
		while(!hash.substring(0, difficulty).equals(target)) {
			nonce ++;
			hash = calculateHash();
		}
		System.out.println("Block Mined!!! : " + hash);
	}
}