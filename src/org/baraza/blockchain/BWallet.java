/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2018.0329
 * @since       3.2
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.blockchain;

import java.security.KeyPair;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.util.List;
import java.util.ArrayList;
import java.util.Date;
import org.baraza.utils.BCipher;

public class BWallet {

	public PrivateKey privateKey;
	public PublicKey publicKey;
	
	public BWallet() {
		KeyPair keyPair = BCipher.generateKeyPair();
		privateKey = keyPair.getPrivate();
		publicKey = keyPair.getPublic();
	}
}