/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2018.0329
 * @since       3.2
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.blockchain;

import java.security.PrivateKey;
import java.security.PublicKey;
import java.util.List;
import java.util.ArrayList;

import org.baraza.utils.BCipher;

public class BTransaction {
	
	public String transactionId;			// this is also the hash of the transaction.
	public PublicKey sender;				// senders address/public key.
	public PublicKey reciepient;			// Recipients address/public key.
	public Float value;
	public byte[] signature; 				// this is to prevent anybody else from spending funds in our wallet.
	
	public List<BTransactionIn> inputs = new ArrayList<BTransactionIn>();
	public List<BTransactionOut> outputs = new ArrayList<BTransactionOut>();
	
	private static Integer sequence = 0; 		// a rough count of how many transactions have been generated. 
	
	// Constructor: 
	public BTransaction(PublicKey from, PublicKey to, Float value, List<BTransactionIn> inputs) {
		this.sender = from;
		this.reciepient = to;
		this.value = value;
		this.inputs = inputs;
	}
	
	// This Calculates the transaction hash (which will be used as its Id)
	private String calulateHash() {
		sequence++; 				//increase the sequence to avoid 2 identical transactions having the same hash
		String senderId = BCipher.getStringFromKey(sender);
		String reciepientId = BCipher.getStringFromKey(reciepient);

		return BCipher.applySha256(senderId + reciepientId + value.toString() + sequence.toString());
	}
}
