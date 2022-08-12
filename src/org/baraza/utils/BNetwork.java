/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.utils;


import java.io.DataOutputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.Enumeration;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.net.URL;
import java.net.InetAddress;
import java.net.InterfaceAddress;
import java.net.NetworkInterface;
import java.net.HttpURLConnection;
import java.net.SocketException;
import java.net.UnknownHostException;

public class BNetwork {

	public static void main(String[] args){
		BNetwork network = new BNetwork();
		
		try {
			Enumeration<NetworkInterface> nets = NetworkInterface.getNetworkInterfaces();
			for (NetworkInterface netint : Collections.list(nets)) {
				network.displayInterfaceInformation(netint);
			}
		} catch (SocketException e) {
			e.printStackTrace();
		}
		
		Properties props = System.getProperties();
		for(String prop : props.stringPropertyNames()) {
			System.out.println("Prop : " + prop + " = " + props.getProperty(prop));
		}
		
		Map<String,String> envs = System.getenv();
		for(String env : envs.keySet()) {
			System.out.println("Env : " + env + " = " + envs.get(env));
		}
	}
	
	public String getMACAddress(String networkIP) {
		String sb = null;
		
		try {
			InetAddress ipAddr = InetAddress.getByName(networkIP);
			if(ipAddr == null) return null;
			
			sb = getMACAddress(ipAddr);
		} catch(UnknownHostException ex) {
			System.out.println("Error on MACAddress " + ex);
		}
		
		return sb;
	}

	
	public String getMACAddress(InetAddress ipAddr) {
		StringBuilder sb = new StringBuilder();
		
		try {
			NetworkInterface netint = NetworkInterface.getByInetAddress(ipAddr);
			if(netint == null) return null;
			if(netint.getHardwareAddress() == null) return null;
				
			byte[] mac = netint.getHardwareAddress();
			for (int i = 0; i < mac.length; i++) sb.append(String.format("%02X%s", mac[i], ""));
			System.out.println("Current MAC address : " + sb.toString());
		} catch(SocketException ex) {
			System.out.println("Error on MACAddress " + ex);
		}
		
		return sb.toString();
	}

	private void displayInterfaceInformation(NetworkInterface netint) throws SocketException {
		System.out.printf("Display name: %s%n", netint.getDisplayName());
		System.out.printf("Name: %s%n", netint.getName());
		Enumeration<InetAddress> inetAddresses = netint.getInetAddresses();
		for (InetAddress inetAddress : Collections.list(inetAddresses)) {
			System.out.printf("InetAddress: %s%n", inetAddress);
		}

		System.out.printf("Parent: %s%n", netint.getParent());
		System.out.printf("Up? %s%n", netint.isUp());
		System.out.printf("Loopback? %s%n", netint.isLoopback());
		System.out.printf("PointToPoint? %s%n", netint.isPointToPoint());
		System.out.printf("Supports multicast? %s%n", netint.isVirtual());
		System.out.printf("Virtual? %s%n", netint.isVirtual());
		if(netint.getHardwareAddress() != null) displayMACAddress(netint.getHardwareAddress());
		System.out.printf("MTU: %s%n", netint.getMTU());

		List<InterfaceAddress> interfaceAddresses = netint.getInterfaceAddresses();
		for (InterfaceAddress addr : interfaceAddresses) {
			System.out.printf("InterfaceAddress: %s%n", addr.getAddress());
		}
		System.out.printf("%n");
		Enumeration<NetworkInterface> subInterfaces = netint.getSubInterfaces();
		for (NetworkInterface networkInterface : Collections.list(subInterfaces)) {
			System.out.printf("%nSubInterface%n");
			displayInterfaceInformation(networkInterface);
		}
		System.out.printf("%n");
	}

	private void displayMACAddress(byte[] mac) {
		StringBuilder sb = new StringBuilder();
		for (int i = 0; i < mac.length; i++) {
			sb.append(String.format("%02X%s", mac[i], (i < mac.length - 1) ? "-" : ""));		
		}
		System.out.println("Current MAC address : " + sb.toString());
		sb = new StringBuilder();
		for (int i = 0; i < mac.length; i++) {
			sb.append(String.format("%02X%s", mac[i], ""));		
		}
		System.out.println("Current MAC address : " + sb.toString());
	}
	
	
	// HTTP POST request
	public String sendPost(URL myURL, Map<String, String> params) {
		StringBuffer response = new StringBuffer();
		try {
			HttpURLConnection con = (HttpURLConnection) myURL.openConnection();
			
			String urlParameters = null;
			for(String param : params.keySet()) {
				if(urlParameters==null) urlParameters = param + "=" + params.get(param);
				else urlParameters += "&" + param + "=" + params.get(param);
			}
			
			//add reuqest header
			con.setRequestMethod("POST");
			con.setRequestProperty("User-Agent", "Mozilla/5.0");
			con.setRequestProperty("Accept-Language", "en-US,en;q=0.5");

			// Send post request
			con.setDoOutput(true);
			DataOutputStream wr = new DataOutputStream(con.getOutputStream());
			wr.writeBytes(urlParameters);
			wr.flush();
			wr.close();

			int responseCode = con.getResponseCode();
			System.out.println("\nSending 'POST' request to URL : " + myURL.toString());
			System.out.println("Post parameters : " + urlParameters);
			System.out.println("Response Code : " + responseCode);

			BufferedReader in = new BufferedReader(new InputStreamReader(con.getInputStream()));
			String inputLine;
			while ((inputLine = in.readLine()) != null) response.append(inputLine);
			in.close();

			//print result
			System.out.println(response.toString());
		} catch(IOException ex) {
			System.out.println("BNetwork sendPost : " + ex);
		}
		
		return response.toString();
	}
}
