/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2018.0329
 * @since       3.2
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.blockchain;

public class BTransactionIn {

	public String transactionOutId; 	//Reference to TransactionOutputs -> transactionId
	public BTransactionOut UTXO; 		//Contains the Unspent transaction output
	
	public BTransactionIn(String transactionOutId) {
		this.transactionOutId = transactionOutId;
	}
	
}
