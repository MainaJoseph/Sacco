/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2018.0329
 * @since       3.2
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.blockchain;

import java.security.PublicKey;

import org.baraza.utils.BCipher;

public class BTransactionOut {
	public String id;
	public PublicKey reciepient; //also known as the new owner of these coins.
	public Float value; //the amount of coins they own
	public String parentTransactionId; //the id of the transaction this output was created in
	
	//Constructor
	public BTransactionOut(PublicKey reciepient, Float value, String parentTransactionId) {
		this.reciepient = reciepient;
		this.value = value;
		this.parentTransactionId = parentTransactionId;
		String reciepientId = BCipher.getStringFromKey(reciepient);
		this.id = BCipher.applySha256(reciepientId + value.toString() + parentTransactionId);
	}
	
	//Check if coin belongs to you
	public boolean isMine(PublicKey publicKey) {
		return (publicKey == reciepient);
	}
	
}
