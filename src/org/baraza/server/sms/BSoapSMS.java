/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.sms;

import java.util.logging.Logger;
import java.util.Date;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.URL;
import java.net.MalformedURLException;
import java.text.SimpleDateFormat;
import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.KeyManagementException;
import java.security.cert.X509Certificate;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

import javax.xml.soap.SOAPConnectionFactory;
import javax.xml.soap.SOAPConnection;
import javax.xml.soap.MessageFactory;
import javax.xml.soap.SOAPMessage;
import javax.xml.soap.SOAPEnvelope;
import javax.xml.soap.SOAPHeader;
import javax.xml.soap.SOAPBody;
import javax.xml.soap.SOAPElement;
import javax.xml.soap.SOAPConstants;
import javax.xml.soap.SOAPException;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BElement;
import org.baraza.server.comm.BComm;
import org.baraza.utils.BNumberFormat;
import org.baraza.utils.BLogHandle;

/* Enviroments
	test Enviroment : 196.201.216.14
	live enviroment : 192.168.9.177, 192.168.9.140, 196.201.216.13
	*/

public class BSoapSMS {
	Logger log = Logger.getLogger(BSoapSMS.class.getName());
	BLogHandle logHandle;

	List<BComm> qcomms;

	String serverIP = null;
	String spPassword = null;
	String endPoint = null;
	String smsReceiver = null;
	String startCorrelator = null;
	Map<String, String[]> smsOrgs;

	BDB db = null; 
	int processdelay = 10000;
	boolean executing = false;

	public BSoapSMS(BDB db, BElement node, BLogHandle logHandle) {
		this.db = db;
		this.logHandle = logHandle;
		logHandle.config(log);

		spPassword = node.getAttribute("sppassword");
		endPoint = node.getAttribute("endpoint");
		serverIP = node.getAttribute("serverip", "192.168.9.177");
		smsReceiver = node.getAttribute("smsreceiver");
		startCorrelator = node.getAttribute("startCorrelator", "12345");
		processdelay = Integer.valueOf(node.getAttribute("processdelay", "10000")).intValue();

		String orgSQL = "SELECT org_id, sp_id, service_id, sender_name, sms_rate, send_fon FROM orgs WHERE (is_active = true) ORDER BY org_id";
		smsOrgs =  new HashMap<String, String[]>();
		BQuery orgRS = new BQuery(db, orgSQL);
		while(orgRS.moveNext()) {
			System.out.println("org_id : " + orgRS.getString("org_id"));

			String orgID = orgRS.getString("org_id");
			String[] orgParams = new String[5];
			orgParams[0] = orgRS.getString("sp_id");
			orgParams[1] = orgRS.getString("service_id");
			orgParams[2] = orgRS.getString("sender_name");
			orgParams[3] = orgRS.getString("sms_rate");
			orgParams[4] = orgRS.getString("send_fon");
			smsOrgs.put(orgID, orgParams);

			if(orgParams[0] != null) startListener(smsReceiver, orgID);
		}

		qcomms = new ArrayList<BComm>();
		for(BElement nd : node.getElements()) {
			if(nd.getName().equals("COMM")) qcomms.add(new BComm(db, nd, logHandle));
		}

		log.info("Starting Soap SMS Server.");
	}

	public int getDelay() { return processdelay; }

	public int process() {
		log.info("Soap SMS Processing...");
		executing = true;

		boolean dbValid = db.isValid();
		if(dbValid) {
			for(BComm qcomm : qcomms) qcomm.process();
			
			sendMessage();
		} else {
			db.reconnect();
		}

		executing = false;
		return processdelay;
	}

	public void sendMessage() {
		String mysql = "SELECT sms_id, sms_number, sms_numbers, message, folder_id, sent, number_error, address_group_id, linkid, org_id FROM sms ";
		mysql += "WHERE (folder_id = 0) AND (message_ready = true) AND (sent = false) AND (number_error = false)";
		BQuery rs = new BQuery(db, mysql);
		
		while(rs.moveNext()) {
			boolean isSent = true;
			boolean numberError = false;
			String msg = rs.getString("message");
			if(msg == null) msg = "";
			String number = rs.getString("sms_number");
			String numbers = rs.getString("sms_numbers");
			if(number == null) number = "";
			if(rs.getString("address_group_id") ==  null) {
				number = number.replace("\n", ",").replace("\r", "").replace("\"", "").replace("'", "").replace("/", "").replace("+", "").trim();
				if(number.startsWith("0")) number = "254" + number.substring(1, number.length());
				
				if((number.length() > 11) && (number.length() < 15) && BNumberFormat.isNumeric(number)) {
					isSent = sendSMS(number.trim(), msg, rs.getString("linkid"), rs.getString("sms_id"), rs.getString("org_id"), false);
				} else {
					numberError = true;
				}

				if(numbers != null) {
					numbers = numbers.replace("\n", ",").replace("\r", "").replace("\"", "").replace("'", "").replace("/", "").replace("+", "").trim();
					System.out.println("Sending messages for numbers : " + numbers);
					
					String[] nums = numbers.split(",");
					for(String num : nums) {
						if((num != null) && (num.length() > 3)) {
							num = num.replace("\n", ",").replace("\r", "").replace("\"", "").replace("'", "").replace("/", "").replace("+", "").trim();
							if(num.length() == 9) num = "254" + num;
							else if(num.startsWith("0")) num = "254" + num.substring(1, num.length());
							
							if((num.length() > 11) && (num.length() < 15) && BNumberFormat.isNumeric(num)) {
								isSent = sendSMS(num, msg, rs.getString("linkid"), rs.getString("sms_id"), rs.getString("org_id"), false);
							} else {
								numberError = true;
							}
						}
					}
					isSent = true;
				}
			}

			mysql = "SELECT sms_address.sms_address_id, address.mobile ";
			mysql += "FROM address INNER JOIN sms_address ON address.address_id = sms_address.address_id ";
			mysql += "WHERE (sms_address.sms_id	= " + rs.getString("sms_id") + ")";
			BQuery rsa = new BQuery(db, mysql);
			while(rsa.moveNext()) {
				number = rsa.getString("mobile");
				if(number == null) number = "";
				number = number.replace("\n", ",").replace("\r", "").replace("\"", "").replace("'", "").replace("/", "").replace("+", "").trim();
				if(number.startsWith("0")) number = "254" + number.substring(1, number.length());
				
				if((number.length() > 11) && (number.length() < 15) && BNumberFormat.isNumeric(number)) {
					isSent = sendSMS(number.trim(), msg, rs.getString("linkid"), rs.getString("sms_id"), rs.getString("org_id"), false);
				} else {
					numberError = true;
				}
				isSent = true;
			}
			rsa.close();

			mysql = "SELECT address_members.address_member_id, address.mobile ";
			mysql += "FROM address INNER JOIN address_members ON address.address_id = address_members.address_id ";
			mysql += "WHERE (address.table_name = 'sms') ";
			mysql += " AND (address_members.address_group_id = " + rs.getString("address_group_id") + ") ";
			BQuery rsg = new BQuery(db, mysql);
			while(rsg.moveNext()) {
				number = rsg.getString("mobile");
				if(number == null) number = "";
				number = number.replace("\n", ",").replace("\r", "").replace("\"", "").replace("'", "").replace("/", "").replace("+", "").trim();
				if(number.startsWith("0")) number = "254" + number.substring(1, number.length());
				
				if((number.length() > 11) && (number.length() < 15) && BNumberFormat.isNumeric(number)) {
					isSent = sendSMS(number.trim(), msg, rs.getString("linkid"), rs.getString("sms_id"), rs.getString("org_id"), false);
				} else {
					numberError = true;
				}
				isSent = true;
			}
			rsg.close();

			if(isSent) {
				rs.recEdit();		
				rs.updateField("sent", "true");
				rs.updateField("folder_id", "2");
				rs.recSave();
			}
			if(numberError) {
				rs.recEdit();		
				rs.updateField("number_error", "true");
				rs.recSave();
			}
		}
		rs.close();
	}

	public boolean sendSMS(String number, String message, String linkId, String smsID, String orgID, boolean isRetry) {
		boolean isSent = false;
		
		if(message == null) return isSent;
		if(smsOrgs.get(orgID)[1] == null) return isSent;
		if(smsOrgs.get(orgID)[2] == null) return isSent;
		
		int smsLen = message.length();
		Integer messageParts = new Integer(1);
		if(smsLen > 160) {
			messageParts = 1 + (smsLen / 153);
		}
		
		String mSql = "INSERT INTO sms_queue (sms_id, org_id, sms_number, message_parts, sms_price) VALUES (";
		mSql += smsID + "," + orgID + ", '" + number + "', " + messageParts.toString() + ", ";
		mSql += smsOrgs.get(orgID)[3] + ")";
		String correlator = db.executeAutoKey(mSql);
		String sendFon = smsOrgs.get(orgID)[4];
		
		int retry = 1;
		while(retry != 0) {
			if(retry > 1) System.out.println("MESSAGE RESENDING RETRY\n");
			String sendResults = null;
			
			boolean airtelNo = false;
			if(number.startsWith("25473") || number.startsWith("25475") || number.startsWith("25478")) airtelNo = true;
			
			if((sendFon != null) && airtelNo) {
				sendResults = sendOFSMS(number, message, linkId, smsID, orgID, correlator);
			} else {
				sendResults = sendSMS(number, message, linkId, smsID, orgID, correlator);
			}
			
			if(sendResults == null) {	// retry once for a error on the sending
				try { Thread.sleep(1000); } catch(InterruptedException ex) {}
				if(retry < 5) retry++;
				else retry = 0;
			} else if(sendResults.equals("SVC0901")) { // retry twice for a error on the sending
				try { Thread.sleep(2000); } catch(InterruptedException ex) {}
				if(retry < 10) retry++;
				else retry = 0;
			} else {
				db.executeUpdate("UPDATE sms_queue SET send_results = '" + sendResults + "' WHERE sms_queue_id = " + correlator);
				
				mSql = "UPDATE sms_configs SET send_code = '" + sendResults + "', last_sent = current_timestamp, ";
				if("POL0904".equals(sendResults)) mSql += "send_error = true, narrative = 'Need credit top up' ";
				else mSql += "send_error = false, narrative = null ";
				mSql += "WHERE sms_config_id  = 0";
				db.executeUpdate(mSql);
				
				retry = 0;
				isSent = true;
			}
		}
		
		return isSent;
	}
		
	public String sendSMS(String number, String message, String linkId, String smsID, String orgID, String correlator) {
		String spId = smsOrgs.get(orgID)[0];
		String serviceId = smsOrgs.get(orgID)[1];
		String senderName = smsOrgs.get(orgID)[2];
		String sendResults = null;
		
		if(serviceId == null) return sendResults;
		if(senderName == null) return sendResults;
	
		try {
			MessageFactory factory = MessageFactory.newInstance();
	
			SOAPMessage soapMessage = factory.createMessage();
			SOAPEnvelope soapEnvelope = soapMessage.getSOAPPart().getEnvelope();
			soapEnvelope.addNamespaceDeclaration("loc", "http://www.csapo.org/schema/parlayx/sms/send/v2_2/local");
			soapEnvelope.addNamespaceDeclaration("v2", "http://www.huawei.com.cn/schema/common/v2_1");

			SOAPHeader soadHeader = soapMessage.getSOAPHeader();
			SOAPBody soapBody = soapMessage.getSOAPBody();
						
			SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmmss");
			String fdt = sdf.format(new Date());
			String myPass = spId + spPassword + fdt;
			MessageDigest digest = MessageDigest.getInstance("MD5");
			digest.update(myPass.getBytes(), 0, myPass.length());
			String digestmd5 = new BigInteger(1, digest.digest()).toString(16);

			SOAPElement soapHeadElem = soadHeader.addChildElement("RequestSOAPHeader", "v2");
			SOAPElement soapHeadElem1 = soapHeadElem.addChildElement("spId", "v2");
			soapHeadElem1.addTextNode(spId);
			SOAPElement soapHeadElem2 = soapHeadElem.addChildElement("spPassword", "v2");
			soapHeadElem2.addTextNode(digestmd5);
			SOAPElement soapHeadElem3 = soapHeadElem.addChildElement("serviceId", "v2");
			soapHeadElem3.addTextNode(serviceId);
			SOAPElement soapHeadElem4 = soapHeadElem.addChildElement("timeStamp", "v2");
			soapHeadElem4.addTextNode(fdt);
			if(linkId != null) {
				SOAPElement soapHeadElem5 = soapHeadElem.addChildElement("linkid", "v2");
				soapHeadElem5.addTextNode(linkId);
			}
			SOAPElement soapHeadElem6 = soapHeadElem.addChildElement("OA", "v2");
			soapHeadElem6.addTextNode("tel:" + number);
			SOAPElement soapHeadElem7 = soapHeadElem.addChildElement("FA", "v2");
			soapHeadElem7.addTextNode("tel:" + number);

			SOAPElement soapBodyElem = soapBody.addChildElement("sendSms", "loc");
			SOAPElement soapBodyElem1 = soapBodyElem.addChildElement("addresses", "loc");
			soapBodyElem1.addTextNode("tel:" + number);
			SOAPElement soapBodyElem2 = soapBodyElem.addChildElement("senderName", "loc");
			soapBodyElem2.addTextNode(senderName);
			SOAPElement soapBodyElem3 = soapBodyElem.addChildElement("message", "loc");
			soapBodyElem3.addTextNode(message);
			SOAPElement soapBodyElem4 = soapBodyElem.addChildElement("receiptRequest", "loc");
			SOAPElement soapBodyElem41 = soapBodyElem4.addChildElement("endpoint");
			soapBodyElem41.addTextNode(endPoint);
			SOAPElement soapBodyElem42 = soapBodyElem4.addChildElement("interfaceName");
			soapBodyElem42.addTextNode("SmsNotification");
			SOAPElement soapBodyElem43 = soapBodyElem4.addChildElement("correlator");
			soapBodyElem43.addTextNode(correlator);
			
			String strMsg = getResp(soapMessage);
			System.out.println("MESSAGE\n" + strMsg + "\n");

			SOAPConnectionFactory scFactory = SOAPConnectionFactory.newInstance();
			SOAPConnection con = scFactory.createConnection();

			URL endpoint = new URL("http://" + serverIP + ":8310/SendSmsService/services/SendSms");
			SOAPMessage response = con.call(soapMessage, endpoint);
			if(response != null) {
				SOAPBody respBody = response.getSOAPBody();
				sendResults = respBody.getFirstChild().getFirstChild().getFirstChild().getNodeValue();
				
				System.out.println("RESPOSE\n" + getResp(response) + "\n");
				System.out.println("RESPOSE : " + sendResults + "\n");
			}
			con.close();
		} catch(SOAPException ex) {
			System.out.println("SOAP Error : " + ex);
		} catch(MalformedURLException ex) {
			System.out.println("Net Error : " + ex);
		} catch(NoSuchAlgorithmException ex) {
			System.out.println("No Algorithim Error : " + ex);
		}

		return sendResults;
	}
	
	
	public String sendOFSMS(String number, String message, String linkId, String smsID, String orgID, String correlator) {
		String spId = smsOrgs.get(orgID)[0];
		String serviceId = smsOrgs.get(orgID)[1];
		String senderName = smsOrgs.get(orgID)[2];
		String sendFon = smsOrgs.get(orgID)[4];
		String sendResults = null;
		
		if(serviceId == null) return sendResults;
		if(senderName == null) return sendResults;
	
		try {
			MessageFactory factory = MessageFactory.newInstance();
			
			SOAPMessage soapMessage = factory.createMessage();
			SOAPEnvelope soapEnvelope = soapMessage.getSOAPPart().getEnvelope();
			soapEnvelope.addNamespaceDeclaration("bul", "http://www.example.org/bulkSms/");

			SOAPHeader soadHeader = soapMessage.getSOAPHeader();
			SOAPBody soapBody = soapMessage.getSOAPBody();
			
			SOAPElement soapBodyElem = soapBody.addChildElement("SMSSubmitReq", "bul");
			SOAPElement soapBodyElem1 = soapBodyElem.addChildElement("Username");
			soapBodyElem1.addTextNode("cwtKenya");
			SOAPElement soapBodyElem2 = soapBodyElem.addChildElement("Password");
			soapBodyElem2.addTextNode("Cwtk3ny@");
			SOAPElement soapBodyElem3 = soapBodyElem.addChildElement("InterfaceID");
			soapBodyElem3.addTextNode("bk");
			
			SOAPElement soapBody2Elem = soapBodyElem.addChildElement("SmsRecord");
			SOAPElement soapBody2Elem1 = soapBody2Elem.addChildElement("SmsId");
			soapBody2Elem1.addTextNode(correlator);
			SOAPElement soapBody2Elem2 = soapBody2Elem.addChildElement("SmsRecipient");
			soapBody2Elem2.addTextNode(number);
			SOAPElement soapBody2Elem3 = soapBody2Elem.addChildElement("SmsText");
			soapBody2Elem3.addTextNode(message);
			SOAPElement soapBody2Elem4 = soapBody2Elem.addChildElement("SmsSenderId");
			soapBody2Elem4.addTextNode(sendFon);
			
			SOAPElement soapBody3Elem = soapBodyElem.addChildElement("ReportEnabled");
			soapBody3Elem.addTextNode("true");


			String strMsg = getResp(soapMessage);
			System.out.println("MESSAGE\n" + strMsg + "\n");

			SOAPConnectionFactory scFactory = SOAPConnectionFactory.newInstance();
			SOAPConnection con = scFactory.createConnection();
			
			TrustManager[] trustAllCerts = new TrustManager[] {
				new X509TrustManager() {
					public java.security.cert.X509Certificate[] getAcceptedIssuers() { return null; }
					public void checkClientTrusted(X509Certificate[] certs, String authType) {  }
					public void checkServerTrusted(X509Certificate[] certs, String authType) {  }
				}
			};
			SSLContext sc = SSLContext.getInstance("SSL");
			sc.init(null, trustAllCerts, new java.security.SecureRandom());
			HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
			HostnameVerifier allHostsValid = new HostnameVerifier() {
				public boolean verify(String hostname, SSLSession session) { return true; }
			};
			HttpsURLConnection.setDefaultHostnameVerifier(allHostsValid);
			
			URL endpoint = new URL("https://212.100.248.24:8080/smshttppush/index.php?wsdl");
			SOAPMessage response = con.call(soapMessage, endpoint);
			if(response != null) {
				SOAPBody respBody = response.getSOAPBody();
				sendResults = respBody.getFirstChild().getFirstChild().getFirstChild().getFirstChild().getNodeValue();
				
				System.out.println("RESPOSE2\n" + getResp(response) + "\n");
				System.out.println("RESPOSE3 : " + sendResults + "\n"); 
			} else {
				sendResults = null;
				System.out.println("FON ERROR : Not able to send SMS on FON");
			}
			con.close();
		} catch(SOAPException ex) {
			System.out.println("SOAP Error : " + ex);
		} catch(MalformedURLException ex) {
			System.out.println("Net Error : " + ex);
		} catch(KeyManagementException ex) {
			System.out.println("Key Error : " + ex);
		} catch(NoSuchAlgorithmException ex) {
			System.out.println("NoSuchAlgorithm Error : " + ex);
		}

		return sendResults;
	}
	
	public void smsStatus(String number, String requestIdentifier, String orgID) {
		String spId = smsOrgs.get(orgID)[0];
		String serviceId = smsOrgs.get(orgID)[1];
		String senderName = smsOrgs.get(orgID)[2];

		if(serviceId == null) return;
		if(senderName == null) return;
	
		try {
			MessageFactory factory = MessageFactory.newInstance(SOAPConstants.SOAP_1_2_PROTOCOL);
	
			SOAPMessage soapMessage = factory.createMessage();
			SOAPEnvelope soapEnvelope = soapMessage.getSOAPPart().getEnvelope();
			soapEnvelope.addNamespaceDeclaration("v2", "http://www.huawei.com.cn/schema/common/v2_1");
            soapEnvelope.addNamespaceDeclaration("loc", "http://www.csapo.org/schema/parlayx/sms/send/v2_2/local");

			SOAPHeader soadHeader = soapMessage.getSOAPHeader();
			SOAPBody soapBody = soapMessage.getSOAPBody();
						
			SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmmss");
			String fdt = sdf.format(new Date());
			String myPass = spId + spPassword + fdt;
			MessageDigest digest = MessageDigest.getInstance("MD5");
			digest.update(myPass.getBytes(), 0, myPass.length());
			String digestmd5 = new BigInteger(1, digest.digest()).toString(16);

			SOAPElement soapHeadElem = soadHeader.addChildElement("RequestSOAPHeader", "v2");
			SOAPElement soapHeadElem1 = soapHeadElem.addChildElement("spId", "v2");
			soapHeadElem1.addTextNode(spId);
			SOAPElement soapHeadElem2 = soapHeadElem.addChildElement("spPassword", "v2");
			soapHeadElem2.addTextNode(digestmd5);
			SOAPElement soapHeadElem3 = soapHeadElem.addChildElement("serviceId", "v2");
			soapHeadElem3.addTextNode(serviceId);
			SOAPElement soapHeadElem4 = soapHeadElem.addChildElement("timeStamp", "v2");
			soapHeadElem4.addTextNode(fdt);
			SOAPElement soapHeadElem5 = soapHeadElem.addChildElement("OA", "v2");
			soapHeadElem5.addTextNode("tel:" + number);
			SOAPElement soapHeadElem6 = soapHeadElem.addChildElement("FA", "v2");
			soapHeadElem6.addTextNode("tel:" + number);

			SOAPElement soapBodyElem = soapBody.addChildElement("getSmsDeliveryStatus", "loc");
			SOAPElement soapBodyElem1 = soapBodyElem.addChildElement("requestIdentifier", "loc");
			soapBodyElem1.addTextNode(requestIdentifier);
			SOAPElement soapBodyElem2 = soapBodyElem.addChildElement("senderName", "loc");
			soapBodyElem2.addTextNode(senderName);

			String strMsg = getResp(soapMessage);
			System.out.println("MESSAGE\n" + strMsg + "\n");

			SOAPConnectionFactory scFactory = SOAPConnectionFactory.newInstance();
			SOAPConnection con = scFactory.createConnection();

			URL endpoint = new URL("http://" + serverIP + ":8310/SendSmsService/services/SendSms");
			SOAPMessage response = con.call(soapMessage, endpoint);

			con.close();
			if(response != null) {
				strMsg = getResp(response);
				System.out.println("RESPOSE\n" + strMsg + "\n");
			}
		} catch(SOAPException ex) {
			System.out.println("SOAP Error : " + ex);
		} catch(MalformedURLException ex) {
			System.out.println("Net Error : " + ex);
		} catch(NoSuchAlgorithmException ex) {
			System.out.println("No Algorithim Error : " + ex);
		}		
	}

	public void smsReceive(String registrationIdentifier, String orgID) {
		String spId = smsOrgs.get(orgID)[0];
		String serviceId = smsOrgs.get(orgID)[1];
		String senderName = smsOrgs.get(orgID)[2];
		
		if(serviceId == null) return;
		if(senderName == null) return;
	
		try {
			MessageFactory factory = MessageFactory.newInstance(SOAPConstants.SOAP_1_2_PROTOCOL);
	
			SOAPMessage soapMessage = factory.createMessage();
			SOAPEnvelope soapEnvelope = soapMessage.getSOAPPart().getEnvelope();
			soapEnvelope.addNamespaceDeclaration("v2", "http://www.huawei.com.cn/schema/common/v2_1");
            soapEnvelope.addNamespaceDeclaration("loc", "http://www.csapo.org/schema/parlayx/sms/receive/v2_2/local");

			SOAPHeader soadHeader = soapMessage.getSOAPHeader();
			SOAPBody soapBody = soapMessage.getSOAPBody();
						
			SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmmss");
			String fdt = sdf.format(new Date());
			String myPass = spId + spPassword + fdt;
			MessageDigest digest = MessageDigest.getInstance("MD5");
			digest.update(myPass.getBytes(), 0, myPass.length());
			String digestmd5 = new BigInteger(1, digest.digest()).toString(16);

			SOAPElement soapHeadElem = soadHeader.addChildElement("RequestSOAPHeader", "v2");
			SOAPElement soapHeadElem1 = soapHeadElem.addChildElement("spId", "v2");
			soapHeadElem1.addTextNode(spId);
			SOAPElement soapHeadElem2 = soapHeadElem.addChildElement("spPassword", "v2");
			soapHeadElem2.addTextNode(digestmd5);
			SOAPElement soapHeadElem3 = soapHeadElem.addChildElement("serviceId", "v2");
			soapHeadElem3.addTextNode(serviceId);
			SOAPElement soapHeadElem4 = soapHeadElem.addChildElement("timeStamp", "v2");
			soapHeadElem4.addTextNode(fdt);
			
			SOAPElement soapBodyElem = soapBody.addChildElement("getReceivedSms", "loc");
			SOAPElement soapBodyElem1 = soapBodyElem.addChildElement("registrationIdentifier", "loc");
			soapBodyElem1.addTextNode(registrationIdentifier);
			SOAPElement soapBodyElem2 = soapBodyElem.addChildElement("senderName", "loc");
			soapBodyElem2.addTextNode(senderName);
			
			String strMsg = getResp(soapMessage);
			System.out.println("MESSAGE\n" + strMsg + "\n");

			SOAPConnectionFactory scFactory = SOAPConnectionFactory.newInstance();
			SOAPConnection con = scFactory.createConnection();

			URL endpoint = new URL("http://" + serverIP + ":8310/ReceiveSmsService/services/ReceiveSms");
			SOAPMessage response = con.call(soapMessage, endpoint);

			con.close();

			if(response != null) {
				strMsg = getResp(response);
				System.out.println("RESPOSE\n" + strMsg + "\n");
			}
		} catch(SOAPException ex) {
			System.out.println("SOAP Error : " + ex);
		} catch(MalformedURLException ex) {
			System.out.println("Net Error : " + ex);
		} catch(NoSuchAlgorithmException ex) {
			System.out.println("No Algorithim Error : " + ex);
		}		
	}

	public void startListener(String smsReceiver, String orgID) {
		String spId = smsOrgs.get(orgID)[0];
		String serviceId = smsOrgs.get(orgID)[1];
		String senderName = smsOrgs.get(orgID)[2];
		
		if(serviceId == null) return;
		if(senderName == null) return;

		try {
			MessageFactory factory = MessageFactory.newInstance(SOAPConstants.SOAP_1_2_PROTOCOL);
	
			SOAPMessage soapMessage = factory.createMessage();
			SOAPEnvelope soapEnvelope = soapMessage.getSOAPPart().getEnvelope();
			soapEnvelope.addNamespaceDeclaration("v2", "http://www.huawei.com.cn/schema/common/v2_1");
            soapEnvelope.addNamespaceDeclaration("loc", "http://www.csapo.org/schema/parlayx/sms/receive/v2_2/local");

			SOAPHeader soadHeader = soapMessage.getSOAPHeader();
			SOAPBody soapBody = soapMessage.getSOAPBody();			
			
			SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmmss");
			String fdt = sdf.format(new Date());
			String myPass = spId + spPassword + fdt;
			MessageDigest digest = MessageDigest.getInstance("MD5");
			digest.update(myPass.getBytes(), 0, myPass.length());
			String digestmd5 = new BigInteger(1, digest.digest()).toString(16);

			SOAPElement soapHeadElem = soadHeader.addChildElement("RequestSOAPHeader", "v2");
			SOAPElement soapHeadElem1 = soapHeadElem.addChildElement("spId");
			soapHeadElem1.addTextNode(spId);
			SOAPElement soapHeadElem2 = soapHeadElem.addChildElement("spPassword");
			soapHeadElem2.addTextNode(digestmd5);
			SOAPElement soapHeadElem3 = soapHeadElem.addChildElement("serviceId");
			soapHeadElem3.addTextNode(serviceId);
			SOAPElement soapHeadElem4 = soapHeadElem.addChildElement("timeStamp");
			soapHeadElem4.addTextNode(fdt);

			SOAPElement soapBodyElem = soapBody.addChildElement("startSmsNotification", "loc");
			SOAPElement soapBodyElem1 = soapBodyElem.addChildElement("reference", "loc");
			SOAPElement soapBodyElem11 = soapBodyElem1.addChildElement("endpoint");
			soapBodyElem11.addTextNode(smsReceiver);
			SOAPElement soapBodyElem12 = soapBodyElem1.addChildElement("interfaceName");
			soapBodyElem12.addTextNode("notifySmsReception");
			SOAPElement soapBodyElem13 = soapBodyElem1.addChildElement("correlator");
			soapBodyElem13.addTextNode(startCorrelator);
			SOAPElement soapBodyElem2 = soapBodyElem.addChildElement("smsServiceActivationNumber", "loc");
			soapBodyElem2.addTextNode(senderName);
			
			String strMsg = getResp(soapMessage);
			System.out.println("MESSAGE\n" + strMsg + "\n");

			SOAPConnectionFactory scFactory = SOAPConnectionFactory.newInstance();
			SOAPConnection con = scFactory.createConnection();

			URL endpoint = new URL("http://" + serverIP + ":8310/SmsNotificationManagerService/services/SmsNotificationManager");
			SOAPMessage response = con.call(soapMessage, endpoint);

			con.close();

			if(response != null) {
				strMsg = getResp(response);
				System.out.println("RESPOSE\n" + strMsg + "\n");
			}
		} catch(SOAPException ex) {
			System.out.println("SOAP Error : " + ex);
		} catch(MalformedURLException ex) {
			System.out.println("Net Error : " + ex);
		} catch(NoSuchAlgorithmException ex) {
			System.out.println("No Algorithim Error : " + ex);
		}
	}

	public void stopListener(String orgID) {
		String spId = smsOrgs.get(orgID)[0];
		String serviceId = smsOrgs.get(orgID)[1];
		String senderName = smsOrgs.get(orgID)[2];
		
		if(serviceId == null) return;
		if(senderName == null) return;

		try {
			MessageFactory factory = MessageFactory.newInstance(SOAPConstants.SOAP_1_2_PROTOCOL);
	
			SOAPMessage soapMessage = factory.createMessage();
			SOAPEnvelope soapEnvelope = soapMessage.getSOAPPart().getEnvelope();
			soapEnvelope.addNamespaceDeclaration("v2", "http://www.huawei.com.cn/schema/common/v2_1");
            soapEnvelope.addNamespaceDeclaration("loc", "http://www.csapo.org/schema/parlayx/sms/receive/v2_2/local");

			SOAPHeader soadHeader = soapMessage.getSOAPHeader();
			SOAPBody soapBody = soapMessage.getSOAPBody();			
			
			SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmmss");
			String fdt = sdf.format(new Date());
			String myPass = spId + spPassword + fdt;
			MessageDigest digest = MessageDigest.getInstance("MD5");
			digest.update(myPass.getBytes(), 0, myPass.length());
			String digestmd5 = new BigInteger(1, digest.digest()).toString(16);

			SOAPElement soapHeadElem = soadHeader.addChildElement("RequestSOAPHeader", "v2");
			SOAPElement soapHeadElem1 = soapHeadElem.addChildElement("spId");
			soapHeadElem1.addTextNode(spId);
			SOAPElement soapHeadElem2 = soapHeadElem.addChildElement("spPassword");
			soapHeadElem2.addTextNode(digestmd5);
			SOAPElement soapHeadElem3 = soapHeadElem.addChildElement("serviceId");
			soapHeadElem3.addTextNode(serviceId);
			SOAPElement soapHeadElem4 = soapHeadElem.addChildElement("timeStamp");
			soapHeadElem4.addTextNode(fdt);
			
			SOAPElement soapBodyElem = soapBody.addChildElement("stopSmsNotification", "loc");
			SOAPElement soapBodyElem1 = soapBodyElem.addChildElement("correlator", "loc");
			soapBodyElem1.addTextNode(startCorrelator);
			
			String strMsg = getResp(soapMessage);
			System.out.println("MESSAGE\n" + strMsg + "\n");

			SOAPConnectionFactory scFactory = SOAPConnectionFactory.newInstance();
			SOAPConnection con = scFactory.createConnection();

			URL endpoint = new URL("http://" + serverIP + ":8310/SmsNotificationManagerService/services/SmsNotificationManager");
			SOAPMessage response = con.call(soapMessage, endpoint);

			con.close();

			if(response != null) {
				strMsg = getResp(response);
				System.out.println("RESPOSE\n" + strMsg + "\n");
			}
		} catch(SOAPException ex) {
			System.out.println("SOAP Error : " + ex);
		} catch(MalformedURLException ex) {
			System.out.println("Net Error : " + ex);
		} catch(NoSuchAlgorithmException ex) {
			System.out.println("No Algorithim Error : " + ex);
		}
	}

	public String getResp(SOAPMessage response) {
		String rsp = "";
		String nRsp = "";
		try {
			ByteArrayOutputStream bosr = new ByteArrayOutputStream();
			response.writeTo(bosr);
			rsp = new String(bosr.toByteArray());

			int tl = rsp.length();
			int i = 0;
			int j = 0;
			int k = 0;
			while (i != -1) {
				i = rsp.indexOf("</", i+1);
				j = rsp.indexOf(">", i+1) + 1;
				if((i>-1) && (j>i) && (j <= tl))
					nRsp += rsp.substring(k, j) + "\n";
				k = j;
			}
		} catch(SOAPException ex) {
			System.out.println("SOAP Error : " + ex);
		} catch(IOException ex) {
			System.out.println("IO Error : " + ex);
		}

		return nRsp;
	}

	public boolean isExecuting() {
		return executing;
	}

	public void close() {
		for(String orgID : smsOrgs.keySet()) {
			stopListener(orgID);
			stopListener(orgID);
		}

		log.info("Closing Soap SMS Server.");
	}

}
