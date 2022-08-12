/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.utils;

import java.util.Base64;
import java.security.Key;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.SecureRandom;
import java.security.MessageDigest;
import java.security.Signature;
import java.security.spec.ECGenParameterSpec;
import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import java.security.NoSuchAlgorithmException;
import java.io.UnsupportedEncodingException;


public class BCipher {

	public static String encrypt(String secret, String plainText) {
		String codedText = "";

		try {
			SecretKey key = new SecretKeySpec(secret.getBytes(), "DES");
			Cipher cipher = Cipher.getInstance("DES");

			cipher.init(Cipher.ENCRYPT_MODE, key);
			byte[] cipherText = cipher.doFinal(plainText.getBytes());
			codedText = Base64.getEncoder().encodeToString(cipherText);
		} catch(java.security.NoSuchAlgorithmException ex) {
			System.out.println("Error; No such Algorithim : " + ex);
		} catch(javax.crypto.NoSuchPaddingException ex) {
			System.out.println("Error; no such padding : " + ex);
		} catch(java.security.InvalidKeyException ex) {
			System.out.println("Error; invalid key : " + ex);
		} catch(javax.crypto.IllegalBlockSizeException ex) {
			System.out.println("Error; Illegal block : " + ex);
		} catch(javax.crypto.BadPaddingException ex) {
			System.out.println("Error; Bad padding : " + ex);
		}

		return codedText;
	}

	public static String decrypt(String secret, String codedText) {
		String decodedText = "";

		try {
			SecretKey key = new SecretKeySpec(secret.getBytes(), "DES");
			Cipher cipher = Cipher.getInstance("DES");

			byte[] encypted = Base64.getDecoder().decode(codedText.getBytes());
			cipher.init(Cipher.DECRYPT_MODE, key);
			byte[] decrypted = cipher.doFinal(encypted); 
			decodedText = new String(decrypted);
		} catch(java.security.NoSuchAlgorithmException ex) {
			System.out.println("Error; No such Algorithim : " + ex);
		} catch(javax.crypto.NoSuchPaddingException ex) {
			System.out.println("Error; no such padding : " + ex);
		} catch(java.security.InvalidKeyException ex) {
			System.out.println("Error; invalid key : " + ex);
		} catch(javax.crypto.IllegalBlockSizeException ex) {
			System.out.println("Error; Illegal block : " + ex);
		} catch(javax.crypto.BadPaddingException ex) {
			System.out.println("Error; Bad padding : " + ex);
		}

		return decodedText;
	}
		
	public static String MD5(String planpw) {
		try {
			MessageDigest md = MessageDigest.getInstance("MD5");
			byte[] array = md.digest(planpw.getBytes());
			StringBuffer sb = new StringBuffer();
			for (int i = 0; i < array.length; ++i)
				sb.append(Integer.toHexString((array[i] & 0xFF) | 0x100).substring(1,3));
			return sb.toString();
		} catch (NoSuchAlgorithmException e) {
			return null;
		}
	}
	
	public static String password(String  planpw) {
		String hash = null;
		try {
			MessageDigest md = MessageDigest.getInstance("SHA-1"); 	// SHA-1 generator instance
			md.update(planpw.getBytes("UTF-8")); 					// Message summary generation
			byte raw[] = md.digest(); 								// Message summary reception
			hash = Base64.getEncoder().encodeToString(raw);			// Encoding to BASE64
			hash = hash.replace("\n", "");
		} catch(NoSuchAlgorithmException ex) {
			System.out.println("No algorithim : " + ex.getMessage());
		} catch(UnsupportedEncodingException ex) {
			System.out.println("Unsupported Encoding : " + ex.getMessage());
		}

		return hash;
	}
	
	public static String applySha256(String input) {
		try {
			MessageDigest digest = MessageDigest.getInstance("SHA-256");
			byte[] hash = digest.digest(input.getBytes("UTF-8"));    
			StringBuffer hexString = new StringBuffer();
			for (int i = 0; i < hash.length; i++) {
				String hex = Integer.toHexString(0xff & hash[i]);
				if(hex.length() == 1) hexString.append('0');
				hexString.append(hex);
			}
			return hexString.toString();
		} catch(Exception e) {
			throw new RuntimeException(e);
		}
	}
	
	//Applies ECDSA Signature and returns the result ( as bytes ).
	public static byte[] applyECDSASig(PrivateKey privateKey, String input) {
		Signature dsa;
		byte[] output = new byte[0];
		try {
			dsa = Signature.getInstance("ECDSA", "BC");
			dsa.initSign(privateKey);
			byte[] strByte = input.getBytes();
			dsa.update(strByte);
			byte[] realSig = dsa.sign();
			output = realSig;
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
		return output;
	}
	
	//Verifies a String signature 
	public static boolean verifyECDSASig(PublicKey publicKey, String data, byte[] signature) {
		try {
			Signature ecdsaVerify = Signature.getInstance("ECDSA", "BC");
			ecdsaVerify.initVerify(publicKey);
			ecdsaVerify.update(data.getBytes());
			return ecdsaVerify.verify(signature);
		} catch(Exception e) {
			throw new RuntimeException(e);
		}
	}
	
	public static KeyPair generateKeyPair() {
		KeyPair keyPair = null;
		try {
			KeyPairGenerator keyGen = KeyPairGenerator.getInstance("ECDSA","BC");
			SecureRandom random = SecureRandom.getInstance("SHA1PRNG");
			ECGenParameterSpec ecSpec = new ECGenParameterSpec("prime192v1");
			// Initialize the key generator and generate a KeyPair
			keyGen.initialize(ecSpec, random);   //256 bytes provides an acceptable security level
			keyPair = keyGen.generateKeyPair();
		} catch(Exception e) {
			throw new RuntimeException(e);
		}
		return keyPair;
	}
	
	public static String getStringFromKey(Key key) {
		return Base64.getEncoder().encodeToString(key.getEncoded());
	}
}
